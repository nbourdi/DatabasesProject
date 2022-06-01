

DROP VIEW IF EXISTS `project_view`;
CREATE VIEW `project_view` AS 
SELECT `p`.`project_id`, `p`.`title`, `p`.`amount`, `p`.`start_date`, `p`.`end_date`, 
YEAR(`p`.`end_date`) - YEAR(`p`.`start_date`) - (DATE_FORMAT(`p`.`end_date`, '%m%d') < DATE_FORMAT(`p`.`start_date`, '%m%d')) `duration`, 
`e`.`executive_id`, CONCAT(`e`.`last_name`, ' ', `e`.`first_name`) `executive_name`, COUNT(`w`.`researcher_id`) `researchers`
FROM `project` `p` 
NATURAL JOIN `executive` `e`
JOIN `WorksOn`  `w`
ON `p`.`project_id` = `w`.`project_id`
GROUP BY `p`.`project_id`;
