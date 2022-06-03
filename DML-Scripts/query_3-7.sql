-- ------------
-- Query 3.7 --
-- ------------
use elidek; 

SELECT * FROM (
SELECT e.executive_id AS id, concat(e.first_name,' ',e.last_name) AS full_name, o.name, p.amount
FROM executive e  
NATURAL JOIN project p 
NATURAL JOIN organization o
WHERE o.type = 'co'
ORDER BY p.amount DESC
LIMIT 5
) `t` 
GROUP BY `full_name`
ORDER BY amount DESC;
