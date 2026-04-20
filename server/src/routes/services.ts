import { Router, Response } from "express";
import pool from "../db/client";
import { authenticateToken, AuthRequest } from "../middleware/auth";

const router = Router();

// GET /services?outletId=
router.get("/", authenticateToken, async (req: AuthRequest, res: Response): Promise<void> => {
  const { outletId } = req.query;

  try {
    const result = await pool.query(
      "SELECT * FROM services WHERE outlet_id::text = $1::text ORDER BY name ASC",
      [String(outletId)]
    );
    res.json({ services: result.rows });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Terjadi kesalahan server" });
  }
});

// POST /services - tambah layanan
router.post("/", authenticateToken, async (req: AuthRequest, res: Response): Promise<void> => {
  const { outletId, name, price, unit, minQuantity } = req.body;

  if (!name || !name.trim()) {
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
    const result = await pool.query(
      `INSERT INTO services (outlet_id, owner_id, name, price, unit, min_quantity)
       VALUES ($1::text, $2::text, $3::text, $4::integer, $5::text, $6)
       RETURNING *`,
      [outletId, req.userId, name.trim(), priceNum, unit?.trim() ?? "kg", minQty]
    );
    res.status(201).json({ service: result.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Terjadi kesalahan server" });
  }
});

// PUT /services/:id - edit layanan
router.put("/:id", authenticateToken, async (req: AuthRequest, res: Response): Promise<void> => {
  const { id } = req.params;
  const { name, price, unit, minQuantity } = req.body;

  if (!name || !name.trim()) {
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
    const result = await pool.query(
      `UPDATE services SET name = $1, price = $2, unit = $3, min_quantity = $4
       WHERE id::text = $5::text
       RETURNING *`,
      [name.trim(), priceNum, unit?.trim() ?? "kg", minQty, id]
    );

    if (result.rows.length === 0) {
      res.status(404).json({ message: "Layanan tidak ditemukan" });
      return;
    }

    res.json({ service: result.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Terjadi kesalahan server" });
  }
});

// DELETE /services/:id - hapus layanan
router.delete("/:id", authenticateToken, async (req: AuthRequest, res: Response): Promise<void> => {
  const { id } = req.params;

  try {
    const result = await pool.query(
      "DELETE FROM services WHERE id::text = $1::text RETURNING id",
      [id]
    );

    if (result.rows.length === 0) {
      res.status(404).json({ message: "Layanan tidak ditemukan" });
      return;
    }

    res.json({ message: "Layanan berhasil dihapus" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Terjadi kesalahan server" });
  }
});

export default router;
