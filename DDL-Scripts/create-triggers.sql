-- These triggers ensure that
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