-- Last 20 clicks across all URLs, joined with the URL they were for.
SELECT c.clicked_at,
       u.short_code,
       c.referrer,
       c.user_agent
FROM clicks c
JOIN urls u ON u.id = c.url_id
ORDER BY c.clicked_at DESC
LIMIT 20;
