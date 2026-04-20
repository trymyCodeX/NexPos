import { Request, Response, NextFunction } from "express";
import jwt from "jsonwebtoken";
import pool from "../db/client";

export interface AuthRequest extends Request {
  userId?: string | number;
  userEmail?: string;
  outletId?: string | number;
  deviceId?: string | number;
}

const DEVICE_REACTIVATION_AFTER_OFFLINE_DAYS = 2;

export async function authenticateToken(
  req: AuthRequest,
  res: Response,
  next: NextFunction
): Promise<void> {
  const authHeader = req.headers["authorization"];
  const token = authHeader && authHeader.split(" ")[1];

  if (!token) {
    res.status(401).json({ message: "Token tidak ditemukan" });
    return;
  }

  try {
    const secret = process.env.JWT_SECRET || "nexpos_secret";
    const decoded = jwt.verify(token, secret) as {
      userId: string | number;
      email: string;
      outletId?: string | number;
      deviceId?: string | number;
    };

    if (decoded.deviceId) {
      // BUG FIX: menggunakan make_interval() agar perkalian interval valid di PostgreSQL
      const deviceResult = await pool.query(
        `SELECT id, last_seen,
                (last_seen IS NULL OR last_seen < NOW() - make_interval(days => $3::int)) AS must_reactivate
         FROM devices
         WHERE id::text = $1::text AND owner_id::text = $2::text
         LIMIT 1`,
        [decoded.deviceId, decoded.userId, DEVICE_REACTIVATION_AFTER_OFFLINE_DAYS]
      );

      if (deviceResult.rows.length === 0) {
        res.status(401).json({ message: "Device tidak terdaftar. Silakan login ulang." });
        return;
      }

      if (deviceResult.rows[0].must_reactivate) {
        await pool.query(
          "UPDATE devices SET status = 'offline', refresh_token = NULL WHERE id::text = $1::text AND owner_id::text = $2::text",
          [decoded.deviceId, decoded.userId]
        );
        res.status(401).json({ message: "Outlet offline lebih dari 2 hari. Silakan login ulang." });
        return;
      }
    }

    req.userId = decoded.userId;
    req.userEmail = decoded.email;
    req.outletId = decoded.outletId;
    req.deviceId = decoded.deviceId;
    next();
  } catch {
    res.status(403).json({ message: "Token tidak valid atau sudah kadaluarsa" });
  }
}
