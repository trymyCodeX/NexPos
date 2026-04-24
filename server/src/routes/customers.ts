import { Router, Response } from "express";
import pool from "../db/client";
import { authenticateToken, AuthRequest } from "../middleware/auth";

const router = Router();

// BUG FIX: GET /customers/search HARUS sebelum GET /:id agar tidak tertangkap wildcard
router.get("/search", authenticateToken, async (req: AuthRequest, res: Response): Promise<void> => {
  const { q, outletId } = req.query;
  const effectiveOutletId = outletId ?? req.outletId;

  if (!q) {
    res.status(400).json({ message: "Parameter pencarian wajib diisi" });
    return;
  }

  if (!effectiveOutletId) {
    res.status(400).json({ message: "outletId wajib diisi" });
    return;
  }

  try {
    const result = await pool.query(
      `SELECT * FROM customers
       WHERE outlet_id::text = $1::text
         AND (name ILIKE $2 OR phone ILIKE $2)
       ORDER BY name ASC`,
      [String(effectiveOutletId), `%${q}%`]
    );
    res.json({ customers: result.rows });
  } catch (err) {
    console.error("[Customers search]", err);
    res.status(500).json({ message: "Terjadi kesalahan server" });
  }
});

// BUG FIX: GET /customers - fallback ke req.outletId jika outletId tidak dikirim
router.get("/", authenticateToken, async (req: AuthRequest, res: Response): Promise<void> => {
  const outletId = req.query.outletId ?? req.outletId;

  if (!outletId) {
    res.status(400).json({ message: "outletId wajib diisi" });
    return;
  }

  try {
    const result = await pool.query(
      "SELECT * FROM customers WHERE outlet_id::text = $1::text ORDER BY name ASC",
      [String(outletId)]
    );
    res.json({ customers: result.rows });
  } catch (err) {
    console.error("[Customers GET]", err);
    res.status(500).json({ message: "Terjadi kesalahan server" });
  }
});

router.post("/", authenticateToken, async (req: AuthRequest, res: Response): Promise<void> => {
  const { outletId, name, phone, address } = req.body;
  const effectiveOutletId = outletId ?? req.outletId;

  if (!name || !String(name).trim()) {
    res.status(400).json({ message: "Nama customer wajib diisi" });
    return;
  }

  if (!effectiveOutletId) {
    res.status(400).json({ message: "outletId wajib diisi" });
    return;
  }

  if (phone && !/^[0-9+\-\s]{7,20}$/.test(String(phone).trim())) {
    res.status(400).json({ message: "Nomor telepon tidak valid" });
    return;
  }

  try {
    // BUG FIX: validasi outlet milik user yang sedang login
    const outletCheck = await pool.query(
      "SELECT id FROM outlets WHERE (id::text = $1::text OR client_id::text = $1::text) AND owner_id::text = $2::text LIMIT 1",
      [String(effectiveOutletId), String(req.userId)]
    );
    if (!outletCheck.rows.length) {
      res.status(403).json({ message: "Outlet tidak ditemukan atau bukan milik Anda" });
      return;
    }

    const result = await pool.query(
      `INSERT INTO customers (outlet_id, owner_id, name, phone, address)
       VALUES ($1::text, $2::text, $3::text, $4::text, $5::text)
       RETURNING *`,
      [String(effectiveOutletId), String(req.userId), String(name).trim(), String(phone ?? "").trim(), String(address ?? "").trim()]
    );
    res.status(201).json({ customer: result.rows[0] });
  } catch (err) {
    console.error("[Customers POST]", err);
    res.status(500).json({ message: "Terjadi kesalahan server" });
  }
});

router.put("/:id", authenticateToken, async (req: AuthRequest, res: Response): Promise<void> => {
  const { id } = req.params;
  const { name, phone, address } = req.body;

  if (!name || !String(name).trim()) {
    res.status(400).json({ message: "Nama customer wajib diisi" });
    return;
  }

  if (phone && !/^[0-9+\-\s]{7,20}$/.test(String(phone).trim())) {
    res.status(400).json({ message: "Nomor telepon tidak valid" });
    return;
  }

  try {
    // BUG FIX: validasi kepemilikan dengan owner_id
    const result = await pool.query(
      `UPDATE customers SET name = $1, phone = $2, address = $3
       WHERE id::text = $4::text AND owner_id::text = $5::text
       RETURNING *`,
      [String(name).trim(), String(phone ?? "").trim(), String(address ?? "").trim(), id, String(req.userId)]
    );

    if (result.rows.length === 0) {
      res.status(404).json({ message: "Customer tidak ditemukan" });
      return;
    }

    res.json({ customer: result.rows[0] });
  } catch (err) {
    console.error("[Customers PUT]", err);
    res.status(500).json({ message: "Terjadi kesalahan server" });
  }
});

router.delete("/:id", authenticateToken, async (req: AuthRequest, res: Response): Promise<void> => {
  const { id } = req.params;

  try {
    // BUG FIX: validasi kepemilikan dengan owner_id
    const result = await pool.query(
      "DELETE FROM customers WHERE id::text = $1::text AND owner_id::text = $2::text RETURNING id",
      [id, String(req.userId)]
    );

    if (result.rows.length === 0) {
      res.status(404).json({ message: "Customer tidak ditemukan" });
      return;
    }

    res.json({ message: "Customer berhasil dihapus" });
  } catch (err) {
    console.error("[Customers DELETE]", err);
    res.status(500).json({ message: "Terjadi kesalahan server" });
  }
});

export default router;
