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
      devices: result.rows.map((d) => ({
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
    console.error("[Devices GET]", err);
    res.status(500).json({ message: "Terjadi kesalahan server" });
  }
});

// BUG FIX: heartbeat menggunakan device_id (UUID hardware) untuk update last_seen
router.post("/heartbeat", authenticateToken, async (req: AuthRequest, res: Response): Promise<void> => {
  const { deviceId } = req.body;
  if (!deviceId) {
    res.status(400).json({ message: "Device ID wajib diisi" });
    return;
  }

  try {
    await pool.query(
      "UPDATE devices SET last_seen = NOW(), status = 'online' WHERE device_id::text = $1::text",
      [String(deviceId)]
    );

    await pool.query(
      `UPDATE devices SET status = 'offline'
       WHERE owner_id::text = $1::text
         AND device_id::text != $2::text
         AND (last_seen IS NULL OR last_seen < NOW() - INTERVAL '2 minutes')`,
      [String(req.userId), String(deviceId)]
    );

    res.json({ message: "Heartbeat berhasil dikirim" });
  } catch (err) {
    console.error("[Devices heartbeat]", err);
    res.status(500).json({ message: "Terjadi kesalahan server" });
  }
});

router.post("/force-logout", authenticateToken, async (req: AuthRequest, res: Response): Promise<void> => {
  const deviceId = String(req.body.deviceId ?? req.body.id ?? "").trim();

  if (!deviceId) {
    res.status(400).json({ message: "Device ID wajib diisi" });
    return;
  }

  try {
    const result = await pool.query(
      `UPDATE devices SET status = 'offline', refresh_token = NULL
       WHERE (id::text = $1::text OR device_id::text = $1::text)
         AND owner_id::text = $2::text
       RETURNING id`,
      [deviceId, String(req.userId)]
    );

    if (result.rows.length === 0) {
      res.status(404).json({ message: "Device tidak ditemukan" });
      return;
    }

    res.json({ message: "Device berhasil di-force logout" });
  } catch (err) {
    console.error("[Devices force-logout]", err);
    res.status(500).json({ message: "Terjadi kesalahan server" });
  }
});

router.put("/:id", authenticateToken, async (req: AuthRequest, res: Response): Promise<void> => {
  const { id } = req.params;
  const { deviceName } = req.body;

  if (!deviceName || !String(deviceName).trim()) {
    res.status(400).json({ message: "Nama device wajib diisi" });
    return;
  }

  try {
    const result = await pool.query(
      `UPDATE devices SET device_name = $1, name = $1
       WHERE (id::text = $2::text OR device_id::text = $2::text)
         AND owner_id::text = $3::text
       RETURNING id, device_name`,
      [String(deviceName).trim(), String(id), String(req.userId)]
    );

    if (result.rows.length === 0) {
      res.status(404).json({ message: "Device tidak ditemukan" });
      return;
    }

    res.json({ message: "Nama device berhasil diperbarui" });
  } catch (err) {
    console.error("[Devices PUT]", err);
    res.status(500).json({ message: "Terjadi kesalahan server" });
  }
});

router.delete("/:id", authenticateToken, async (req: AuthRequest, res: Response): Promise<void> => {
  const { id } = req.params;

  try {
    const result = await pool.query(
      `DELETE FROM devices
       WHERE (id::text = $1::text OR device_id::text = $1::text)
         AND owner_id::text = $2::text
       RETURNING id`,
      [String(id), String(req.userId)]
    );

    if (result.rows.length === 0) {
      res.status(404).json({ message: "Device tidak ditemukan" });
      return;
    }

    res.json({ message: "Device berhasil dihapus" });
  } catch (err) {
    console.error("[Devices DELETE]", err);
    res.status(500).json({ message: "Terjadi kesalahan server" });
  }
});

export default router;
