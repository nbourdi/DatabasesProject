-- ------------
-- Query 3.8 --
-- ------------

use elidek;

SELECT r.researcher_id, r.first_name, r.last_name, COUNT(*) `count`
FROM researcher r 
INNER JOIN WorksOn w ON r.researcher_id = w.researcher_id
inner join project p ON w.project_id = p.project_id 
WHERE w.project_id NOT IN (SELECT project_id FROM deliverable)  AND p.end_date > curdate()
GROUP BY r.researcher_id
HAVING COUNT(*) > 4
ORDER BY COUNT(*) DESC;
