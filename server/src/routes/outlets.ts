import { Router, Response } from "express";
import { nanoid } from "../utils/nanoid";
import pool from "../db/client";
import { authenticateToken, AuthRequest } from "../middleware/auth";

const router = Router();

function safeInt(value: unknown): number {
  const n = Number(value);
  return Number.isFinite(n) ? Math.floor(n) : 0;
}

router.get("/", authenticateToken, async (req: AuthRequest, res: Response): Promise<void> => {
  try {
    const result = await pool.query(
      "SELECT id, client_id, owner_id, name, activation_code, created_at FROM outlets WHERE owner_id::text = $1::text ORDER BY created_at DESC",
      [String(req.userId)]
    );
    res.json({
      outlets: result.rows.map((r) => ({
        id: safeInt(r.client_id ?? r.id),
        dbId: String(r.id),
        ownerId: String(r.owner_id),
        name: r.name as string,
        activationCode: r.activation_code as string,
        createdAt: r.created_at,
      })),
    });
  } catch (err) {
    console.error("[Outlets GET]", err);
    res.status(500).json({ message: "Terjadi kesalahan server" });
  }
});

router.post("/", authenticateToken, async (req: AuthRequest, res: Response): Promise<void> => {
  const { name } = req.body;
  if (!name || String(name).trim().length === 0) {
    res.status(400).json({ message: "Nama outlet wajib diisi" });
    return;
  }

  try {
    const countResult = await pool.query(
      "SELECT COUNT(*) FROM outlets WHERE owner_id::text = $1::text",
      [String(req.userId)]
    );
    const count = parseInt(countResult.rows[0].count, 10);
    if (count >= 5) {
      res.status(403).json({ message: "Batas maksimal 5 outlet per owner tercapai" });
      return;
    }

    const activationCode = nanoid(8).toUpperCase();
    const result = await pool.query(
      "INSERT INTO outlets (owner_id, name, activation_code) VALUES ($1, $2, $3) RETURNING *",
      [String(req.userId), String(name).trim(), activationCode]
    );
    const outlet = result.rows[0];

    res.status(201).json({
      outlet: {
        id: safeInt(outlet.client_id ?? outlet.id),
        dbId: String(outlet.id),
        ownerId: String(outlet.owner_id),
        name: outlet.name as string,
        activationCode: outlet.activation_code as string,
        createdAt: outlet.created_at,
      },
    });
  } catch (err) {
    console.error("[Outlets POST]", err);
    res.status(500).json({ message: "Terjadi kesalahan server" });
  }
});

router.put("/:id", authenticateToken, async (req: AuthRequest, res: Response): Promise<void> => {
  const outletId = parseInt(req.params.id, 10);
  const { name } = req.body;

  if (!name || String(name).trim().length === 0) {
    res.status(400).json({ message: "Nama outlet tidak boleh kosong" });
    return;
  }

  try {
    // BUG FIX: query by client_id OR id (untuk kompatibilitas)
    const result = await pool.query(
      `UPDATE outlets SET name = $1
       WHERE (client_id::text = $2::text OR id::text = $2::text) AND owner_id::text = $3::text
       RETURNING *`,
      [String(name).trim(), outletId, String(req.userId)]
    );

    if (result.rows.length === 0) {
      res.status(404).json({ message: "Outlet tidak ditemukan atau bukan milik Anda" });
      return;
    }

    const outlet = result.rows[0];
    res.json({
      outlet: {
        id: safeInt(outlet.client_id ?? outlet.id),
        dbId: String(outlet.id),
        ownerId: String(outlet.owner_id),
        name: outlet.name as string,
        activationCode: outlet.activation_code as string,
        createdAt: outlet.created_at,
      },
    });
  } catch (err) {
    console.error("[Outlets PUT]", err);
    res.status(500).json({ message: "Terjadi kesalahan server" });
  }
});

router.delete("/:id", authenticateToken, async (req: AuthRequest, res: Response): Promise<void> => {
  const outletId = parseInt(req.params.id, 10);
  if (!outletId || isNaN(outletId)) {
    res.status(400).json({ message: "ID outlet tidak valid" });
    return;
  }

  try {
    // BUG FIX: query by client_id OR id
    const existing = await pool.query(
      "SELECT id, client_id FROM outlets WHERE (client_id::text = $1::text OR id::text = $1::text) AND owner_id::text = $2::text",
      [outletId, String(req.userId)]
    );
    if (existing.rows.length === 0) {
      res.status(404).json({ message: "Outlet tidak ditemukan atau bukan milik Anda" });
      return;
    }

    const outletDbId = String(existing.rows[0].id);
    const outletClientId = String(existing.rows[0].client_id ?? existing.rows[0].id);
    const client = await pool.connect();
    try {
      await client.query("BEGIN");
      await client.query(
        "DELETE FROM transactions WHERE outlet_id::text = $1::text OR outlet_id::text = $2::text",
        [outletDbId, outletClientId]
      );
      await client.query(
        "UPDATE devices SET outlet_id = NULL, status = 'offline', refresh_token = NULL WHERE outlet_id::text = $1::text OR outlet_id::text = $2::text",
        [outletDbId, outletClientId]
      );
      await client.query("DELETE FROM services WHERE outlet_id::text = $1::text OR outlet_id::text = $2::text", [outletDbId, outletClientId]);
      await client.query("DELETE FROM customers WHERE outlet_id::text = $1::text OR outlet_id::text = $2::text", [outletDbId, outletClientId]);
      await client.query("DELETE FROM outlets WHERE id::text = $1::text", [outletDbId]);
      await client.query("COMMIT");
    } catch (err) {
      await client.query("ROLLBACK");
      throw err;
    } finally {
      client.release();
    }

    res.json({ message: "Outlet berhasil dihapus" });
  } catch (err) {
    console.error("[Outlets DELETE]", err);
    res.status(500).json({ message: "Terjadi kesalahan server" });
  }
});

export default router;
