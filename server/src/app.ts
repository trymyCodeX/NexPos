import express from "express";
import cors from "cors";
import authRouter from "./routes/auth";
import outletsRouter from "./routes/outlets";
import devicesRouter from "./routes/devices";
import servicesRouter from "./routes/services";
import customersRouter from "./routes/customers";
import transactionsRouter from "./routes/transactions";
import superAdminRouter from "./routes/superAdmin";
import notificationsRouter from "./routes/notifications";
import reportsRouter from "./routes/reports";
import transactionLogsRouter from "./routes/transactionLogs";

const app = express();

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

app.get("/", (_req, res) => {
  res.json({
    name: "NexPos API",
    status: "ok",
    health: "/api/healthz",
  });
});

app.get("/api/healthz", (_req, res) => {
  res.json({ status: "ok", timestamp: new Date().toISOString() });
});

app.use("/api/auth", authRouter);
app.use("/api/outlets", outletsRouter);
app.use("/api/devices", devicesRouter);
app.use("/api/services", servicesRouter);
app.use("/api/customers", customersRouter);
app.use("/api/transactions", transactionsRouter);
app.use("/api/super-admin", superAdminRouter);
app.use("/api/notifications", notificationsRouter);
app.use("/api/reports", reportsRouter);
app.use("/api/transaction-logs", transactionLogsRouter);

app.use((_req, res) => {
  res.status(404).json({ message: "Endpoint tidak ditemukan" });
});

export default app;
