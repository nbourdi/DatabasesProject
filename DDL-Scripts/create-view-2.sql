-- ----------------------------------------
-- Create View 2 for the ELIDEK database --
-- ----------------------------------------

use elidek;
-- Evaluations of projects

DROP VIEW IF EXISTS `eval_view`;

CREATE VIEW `eval_view` AS 
SELECT `e`.`rating`, `e`.`eval_date`, `e`.`researcher_id`, CONCAT(`r`.`last_name`, ' ', `r`.`first_name`) AS eval_name, 
		`p`.`project_id`, `p`.`title`, `p`.`abbreviation`, `o`.`name`
FROM `evaluates` `e`
INNER JOIN `project` `p` ON `e`.`project_id` = `p`.`project_id`
INNER JOIN `researcher` `r` ON `r`.`researcher_id` = `e`.`researcher_id`
INNER JOIN `organization` `o` ON `o`.`abbreviation` = `p`.`abbreviation`;