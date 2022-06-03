-- ------------
-- Query 3.4 --
-- ------------

use elidek;

SELECT `ab`, `org_name`, `proj_count`, `proj_count2`, concat(`year1`, ' - ', `year2`) AS `span` FROM
(SELECT o.`abbreviation` as `ab`, `o`.`name` as `org_name`, count(*) AS `proj_count`, year(`p`.`start_date`) AS `year1`
FROM `organization` `o`
INNER JOIN `project` `p` ON `o`.`abbreviation` = `p`.`abbreviation`
GROUP BY `o`.`abbreviation`, year(`p`.`start_date`)
) `t`,
(SELECT `o`.`abbreviation`, `o`.`name`, count(*) AS `proj_count2`, year(`p`.`start_date`) AS `year2`
FROM `organization` o
INNER JOIN `project` `p` ON `o`.`abbreviation` = `p`.`abbreviation`
GROUP BY `o`.`abbreviation`, year(`p`.`start_date`)
) `t2`
WHERE `t2`.`abbreviation` = `ab` AND `year2` - `year1` = 1
HAVING `proj_count2` = `proj_count` AND `proj_count` >= 10

