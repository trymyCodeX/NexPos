import { Pool } from "pg";

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl:
    process.env.NODE_ENV === "production"
      ? { rejectUnauthorized: false }
      : false,
});

const migrations = [
  "CREATE EXTENSION IF NOT EXISTS pgcrypto",
  // Hapus NOT NULL di owner_id agar tidak crash jika tipe UUID (Railway legacy schema)
  "ALTER TABLE devices ALTER COLUMN owner_id DROP NOT NULL",
  "ALTER TABLE outlets ALTER COLUMN owner_id DROP NOT NULL",
  "ALTER TABLE users ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT NOW()",
  "ALTER TABLE outlets ADD COLUMN IF NOT EXISTS owner_id INTEGER REFERENCES users(id) ON DELETE CASCADE",
  `DO $$
   DECLARE constraint_name text;
   BEGIN
     FOR constraint_name IN
       SELECT kcu.constraint_name
       FROM information_schema.key_column_usage kcu
       WHERE kcu.table_name = 'outlets'
         AND kcu.column_name = 'owner_id'
         AND kcu.table_schema = current_schema()
     LOOP
       EXECUTE format('ALTER TABLE outlets DROP CONSTRAINT IF EXISTS %I', constraint_name);
     END LOOP;
   END $$`,
  "ALTER TABLE outlets ALTER COLUMN owner_id TYPE VARCHAR(255) USING owner_id::text",
  "CREATE SEQUENCE IF NOT EXISTS outlets_client_id_seq",
  "ALTER TABLE outlets ADD COLUMN IF NOT EXISTS client_id INTEGER",
  "UPDATE outlets SET client_id = nextval('outlets_client_id_seq') WHERE client_id IS NULL",
  "SELECT setval('outlets_client_id_seq', GREATEST((SELECT COALESCE(MAX(client_id), 0) FROM outlets), 1), true)",
  "ALTER TABLE outlets ALTER COLUMN client_id SET DEFAULT nextval('outlets_client_id_seq')",
  "ALTER TABLE outlets ADD COLUMN IF NOT EXISTS activation_code VARCHAR(50)",
  "ALTER TABLE outlets ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT NOW()",
  "ALTER TABLE devices ADD COLUMN IF NOT EXISTS owner_id INTEGER REFERENCES users(id) ON DELETE CASCADE",
  `DO $$
   DECLARE constraint_name text;
   BEGIN
     FOR constraint_name IN
       SELECT kcu.constraint_name
       FROM information_schema.key_column_usage kcu
       WHERE kcu.table_name = 'devices'
         AND kcu.column_name = 'owner_id'
         AND kcu.table_schema = current_schema()
     LOOP
       EXECUTE format('ALTER TABLE devices DROP CONSTRAINT IF EXISTS %I', constraint_name);
     END LOOP;
   END $$`,
  "ALTER TABLE devices ALTER COLUMN owner_id TYPE VARCHAR(255) USING owner_id::text",
  `DO $$
   DECLARE outlet_id_type text;
   DECLARE constraint_name text;
   BEGIN
     SELECT data_type INTO outlet_id_type
     FROM information_schema.columns
     WHERE table_name = 'devices'
       AND column_name = 'outlet_id'
       AND table_schema = current_schema();

     IF outlet_id_type IS NOT NULL THEN
       FOR constraint_name IN
         SELECT tc.constraint_name
         FROM information_schema.table_constraints tc
         JOIN information_schema.key_column_usage kcu
           ON tc.constraint_name = kcu.constraint_name
          AND tc.table_schema = kcu.table_schema
         WHERE tc.table_name = 'devices'
           AND kcu.column_name = 'outlet_id'
           AND tc.table_schema = current_schema()
       LOOP
         EXECUTE format('ALTER TABLE devices DROP CONSTRAINT IF EXISTS %I', constraint_name);
       END LOOP;

       ALTER TABLE devices ALTER COLUMN outlet_id TYPE VARCHAR(255) USING outlet_id::text;
       RAISE NOTICE 'devices.outlet_id type % dinormalisasi menjadi VARCHAR', outlet_id_type;
     END IF;
   END $$`,
  "ALTER TABLE devices ADD COLUMN IF NOT EXISTS outlet_id VARCHAR(255)",
  "ALTER TABLE devices ADD COLUMN IF NOT EXISTS name VARCHAR(255)",
  "ALTER TABLE devices ADD COLUMN IF NOT EXISTS device_name VARCHAR(255)",
  "UPDATE devices SET device_name = COALESCE(device_name, name), name = COALESCE(name, device_name, 'Unknown Device') WHERE device_name IS NULL OR name IS NULL",
  "ALTER TABLE devices ADD COLUMN IF NOT EXISTS device_id VARCHAR(255)",
  "ALTER TABLE devices ADD COLUMN IF NOT EXISTS status VARCHAR(20) DEFAULT 'offline'",
  "ALTER TABLE devices ADD COLUMN IF NOT EXISTS activation_code VARCHAR(50)",
  "ALTER TABLE devices ADD COLUMN IF NOT EXISTS last_seen TIMESTAMP",
  "ALTER TABLE devices ADD COLUMN IF NOT EXISTS refresh_token TEXT",
  "ALTER TABLE devices ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT NOW()",
  `DO $$
   DECLARE outlet_id_type text;
   DECLARE constraint_name text;
   BEGIN
     SELECT data_type INTO outlet_id_type
     FROM information_schema.columns
     WHERE table_name = 'transactions'
       AND column_name = 'outlet_id'
       AND table_schema = current_schema();

     IF outlet_id_type IS NOT NULL THEN
       FOR constraint_name IN
         SELECT tc.constraint_name
         FROM information_schema.table_constraints tc
         JOIN information_schema.key_column_usage kcu
           ON tc.constraint_name = kcu.constraint_name
          AND tc.table_schema = kcu.table_schema
         WHERE tc.table_name = 'transactions'
           AND kcu.column_name = 'outlet_id'
           AND tc.table_schema = current_schema()
       LOOP
         EXECUTE format('ALTER TABLE transactions DROP CONSTRAINT IF EXISTS %I', constraint_name);
       END LOOP;

       ALTER TABLE transactions ALTER COLUMN outlet_id TYPE VARCHAR(255) USING outlet_id::text;
       RAISE NOTICE 'transactions.outlet_id type % dinormalisasi menjadi VARCHAR', outlet_id_type;
     END IF;
   END $$`,
  "ALTER TABLE transactions ADD COLUMN IF NOT EXISTS outlet_id VARCHAR(255)",
  "UPDATE devices d SET outlet_id = o.id::text FROM outlets o WHERE d.outlet_id::text = o.client_id::text",
  "UPDATE transactions t SET outlet_id = o.id::text FROM outlets o WHERE t.outlet_id::text = o.client_id::text",
  "ALTER TABLE transactions ADD COLUMN IF NOT EXISTS customer VARCHAR(255)",
  "ALTER TABLE transactions ADD COLUMN IF NOT EXISTS service VARCHAR(255)",
  "ALTER TABLE transactions ADD COLUMN IF NOT EXISTS amount DECIMAL(10,2)",
  "ALTER TABLE transactions ADD COLUMN IF NOT EXISTS owner_id TEXT",
  "ALTER TABLE transactions ADD COLUMN IF NOT EXISTS customer_id UUID",
  "ALTER TABLE transactions ADD COLUMN IF NOT EXISTS service_id UUID",
  "ALTER TABLE transactions ADD COLUMN IF NOT EXISTS quantity FLOAT",
  "ALTER TABLE transactions ADD COLUMN IF NOT EXISTS total_amount INTEGER",
  "UPDATE transactions SET total_amount = COALESCE(total_amount, amount::integer, 0) WHERE total_amount IS NULL",
  "ALTER TABLE transactions ALTER COLUMN total_amount SET DEFAULT 0",
  "ALTER TABLE transactions ALTER COLUMN total_amount DROP NOT NULL",
  "ALTER TABLE devices DROP CONSTRAINT IF EXISTS devices_activation_code_unique",
  "DROP INDEX IF EXISTS devices_activation_code_unique",
  "ALTER TABLE transactions ADD COLUMN IF NOT EXISTS status VARCHAR(50) DEFAULT 'diterima'",
  "ALTER TABLE transactions ADD COLUMN IF NOT EXISTS created_at TIMESTAMP DEFAULT NOW()",
  "ALTER TABLE transactions ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT NOW()",
  "UPDATE users SET created_at = NOW() WHERE created_at IS NULL",
  "UPDATE outlets SET created_at = NOW() WHERE created_at IS NULL",
  "UPDATE devices SET status = COALESCE(status, 'offline'), created_at = COALESCE(created_at, NOW()) WHERE status IS NULL OR created_at IS NULL",
  "UPDATE transactions SET created_at = COALESCE(created_at, NOW()), updated_at = COALESCE(updated_at, created_at, NOW()), status = COALESCE(status, 'diterima') WHERE created_at IS NULL OR updated_at IS NULL OR status IS NULL",
  "ALTER TABLE users ADD COLUMN IF NOT EXISTS otp_code VARCHAR(6)",
  "ALTER TABLE users ADD COLUMN IF NOT EXISTS otp_expires_at TIMESTAMP",
  "ALTER TABLE users ADD COLUMN IF NOT EXISTS reset_token VARCHAR(128)",
  "ALTER TABLE users ADD COLUMN IF NOT EXISTS reset_token_expires_at TIMESTAMP",
  "ALTER TABLE users ADD COLUMN IF NOT EXISTS account_status VARCHAR(20) DEFAULT 'active'",
  "ALTER TABLE users ADD COLUMN IF NOT EXISTS penalty_reason TEXT",
  "ALTER TABLE users ADD COLUMN IF NOT EXISTS banned_at TIMESTAMP",
  "ALTER TABLE users ADD COLUMN IF NOT EXISTS banned_permanent BOOLEAN DEFAULT FALSE",
  "CREATE TABLE IF NOT EXISTS super_admin_events (id SERIAL PRIMARY KEY, type VARCHAR(50) NOT NULL, user_id VARCHAR(255), email VARCHAR(255), name VARCHAR(255), otp_code VARCHAR(6), message TEXT, metadata JSONB, created_at TIMESTAMP DEFAULT NOW())",
  "CREATE TABLE IF NOT EXISTS notifications (id SERIAL PRIMARY KEY, owner_id VARCHAR(255) NOT NULL, title VARCHAR(255) NOT NULL, message TEXT NOT NULL, type VARCHAR(50) DEFAULT 'info', is_read BOOLEAN DEFAULT FALSE, created_at TIMESTAMP DEFAULT NOW())",
  "CREATE TABLE IF NOT EXISTS services (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), outlet_id TEXT, owner_id TEXT, name TEXT, price INTEGER, unit TEXT, created_at TIMESTAMP DEFAULT NOW())",
  "CREATE TABLE IF NOT EXISTS customers (id UUID PRIMARY KEY DEFAULT gen_random_uuid(), outlet_id TEXT, owner_id TEXT, name TEXT, phone TEXT, address TEXT, created_at TIMESTAMP DEFAULT NOW())",
  "ALTER TABLE users ADD COLUMN IF NOT EXISTS otp_hash VARCHAR(64)",
  "ALTER TABLE users ADD COLUMN IF NOT EXISTS otp_request_count INTEGER DEFAULT 0",
  "ALTER TABLE users ADD COLUMN IF NOT EXISTS otp_last_request_at TIMESTAMP",
  // New: min_quantity untuk layanan, transaction_logs untuk audit
  "ALTER TABLE services ADD COLUMN IF NOT EXISTS min_quantity FLOAT",
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

export async function ensureRuntimeSchema() {
  for (const migration of migrations) {
    try {
      await pool.query(migration);
    } catch (err) {
      console.warn("[DB] Migrasi dilewati:", migration, err);
    }
  }
}

export async function initDb() {
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
        client_id SERIAL UNIQUE,
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
        customer VARCHAR(255) NOT NULL,
        service VARCHAR(255) NOT NULL,
        amount DECIMAL(10,2) NOT NULL,
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
    `);
    await ensureRuntimeSchema();
    console.log("[DB] Tabel berhasil dibuat/diverifikasi");
  } finally {
    client.release();
  }
}

export default pool;
