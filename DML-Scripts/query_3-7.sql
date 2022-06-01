-- ------------
-- Query 3.7 --
-- ------------
-- ISSUE: if an exec funds > 1 project, one of the companies they fund will be deleted randomly when the one with the smallest amount should be deleted. 
use elidek; 

SELECT concat(e.first_name,' ',e.last_name) AS full_name, o.name, p.amount FROM executive e  
RIGHT JOIN project p ON p.executive_id = e.executive_id
INNER JOIN organization o ON p.abbreviation = o.abbreviation
WHERE o.type = 'co'
GROUP BY full_name
ORDER BY p.amount DESC
LIMIT 5;