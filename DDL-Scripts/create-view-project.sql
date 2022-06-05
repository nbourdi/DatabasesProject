-- ----------------------------------------
-- Create View 2 for the ELIDEK database --
-- ----------------------------------------

USE elidek;

DROP VIEW IF EXISTS `project_view`;

CREATE VIEW `project_view` AS 
SELECT `p`.`project_id`, `p`.`title`, `p`.`summary`, `p`.`amount`, `p`.`start_date`, `p`.`end_date`,`p`.`program_id`, 
YEAR(`p`.`end_date`) - YEAR(`p`.`start_date`) - (DATE_FORMAT(`p`.`end_date`, '%m%d') < DATE_FORMAT(`p`.`start_date`, '%m%d')) `duration`, `p`.`abbreviation`, `o`.`name` `organization`, `p`.`researcher_id` `manager_id`, CONCAT(`r`.`last_name`, ' ', `r`.`first_name`) `manager`, 
`e`.`executive_id`, CONCAT(`e`.`first_name`, ' ', `e`.`last_name`) `executive_name`, COUNT(`w`.`researcher_id`) `researchers`, GROUP_CONCAT(DISTINCT `field_id`) `field`
FROM `project` `p` 
NATURAL JOIN `executive` `e`
JOIN `researcher` `r`
ON `p`.`researcher_id` = `r`.`researcher_id`
JOIN `WorksOn`  `w`
ON `p`.`project_id` = `w`.`project_id`
JOIN `FieldProject` `f`
ON `p`.`project_id` = `f`.`project_id`
JOIN `organization` `o`
ON `p`.`abbreviation` = `o`.`abbreviation`
GROUP BY `p`.`project_id`;