import { Router, Response } from "express";
import pool from "../db/client";
import { authenticateToken, AuthRequest } from "../middleware/auth";

const router = Router();

const VALID_STATUSES = ["diterima", "dicuci", "disetrika", "selesai", "dibatalkan"];
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

const TX_JOIN_SELECT = `
  SELECT t.*,
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
`;

// FIX #2: Tambah pagination (limit/offset) agar tidak load semua data sekaligus
router.get("/", authenticateToken, async (req: AuthRequest, res: Response): Promise<void> => {
  const queryOutletId = req.query.outletId;
  const tokenOutletId = req.outletId;
  const limit = Math.min(parseInt(String(req.query.limit ?? "100"), 10), 500);
  const offset = Math.max(parseInt(String(req.query.offset ?? "0"), 10), 0);

  try {
    let result;
    if (queryOutletId) {
      result = await pool.query(
        `${TX_JOIN_SELECT}
         WHERE t.outlet_id::text = $1::text OR o.client_id::text = $1::text
         ORDER BY t.created_at DESC LIMIT $2 OFFSET $3`,
        [String(queryOutletId), limit, offset]
      );
    } else if (tokenOutletId) {
      result = await pool.query(
        `${TX_JOIN_SELECT}
         WHERE t.outlet_id::text = $1::text OR o.client_id::text = $1::text
         ORDER BY t.created_at DESC LIMIT $2 OFFSET $3`,
        [String(tokenOutletId), limit, offset]
      );
    } else {
      result = await pool.query(
        `${TX_JOIN_SELECT}
         WHERE o.owner_id::text = $1::text
         ORDER BY t.created_at DESC LIMIT $2 OFFSET $3`,
        [String(req.userId), limit, offset]
      );
    }

    res.json({ transactions: result.rows.map(toTransactionPayload) });
  } catch (err) {
    console.error("[Transactions GET]", err);
    res.status(500).json({ message: "Terjadi kesalahan server" });
  }
});

router.post("/", authenticateToken, async (req: AuthRequest, res: Response): Promise<void> => {
  const { outletId, customerId, serviceId, quantity } = req.body;

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
    const serviceResult = await pool.query(
      "SELECT id, name, price, min_quantity FROM services WHERE id::text = $1::text",
      [serviceId]
    );

    if (!serviceResult.rows.length) {
      res.status(400).json({ message: "Layanan tidak ditemukan" });
      return;
    }

    const service = serviceResult.rows[0];
    const price = service.price ?? 0;
    const minQty = service.min_quantity ? Number(service.min_quantity) : null;
    const effectiveQty = minQty !== null && qty < minQty ? minQty : qty;
    const total_amount = price * effectiveQty;

    const customerResult = await pool.query(
      "SELECT name FROM customers WHERE id::text = $1::text LIMIT 1",
      [customerId]
    );
    const outletResult = await pool.query(
      "SELECT name FROM outlets WHERE id::text = $1::text OR client_id::text = $1::text LIMIT 1",
      [String(outletId)]
    );

    const customerName = customerResult.rows[0]?.name ?? null;
    const outletName = outletResult.rows[0]?.name ?? null;

    // FIX #5: Isi kolom legacy 'customer' dan 'service' (text) agar tidak NULL
    const result = await pool.query(
      `INSERT INTO transactions
         (outlet_id, owner_id, customer_id, service_id, customer, service, quantity, total_amount, status)
       VALUES ($1::text, $2::text, $3::uuid, $4::uuid, $5::text, $6::text, $7::float, $8::integer, 'diterima')
       RETURNING id`,
      [String(outletId), String(req.userId), customerId, serviceId, customerName, service.name, effectiveQty, total_amount]
    );

    const insertedId = result.rows[0].id;

    // FIX #4: Fetch ulang dengan JOIN agar response berisi nama customer, layanan, outlet
    const fullTxResult = await pool.query(
      `${TX_JOIN_SELECT} WHERE t.id = $1`,
      [insertedId]
    );
    const tx = fullTxResult.rows[0];

    pool.query(
      `INSERT INTO transaction_logs
         (transaction_id, action, owner_id, outlet_id, outlet_name, customer_name, service_name, quantity, total_amount, status, actor_type, notes)
       VALUES ($1, 'created', $2, $3, $4, $5, $6, $7, $8, 'diterima', 'kasir', $9)`,
      [
        insertedId, String(req.userId), String(outletId),
        outletName, customerName, service.name, effectiveQty, total_amount,
        minQty !== null && qty < minQty ? `Input ${qty}, dihitung dari minimal ${minQty}` : null,
      ]
    ).catch((logErr: Error) => console.warn("[LOG] Gagal simpan log transaksi:", logErr));

    res.status(201).json(toTransactionPayload(tx));
  } catch (err) {
    console.error("[Transactions POST]", err);
    res.status(500).json({ message: "Terjadi kesalahan server" });
  }
});

