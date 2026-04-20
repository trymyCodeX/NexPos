import { Router, Response } from "express";
import pool from "../db/client";
import { authenticateToken, AuthRequest } from "../middleware/auth";

const router = Router();

router.get("/summary", authenticateToken, async (req: AuthRequest, res: Response): Promise<void> => {
  const queryOutletId = req.query.outletId;
  const tokenOutletId = req.outletId;

  try {
    let whereClause: string;
    let params: (string | number)[];

    if (queryOutletId) {
      whereClause = "WHERE t.outlet_id::text = $1::text OR o.client_id::text = $1::text";
      params = [String(queryOutletId)];
    } else if (tokenOutletId) {
      whereClause = "WHERE t.outlet_id::text = $1::text OR o.client_id::text = $1::text";
      params = [String(tokenOutletId)];
    } else {
      whereClause = "WHERE o.owner_id::text = $1::text";
      params = [String(req.userId)];
    }

    const result = await pool.query(
      `SELECT
         COUNT(t.id) AS total_transactions,
         COALESCE(SUM(t.total_amount), 0) AS total_income,
         COUNT(CASE WHEN t.status = 'diterima' THEN 1 END) AS total_diterima,
         COUNT(CASE WHEN t.status = 'dicuci' THEN 1 END) AS total_dicuci,
         COUNT(CASE WHEN t.status = 'disetrika' THEN 1 END) AS total_disetrika,
         COUNT(CASE WHEN t.status = 'selesai' THEN 1 END) AS total_selesai,
         COUNT(CASE WHEN t.status = 'dibatalkan' THEN 1 END) AS total_dibatalkan
       FROM transactions t
       LEFT JOIN outlets o ON t.outlet_id::text = o.id::text OR t.outlet_id::text = o.client_id::text
       ${whereClause}`,
      params
    );

    const row = result.rows[0];
    res.json({
      totalTransactions: parseInt(row.total_transactions, 10),
      totalIncome: parseFloat(row.total_income),
      totalDiterima: parseInt(row.total_diterima, 10),
      totalDicuci: parseInt(row.total_dicuci, 10),
      totalDisetrika: parseInt(row.total_disetrika, 10),
      totalSelesai: parseInt(row.total_selesai, 10),
      totalDibatalkan: parseInt(row.total_dibatalkan, 10),
    });
  } catch (err) {
    console.error("[Reports summary]", err);
    res.status(500).json({ message: "Terjadi kesalahan server" });
  }
});

// BUG FIX: perbaiki konstruksi query agar tidak ada AND AND ketika both clauses kosong
router.get("/daily", authenticateToken, async (req: AuthRequest, res: Response): Promise<void> => {
  const queryOutletId = req.query.outletId;
  const tokenOutletId = req.outletId;

  try {
    let filterClause: string;
    let params: (string | number)[];

    if (queryOutletId) {
      filterClause = "AND (t.outlet_id::text = $1::text OR o.client_id::text = $1::text)";
      params = [String(queryOutletId)];
    } else if (tokenOutletId) {
      filterClause = "AND (t.outlet_id::text = $1::text OR o.client_id::text = $1::text)";
      params = [String(tokenOutletId)];
    } else {
      filterClause = "AND o.owner_id::text = $1::text";
      params = [String(req.userId)];
    }

    const result = await pool.query(
      `SELECT
         DATE(t.created_at) AS date,
         COUNT(t.id) AS count,
         COALESCE(SUM(t.total_amount), 0) AS income
       FROM transactions t
       LEFT JOIN outlets o ON t.outlet_id::text = o.id::text OR t.outlet_id::text = o.client_id::text
       WHERE t.created_at >= NOW() - INTERVAL '30 days'
         ${filterClause}
       GROUP BY DATE(t.created_at)
       ORDER BY date DESC
       LIMIT 30`,
      params
    );

    res.json({
      days: result.rows.map((r) => ({
        date: r.date,
        count: parseInt(r.count, 10),
        income: parseFloat(r.income),
      })),
    });
  } catch (err) {
    console.error("[Reports daily]", err);
    res.status(500).json({ message: "Terjadi kesalahan server" });
  }
});

export default router;
