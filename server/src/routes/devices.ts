import { Router, Response } from "express";
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
      `SELECT d.*, o.client_id as outlet_client_id, o.name as outlet_name 
       FROM devices d 
       LEFT JOIN outlets o ON d.outlet_id::text = o.id::text OR d.outlet_id::text = o.client_id::text
       WHERE d.owner_id::text = $1::text 
       ORDER BY d.last_seen DESC NULLS LAST`,
      [req.userId]
    );
    res.json({
      devices: result.rows.map(d => ({
        id: d.id,
        deviceName: d.device_name ?? d.name,
        deviceId: d.device_id,
        status: d.status,
        outletId: safeInt(d.outlet_client_id ?? d.outlet_id),
        outletName: d.outlet_name,
        lastSeen: d.last_seen,
      })),
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Terjadi kesalahan server" });
  }
});

router.post("/heartbeat", authenticateToken, async (req: AuthRequest, res: Response): Promise<void> => {
  const { deviceId } = req.body;
  if (!deviceId) {
    res.status(400).json({ message: "Device ID wajib diisi" });
    return;
  }

  try {
    await pool.query(
      "UPDATE devices SET last_seen = NOW(), status = 'online' WHERE device_id = $1",
      [deviceId]
    );

    await pool.query(
      `UPDATE devices SET status = 'offline' 
       WHERE owner_id::text = $1::text 
       AND device_id != $2 
       AND (last_seen IS NULL OR last_seen < NOW() - INTERVAL '2 minutes')`,
      [req.userId, deviceId]
    );

    res.json({ message: "Heartbeat berhasil dikirim" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Terjadi kesalahan server" });
  }
});

router.post("/force-logout", authenticateToken, async (req: AuthRequest, res: Response): Promise<void> => {
  const { deviceId } = req.body;
  if (!deviceId) {
    res.status(400).json({ message: "Device ID wajib diisi" });
    return;
  }

  try {
    const result = await pool.query(
      "UPDATE devices SET status = 'offline', refresh_token = NULL WHERE id::text = $1::text AND owner_id::text = $2::text RETURNING id",
      [deviceId, req.userId]
    );

    if (result.rows.length === 0) {
      res.status(404).json({ message: "Device tidak ditemukan" });
      return;
    }

    res.json({ message: "Device berhasil di-force logout" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Terjadi kesalahan server" });
  }
});

router.put("/:id", authenticateToken, async (req: AuthRequest, res: Response): Promise<void> => {
  const { id } = req.params;
  const { deviceName } = req.body;

  if (!deviceName || !deviceName.trim()) {
    res.status(400).json({ message: "Nama device wajib diisi" });
    return;
  }

  try {
    const result = await pool.query(
      "UPDATE devices SET device_name = $1 WHERE id::text = $2::text AND owner_id::text = $3::text RETURNING id, device_name",
      [deviceName.trim(), id, req.userId]
    );

    if (result.rows.length === 0) {
      res.status(404).json({ message: "Device tidak ditemukan" });
      return;
    }

    res.json({ message: "Nama device berhasil diperbarui" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Terjadi kesalahan server" });
  }
});

router.delete("/:id", authenticateToken, async (req: AuthRequest, res: Response): Promise<void> => {
  const { id } = req.params;

  try {
    const result = await pool.query(
      "DELETE FROM devices WHERE id::text = $1::text AND owner_id::text = $2::text RETURNING id",
      [id, req.userId]
    );

    if (result.rows.length === 0) {
      res.status(404).json({ message: "Device tidak ditemukan" });
      return;
    }

    res.json({ message: "Device berhasil dihapus" });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Terjadi kesalahan server" });
  }
});

export default router;