// FIX #1a: Tambah log perubahan status ke transaction_logs (route body)
router.put("/status", authenticateToken, async (req: AuthRequest, res: Response): Promise<void> => {
  const { transactionId, status } = req.body;
  const normalizedStatus = normalizeStatus(status);

  if (!transactionId || !status) {
    res.status(400).json({ message: "ID transaksi dan status wajib diisi" });
    return;
  }

  if (!normalizedStatus) {
    res.status(400).json({ message: `Status tidak valid. Gunakan: ${VALID_STATUSES.join(", ")}` });
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
         )
       RETURNING *`,
      [normalizedStatus, String(transactionId), String(req.userId), outletIdStr]
    );

    if (result.rows.length === 0) {
      res.status(404).json({ message: "Transaksi tidak ditemukan" });
      return;
    }

    const tx = result.rows[0];

    pool.query(
      `INSERT INTO transaction_logs
         (transaction_id, action, owner_id, outlet_id, status, actor_type, notes)
       VALUES ($1, 'status_changed', $2, $3, $4, 'kasir', $5)`,
      [tx.id, String(req.userId), tx.outlet_id, normalizedStatus, `Status diubah menjadi ${normalizedStatus}`]
    ).catch((logErr: Error) => console.warn("[LOG] Gagal simpan log status:", logErr));

    const transaction = toTransactionPayload(tx);
    res.json({ ...transaction, transaction: tx, message: "Status transaksi berhasil diperbarui" });
  } catch (err) {
    console.error("[Transactions PUT /status]", err);
    res.status(500).json({ message: "Terjadi kesalahan server" });
  }
});

// FIX #1b: Tambah log perubahan status ke transaction_logs (route param)
router.put("/:id/status", authenticateToken, async (req: AuthRequest, res: Response): Promise<void> => {
  const { id } = req.params;
  const { status } = req.body;
  const normalizedStatus = normalizeStatus(status);

  if (!status) {
    res.status(400).json({ message: "Status wajib diisi" });
    return;
  }

  if (!normalizedStatus) {
    res.status(400).json({ message: `Status tidak valid. Gunakan: ${VALID_STATUSES.join(", ")}` });
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
         )
       RETURNING *`,
      [normalizedStatus, id, String(req.userId), outletIdStr]
    );

    if (result.rows.length === 0) {
      res.status(404).json({ message: "Transaksi tidak ditemukan" });
      return;
    }

    const tx = result.rows[0];

    pool.query(
      `INSERT INTO transaction_logs
         (transaction_id, action, owner_id, outlet_id, status, actor_type, notes)
       VALUES ($1, 'status_changed', $2, $3, $4, 'kasir', $5)`,
      [parseInt(id), String(req.userId), tx.outlet_id, normalizedStatus, `Status diubah menjadi ${normalizedStatus}`]
    ).catch((logErr: Error) => console.warn("[LOG] Gagal simpan log status:", logErr));

    const transaction = toTransactionPayload(tx);
    res.json({ ...transaction, transaction: tx, message: "Status transaksi berhasil diperbarui" });
  } catch (err) {
    console.error("[Transactions PUT /:id/status]", err);
    res.status(500).json({ message: "Terjadi kesalahan server" });
  }
});

router.delete("/:id", authenticateToken, async (req: AuthRequest, res: Response): Promise<void> => {
  const { id } = req.params;

  try {
    const check = await pool.query(
      `SELECT t.id, t.owner_id, t.outlet_id, t.customer_id, t.service_id, t.quantity, t.total_amount, t.status,
              c.name AS customer_name,
              s.name AS service_name,
              o.name AS outlet_name
       FROM transactions t
       LEFT JOIN outlets o ON t.outlet_id::text = o.id::text OR t.outlet_id::text = o.client_id::text
       LEFT JOIN customers c ON t.customer_id::text = c.id::text
       LEFT JOIN services s ON t.service_id::text = s.id::text
       WHERE t.id::text = $1::text
         AND (
           t.owner_id::text = $2::text
           OR o.owner_id::text = $2::text
           OR t.outlet_id::text = $3::text
           OR o.id::text = $3::text
           OR o.client_id::text = $3::text
         )`,
      [id, String(req.userId), req.outletId ? String(req.outletId) : ""]
    );

    if (check.rows.length === 0) {
      res.status(404).json({ message: "Transaksi tidak ditemukan atau akses ditolak" });
      return;
    }

    const txData = check.rows[0];

    await pool.query("DELETE FROM transactions WHERE id::text = $1::text", [id]);

    pool.query(
      `INSERT INTO transaction_logs
         (transaction_id, action, owner_id, outlet_id, outlet_name, customer_name, service_name, quantity, total_amount, status, actor_type, notes)
       VALUES ($1, 'deleted', $2, $3, $4, $5, $6, $7, $8, $9, 'kasir', 'Transaksi dihapus')`,
      [
        parseInt(id), String(req.userId), txData.outlet_id, txData.outlet_name,
        txData.customer_name, txData.service_name, txData.quantity, txData.total_amount, txData.status,
      ]
    ).catch((logErr: Error) => console.warn("[LOG] Gagal simpan log hapus transaksi:", logErr));

    res.json({ message: "Transaksi berhasil dihapus" });
  } catch (err) {
    console.error("[Transactions DELETE]", err);
    res.status(500).json({ message: "Terjadi kesalahan server" });
  }
});

export default router;
