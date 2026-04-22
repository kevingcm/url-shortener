-- Postgres syntax: INTERVAL for time math.
-- (SQLite version would be: WHERE clicked_at >= datetime('now', '-1 hour'))
SELECT COUNT(*) AS clicks_last_hour
FROM clicks
WHERE clicked_at >= NOW() - INTERVAL '1 hour';
