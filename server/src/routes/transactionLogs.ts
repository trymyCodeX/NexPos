import { Router, Response } from "express";
import pool from "../db/client";
import { authenticateToken, AuthRequest } from "../middleware/auth";

const router = Router();

// GET /transaction-logs - ambil log transaksi (masuk & dihapus) untuk owner
router.get("/", authenticateToken, async (req: AuthRequest, res: Response): Promise<void> => {
  const { action, outletId, limit = "100", offset = "0" } = req.query;

  try {
    const params: any[] = [String(req.userId)];
    const conditions: string[] = ["tl.owner_id::text = $1::text"];

    if (action) {
      params.push(String(action));
      conditions.push(`tl.action = $${params.length}`);
    }

    if (outletId) {
      params.push(String(outletId));
      conditions.push(`tl.outlet_id::text = $${params.length}::text`);
    }

    const whereClause = conditions.length > 0 ? `WHERE ${conditions.join(" AND ")}` : "";
    params.push(parseInt(String(limit), 10));
    params.push(parseInt(String(offset), 10));

    const result = await pool.query(
      `SELECT tl.*
       FROM transaction_logs tl
       ${whereClause}
       ORDER BY tl.created_at DESC
       LIMIT $${params.length - 1} OFFSET $${params.length}`,
      params
    );

    const countResult = await pool.query(
      `SELECT COUNT(*) AS total FROM transaction_logs tl ${whereClause}`,
      params.slice(0, params.length - 2)
    );

    res.json({
      logs: result.rows.map((r) => ({
        id: r.id,
        transactionId: r.transaction_id,
        action: r.action,
        outletName: r.outlet_name,
        customerName: r.customer_name,
        serviceName: r.service_name,
        quantity: r.quantity,
        totalAmount: r.total_amount,
        status: r.status,
        actorType: r.actor_type,
        notes: r.notes,
        createdAt: r.created_at,
      })),
      total: parseInt(countResult.rows[0]?.total ?? "0", 10),
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: "Terjadi kesalahan server" });
  }
});

export default router;
