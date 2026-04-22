// One-off script: create the Postgres schema and copy existing data from the
// local urls.db (SQLite) into it. Run once:  node migrate-to-postgres.js
//
// Safe to re-run: it uses INSERT ... ON CONFLICT DO NOTHING, so duplicate
// runs won't create duplicate rows.

require('dotenv').config();
const path = require('path');
const Database = require('better-sqlite3');
const { pool, initSchema } = require('./db');

async function main() {
  console.log('→ Creating schema in Postgres...');
  await initSchema();

  const sqlitePath = path.join(__dirname, 'urls.db');
  let sqlite;
  try {
    sqlite = new Database(sqlitePath, { readonly: true, fileMustExist: true });
  } catch {
    console.log('  (no urls.db found — skipping data copy)');
    await pool.end();
    return;
  }

  const urls = sqlite.prepare('SELECT * FROM urls').all();
  console.log(`→ Copying ${urls.length} urls...`);
  for (const u of urls) {
    await pool.query(
      `INSERT INTO urls (id, short_code, long_url, created_at)
       VALUES ($1, $2, $3, $4)
       ON CONFLICT (short_code) DO NOTHING`,
      [u.id, u.short_code, u.long_url, u.created_at]
    );
  }

  const clicks = sqlite.prepare('SELECT * FROM clicks').all();
  console.log(`→ Copying ${clicks.length} clicks...`);
  for (const c of clicks) {
    await pool.query(
      `INSERT INTO clicks (id, url_id, clicked_at, referrer, user_agent)
       VALUES ($1, $2, $3, $4, $5)
       ON CONFLICT (id) DO NOTHING`,
      [c.id, c.url_id, c.clicked_at, c.referrer, c.user_agent]
    );
  }

  // IMPORTANT: when you insert rows with explicit ids (as we just did to
  // preserve the data), Postgres's auto-increment sequence doesn't advance.
  // The next insert *without* an explicit id would try id=1 and collide.
  // setval fixes it: "the next value should be MAX(id) + 1".
  console.log('→ Fixing auto-increment sequences...');
  await pool.query(
    `SELECT setval('urls_id_seq',   COALESCE((SELECT MAX(id) FROM urls),   1), true)`
  );
  await pool.query(
    `SELECT setval('clicks_id_seq', COALESCE((SELECT MAX(id) FROM clicks), 1), true)`
  );

  sqlite.close();
  await pool.end();
  console.log('✓ Done.');
}

main().catch((err) => {
  console.error('Migration failed:', err);
  process.exit(1);
});
