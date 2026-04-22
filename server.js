const express = require('express');
const path = require('path');
const { pool, initSchema } = require('./db');

const app = express();
const PORT = process.env.PORT || 3000;

// Behind a reverse proxy (Render, Railway, nginx, etc.), the incoming request
// hits the proxy over HTTPS, then the proxy forwards plain HTTP to our app.
// Without this, req.protocol returns 'http' even when the user is on HTTPS,
// and the short URLs we generate get the wrong scheme.
app.set('trust proxy', 1);

app.use(express.json());
app.use(express.static(path.join(__dirname, 'public')));

const ALPHABET = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

function generateShortCode(length = 6) {
  let code = '';
  for (let i = 0; i < length; i++) {
    code += ALPHABET[Math.floor(Math.random() * ALPHABET.length)];
  }
  return code;
}

function isValidHttpUrl(str) {
  try {
    const u = new URL(str);
    return u.protocol === 'http:' || u.protocol === 'https:';
  } catch {
    return false;
  }
}

// ─── Routes ─────────────────────────────────────────────────────────────────
// Note: Postgres uses $1, $2, ... placeholders instead of SQLite's ?
// Every DB call is async, so route handlers are `async` and use `await`.

app.post('/api/shorten', async (req, res) => {
  const { url } = req.body;
  if (!url || !isValidHttpUrl(url)) {
    return res.status(400).json({ error: 'Please provide a valid http(s) URL' });
  }

  let shortCode;
  for (let attempt = 0; attempt < 5; attempt++) {
    const candidate = generateShortCode();
    const existing = await pool.query(
      'SELECT 1 FROM urls WHERE short_code = $1',
      [candidate]
    );
    if (existing.rowCount === 0) {
      shortCode = candidate;
      break;
    }
  }
  if (!shortCode) {
    return res.status(500).json({ error: 'Could not generate a unique short code' });
  }

  await pool.query(
    'INSERT INTO urls (short_code, long_url) VALUES ($1, $2)',
    [shortCode, url]
  );

  res.json({
    short_code: shortCode,
    short_url: `${req.protocol}://${req.get('host')}/${shortCode}`,
    long_url: url,
  });
});

app.get('/api/stats/:code', async (req, res) => {
  const urlRes = await pool.query(
    'SELECT id, short_code, long_url, created_at FROM urls WHERE short_code = $1',
    [req.params.code]
  );
  if (urlRes.rowCount === 0) {
    return res.status(404).json({ error: 'Short URL not found' });
  }
  const url = urlRes.rows[0];

  // COUNT(*) returns a bigint in Postgres, which the `pg` driver returns as a
  // string to avoid JS number precision loss. For small counts we cast to int
  // so the JSON response has a real number, not a string.
  const totalRes = await pool.query(
    'SELECT COUNT(*)::int AS total FROM clicks WHERE url_id = $1',
    [url.id]
  );

  const byDayRes = await pool.query(
    `SELECT DATE(clicked_at)::text AS day, COUNT(*)::int AS count
     FROM clicks
     WHERE url_id = $1
       AND clicked_at >= NOW() - INTERVAL '30 days'
     GROUP BY DATE(clicked_at)
     ORDER BY day DESC`,
    [url.id]
  );

  const referrersRes = await pool.query(
    `SELECT COALESCE(NULLIF(referrer, ''), '(direct)') AS referrer,
            COUNT(*)::int AS count
     FROM clicks
     WHERE url_id = $1
     GROUP BY referrer
     ORDER BY count DESC
     LIMIT 10`,
    [url.id]
  );

  res.json({
    short_code: url.short_code,
    long_url: url.long_url,
    created_at: url.created_at,
    total_clicks: totalRes.rows[0].total,
    clicks_by_day: byDayRes.rows,
    top_referrers: referrersRes.rows,
  });
});

app.get('/:code', async (req, res) => {
  const { rows } = await pool.query(
    'SELECT id, long_url FROM urls WHERE short_code = $1',
    [req.params.code]
  );
  if (rows.length === 0) return res.status(404).send('Short URL not found');

  const row = rows[0];

  // Fire-and-forget the click log so it doesn't delay the redirect. If it
  // fails we log to the console but the user still gets their redirect.
  pool.query(
    'INSERT INTO clicks (url_id, referrer, user_agent) VALUES ($1, $2, $3)',
    [row.id, req.get('Referer') || null, req.get('User-Agent') || null]
  ).catch((err) => console.error('Failed to log click:', err.message));

  res.redirect(row.long_url);
});

// ─── Startup ────────────────────────────────────────────────────────────────

async function start() {
  await initSchema();
  app.listen(PORT, () => {
    console.log(`Server running at http://localhost:${PORT}`);
  });
}

start().catch((err) => {
  console.error('Failed to start:', err);
  process.exit(1);
});
