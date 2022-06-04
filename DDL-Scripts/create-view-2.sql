-- ----------------------------------------
-- Create View 2 for the ELIDEK database --
-- ----------------------------------------

use elidek;
-- Evaluations of projects

DROP VIEW IF EXISTS `eval_view`;

CREATE VIEW `eval_view` AS 
SELECT `e`.`rating`, `e`.`eval_date`, `e`.`researcher_id`, `p`.`project_id`, `p`.`title`, `p`.`abbreviation`
FROM `evaluates` `e`
INNER JOIN `project` `p` ON `e`.`project_id` = `p`.`project_id`;