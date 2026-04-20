import { Router, Request, Response } from "express";
import bcrypt from "bcryptjs";
import jwt from "jsonwebtoken";
import crypto from "crypto";
import pool from "../db/client";
import { sendOtpEmail } from "../utils/email";
import { authenticateToken, AuthRequest } from "../middleware/auth";

const router = Router();

function generateToken(payload: object): string {
  const secret = process.env.JWT_SECRET || "nexpos_secret";
  const expiresIn = process.env.JWT_EXPIRES_IN || "7d";
  return jwt.sign(payload, secret, { expiresIn } as jwt.SignOptions);
}

function toRequiredClientId(value: unknown): number {
  const numberValue = Number(value);
  return Number.isSafeInteger(numberValue) ? numberValue : 0;
}

router.post("/register", async (req: Request, res: Response): Promise<void> => {
  const { email, password, name } = req.body;
  if (!email || !password || !name) {
    res.status(400).json({ message: "Email, password, dan nama wajib diisi" });
    return;
  }

  try {
    const existing = await pool.query("SELECT id FROM users WHERE email = $1", [email.trim().toLowerCase()]);
    if (existing.rows.length > 0) {
      res.status(409).json({ message: "Email sudah terdaftar" });
      return;
    }

    const hashedPassword = await bcrypt.hash(password, 10);
    const result = await pool.query(
      "INSERT INTO users (email, password, name) VALUES ($1, $2, $3) RETURNING id, email, name",
      [email.trim().toLowerCase(), hashedPassword, name.trim()]
    );

    const user = result.rows[0];
    const token = generateToken({ userId: user.id, email: user.email });

    res.status(201).json({
      token,
      user: { id: user.id, email: user.email, name: user.name },
    });
  } catch (err) {
    console.error("[register]", err);
    res.status(500).json({ message: "Terjadi kesalahan server" });
  }
});

router.post("/login", async (req: Request, res: Response): Promise<void> => {
  const { email, password } = req.body;
  if (!email || !password) {
    res.status(400).json({ message: "Email dan password wajib diisi" });
    return;
  }

  try {
    const result = await pool.query("SELECT * FROM users WHERE email = $1", [email.trim().toLowerCase()]);
    if (result.rows.length === 0) {
      res.status(401).json({ message: "Email atau password salah" });
      return;
    }

    const user = result.rows[0];
    if (user.account_status === "banned" || user.banned_permanent === true) {
      res.status(403).json({ message: user.penalty_reason || "Akun Anda dibanned permanen. Hubungi Customer Service." });
      return;
    }

    const valid = await bcrypt.compare(password, user.password);
    if (!valid) {
      res.status(401).json({ message: "Email atau password salah" });
      return;
    }

    const token = generateToken({ userId: user.id, email: user.email });
    res.json({ token, user: { id: user.id, email: user.email, name: user.name } });
  } catch (err) {
    console.error("[login]", err);
    res.status(500).json({ message: "Terjadi kesalahan server" });
  }
});

