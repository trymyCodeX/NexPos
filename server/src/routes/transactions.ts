import { Router, Response } from "express";
import pool from "../db/client";
import { authenticateToken, AuthRequest } from "../middleware/auth";

const router = Router();

const VALID_STATUSES = ["pending", "process", "done", "picked", "diterima", "dicuci", "disetrika", "selesai", "dibatalkan"];
const STATUS_ALIASES: Record<string, string> = {
  "terima": "diterima",
  "diterima": "diterima",
  "received": "diterima",
  "pending": "diterima",
  "cuci": "dicuci",
  "dicuci": "dicuci",
  "proses": "dicuci",
  "process": "dicuci",
  "processing": "dicuci",
  "setrika": "disetrika",
  "disetrika": "disetrika",
  "selesai": "selesai",
  "done": "selesai",
  "picked": "selesai",
  "batal": "dibatalkan",
  "dibatalkan": "dibatalkan",
  "cancelled": "dibatalkan",
  "canceled": "dibatalkan",
};

function safeInt(value: unknown): number {
  const n = Number(value);
  return Number.isFinite(n) ? Math.floor(n) : 0;
}

function normalizeStatus(value: unknown): string | null {
  const raw = String(value ?? "").trim().toLowerCase();
  if (!raw) return null;
  return STATUS_ALIASES[raw] ?? (VALID_STATUSES.includes(raw) ? raw : null);
}

function toTransactionPayload(t: any) {
  return {
    id: safeInt(t.id),
    outletId: safeInt(t.outlet_client_id ?? t.outlet_id),
    outletName: t.outlet_name ?? null,
    customerId: t.customer_id,
    customer: t.customer_name ?? t.customer ?? "",
    customerName: t.customer_name ?? t.customer ?? "",
    serviceId: t.service_id,
    service: t.service_name ?? t.service ?? null,
    serviceName: t.service_name ?? t.service ?? null,
    servicePrice: t.service_price ?? null,
    serviceUnit: t.service_unit ?? null,
    quantity: t.quantity ?? 1,
    amount: parseFloat(t.total_amount ?? t.amount ?? 0),
    totalAmount: parseFloat(t.total_amount ?? t.amount ?? 0),
    status: t.status,
    createdAt: t.created_at,
    updatedAt: t.updated_at,
  };
}

