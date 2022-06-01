-- ------------
-- Query 3.3 --
-- ------------
use elidek;


SELECT p.title, p.start_date, p.end_date FROM project p
INNER JOIN FieldProject f ON f.project_id = p.project_id
WHERE f.field_id = 1 and p.end_date > curdate();

SELECT DISTINCT concat(R.first_name,' ',R.last_name) AS full_name  FROM researcher R 
INNER JOIN WorksOn w ON w.researcher_id = R.researcher_id
INNER JOIN project p ON p.project_id = w.project_id
WHERE p.project_id IN (SELECT p.project_id FROM project p
						INNER JOIN FieldProject f ON f.project_id = p.project_id
						WHERE f.field_id = 1 and p.end_date > curdate());