router.post("/login-device", async (req: Request, res: Response): Promise<void> => {
  const { activationCode, deviceName, deviceId } = req.body;
  if (!activationCode || !deviceName || !deviceId) {
    res.status(400).json({ message: "Kode aktivasi, nama device, dan ID device wajib diisi" });
    return;
  }

  const step = { current: "init" };
  try {
    const normalizedActivationCode = String(activationCode).trim().toUpperCase();
    const normalizedDeviceId = String(deviceId).trim();
    const normalizedDeviceName = String(deviceName).trim();

    step.current = "query-outlet";
    const outletResult = await pool.query(
      "SELECT * FROM outlets WHERE UPPER(TRIM(activation_code)) = $1::text",
      [normalizedActivationCode]
    );
    if (outletResult.rows.length === 0) {
      res.status(401).json({ message: "Kode aktivasi tidak valid" });
      return;
    }
    const outlet = outletResult.rows[0];
    const outletDbId = String(outlet.id);
    const outletClientId = toRequiredClientId(outlet.client_id ?? outlet.id);
    const outletOwnerId = String(outlet.owner_id);

    step.current = "query-existing-device";
    const existingDevice = await pool.query(
      "SELECT * FROM devices WHERE device_id::text = $1::text",
      [normalizedDeviceId]
    );

    if (existingDevice.rows.length === 0) {
      step.current = "count-devices";
      const deviceCountResult = await pool.query(
        "SELECT COUNT(*) FROM devices WHERE outlet_id::text = $1::text OR outlet_id::text = $2::text",
        [outletDbId, String(outletClientId)]
      );
      const deviceCount = parseInt(deviceCountResult.rows[0].count);
      if (deviceCount >= 5) {
        res.status(403).json({ message: "Batas maksimal 5 device per owner tercapai" });
        return;
      }
    }

    let device;
    if (existingDevice.rows.length > 0) {
      step.current = "update-device";
      const updated = await pool.query(
        "UPDATE devices SET status = 'online', last_seen = NOW(), name = $1::text, device_name = $2::text, outlet_id = $3::text, owner_id = $4::text WHERE device_id::text = $5::text RETURNING *",
        [normalizedDeviceName, normalizedDeviceName, outletDbId, outletOwnerId, normalizedDeviceId]
      );
      device = updated.rows[0];
      if (!device) {
        const fallback = await pool.query("SELECT * FROM devices WHERE device_id::text = $1::text", [normalizedDeviceId]);
        device = fallback.rows[0];
      }
    } else {
      step.current = "insert-device";
      const inserted = await pool.query(
        "INSERT INTO devices (owner_id, outlet_id, name, device_name, device_id, activation_code, status, last_seen) VALUES ($1::text, $2::text, $3::text, $4::text, $5::text, $6::text, 'online', NOW()) RETURNING *",
        [outletOwnerId, outletDbId, normalizedDeviceName, normalizedDeviceName, normalizedDeviceId, normalizedActivationCode]
      );
      device = inserted.rows[0];
    }

    if (!device) {
      console.error("[login-device] device undefined setelah step:", step.current);
      res.status(500).json({ message: "Terjadi kesalahan server, coba lagi nanti" });
      return;
    }

    step.current = "query-owner";
    const ownerResult = await pool.query("SELECT * FROM users WHERE id::text = $1::text", [outletOwnerId]);
    const owner = ownerResult.rows[0];
    if (owner?.account_status === "banned" || owner?.banned_permanent === true) {
      res.status(403).json({ message: owner?.penalty_reason || "Akun owner dibanned permanen" });
      return;
    }

    step.current = "generate-token";
    const tokenPayload = {
      userId: String(owner?.id ?? outletOwnerId),
      email: owner?.email ?? "",
      deviceId: device.id,
      outletId: outletClientId,
    };

    const token = generateToken(tokenPayload);
    res.json({
      token,
      outlet: {
        id: outletClientId,
        name: outlet.name,
        ownerId: outletOwnerId,
        activationCode: outlet.activation_code,
      },
      device: {
        id: device.id,
        deviceName: device.device_name,
        deviceId: device.device_id,
        status: device.status,
        outletId: outletClientId,
      },
    });
  } catch (err: any) {
    console.error(`[login-device:${step.current}] ERROR:`, err);
    res.status(500).json({ message: "Terjadi kesalahan server, coba lagi nanti" });
  }
});

router.delete("/account", async (req: Request, res: Response): Promise<void> => {
  const authHeader = req.headers["authorization"];
  const token = authHeader && authHeader.split(" ")[1];

  if (!token) {
    res.status(401).json({ message: "Token tidak ditemukan" });
    return;
  }

  try {
    const secret = process.env.JWT_SECRET || "nexpos_secret";
    const decoded = jwt.verify(token, secret) as { userId: string | number; email: string };
    const userId = decoded.userId;

    const client = await pool.connect();
    try {
      await client.query("BEGIN");
      await client.query(
        "DELETE FROM transactions WHERE outlet_id IN (SELECT id::text FROM outlets WHERE owner_id::text = $1::text)",
        [userId]
      );
      await client.query(
        "DELETE FROM services WHERE outlet_id IN (SELECT id::text FROM outlets WHERE owner_id::text = $1::text)",
        [userId]
      );
      await client.query(
        "DELETE FROM customers WHERE outlet_id IN (SELECT id::text FROM outlets WHERE owner_id::text = $1::text)",
        [userId]
      );
      await client.query("DELETE FROM devices WHERE owner_id::text = $1::text", [userId]);
      await client.query("DELETE FROM outlets WHERE owner_id::text = $1::text", [userId]);
      await client.query("DELETE FROM users WHERE id::text = $1::text", [userId]);
      await client.query("COMMIT");
    } catch (err) {
      await client.query("ROLLBACK");
      throw err;
    } finally {
      client.release();
    }

    res.json({ message: "Akun berhasil dihapus" });
  } catch (err: any) {
    if (err.name === "JsonWebTokenError" || err.name === "TokenExpiredError") {
      res.status(401).json({ message: "Token tidak valid atau sudah kadaluarsa" });
      return;
    }
    console.error("[delete-account]", err);
    res.status(500).json({ message: "Terjadi kesalahan server" });
  }
});

