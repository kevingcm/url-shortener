-- "Which short_code got the most clicks in the last hour?"
--
-- Recipe: FROM → JOIN → WHERE → GROUP BY → ORDER BY → LIMIT
--   FROM clicks        : click events live here
--   JOIN urls          : bring in the short_code label
--   WHERE ...          : restrict to the last hour
--   GROUP BY u.id      : collapse to one row per URL
--   COUNT(*)           : count evaluated per group
--   ORDER BY ... DESC  : biggest group first
--   LIMIT 1            : keep only the winner
SELECT u.short_code, COUNT(*) AS clicks
FROM clicks c
JOIN urls u ON u.id = c.url_id
WHERE c.clicked_at >= datetime('now', '-5 hour')
GROUP BY u.id
ORDER BY clicks DESC
LIMIT 3;
