-- Your first JOIN. Combines data from `urls` and `clicks` into one result.
-- LEFT JOIN so URLs with zero clicks still show up (they'd disappear with INNER JOIN).
SELECT u.short_code,
       u.long_url,
       COUNT(c.id) AS clicks
FROM urls u
LEFT JOIN clicks c ON c.url_id = u.id
GROUP BY u.id
ORDER BY clicks DESC;
