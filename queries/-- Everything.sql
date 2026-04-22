-- Everything
SELECT * FROM urls;

-- Just the short codes and where they go
SELECT short_code, long_url FROM urls;

-- Newest first
SELECT short_code, long_url, created_at FROM urls ORDER BY created_at DESC;

-- How many URLs have we shortened?
SELECT COUNT(*) FROM urls;
