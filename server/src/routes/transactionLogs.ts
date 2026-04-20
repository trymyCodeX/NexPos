import { Router, Response } from "express";
import pool from "../db/client";
import { authenticateToken, AuthRequest } from "../middleware/auth";

const router = Router();

// BUG FIX: query count menggunakan params yang benar (tanpa limit/offset)
router.get("/", authenticateToken, async (req: AuthRequest, res: Response): Promise<void> => {
  const { action, outletId } = req.query;
  const limitNum = Math.min(parseInt(String(req.query.limit ?? "100"), 10), 500);
  const offsetNum = Math.max(parseInt(String(req.query.offset ?? "0"), 10), 0);

  try {
    const filterParams: any[] = [String(req.userId)];
    const conditions: string[] = ["tl.owner_id::text = $1::text"];

    if (action) {
      filterParams.push(String(action));
      conditions.push(`tl.action = $${filterParams.length}`);
    }

    if (outletId) {
      filterParams.push(String(outletId));
      conditions.push(`tl.outlet_id::text = $${filterParams.length}::text`);
    }

    const whereClause = `WHERE ${conditions.join(" AND ")}`;

    // BUG FIX: count query menggunakan filterParams saja (tanpa limit/offset)
    const countResult = await pool.query(
      `SELECT COUNT(*) AS total FROM transaction_logs tl ${whereClause}`,
      filterParams
    );

    // Data query menambahkan limit dan offset setelah filterParams
    const dataParams = [...filterParams, limitNum, offsetNum];
    const result = await pool.query(
      `SELECT tl.*
       FROM transaction_logs tl
       ${whereClause}
       ORDER BY tl.created_at DESC
       LIMIT $${dataParams.length - 1} OFFSET $${dataParams.length}`,
      dataParams
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
    console.error("[TransactionLogs GET]", err);
    res.status(500).json({ message: "Terjadi kesalahan server" });
  }
});

export default router;
