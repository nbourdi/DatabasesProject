-- ------------
-- Query 3.5 --
-- ------------

use elidek;

SELECT f1.field_id, f1.field_name as field_1, f2.field_name as field_2, count 
FROM 
	(SELECT fp1.field_id as field1 , fp2.field_id as field2, COUNT(*) AS count, fp1.project_id as proj
	FROM fieldproject fp1
	INNER JOIN fieldproject fp2 ON
		fp1.project_id  = fp2.project_id AND fp1.field_id <> fp2.field_id
	group by fp1.field_id, fp2.field_id ) `t`
INNER JOIN field f1 ON field1 = f1.field_id 
INNER JOIN field f2 ON field2 = f2.field_id
GROUP BY proj
ORDER BY count DESC
LIMIT 3;