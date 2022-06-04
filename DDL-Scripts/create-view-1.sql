
-- ----------------------------------------
-- Create View 1 for the ELIDEK database --
-- ----------------------------------------

use elidek;


DROP VIEW IF EXISTS `projectresearcher_vw`;
CREATE VIEW `projectresearcher_vw` AS
SELECT `p`.`project_id`, `p`.`title`, `r`.`researcher_id`, CONCAT(`r`.`first_name`,' ',`r`.`last_name`) AS `full_name`, `o`.`name` `organization` 
FROM `project` `p` 
JOIN `WorksOn` `w` 
ON `w`.`project_id` = `p`.`project_id` 
JOIN `researcher` `r` 
ON `w`.`researcher_id` = `r`.`researcher_id` 
JOIN `organization` `o` 
ON `r`.`abbreviation` = `o`.`abbreviation`; 
