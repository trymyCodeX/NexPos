import { Router, Request, Response, NextFunction } from "express";
import jwt from "jsonwebtoken";
import pool from "../db/client";

const router = Router();

interface SuperAdminRequest extends Request {
  superAdmin?: boolean;
}

function generateToken(): string {
  const secret = process.env.JWT_SECRET || "nexpos_secret";
  return jwt.sign(
    { role: "super_admin", username: process.env.SUPER_ADMIN_USERNAME || "admin" },
    secret,
    { expiresIn: "12h" }
  );
}

function authenticateSuperAdmin(req: SuperAdminRequest, res: Response, next: NextFunction): void {
  const authHeader = req.headers["authorization"];
  const token = authHeader && authHeader.split(" ")[1];
  if (!token) {
    res.status(401).json({ message: "Token tidak ditemukan" });
    return;
  }
  try {
    const secret = process.env.JWT_SECRET || "nexpos_secret";
    const decoded = jwt.verify(token, secret) as { role?: string };
    if (decoded.role !== "super_admin") {
      res.status(403).json({ message: "Akses super admin ditolak" });
      return;
    }
    req.superAdmin = true;
    next();
  } catch {
    res.status(403).json({ message: "Token tidak valid atau sudah kadaluarsa" });
  }
}

router.post("/login", (req: Request, res: Response): void => {
  const { username, password } = req.body;
  const expectedUsername = process.env.SUPER_ADMIN_USERNAME || "admin";
  const expectedPassword = process.env.SUPER_ADMIN_PASSWORD || "admin!@#";
  if (username === expectedUsername && password === expectedPassword) {
    res.json({ token: generateToken(), username: expectedUsername });
    return;
  }
  res.status(401).json({ message: "ID atau password super admin salah" });
});

router.get("/stats", authenticateSuperAdmin, async (_req: SuperAdminRequest, res: Response): Promise<void> => {
  try {
    const [users, outlets, devices, transactions, otpRequests] = await Promise.all([
      pool.query("SELECT COUNT(*) FROM users"),
      pool.query("SELECT COUNT(*) FROM outlets"),
      pool.query("SELECT COUNT(*) FROM devices"),
      pool.query("SELECT COUNT(*) FROM transactions"),
      pool.query("SELECT COUNT(*) FROM super_admin_events WHERE type = 'otp_request'"),
    ]);
    res.json({
      totalUsers: Number(users.rows[0].count),
      totalOutlets: Number(outlets.rows[0].count),
      totalDevices: Number(devices.rows[0].count),
      totalTransactions: Number(transactions.rows[0].count),
      totalOtpRequests: Number(otpRequests.rows[0].count),
    });
  } catch (err) {
    console.error("[SuperAdmin stats]", err);
    res.status(500).json({ message: "Terjadi kesalahan server" });
  }
});

router.get("/users", authenticateSuperAdmin, async (_req: SuperAdminRequest, res: Response): Promise<void> => {
  try {
    const result = await pool.query(
      `SELECT u.id, u.email, u.name, u.created_at,
              COALESCE(u.account_status, 'active') AS account_status,
              u.penalty_reason,
              COALESCE(u.banned_permanent, FALSE) AS banned_permanent,
              (SELECT COUNT(*) FROM outlets o WHERE o.owner_id::text = u.id::text) AS outlet_count,
              (SELECT COUNT(*) FROM devices d WHERE d.owner_id::text = u.id::text) AS device_count
       FROM users u
       ORDER BY u.created_at DESC`
    );
    res.json({
      users: result.rows.map((u) => ({
        id: String(u.id),
        email: u.email,
        name: u.name,
        createdAt: u.created_at,
        accountStatus: u.account_status,
        penaltyReason: u.penalty_reason,
        bannedPermanent: Boolean(u.banned_permanent),
        outletCount: Number(u.outlet_count),
        deviceCount: Number(u.device_count),
      })),
    });
  } catch (err) {
    console.error("[SuperAdmin users]", err);
    res.status(500).json({ message: "Terjadi kesalahan server" });
  }
});

