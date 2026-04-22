require('dotenv').config();
const { Pool } = require('pg');

if (!process.env.DATABASE_URL) {
  throw new Error('DATABASE_URL is not set. Copy .env.example to .env and fill it in.');
}

// A connection pool keeps a handful of Postgres connections open and hands them
// out to queries as needed. Opening a fresh connection for every query would
// be slow (TCP handshake + TLS + auth every time). The pool amortizes that.
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
});

async function initSchema() {
  await pool.query(`
    CREATE TABLE IF NOT EXISTS urls (
      id          SERIAL       PRIMARY KEY,
      short_code  TEXT         NOT NULL UNIQUE,
      long_url    TEXT         NOT NULL,
      created_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW()
    );

    CREATE TABLE IF NOT EXISTS clicks (
      id          SERIAL       PRIMARY KEY,
      url_id      INTEGER      NOT NULL REFERENCES urls(id) ON DELETE CASCADE,
      clicked_at  TIMESTAMPTZ  NOT NULL DEFAULT NOW(),
      referrer    TEXT,
      user_agent  TEXT
    );

    CREATE INDEX IF NOT EXISTS idx_clicks_url_id     ON clicks(url_id);
    CREATE INDEX IF NOT EXISTS idx_clicks_clicked_at ON clicks(clicked_at);
  `);
}

module.exports = { pool, initSchema };