const OTP_COOLDOWN_SEC = 60;
const OTP_MAX_REQUESTS = 3;
const OTP_RESET_HOURS = 24;

function hashOtp(otp: string, email: string): string {
  return crypto.createHash("sha256").update(otp + email.toLowerCase()).digest("hex");
}

router.post("/forgot-password", async (req: Request, res: Response): Promise<void> => {
  const { email } = req.body;
  if (!email) {
    res.status(400).json({ message: "Email wajib diisi" });
    return;
  }

  const normalizedEmail = email.trim().toLowerCase();

  try {
    const result = await pool.query(
      "SELECT id, name, email, otp_request_count, otp_last_request_at FROM users WHERE email = $1",
      [normalizedEmail]
    );
    if (result.rows.length === 0) {
      res.json({ message: "Jika email terdaftar, kode OTP telah dikirim ke email Anda" });
      return;
    }

    const user = result.rows[0];
    const now = Date.now();
    const lastRequestMs = user.otp_last_request_at ? new Date(user.otp_last_request_at).getTime() : 0;
    const hoursSinceLast = (now - lastRequestMs) / (1000 * 60 * 60);
    const requestCount = hoursSinceLast >= OTP_RESET_HOURS ? 0 : (user.otp_request_count || 0);
    const secondsSinceLast = (now - lastRequestMs) / 1000;

    if (requestCount > 0 && secondsSinceLast < OTP_COOLDOWN_SEC) {
      const remaining = Math.ceil(OTP_COOLDOWN_SEC - secondsSinceLast);
      res.status(429).json({ message: `Tunggu ${remaining} detik sebelum meminta OTP kembali`, cooldown: remaining });
      return;
    }

    if (requestCount >= OTP_MAX_REQUESTS) {
      res.status(429).json({
        message: "Batas permintaan OTP habis (maks 3x per 24 jam). Hubungi Customer Service untuk bantuan.",
        contact_cs: true,
      });
      return;
    }

    const otp = crypto.randomInt(100000, 1000000).toString();
    const otpHash = hashOtp(otp, normalizedEmail);
    const expiresAt = new Date(now + 10 * 60 * 1000);
    const newCount = requestCount + 1;

    await pool.query(
      `UPDATE users SET otp_hash = $1, otp_expires_at = $2,
       otp_request_count = $3, otp_last_request_at = NOW(),
       otp_code = NULL, reset_token = NULL, reset_token_expires_at = NULL
       WHERE id = $4`,
      [otpHash, expiresAt, newCount, user.id]
    );

    await pool.query(
      "INSERT INTO super_admin_events (type, user_id, email, name, otp_code, message, metadata) VALUES ('otp_request', $1, $2, $3, $4, $5, $6)",
      [String(user.id), user.email, user.name, otp, `Request OTP #${newCount}/${OTP_MAX_REQUESTS}`, JSON.stringify({ expiresAt: expiresAt.toISOString(), requestCount: newCount })]
    ).catch(() => {});

    console.info(`[forgot-password] OTP untuk ${user.email}: ${otp} | #${newCount}/${OTP_MAX_REQUESTS}`);

    sendOtpEmail(user.email, otp, user.name).catch((emailErr: any) => {
      console.error("[forgot-password] Gagal kirim email:", emailErr?.message);
    });

    res.json({ message: "Kode OTP berhasil dikirim ke email Anda" });
  } catch (err: any) {
    console.error("[forgot-password]", err);
    res.status(500).json({ message: "Terjadi kesalahan server" });
  }
});