router.get("/otp-requests", authenticateSuperAdmin, async (_req: SuperAdminRequest, res: Response): Promise<void> => {
  try {
    const result = await pool.query(
      "SELECT id, user_id, email, name, otp_code, message, created_at FROM super_admin_events WHERE type = 'otp_request' ORDER BY created_at DESC LIMIT 100"
    );
    res.json({
      requests: result.rows.map((r) => ({
        id: r.id,
        userId: r.user_id,
        email: r.email,
        name: r.name,
        otpCode: r.otp_code,
        message: r.message,
        createdAt: r.created_at,
      })),
    });
  } catch (err) {
    console.error("[SuperAdmin otp-requests]", err);
    res.status(500).json({ message: "Terjadi kesalahan server" });
  }
});

router.delete("/users/:id", authenticateSuperAdmin, async (req: SuperAdminRequest, res: Response): Promise<void> => {
  const userId = req.params.id;
  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    const outlets = await client.query("SELECT id, client_id FROM outlets WHERE owner_id::text = $1::text", [userId]);
    for (const outlet of outlets.rows) {
      await client.query(
        "DELETE FROM transactions WHERE outlet_id::text = $1::text OR outlet_id::text = $2::text",
        [String(outlet.id), String(outlet.client_id)]
      );
    }
    await client.query("DELETE FROM notifications WHERE owner_id::text = $1::text", [userId]);
    await client.query("DELETE FROM services WHERE owner_id::text = $1::text", [userId]);
    await client.query("DELETE FROM customers WHERE owner_id::text = $1::text", [userId]);
    await client.query("DELETE FROM devices WHERE owner_id::text = $1::text", [userId]);
    await client.query("DELETE FROM outlets WHERE owner_id::text = $1::text", [userId]);
    const deleted = await client.query("DELETE FROM users WHERE id::text = $1::text RETURNING id", [userId]);
    await client.query("COMMIT");
    if (deleted.rows.length === 0) {
      res.status(404).json({ message: "User tidak ditemukan" });
      return;
    }
    res.json({ message: "Akun berhasil dihapus permanen" });
  } catch (err) {
    await client.query("ROLLBACK");
    console.error("[SuperAdmin delete user]", err);
    res.status(500).json({ message: "Terjadi kesalahan server" });
  } finally {
    client.release();
  }
});

router.post("/users/:id/ban", authenticateSuperAdmin, async (req: SuperAdminRequest, res: Response): Promise<void> => {
  const { reason, permanent } = req.body;
  try {
    const result = await pool.query(
      "UPDATE users SET account_status = 'banned', penalty_reason = $1, banned_at = NOW(), banned_permanent = $2 WHERE id::text = $3::text RETURNING id",
      [reason || "Banned oleh super admin", permanent !== false, req.params.id]
    );
    if (result.rows.length === 0) {
      res.status(404).json({ message: "User tidak ditemukan" });
      return;
    }
    res.json({ message: "User berhasil dibanned" });
  } catch (err) {
    console.error("[SuperAdmin ban]", err);
    res.status(500).json({ message: "Terjadi kesalahan server" });
  }
});

router.post("/users/:id/unban", authenticateSuperAdmin, async (req: SuperAdminRequest, res: Response): Promise<void> => {
  try {
    const result = await pool.query(
      "UPDATE users SET account_status = 'active', penalty_reason = NULL, banned_at = NULL, banned_permanent = FALSE WHERE id::text = $1::text RETURNING id",
      [req.params.id]
    );
    if (result.rows.length === 0) {
      res.status(404).json({ message: "User tidak ditemukan" });
      return;
    }
    res.json({ message: "Banned user berhasil dibuka" });
  } catch (err) {
    console.error("[SuperAdmin unban]", err);
    res.status(500).json({ message: "Terjadi kesalahan server" });
  }
});

router.post("/notifications", authenticateSuperAdmin, async (req: SuperAdminRequest, res: Response): Promise<void> => {
  const { ownerId, title, message, type } = req.body;
  if (!ownerId || !title || !message) {
    res.status(400).json({ message: "Owner, judul, dan pesan wajib diisi" });
    return;
  }
  try {
    await pool.query(
      "INSERT INTO notifications (owner_id, title, message, type) VALUES ($1, $2, $3, $4)",
      [String(ownerId), String(title).trim(), String(message).trim(), type || "info"]
    );
    res.status(201).json({ message: "Notifikasi berhasil dibuat" });
  } catch (err) {
    console.error("[SuperAdmin notification]", err);
    res.status(500).json({ message: "Terjadi kesalahan server" });
  }
});

export default router;
