# Queries 3.1 - 3.8

## 3.1 

Τα αναλυτικά/σύνθετα ερωτήματα του 3.1 βρίσκονται στα project.php και program.php.

```sql
Το ερώτημα για τα προγράμματα 

SELECT `program_id`, `title`, `department`
FROM `program`
WHERE `program_id` = '$edit_id'

Το ερώτημα για τα έργα:

SELECT `project_id`,`title`,`amount`,DATE_FORMAT(`start_date`, '%d/%m/%Y') `start_date`,DATE_FORMAT(`end_date`, '%d/%m/%Y') `end_date`,`duration`,`organization`,`manager`,`executive_name`,`researchers`
FROM `project_view`
WHERE $filter
```

## 3.2

Τα ερωτήματα είναι παραμετροποιημένα και χρησιμοποιούνται στα 3.2.1.php και 3.2.2.php. 

```sql
Τα ερωτήματα για τα έργα ανά ερευνητή:

SELECT DISTINCT `researcher_id`, `full_name`, `organization`
FROM `projectresearcher_vw`

SELECT `project_id`, `title`
FROM `projectresearcher_vw`
WHERE `researcher_id` = $edit_id;

Το ερωτήμα για τις αξιολογήσεις:

SELECT DISTINCT `project_id`, `title`, `name`, `eval_name`,  DATE_FORMAT(`eval_date`, '%d/%m/%Y') `eval_date`, `rating`
FROM `eval_view` 
```

## 3.3

```sql
SELECT p.title, p.start_date, p.end_date FROM project p
INNER JOIN FieldProject f ON f.project_id = p.project_id
WHERE f.field_id = 1 and p.end_date > curdate();

SELECT DISTINCT concat(R.first_name,' ',R.last_name) AS full_name  FROM researcher R 
INNER JOIN WorksOn w ON w.researcher_id = R.researcher_id
INNER JOIN project p ON p.project_id = w.project_id
WHERE p.project_id IN (SELECT p.project_id FROM project p
INNER JOIN FieldProject f ON f.project_id = p.project_id
WHERE f.field_id = 1 and p.end_date > curdate());
```

## 3.4

```sql
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
```

## 3.5

```sql
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
```

## 3.6

```sql
SELECT r.researcher_id, r.first_name, r.last_name, COUNT(*) as count , DATE_FORMAT(FROM_DAYS(DATEDIFF(now(), r.birth_date)), '%Y')+0  AS age 
FROM researcher r 
INNER JOIN WorksOn w ON w.researcher_id = r.researcher_id
INNER JOIN project p ON p.project_id = w.project_id WHERE p.end_date > curdate()
GROUP BY r.researcher_id
HAVING age < 40
ORDER BY COUNT(*) DESC; 
```

## 3.7

```sql
SELECT * FROM (
SELECT e.executive_id AS id, concat(e.first_name,' ',e.last_name) AS full_name, o.name, p.amount
FROM executive e  
NATURAL JOIN project p 
NATURAL JOIN organization o
WHERE o.type = 'co'
ORDER BY p.amount DESC
LIMIT 5
) `t` 
GROUP BY `full_name`
ORDER BY amount DESC;
```

## 3.8

```sql
SELECT r.researcher_id, r.first_name, r.last_name, COUNT(*) `count`
FROM researcher r 
INNER JOIN WorksOn w ON r.researcher_id = w.researcher_id
inner join project p ON w.project_id = p.project_id 
WHERE w.project_id NOT IN (SELECT project_id FROM deliverable)  AND p.end_date > curdate()
GROUP BY r.researcher_id
HAVING COUNT(*) > 4
ORDER BY COUNT(*) DESC;
```