router.post("/verify-otp", async (req: Request, res: Response): Promise<void> => {
  const { email, otp } = req.body;
  if (!email || !otp) {
    res.status(400).json({ message: "Email dan kode OTP wajib diisi" });
    return;
  }

  const normalizedEmail = email.trim().toLowerCase();

  try {
    const result = await pool.query(
      "SELECT id, otp_hash, otp_expires_at FROM users WHERE email = $1",
      [normalizedEmail]
    );

    if (result.rows.length === 0 || !result.rows[0].otp_hash) {
      res.status(400).json({ message: "OTP tidak ditemukan atau sudah digunakan" });
      return;
    }

    const user = result.rows[0];

    if (!user.otp_expires_at || new Date(user.otp_expires_at) < new Date()) {
      res.status(400).json({ message: "OTP kadaluarsa. Minta kode baru." });
      return;
    }

    const expectedHash = hashOtp(otp.trim(), normalizedEmail);
    if (user.otp_hash !== expectedHash) {
      res.status(400).json({ message: "OTP salah" });
      return;
    }

    const resetToken = crypto.randomBytes(48).toString("hex");
    const resetExpiresAt = new Date(Date.now() + 15 * 60 * 1000);

    await pool.query(
      "UPDATE users SET otp_hash = NULL, otp_expires_at = NULL, reset_token = $1, reset_token_expires_at = $2 WHERE id = $3",
      [resetToken, resetExpiresAt, user.id]
    );

    res.json({ resetToken });
  } catch (err) {
    console.error("[verify-otp]", err);
    res.status(500).json({ message: "Terjadi kesalahan server" });
  }
});

router.post("/reset-password", async (req: Request, res: Response): Promise<void> => {
  const { email, resetToken, newPassword } = req.body;
  if (!email || !resetToken || !newPassword) {
    res.status(400).json({ message: "Email, token reset, dan password baru wajib diisi" });
    return;
  }

  if (newPassword.length < 6) {
    res.status(400).json({ message: "Password baru minimal 6 karakter" });
    return;
  }

  try {
    const result = await pool.query(
      "SELECT id, reset_token, reset_token_expires_at FROM users WHERE email = $1",
      [email.trim().toLowerCase()]
    );

    if (result.rows.length === 0) {
      res.status(400).json({ message: "Permintaan reset password tidak valid" });
      return;
    }

    const user = result.rows[0];

    if (!user.reset_token || user.reset_token !== resetToken) {
      res.status(400).json({ message: "Token reset tidak valid" });
      return;
    }

    if (!user.reset_token_expires_at || new Date(user.reset_token_expires_at) < new Date()) {
      res.status(400).json({ message: "Token reset sudah kadaluarsa. Ulangi proses dari awal." });
      return;
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);
    await pool.query(
      "UPDATE users SET password = $1, reset_token = NULL, reset_token_expires_at = NULL, otp_request_count = 0, otp_last_request_at = NULL WHERE id = $2",
      [hashedPassword, user.id]
    );

    res.json({ message: "Password berhasil diperbarui. Silakan login dengan password baru." });
  } catch (err) {
    console.error("[reset-password]", err);
    res.status(500).json({ message: "Terjadi kesalahan server" });
  }
});

router.put("/change-password", authenticateToken, async (req: AuthRequest, res: Response): Promise<void> => {
  const { currentPassword, newPassword } = req.body;

  if (!currentPassword || !newPassword) {
    res.status(400).json({ message: "Password lama dan password baru wajib diisi" });
    return;
  }

  if (newPassword.length < 6) {
    res.status(400).json({ message: "Password baru minimal 6 karakter" });
    return;
  }

  try {
    const result = await pool.query("SELECT * FROM users WHERE id = $1", [req.userId]);
    if (result.rows.length === 0) {
      res.status(404).json({ message: "Pengguna tidak ditemukan" });
      return;
    }

    const user = result.rows[0];
    const valid = await bcrypt.compare(currentPassword, user.password);
    if (!valid) {
      res.status(401).json({ message: "Password lama tidak sesuai" });
      return;
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);
    await pool.query("UPDATE users SET password = $1 WHERE id = $2", [hashedPassword, req.userId]);

    res.json({ message: "Password berhasil diperbarui" });
  } catch (err) {
    console.error("[change-password]", err);
    res.status(500).json({ message: "Terjadi kesalahan server" });
  }
});

export default router;
