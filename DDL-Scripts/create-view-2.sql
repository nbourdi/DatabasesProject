-- ----------------------------------------
-- Create View 2 for the ELIDEK database --
-- ----------------------------------------

use elidek;
-- projects per organization

CREATE VIEW researchers_per_organization_vw AS
SELECT DISTINCT 
O.name, O.abbreviation, R.researcher_id,
concat(R.first_name,' ',R.last_name) AS full_name, 
DATE_FORMAT(FROM_DAYS(DATEDIFF(now(),R.birth_date)), '%Y')+0  AS age, R.gender
FROM organization O
INNER JOIN WorksFor W 
ON O.abbreviation = W.abbreviation 
INNER JOIN researcher R
ON W.researcher_id = R.researcher_id
