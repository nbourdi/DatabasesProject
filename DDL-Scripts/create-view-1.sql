
-- ----------------------------------------
-- Create View 1 for the ELIDEK database --
-- ----------------------------------------

use elidek;
-- not sure it's what we want.

CREATE VIEW projectresearcher_vw AS
SELECT DISTINCT 
P.project_id, P.title, R.researcher_id,
concat(R.first_name,' ',R.last_name) AS full_name, 
DATE_FORMAT(FROM_DAYS(DATEDIFF(now(),R.birth_date)), '%Y')+0  AS age, R.gender
FROM project P
INNER JOIN WorksOn W 
ON W.project_id = P.project_id 
INNER JOIN researcher R
ON W.researcher_id = R.researcher_id
ORDER BY age;
