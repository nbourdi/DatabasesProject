-- These 2 triggers ensure that
-- a projects duration is less than 4
-- years but more than 1 before commiting 
-- to an insert/update on project.

DELIMITER $$
CREATE TRIGGER proj_duration_check_insert BEFORE INSERT ON project
	FOR EACH ROW 
	BEGIN
    IF NOT(4 >= DATE_FORMAT(FROM_DAYS(DATEDIFF(new.end_date,new.start_date)), '%Y')+0 >= 1) THEN
    SIGNAL SQLSTATE '45000';
    END IF;
END$$
DELIMITER ;

DELIMITER $$
CREATE TRIGGER proj_duration_check_update BEFORE UPDATE ON project
	FOR EACH ROW 
	BEGIN
    IF NOT(4 >= DATE_FORMAT(FROM_DAYS(DATEDIFF(new.end_date,new.start_date)), '%Y')+0 >= 1) THEN
    SIGNAL SQLSTATE '45000';
    END IF;
END$$
DELIMITER ;


-- These 2 triggers ensure that an evaluator
-- inserted isn't part of the organization
-- that the project is managed by.

DROP TRIGGER IF EXISTS eval_insert;
DELIMITER $$
CREATE TRIGGER eval_insert BEFORE INSERT ON evaluates
	FOR EACH ROW 
	BEGIN
    IF (SELECT abbreviation  FROM researcher where researcher_id = new.researcher_id) =  (SELECT abbreviation FROM project where project_id = new.project_id) THEN
    SIGNAL SQLSTATE '45000';
    END IF;
END$$
DELIMITER ;

DROP TRIGGER IF EXISTS eval_update;
DELIMITER $$
CREATE TRIGGER eval_update BEFORE UPDATE ON evaluates
	FOR EACH ROW 
	BEGIN
    IF (SELECT abbreviation  FROM researcher where researcher_id = new.researcher_id) =  (SELECT abbreviation FROM project where project_id = new.project_id) THEN
    SIGNAL SQLSTATE '45000';
    END IF;
END$$
DELIMITER ;


-- These 2 triggers ensure that a researcher
-- that works on a project is part of the organization
-- that manages the project.

DROP TRIGGER IF EXISTS workson_insert;
DELIMITER $$
CREATE TRIGGER workson_insert BEFORE INSERT ON WorksOn
	FOR EACH ROW 
	BEGIN
    IF (SELECT abbreviation  FROM researcher where researcher_id = new.researcher_id) <> (SELECT abbreviation FROM project where project_id = new.project_id) THEN
    SIGNAL SQLSTATE '45000';
    END IF;
END$$
DELIMITER ;


DROP TRIGGER IF EXISTS workson_update;
DELIMITER $$
CREATE TRIGGER workson_update BEFORE UPDATE ON WorksOn
	FOR EACH ROW 
	BEGIN
    IF (SELECT abbreviation  FROM researcher where researcher_id = new.researcher_id) <>  (SELECT abbreviation FROM project where project_id = new.project_id) THEN
    SIGNAL SQLSTATE '45000';
    END IF;
END$$
DELIMITER ;