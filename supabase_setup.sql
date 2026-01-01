CREATE TABLE IF NOT EXISTS users (
  id BIGSERIAL PRIMARY KEY,
  name TEXT NOT NULL,
  phone TEXT NOT NULL,
  government_id TEXT,
  service_name TEXT NOT NULL,
  service_number INTEGER NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS global_counter (
  id TEXT PRIMARY KEY DEFAULT 'main',
  last_number INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS admins (
  id TEXT PRIMARY KEY,
  password TEXT NOT NULL,
  service TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  seeded_from_env BOOLEAN NOT NULL DEFAULT FALSE
);

ALTER TABLE users REPLICA IDENTITY FULL;
ALTER TABLE global_counter REPLICA IDENTITY FULL;
ALTER TABLE admins REPLICA IDENTITY FULL;

CREATE INDEX IF NOT EXISTS idx_users_service_name ON users(service_name);
CREATE INDEX IF NOT EXISTS idx_users_phone ON users(phone);
CREATE INDEX IF NOT EXISTS idx_admins_service ON admins(service);

