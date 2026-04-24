import { Router, Response } from "express";
import pool from "../db/client";
import { authenticateToken, AuthRequest } from "../middleware/auth";

const router = Router();

// BUG FIX: GET /services - wajib ada outletId, fallback ke req.outletId jika tidak dikirim
router.get("/", authenticateToken, async (req: AuthRequest, res: Response): Promise<void> => {
  const outletId = req.query.outletId ?? req.outletId;

  if (!outletId) {
    res.status(400).json({ message: "outletId wajib diisi" });
    return;
  }

  try {
    const result = await pool.query(
      `SELECT * FROM services
       WHERE outlet_id::text = $1::text
       ORDER BY name ASC`,
      [String(outletId)]
    );
    res.json({ services: result.rows });
  } catch (err) {
    console.error("[Services GET]", err);
    res.status(500).json({ message: "Terjadi kesalahan server" });
  }
});

router.post("/", authenticateToken, async (req: AuthRequest, res: Response): Promise<void> => {
  const { outletId, name, price, unit, minQuantity } = req.body;

  if (!name || !String(name).trim()) {
    res.status(400).json({ message: "Nama layanan wajib diisi" });
    return;
  }

  const priceNum = Number(price);
  if (!price || isNaN(priceNum) || priceNum <= 0) {
    res.status(400).json({ message: "Harga harus lebih dari 0" });
    return;
  }

  const minQty = minQuantity != null && minQuantity !== "" ? Number(minQuantity) : null;
  if (minQty !== null && (isNaN(minQty) || minQty <= 0)) {
    res.status(400).json({ message: "Minimal quantity harus lebih dari 0" });
    return;
  }

  const effectiveOutletId = outletId ?? req.outletId;
  if (!effectiveOutletId) {
    res.status(400).json({ message: "outletId wajib diisi" });
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
      `INSERT INTO services (outlet_id, owner_id, name, price, unit, min_quantity)
       VALUES ($1::text, $2::text, $3::text, $4::integer, $5::text, $6)
       RETURNING *`,
      [String(effectiveOutletId), String(req.userId), String(name).trim(), priceNum, String(unit ?? "kg").trim(), minQty]
    );
    res.status(201).json({ service: result.rows[0] });
  } catch (err) {
    console.error("[Services POST]", err);
    res.status(500).json({ message: "Terjadi kesalahan server" });
  }
});

router.put("/:id", authenticateToken, async (req: AuthRequest, res: Response): Promise<void> => {
  const { id } = req.params;
  const { name, price, unit, minQuantity } = req.body;

  if (!name || !String(name).trim()) {
    res.status(400).json({ message: "Nama layanan wajib diisi" });
    return;
  }

  const priceNum = Number(price);
  if (!price || isNaN(priceNum) || priceNum <= 0) {
    res.status(400).json({ message: "Harga harus lebih dari 0" });
    return;
  }

  const minQty = minQuantity != null && minQuantity !== "" ? Number(minQuantity) : null;
  if (minQty !== null && (isNaN(minQty) || minQty <= 0)) {
    res.status(400).json({ message: "Minimal quantity harus lebih dari 0" });
    return;
  }

  try {
    // BUG FIX: validasi kepemilikan dengan owner_id
    const result = await pool.query(
      `UPDATE services SET name = $1, price = $2, unit = $3, min_quantity = $4
       WHERE id::text = $5::text AND owner_id::text = $6::text
       RETURNING *`,
      [String(name).trim(), priceNum, String(unit ?? "kg").trim(), minQty, id, String(req.userId)]
    );

    if (result.rows.length === 0) {
      res.status(404).json({ message: "Layanan tidak ditemukan" });
      return;
    }

    res.json({ service: result.rows[0] });
  } catch (err) {
    console.error("[Services PUT]", err);
    res.status(500).json({ message: "Terjadi kesalahan server" });
  }
});

router.delete("/:id", authenticateToken, async (req: AuthRequest, res: Response): Promise<void> => {
  const { id } = req.params;

  try {
    // BUG FIX: validasi kepemilikan dengan owner_id
    const result = await pool.query(
      "DELETE FROM services WHERE id::text = $1::text AND owner_id::text = $2::text RETURNING id",
      [id, String(req.userId)]
    );

    if (result.rows.length === 0) {
      res.status(404).json({ message: "Layanan tidak ditemukan" });
      return;
    }

    res.json({ message: "Layanan berhasil dihapus" });
  } catch (err) {
    console.error("[Services DELETE]", err);
    res.status(500).json({ message: "Terjadi kesalahan server" });
  }
});

export default router;
