-- ------------
-- Query 3.6 --
-- ------------

use elidek;

SELECT r.researcher_id, r.first_name, r.last_name, COUNT(*) as count , DATE_FORMAT(FROM_DAYS(DATEDIFF(now(), r.birth_date)), '%Y')+0  AS age 
FROM researcher r 
INNER JOIN WorksOn w ON w.researcher_id = r.researcher_id
INNER JOIN project p ON p.project_id = w.project_id WHERE p.end_date > curdate()
GROUP BY r.researcher_id
HAVING age < 40
ORDER BY COUNT(*) DESC; 