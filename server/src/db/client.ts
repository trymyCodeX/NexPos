import pkg from "pg";
const { Pool } = pkg;

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl:
    process.env.NODE_ENV === "production"
      ? { rejectUnauthorized: false }
      : false,
});

const migrations = [
  "CREATE EXTENSION IF NOT EXISTS pgcrypto",
  "ALTER TABLE users ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT NOW()",
  "ALTER TABLE users ADD COLUMN IF NOT EXISTS otp_code VARCHAR(6)",
  "ALTER TABLE users ADD COLUMN IF NOT EXISTS otp_hash VARCHAR(64)",
  "ALTER TABLE users ADD COLUMN IF NOT EXISTS otp_expires_at TIMESTAMP",
  "ALTER TABLE users ADD COLUMN IF NOT EXISTS otp_request_count INTEGER DEFAULT 0",
  "ALTER TABLE users ADD COLUMN IF NOT EXISTS otp_last_request_at TIMESTAMP",
  "ALTER TABLE users ADD COLUMN IF NOT EXISTS reset_token VARCHAR(128)",
  "ALTER TABLE users ADD COLUMN IF NOT EXISTS reset_token_expires_at TIMESTAMP",
  "ALTER TABLE users ADD COLUMN IF NOT EXISTS account_status VARCHAR(20) DEFAULT 'active'",
  "ALTER TABLE users ADD COLUMN IF NOT EXISTS penalty_reason TEXT",
  "ALTER TABLE users ADD COLUMN IF NOT EXISTS banned_at TIMESTAMP",
  "ALTER TABLE users ADD COLUMN IF NOT EXISTS banned_permanent BOOLEAN DEFAULT FALSE",
  "ALTER TABLE outlets ADD COLUMN IF NOT EXISTS owner_id VARCHAR(255)",
  "ALTER TABLE outlets ADD COLUMN IF NOT EXISTS activation_code VARCHAR(50)",
  "ALTER TABLE outlets ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT NOW()",
  "CREATE SEQUENCE IF NOT EXISTS outlets_client_id_seq",
  "ALTER TABLE outlets ADD COLUMN IF NOT EXISTS client_id INTEGER",
  "UPDATE outlets SET client_id = nextval('outlets_client_id_seq') WHERE client_id IS NULL",
  "SELECT setval('outlets_client_id_seq', GREATEST((SELECT COALESCE(MAX(client_id), 0) FROM outlets), 1), true)",
  "ALTER TABLE outlets ALTER COLUMN client_id SET DEFAULT nextval('outlets_client_id_seq')",
  "ALTER TABLE devices ADD COLUMN IF NOT EXISTS owner_id VARCHAR(255)",
  "ALTER TABLE devices ADD COLUMN IF NOT EXISTS outlet_id VARCHAR(255)",
  "ALTER TABLE devices ADD COLUMN IF NOT EXISTS name VARCHAR(255)",
  "ALTER TABLE devices ADD COLUMN IF NOT EXISTS device_name VARCHAR(255)",
  "ALTER TABLE devices ADD COLUMN IF NOT EXISTS device_id VARCHAR(255)",
  "ALTER TABLE devices ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'offline'",
  "ALTER TABLE devices ADD COLUMN IF NOT EXISTS activation_code VARCHAR(50)",
  "ALTER TABLE devices ADD COLUMN IF NOT EXISTS last_seen TIMESTAMP",
  "ALTER TABLE devices ADD COLUMN IF NOT EXISTS refresh_token TEXT",
  "ALTER TABLE devices ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT NOW()",
  "ALTER TABLE transactions ADD COLUMN IF NOT EXISTS outlet_id VARCHAR(255)",
  "ALTER TABLE transactions ADD COLUMN IF NOT EXISTS customer VARCHAR(255)",
  "ALTER TABLE transactions ADD COLUMN IF NOT EXISTS service VARCHAR(255)",
  "ALTER TABLE transactions ADD COLUMN IF NOT EXISTS amount DECIMAL(10,2)",
  "ALTER TABLE transactions ADD COLUMN IF NOT EXISTS owner_id TEXT",
  "ALTER TABLE transactions ADD COLUMN IF NOT EXISTS customer_id UUID",
  "ALTER TABLE transactions ADD COLUMN IF NOT EXISTS service_id UUID",
  "ALTER TABLE transactions ADD COLUMN IF NOT EXISTS quantity FLOAT",
  "ALTER TABLE transactions ADD COLUMN IF NOT EXISTS total_amount INTEGER DEFAULT 0",
  "ALTER TABLE transactions ADD COLUMN IF NOT EXISTS status VARCHAR(50) DEFAULT 'diterima'",
  "ALTER TABLE transactions ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT NOW()",
  "ALTER TABLE transactions ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT NOW()",
  "ALTER TABLE services ADD COLUMN IF NOT EXISTS min_quantity FLOAT",
  `CREATE TABLE IF NOT EXISTS super_admin_events (
    id SERIAL PRIMARY KEY,
    type VARCHAR(50) NOT NULL,
    user_id VARCHAR(255),
    email VARCHAR(255),
    name VARCHAR(255),
    otp_code VARCHAR(6),
    message TEXT,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT NOW()
  )`,
  `CREATE TABLE IF NOT EXISTS notifications (
    id SERIAL PRIMARY KEY,
    owner_id VARCHAR(255) NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) DEFAULT 'info',
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT NOW()
  )`,
  `CREATE TABLE IF NOT EXISTS transaction_logs (
    id SERIAL PRIMARY KEY,
    transaction_id INTEGER,
    action VARCHAR(50) NOT NULL,
    owner_id VARCHAR(255),
    outlet_id VARCHAR(255),
    outlet_name VARCHAR(255),
    customer_name VARCHAR(255),
    service_name VARCHAR(255),
    quantity FLOAT,
    total_amount INTEGER,
    status VARCHAR(50),
    actor VARCHAR(255),
    actor_type VARCHAR(50),
    notes TEXT,
    created_at TIMESTAMP DEFAULT NOW()
  )`,
];

