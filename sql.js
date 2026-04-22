// Tiny SQL runner: `npm run sql -- path/to/file.sql`
// Reads a .sql file and executes it against the Postgres DB in DATABASE_URL.
// If the query returns rows, prints them as a table. Otherwise reports OK.

require('dotenv').config();
const fs = require('fs');
const { Pool } = require('pg');

const file = process.argv[2];
if (!file) {
  console.error('Usage: npm run sql -- path/to/file.sql');
  process.exit(1);
}

const sql = fs.readFileSync(file, 'utf8');
const pool = new Pool({ connectionString: process.env.DATABASE_URL });

(async () => {
  try {
    const result = await pool.query(sql);
    if (result.rows && result.rows.length > 0) {
      console.table(result.rows);
    } else {
      console.log(`OK — ${result.command || 'executed'} (${result.rowCount ?? 0} rows affected)`);
    }
  } catch (err) {
    console.error('SQL error:', err.message);
    process.exitCode = 1;
  } finally {
    await pool.end();
  }
})();