// GET /transactions - ambil semua transaksi dengan JOIN customer & service
router.get("/", authenticateToken, async (req: AuthRequest, res: Response): Promise<void> => {
  const { outletId } = req.query;

  try {
    let result;
    if (outletId) {
      result = await pool.query(
        `SELECT t.*,
                c.name AS customer_name,
                s.name AS service_name,
                s.price AS service_price,
                s.unit AS service_unit,
                o.client_id AS outlet_client_id,
                o.name AS outlet_name
         FROM transactions t
         LEFT JOIN customers c ON t.customer_id = c.id
         LEFT JOIN services s ON t.service_id = s.id
         LEFT JOIN outlets o ON t.outlet_id::text = o.id::text OR t.outlet_id::text = o.client_id::text
         WHERE t.outlet_id::text = $1::text OR o.client_id::text = $1::text
         ORDER BY t.created_at DESC`,
        [outletId]
      );
    } else if (req.outletId) {
      result = await pool.query(
        `SELECT t.*,
                c.name AS customer_name,
                s.name AS service_name,
                s.price AS service_price,
                s.unit AS service_unit,
                o.client_id AS outlet_client_id,
                o.name AS outlet_name
         FROM transactions t
         LEFT JOIN customers c ON t.customer_id = c.id
         LEFT JOIN services s ON t.service_id = s.id
         LEFT JOIN outlets o ON t.outlet_id::text = o.id::text OR t.outlet_id::text = o.client_id::text
         WHERE t.outlet_id::text = $1::text OR o.client_id::text = $1::text
         ORDER BY t.created_at DESC`,
        [req.outletId]
      );
    } else {
      result = await pool.query(
        `SELECT t.*,
                c.name AS customer_name,
                s.name AS service_name,
                s.price AS service_price,
                s.unit AS service_unit,
                o.client_id AS outlet_client_id,
                o.name AS outlet_name
         FROM transactions t
         LEFT JOIN customers c ON t.customer_id = c.id
         LEFT JOIN services s ON t.service_id = s.id
         LEFT JOIN outlets o ON t.outlet_id::text = o.id::text OR t.outlet_id::text = o.client_id::text
         WHERE o.owner_id::text = $1::text
         ORDER BY t.created_at DESC`,
        [req.userId]
      );
    }

    res.json({
      transactions: result.rows.map(toTransactionPayload),
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Terjadi kesalahan server" });
  }
});

// POST /transactions - buat transaksi baru (harga otomatis dari service)
router.post("/", authenticateToken, async (req: AuthRequest, res: Response): Promise<void> => {
  const { outletId, customerId, serviceId, quantity } = req.body;

  // Flow baru: wajib pakai customerId + serviceId
  if (!outletId || !customerId || !serviceId) {
    res.status(400).json({ message: "outletId, customerId, dan serviceId wajib diisi" });
    return;
  }

  const qty = Number(quantity);
  if (!quantity || isNaN(qty) || qty <= 0) {
    res.status(400).json({ message: "Quantity harus lebih dari 0" });
    return;
  }

  try {
    // Ambil harga dari tabel services (otomatis)
    const serviceResult = await pool.query(
      "SELECT id, name, price FROM services WHERE id::text = $1::text",
      [serviceId]
    );

    if (!serviceResult.rows.length) {
      res.status(400).json({ message: "Layanan tidak ditemukan" });
      return;
    }

    const service = serviceResult.rows[0];
    const price = service.price ?? 0;
    const total_amount = price * qty; // harga × quantity = total otomatis

    const result = await pool.query(
      `INSERT INTO transactions
         (outlet_id, owner_id, customer_id, service_id, quantity, total_amount, status)
       VALUES ($1::text, $2::text, $3::uuid, $4::uuid, $5::float, $6::integer, 'diterima')
       RETURNING *`,
      [outletId, req.userId, customerId, serviceId, qty, total_amount]
    );

    const transaction = toTransactionPayload(result.rows[0]);
    res.status(201).json({ ...transaction, transaction: result.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Terjadi kesalahan server" });
  }
});

// PUT /transactions/status (legacy support) - HARUS sebelum /:id/status agar tidak tertimpa wildcard /:id
router.put("/status", authenticateToken, async (req: AuthRequest, res: Response): Promise<void> => {
  const { transactionId, status } = req.body;
  const normalizedStatus = normalizeStatus(status);

  if (!transactionId || !status) {
    res.status(400).json({ message: "ID transaksi dan status wajib diisi" });
    return;
  }

  if (!normalizedStatus) {
    res.status(400).json({
      message: `Status tidak valid. Gunakan: ${VALID_STATUSES.join(", ")}`,
    });
    return;
  }

  const outletIdStr = req.outletId ? String(req.outletId) : "";

  try {
    const result = await pool.query(
      `UPDATE transactions SET status = $1, updated_at = NOW()
       WHERE id::text = $2::text
         AND (
           owner_id::text = $3::text
           OR outlet_id::text = $4::text
           OR EXISTS (
             SELECT 1 FROM outlets o
             WHERE (transactions.outlet_id::text = o.id::text OR transactions.outlet_id::text = o.client_id::text)
               AND (o.owner_id::text = $3::text OR o.id::text = $4::text OR o.client_id::text = $4::text)
           )
           OR EXISTS (
             SELECT 1 FROM customers c
             WHERE transactions.customer_id::text = c.id::text AND c.owner_id::text = $3::text
           )
           OR EXISTS (
             SELECT 1 FROM services s
             WHERE transactions.service_id::text = s.id::text AND s.owner_id::text = $3::text
           )
         )
       RETURNING *`,
      [normalizedStatus, String(transactionId), String(req.userId), outletIdStr]
    );

    if (result.rows.length === 0) {
      res.status(404).json({ message: "Transaksi tidak ditemukan" });
      return;
    }

    const transaction = toTransactionPayload(result.rows[0]);
    res.json({ ...transaction, transaction: result.rows[0], message: "Status transaksi berhasil diperbarui" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Terjadi kesalahan server" });
  }
});

// PUT /transactions/:id/status - ubah status transaksi by path param
router.put("/:id/status", authenticateToken, async (req: AuthRequest, res: Response): Promise<void> => {
  const { id } = req.params;
  const { status } = req.body;
  const normalizedStatus = normalizeStatus(status);

  if (!status) {
    res.status(400).json({ message: "Status wajib diisi" });
    return;
  }

  if (!normalizedStatus) {
    res.status(400).json({
      message: `Status tidak valid. Gunakan: ${VALID_STATUSES.join(", ")}`,
    });
    return;
  }

  const outletIdStr = req.outletId ? String(req.outletId) : "";

  try {
    const result = await pool.query(
      `UPDATE transactions SET status = $1::text, updated_at = NOW()
       WHERE id::text = $2::text
         AND (
           owner_id::text = $3::text
           OR outlet_id::text = $4::text
           OR EXISTS (
             SELECT 1 FROM outlets o
             WHERE (transactions.outlet_id::text = o.id::text OR transactions.outlet_id::text = o.client_id::text)
               AND (o.owner_id::text = $3::text OR o.id::text = $4::text OR o.client_id::text = $4::text)
           )
           OR EXISTS (
             SELECT 1 FROM customers c
             WHERE transactions.customer_id::text = c.id::text AND c.owner_id::text = $3::text
           )
           OR EXISTS (
             SELECT 1 FROM services s
             WHERE transactions.service_id::text = s.id::text AND s.owner_id::text = $3::text
           )
         )
       RETURNING *`,
      [normalizedStatus, id, String(req.userId), outletIdStr]
    );

    if (result.rows.length === 0) {
      res.status(404).json({ message: "Transaksi tidak ditemukan" });
      return;
    }

    const transaction = toTransactionPayload(result.rows[0]);
    res.json({ ...transaction, transaction: result.rows[0], message: "Status transaksi berhasil diperbarui" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Terjadi kesalahan server" });
  }
});

// DELETE /transactions/:id - hapus transaksi (owner atau device dengan outlet yang sama)
router.delete("/:id", authenticateToken, async (req: AuthRequest, res: Response): Promise<void> => {
  const { id } = req.params;

  try {
    const check = await pool.query(
      `SELECT t.id FROM transactions t
       LEFT JOIN outlets o ON t.outlet_id::text = o.id::text OR t.outlet_id::text = o.client_id::text
       WHERE t.id::text = $1::text
         AND (
           t.owner_id::text = $2::text
           OR o.owner_id::text = $2::text
           OR t.outlet_id::text = $3::text
           OR o.id::text = $3::text
           OR o.client_id::text = $3::text
           OR EXISTS (
             SELECT 1 FROM customers c
             WHERE t.customer_id::text = c.id::text AND c.owner_id::text = $2::text
           )
           OR EXISTS (
             SELECT 1 FROM services s
             WHERE t.service_id::text = s.id::text AND s.owner_id::text = $2::text
           )
         )`,
      [id, String(req.userId), req.outletId ? String(req.outletId) : ""]
    );

    if (check.rows.length === 0) {
      res.status(404).json({ message: "Transaksi tidak ditemukan atau akses ditolak" });
      return;
    }

    await pool.query("DELETE FROM transactions WHERE id::text = $1::text", [id]);
    res.json({ message: "Transaksi berhasil dihapus" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Terjadi kesalahan server" });
  }
});

export default router;