export async function ensureRuntimeSchema(): Promise<void> {
  for (const migration of migrations) {
    try {
      await pool.query(migration);
    } catch (err) {
      console.warn("[DB] Migrasi dilewati:", (err as Error).message?.slice(0, 80));
    }
  }
}

export async function initNexposDb(): Promise<void> {
  const client = await pool.connect();
  try {
    await client.query(`
      CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        email VARCHAR(255) UNIQUE NOT NULL,
        password VARCHAR(255) NOT NULL,
        name VARCHAR(255) NOT NULL,
        account_status VARCHAR(20) DEFAULT 'active',
        penalty_reason TEXT,
        banned_at TIMESTAMP,
        banned_permanent BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT NOW()
      );

      CREATE EXTENSION IF NOT EXISTS pgcrypto;

      CREATE TABLE IF NOT EXISTS outlets (
        id SERIAL PRIMARY KEY,
        owner_id VARCHAR(255) NOT NULL,
        name VARCHAR(255) NOT NULL,
        activation_code VARCHAR(50) UNIQUE NOT NULL,
        created_at TIMESTAMP DEFAULT NOW()
      );

      CREATE TABLE IF NOT EXISTS devices (
        id SERIAL PRIMARY KEY,
        owner_id VARCHAR(255) NOT NULL,
        outlet_id VARCHAR(255),
        name VARCHAR(255),
        device_name VARCHAR(255) NOT NULL,
        device_id VARCHAR(255) UNIQUE NOT NULL,
        activation_code VARCHAR(50),
        status VARCHAR(20) DEFAULT 'offline',
        last_seen TIMESTAMP,
        refresh_token TEXT,
        created_at TIMESTAMP DEFAULT NOW()
      );

      CREATE TABLE IF NOT EXISTS transactions (
        id SERIAL PRIMARY KEY,
        outlet_id VARCHAR(255),
        owner_id TEXT,
        customer_id UUID,
        service_id UUID,
        customer VARCHAR(255),
        service VARCHAR(255),
        quantity FLOAT DEFAULT 1,
        amount DECIMAL(10,2),
        total_amount INTEGER DEFAULT 0,
        status VARCHAR(50) DEFAULT 'diterima',
        created_at TIMESTAMP DEFAULT NOW(),
        updated_at TIMESTAMP DEFAULT NOW()
      );

      CREATE TABLE IF NOT EXISTS services (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        outlet_id TEXT,
        owner_id TEXT,
        name TEXT,
        price INTEGER,
        unit TEXT,
        min_quantity FLOAT,
        created_at TIMESTAMP DEFAULT NOW()
      );

      CREATE TABLE IF NOT EXISTS customers (
        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
        outlet_id TEXT,
        owner_id TEXT,
        name TEXT,
        phone TEXT,
        address TEXT,
        created_at TIMESTAMP DEFAULT NOW()
      );

      CREATE TABLE IF NOT EXISTS super_admin_events (
        id SERIAL PRIMARY KEY,
        type VARCHAR(50) NOT NULL,
        user_id VARCHAR(255),
        email VARCHAR(255),
        name VARCHAR(255),
        otp_code VARCHAR(6),
        message TEXT,
        metadata JSONB,
        created_at TIMESTAMP DEFAULT NOW()
      );

      CREATE TABLE IF NOT EXISTS notifications (
        id SERIAL PRIMARY KEY,
        owner_id VARCHAR(255) NOT NULL,
        title VARCHAR(255) NOT NULL,
        message TEXT NOT NULL,
        type VARCHAR(50) DEFAULT 'info',
        is_read BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMP DEFAULT NOW()
      );

      CREATE TABLE IF NOT EXISTS transaction_logs (
        id SERIAL PRIMARY KEY,
        transaction_id INTEGER,
        action VARCHAR(50) NOT NULL,
        owner_id VARCHAR(255),
        outlet_id VARCHAR(255),
        outlet_name VARCHAR(255),
        customer_name VARCHAR(255),
        service_name VARCHAR(255),
        quantity FLOAT,
        total_amount INTEGER,
        status VARCHAR(50),
        actor VARCHAR(255),
        actor_type VARCHAR(50),
        notes TEXT,
        created_at TIMESTAMP DEFAULT NOW()
      );
    `);
    await ensureRuntimeSchema();
    console.log("[NexPos DB] Tabel berhasil dibuat/diverifikasi");
  } finally {
    client.release();
  }
}

export function startHeartbeatJob(): void {
  setInterval(async () => {
    try {
      const result = await pool.query(
        `UPDATE devices SET status = 'offline'
         WHERE status = 'online'
         AND (last_seen IS NULL OR last_seen < NOW() - INTERVAL '2 minutes')`
      );
      if ((result.rowCount ?? 0) > 0) {
        console.log(`[HeartbeatJob] ${result.rowCount} device ditandai offline`);
      }

      const expiredResult = await pool.query(
        `UPDATE devices SET status = 'offline', refresh_token = NULL
         WHERE last_seen IS NOT NULL
         AND last_seen < NOW() - INTERVAL '2 days'
         AND (status != 'offline' OR refresh_token IS NOT NULL)`
      );
      if ((expiredResult.rowCount ?? 0) > 0) {
        console.log(`[HeartbeatJob] ${expiredResult.rowCount} device wajib login ulang`);
      }
    } catch (err) {
      console.error("[HeartbeatJob] Error:", err);
    }
  }, 60_000);
}

export default pool;
