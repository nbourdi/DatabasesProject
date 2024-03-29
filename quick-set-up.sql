-- Creating the ELIDEK Database Schema 
-- Project Group 3


DROP SCHEMA IF EXISTS elidek;
CREATE SCHEMA elidek;
USE elidek;

-- ----------------------------------------
-- --------------- ENTITIES ---------------
-- ----------------------------------------


CREATE TABLE organization (
	abbreviation VARCHAR(15) NOT NULL,
    name VARCHAR(70) NOT NULL,
    type ENUM('uni','co','inst'),
    budget JSON,
    street VARCHAR(50),
    street_number INT UNSIGNED,
	postal_code INT(10),
    city VARCHAR(50) NOT NULL,
	PRIMARY KEY (abbreviation)
);


-- Table structure for table 'program'

CREATE TABLE program (
	program_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
	title VARCHAR(90) NOT NULL,
    department VARCHAR(90) NOT NULL,
	PRIMARY KEY (program_id)
);

-- Table structure for table 'executive'

CREATE TABLE executive ( 
	executive_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
	first_name VARCHAR(45) NOT NULL,
	last_name VARCHAR(45) NOT NULL,
	PRIMARY KEY (executive_id)
);

-- Table structure for table 'field'

CREATE TABLE field ( 
	field_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    field_name VARCHAR(70),
    PRIMARY KEY (field_id)
);

-- Table structure for table 'researcher'

CREATE TABLE researcher ( 
	researcher_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
	first_name VARCHAR(45) NOT NULL,
	last_name VARCHAR(45) NOT NULL,
	gender ENUM('male', 'female') ,
	birth_date DATE,	
    abbreviation VARCHAR(15) NOT NULL,  -- WORKSFOR
    since_date DATE,
    CONSTRAINT fk_worksfor_organization FOREIGN KEY (abbreviation)
		REFERENCES organization (abbreviation) ON DELETE CASCADE ON UPDATE CASCADE,
	PRIMARY KEY (researcher_id)
);

-- Table structure for table 'project'

CREATE TABLE project ( 
	project_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
	title VARCHAR(255) NOT NULL,
    amount FLOAT(9,2) ,              -- EXAMPLE: 108000.25 --
	summary TEXT DEFAULT NULL,
    start_date DATE NOT NULL,		-- FORMAT: YYYY-MM-DD --
    end_date DATE NOT NULL,    
    researcher_id INT UNSIGNED NOT NULL,   -- manager --
    abbreviation VARCHAR(15) NOT NULL,
    executive_id INT UNSIGNED NOT NULL,
    program_id INT UNSIGNED NOT NULL,
    CONSTRAINT check_amount CHECK (amount <= 1000000 AND amount >= 100000),
	PRIMARY KEY (project_id),
    -- FOREIGN KEY CONSTRAINTS --
    CONSTRAINT fk_project_manager FOREIGN KEY (researcher_id)
		REFERENCES researcher (researcher_id) ON DELETE RESTRICT ON UPDATE CASCADE,
	CONSTRAINT fk_project_organization FOREIGN KEY (abbreviation)
		REFERENCES organization (abbreviation) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT fk_project_executive FOREIGN KEY (executive_id)
		REFERENCES executive (executive_id) ON DELETE RESTRICT ON UPDATE CASCADE,
	CONSTRAINT fk_project_program FOREIGN KEY (program_id)
		REFERENCES program (program_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- Table structure for table 'deliverable' (WEAK entity set)

CREATE TABLE deliverable (
	deliverable_id VARCHAR(100) NOT NULL,
	summary TEXT DEFAULT NULL,
	project_id INT UNSIGNED NOT NULL,
    CONSTRAINT fk_project_deliverable FOREIGN KEY (project_id)
		REFERENCES project (project_id) ON DELETE CASCADE ON UPDATE CASCADE,   -- both cascade since it's a weak entity --
	PRIMARY KEY (deliverable_id, project_id)
);

-- Table structure for table 'phone' (multivalued attribute)

CREATE TABLE organization__phone ( 
	phone VARCHAR(20) NOT NULL,
	abbreviation VARCHAR(15) NOT NULL,
	PRIMARY KEY (abbreviation, phone),
	CONSTRAINT fk_organization_phone FOREIGN KEY (abbreviation) 
		REFERENCES organization (abbreviation) ON DELETE CASCADE ON UPDATE CASCADE
);



-- ----------------------------------------
-- ------- RELATIONSHIPS ------------------
-- ----------------------------------------


-- Table structure for 'FieldProject' 

CREATE TABLE FieldProject ( 
	project_id INT UNSIGNED NOT NULL REFERENCES project (project_id),
    field_id INT UNSIGNED NOT NULL REFERENCES field (field_id),
    PRIMARY KEY (project_id, field_id),
    CONSTRAINT fk_fieldproj_project FOREIGN KEY (project_id)
		REFERENCES project (project_id) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT fk_fieldproj_field FOREIGN KEY (field_id)
		REFERENCES field (field_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- Table structure for table 'WorksOn'  (researchers WorkOn rojects)

CREATE TABLE WorksOn ( 
	project_id INT UNSIGNED NOT NULL REFERENCES project (project_id),
    researcher_id INT UNSIGNED NOT NULL REFERENCES researcher (researcher_id),
    PRIMARY KEY (project_id, researcher_id),
    CONSTRAINT fk_workson_project FOREIGN KEY (project_id)
		REFERENCES project (project_id) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT fk_worksfon_researcher FOREIGN KEY (researcher_id)
		REFERENCES researcher (researcher_id) ON DELETE CASCADE ON UPDATE CASCADE
);


-- Table structure for table 'evaluates'

CREATE TABLE evaluates (
	project_id INT UNSIGNED NOT NULL UNIQUE,
    researcher_id INT UNSIGNED NOT NULL,
    rating ENUM('A', 'B') NOT NULL,      -- we assume it must have recieved an A or a B to have been funded 
    eval_date DATE NOT NULL,
    PRIMARY KEY (project_id, researcher_id),
	CONSTRAINT fk_evalutes_project FOREIGN KEY (project_id)
		REFERENCES project (project_id) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT fk_evaluates_researcher FOREIGN KEY (researcher_id)
		REFERENCES researcher (researcher_id) ON DELETE CASCADE ON UPDATE CASCADE
);


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

-- ----------------------------------------
-- Create View 2 for the ELIDEK database --
-- ----------------------------------------

DROP VIEW IF EXISTS `eval_view`;
CREATE VIEW `eval_view` AS 
SELECT `e`.`rating`, `e`.`eval_date`, `e`.`researcher_id`, CONCAT(`r`.`last_name`, ' ', `r`.`first_name`) AS eval_name, 
		`p`.`project_id`, `p`.`title`, `p`.`abbreviation`, `o`.`name`
FROM `evaluates` `e`
INNER JOIN `project` `p` ON `e`.`project_id` = `p`.`project_id`
INNER JOIN `researcher` `r` ON `r`.`researcher_id` = `e`.`researcher_id`
INNER JOIN `organization` `o` ON `o`.`abbreviation` = `p`.`abbreviation`;


-- ----------------------------------------
-- Create View 3: project for the ELIDEK database --
-- ----------------------------------------

DROP VIEW IF EXISTS `project_view`;

CREATE VIEW `project_view` AS 
SELECT `p`.`project_id`, `p`.`title`, `p`.`summary`, `p`.`amount`, `p`.`start_date`, `p`.`end_date`,`p`.`program_id`, 
YEAR(`p`.`end_date`) - YEAR(`p`.`start_date`) - (DATE_FORMAT(`p`.`end_date`, '%m%d') < DATE_FORMAT(`p`.`start_date`, '%m%d')) `duration`, `p`.`abbreviation`, `o`.`name` `organization`, `p`.`researcher_id` `manager_id`, CONCAT(`r`.`last_name`, ' ', `r`.`first_name`) `manager`, 
`e`.`executive_id`, CONCAT(`e`.`last_name`, ' ', `e`.`first_name`) `executive_name`, COUNT(`w`.`researcher_id`) `researchers`, GROUP_CONCAT(DISTINCT `field_id`) `field`
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


-- --------------------
-- --- TRIGGERS -------
-- --------------------

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


-- ----------
-- INDEXES --
-- ----------

-- 3.7
CREATE INDEX idx_amount ON project (`amount`);

-- 3.3 & 3.6 & 3.8 & filters 
CREATE INDEX idx_end_date ON project (`end_date`);

CREATE INDEX idx_start_date ON project (`start_date`);

-- 3.6
CREATE INDEX idx_birth_date ON researcher (`birth_date`);


-- --------------------
-- Stored Procedures --
-- --------------------



-- Insertion of mock data

--
-- Delete data 
--

DELETE FROM project;
DELETE FROM organization;
DELETE FROM researcher;
DELETE FROM program;
DELETE FROM executive;
DELETE FROM field;
DELETE FROM organization__phone;
DELETE FROM deliverable;
DELETE FROM evaluates;
DELETE FROM WorksOn;
DELETE FROM FieldProject;

-- ---------------------
-- Insert Researchers --
-- ---------------------

-- ORGANIZATIONS

INSERT INTO organization (abbreviation, name, type, budget, street, street_number, postal_code, city) VALUES 

-- unis:12

('UOI', 'Πανεπιστήμιο Ιωαννίνων', 'uni', '{"ministry":"104000"}', 'Λεωφόρος Σταύρου Νιάρχου', '60', '45500','Ιωάννινα'),
('UOA', 'Εθνικό και Καποδιστριακό Πανεπιστήμιο Αθηνών', 'uni','{"ministry":"150000"}','Υμηττού', '5', '15772', 'Ζωγράφου'),
('UOP', 'Πανεπιστήμιο Πατρών', 'uni','{"ministry":"107850"}', 'Πανεπιστημιούπολη', NULL , '26504', 'Πάτρα'),
('UOWA', 'Πανεπιστήμιο Δυτικής Αττικής', 'uni','{"ministry":"100000"}', 'Αγίου Σπυρίδωνος', '28', '12243', 'Αθήνα'),
('AUTH', 'Αριστοτέλειο Πανεπιστήμιο Θεσσαλονίκης', 'uni', '{"ministry":"200500"}','Αγίου Δημητρίου', '20', '54124', 'Θεσσαλονίκη'),
('NTUA', 'Εθνικό Μετσόβιο Πολυτεχνείο', 'uni', '{"ministry":"156000"}','Ηρώων Πολυτεχνείου', '5', '15772', 'Ζωγράφου'),
('IONIO', 'Ιόνιο Πανεπιστήμιο', 'uni', '{"ministry":"156000"}','Ιωάννου Θεοτοκή', '72', '49100', 'Κέρκυρα'),
('AUOA', 'Γεωπονικό Πανεπιστήμιο Αθηνών', 'uni', '{"ministry":"90000"}','Ιερά Οδός', '75', '11855', 'Αθήνα'),
('DUOT', 'Δημοκρίτειο Πανεπιστήμιο Θράκης', 'uni', '{"ministry":"90000"}','Πανεπιστημιούπολη', NULL, '69100', 'Κομοτηνή'),
('UNIPI', 'Πανεπιστήμιο Πειραιώς', 'uni', '{"ministry":"90500"}','Καραόλη', '60', '18534', 'Πειραιάς'),
('AUEB', 'Οικονομικό Πανεπιστήμιο Αθηνών', 'uni', '{"ministry":"90500"}','28ης Οκτωβρίου', '76', '10434', 'Αθήνα'),
('UOC', 'Πανεπιστήμιο Κρήτης', 'uni', '{"ministry":"140000"}','Καλοκαιρινού', '13', '70013', 'Ηράκλειο'),

-- institutes:7

('NOA', 'Εθνικό Αστεροσκοπείο Αθηνών', 'inst', '{"ministry":"104000", "private":"150000"}', 'Λόφος Νύμφων', NULL, '11810', 'Αθήνα'),
('EKETA', 'Εθνικό Κέντρο Έρευνας και Τεχνολογικής Ανάπτυξης', 'inst', '{"ministry":"104000", "private":"150000"}', 'Αιγιαλείας', '52', '15125', 'Αθήνα'),
('FORTH', 'Ίδρυμα Τεχνολογίας και Έρευνας', 'inst', '{"ministry":"104000", "private":"150000"}', 'Πλαστήρα', '100', '70013', 'Ηράκλειο'),
('NHRF', 'Εθνικό Ίδρυμα Ερευνών', 'inst', '{"ministry":"104000", "private":"150000"}', 'Κωνσταντίνου', '48', '11635', 'Αθήνα'),
('NCSR', 'Δημόκριτος', 'inst', '{"ministry":"104500", "private":"100000"}', 'Δημόκριτος', '27', '15341', 'Αθήνα'),
('EKKE', 'Εθνικό κέντρο κοινωνικών ερευνών', 'inst', '{"ministry":"85000", "private":"90000"}', 'Κρατίνου', '9', '10552', 'Αθήνα'),
('KETEP', 'Κέντρο Εφαρμογών των Τεχνολογιών Επικοινωνίας και Πληροφορίας', 'inst', '{"ministry":"95000", "private":"70000"}', 'Αγίου Δημητρίου', '89', '15124', 'Μαρούσι'),

-- companies:20 
('PRGAS', 'ΠΡΟΜΗΘΕΑΣ GAS Α.Ε.', 'co', '{"capital":"85000"}', 'Δραγατσανίου', '41', '32005', 'Αθήνα'), 
('MEDATH','ΙΑΤΡΙΚΟ ΑΘΗΝΩΝ Ε.Α.Ε.', 'co', '{"capital":"100000"}', 'Καραπαναγιώτου', '158', '50002','Μαρούσι'), 
('FARMANET','ΦΑΡΜΑΤΕΝ Α.Β.Ε.Ε.', 'co', '{"capital":"75000"}', 'Πουλίου', '126', '71414', 'Παλλήνη'), 
('SEKA','ΣΕΚΑ Α.Ε.', 'co', '{"capital":"200000"}', 'Ξεναγόρα', '132', '38300','Πειραιάς'), 
('SEP','ΣΕΠ Α.Ε.', 'co', '{"capital":"50000"}', 'Ναρσή', '65', '66031','Πειραιάς'), 
('VIANEX','ΒΙΑΝΕΞ Α.Ε.', 'co', '{"capital":"600000"}', 'Αραχώβης', '152', '16121','Γέρακας'), 
('ALOUMIL','ΑΛΟΥΜΥΛ Α.Ε.', 'co', '{"capital":"72000"}', 'Φρεαρίων', '23', '43061','Κιλκίς'),
('DESFA','ΔΕΣΦΑ Α.Ε.', 'co', '{"capital":"63000"}', 'Πέλοπος', '130', '44200','Χαλάνδρι'), 
('TELEPR','TELEPERFORMANCE HELLAS', 'co', '{"capital":"40000"}', 'Λέκκα', '165', '35007','Μοσχάτο'),
('SOYAGR','SOYA HELLAS', 'co', '{"capital":"30000"}', 'Πανδρόσου', '191', '72055','Αθήνα'),
('PLASTKR','ΠΛΑΣΤΙΚΑ ΚΡΗΤΗΣ Α.Β.Ε.Ε.', 'co', '{"capital":"130000"}', 'Μπενάκη Παναγή', '171', '61003','Ηράκλειο'), 
('MUHALIS','ΜΟΥΧΑΛΗΣ Α.Ε.Ε.', 'co', '{"capital":"150000"}', 'Τούσα', '43', '62049','Κορωπί'), 
('SOVEL','SOVEL Α.Ε.', 'co', '{"capital":"190000"}', 'Σαχίνη', '12', '34600','Αλμυρός'),  
('NITSIAK','ΝΙΤΣΙΑΚΟΣ Α.Β.Ε.Ε.', 'co', '{"capital":"200000"}', 'Αινείου', '41', '68100','Ιωάννινα'), 
('SFAK','ΣΦΑΚΙΑΝΑΚΗΣ Α.Ε.Β.Ε.', 'co', '{"capital":"330000"}', 'Τιμαίου', '139', '60065','Αθήνα'), 
('SARANT','ΣΑΡΑΝΤΗΣ Α.Β.Ε.Ε.', 'co', '{"capital":"91000"}', 'Δωδεκανήσου', '191', '54625','Μαρούσι'), 
('PRODEA','ΠΡΟΝΤΕΑ Α.E.', 'co', '{"capital":"45000"}', 'Αρτεμισίου', '84', '23100','Αθήνα'), 
('PENTE','ΠΕΝΤΕ Α.Ε.', 'co', '{"capital":"73000"}', 'Αγ.Δημητρίου των Όπλων', '10', '24001','Κολωνός'), 
('ELKAL','ΕΛΛΗΝΙΚΑ ΚΑΛΩΔΙΑ Α.Ε.', 'co', '{"capital":"700000"}', 'Ευμένους', '88', '11472','Μαρούσι'), 
('PAPASTR','ΠΑΠΑΣΤΡΑΤΟΣ', 'co', '{"capital":"400000"}', 'Ναύαρχου Βούλγαρη', '33', '54632','Ασπρόπυργος'); 


INSERT INTO `organization__phone` (`phone`, `abbreviation`) VALUES
('2417518131', 'ALOUMIL'),
('2230489228', 'AUEB'),
('2234327131', 'AUEB'),
('2449464777', 'AUEB'),
('2647048819', 'AUEB'),
('2430886876', 'AUOA'),
('2555856235', 'AUOA'),
('2141667924', 'AUTH'),
('2486865704', 'AUTH'),
('2247742537', 'DESFA'),
('2325317152', 'DESFA'),
('2813708946', 'DESFA'),
('2185458950', 'DUOT'),
('2951343328', 'DUOT'),
('2243624198', 'EKETA'),
('2299837683', 'EKKE'),
('2504298478', 'EKKE'),
('2806142049', 'EKKE'),
('2807622997', 'EKKE'),
('2578044564', 'ELKAL'),
('2627507795', 'FARMANET'),
('2727547215', 'FARMANET'),
('2755212720', 'FORTH'),
('2473971141', 'IONIO'),
('2531050077', 'IONIO'),
('2727093091', 'IONIO'),
('2461614128', 'MEDATH'),
('2504928451', 'MEDATH'),
('2776705504', 'MEDATH'),
('2977954161', 'MEDATH'),
('2423229105', 'MUHALIS'),
('2439113697', 'MUHALIS'),
('2590779804', 'MUHALIS'),
('2225261826', 'NCSR'),
('2724335037', 'NCSR'),
('2798804464', 'NCSR'),
('2953304048', 'NCSR'),
('2593761859', 'NHRF'),
('2696604941', 'NHRF'),
('2701739161', 'NHRF'),
('2907347948', 'NHRF'),
('2418881015', 'NITSIAK'),
('2689295092', 'NITSIAK'),
('2989187621', 'NITSIAK'),
('2478912627', 'NOA'),
('2032244063', 'NTUA'),
('2196651610', 'NTUA'),
('2326677892', 'NTUA'),
('2426167230', 'NTUA'),
('2121162964', 'PAPASTR'),
('2273076937', 'PAPASTR'),
('2327313159', 'PAPASTR'),
('2383445239', 'PENTE'),
('2979954172', 'PLASTKR'),
('2339641397', 'PRGAS'),
('2021796636', 'PRODEA'),
('2404220764', 'PRODEA'),
('2798236054', 'PRODEA'),
('2984641310', 'PRODEA'),
('2688568208', 'SARANT'),
('2857345805', 'SARANT'),
('2023506376', 'SEKA'),
('2221024433', 'SEKA'),
('2412498874', 'SEKA'),
('2533084781', 'SEKA'),
('2322518954', 'SEP'),
('2397158684', 'SEP'),
('2554424925', 'SEP'),
('2113803857', 'SFAK'),
('2421119025', 'SFAK'),
('2543889116', 'SOVEL'),
('2485834956', 'SOYAGR'),
('2623500454', 'SOYAGR'),
('2032917214', 'TELEPR'),
('2088714147', 'TELEPR'),
('2145795486', 'UNIPI'),
('2344819398', 'UNIPI'),
('2625531641', 'UNIPI'),
('2574764004', 'UOA'),
('2690271779', 'UOA'),
('2803004714', 'UOA'),
('2290731589', 'UOC'),
('2446438352', 'UOI'),
('2351024438', 'UOP'),
('2528802928', 'UOP'),
('2621190715', 'UOP'),
('2250414721', 'UOWA'),
('2400829349', 'UOWA'),
('2588689698', 'UOWA'),
('2845505897', 'UOWA'),
('2272785049', 'VIANEX'),
('2575551467', 'VIANEX'),
('2637270874', 'VIANEX'),
('2868324106', 'VIANEX');
-- RESEARCHERS 

-- ----

INSERT INTO `researcher` (`researcher_id`, `first_name`, `last_name`, `gender`, `birth_date`, `abbreviation`, `since_date`) VALUES
(1, 'Μάξιμος', 'Λούπης', 'male', '1955-06-01', 'UOP', '2005-02-25'),
(2, 'Αθανασία', 'Ιωάννου', 'female', '1955-07-22', 'FORTH', '2000-11-27'),
(3, 'Πουλουδιά', 'Δελή', 'female', '1955-12-20', 'UOA', '2013-06-10'),
(4, 'Λεωνίδας', 'Βούλγαρης', 'male', '1956-05-08', 'NOA', '2011-03-23'),
(5, 'Ζουμπουλιά', 'Κεχαγιά', 'female', '1956-12-13', 'NOA', '2001-07-21'),
(6, 'Σταμάτης', 'Γιωτόπουλος', 'male', '1957-02-16', 'UOA', '1997-01-27'),
(7, 'Αλύσσα', 'Θεοδοσίου', 'female', '1957-06-17', 'UOWA', '2003-07-03'),
(8, 'Ιάκωβος', 'Μητρόπουλος', 'male', '1957-06-23', 'EKETA', '2011-06-02'),
(9, 'Ιωάννης', 'Ταμτάκος', 'male', '1957-07-02', 'AUTH', '1995-03-21'),
(10, 'Διαλεχτή', 'Οικονόμου', 'female', '1988-06-25', 'NTUA', '2001-08-06'),
(11, 'Αχαιός', 'Βούλτεψης', 'male', '1958-07-30', 'AUTH', '2006-06-01'),
(12, 'Ανάργυρος', 'Μπότσαρης', 'male', '1958-08-02', 'FORTH', '2012-10-05'),
(13, 'Σπυριδούλα', 'Αναγνώστου', 'female', '1958-09-17', 'FORTH', '1994-05-20'),
(14, 'Θωμαή', 'Παπαντωνίου', 'female', '1958-11-08', 'NHRF', '1990-09-14'),
(15, 'Λυσίας', 'Δασκαλοπούλου', 'male', '1958-11-20', 'IONIO', '1991-04-19'),
(16, 'Τσαμπίκα', 'Μπακογιάννη', 'female', '1959-01-27', 'UOP', '2005-06-21'),
(17, 'Πουλουδιά', 'Ιωάννου', 'female', '1959-04-12', 'UOP', '2003-05-31'),
(18, 'Χιονία', 'Παπανδρέου', 'female', '1959-08-02', 'AUOA', '1986-04-29'),
(19, 'Γεωργία', 'Σακελλαρίου', 'female', '1959-08-16', 'DUOT', '2011-03-08'),
(20, 'Βιθυνός', 'Αποστόλου', 'male', '1959-11-05', 'NTUA', '2012-11-05'),
(21, 'Σία', 'Παπάζογλου', 'female', '1959-12-05', 'AUOA', '1981-09-21'),
(22, 'Λουκάς', 'Ζαχαρίου', 'male', '1960-01-21', 'NCSR', '1993-09-05'),
(23, 'Μένανδρος', 'Αντωνόπουλος', 'male', '1960-06-05', 'UOI', '2008-07-04'),
(24, 'Κίμων', 'Φανουράκης', 'male', '1960-06-10', 'UOA', '2012-06-04'),
(25, 'Αχαιός', 'Γκόφας', 'male', '1960-07-07', 'UNIPI', '1988-04-05'),
(26, 'Κρέων', 'Αναγνωστόπουλος', 'male', '1961-01-06', 'UOA', '1991-08-26'),
(27, 'Ζουμπουλιά', 'Σπανού', 'female', '1961-06-07', 'UOA', '2011-05-02'),
(28, 'Ανάργυρος', 'Αξιώτης', 'male', '1961-06-20', 'NTUA', '2000-06-28'),
(29, 'Έφη', 'Αγγελοπούλου', 'female', '1961-08-09', 'UNIPI', '1987-02-05'),
(30, 'Άλκηστη', 'Γερμανού', 'female', '1962-03-08', 'AUTH', '1985-07-23'),
(31, 'Κλεομένης', 'Παπακωνσταντίνου', 'male', '1962-06-05', 'DUOT', '1983-02-11'),
(32, 'Διαλεχτή', 'Παπανδρέου', 'female', '1962-09-18', 'AUEB', '2007-11-13'),
(33, 'Αθανασία', 'Δημητρίου', 'female', '1963-02-12', 'UOP', '2011-05-13'),
(34, 'Διόδωρος', 'Βάμβας', 'male', '1963-04-15', 'EKKE', '1987-05-29'),
(35, 'Δήμητρα', 'Σακελλαρίου', 'female', '1963-04-20', 'DUOT', '2012-12-31'),
(36, 'Θωμάς', 'Φραγκούδης', 'male', '1963-06-01', 'UOA', '1995-01-21'),
(37, 'Σταματίνα', 'Βασιλείου', 'female', '1963-08-16', 'UOA', '1984-01-21'),
(38, 'Θεοχάρης', 'Μπότσαρης', 'male', '1964-01-08', 'AUTH', '2012-09-13'),
(39, 'Θεόδοτος', 'Αναγνωστόπουλος', 'male', '1964-06-06', 'UOC', '2004-09-12'),
(40, 'Μενέλαος', 'Γραμματικόπουλος', 'male', '1964-07-31', 'UOA', '2000-12-15'),
(41, 'Κλεισθένης', 'Γερμανός', 'male', '1964-08-13', 'UOC', '2005-12-20'),
(42, 'Ανουτσιάτα', 'Ιορδανίδου', 'female', '1964-11-12', 'AUEB', '2012-07-14'),
(43, 'Καλυψώ', 'Παπάζογλου', 'female', '1984-11-23', 'NTUA', '2000-08-09'),
(44, 'Τσιτσέκα', 'Παπαθανασίου', 'female', '1965-05-05', 'UNIPI', '2010-02-07'),
(45, 'Βανέσα', 'Ιωάννου', 'female', '1965-12-07', 'PRGAS', '2004-10-15'),
(46, 'Υρώ', 'Γεωργίου', 'female', '1966-06-11', 'MEDATH', '2007-07-25'),
(47, 'Όλγα', 'Οικονόμου', 'female', '1966-09-08', 'FARMANET', '2008-07-24'),
(48, 'Αθανασία', 'Παπαθανασίου', 'female', '1966-12-23', 'NITSIAK', '2005-08-18'),
(49, 'Ηρώ', 'Παπαφιλίππου', 'female', '1967-04-24', 'TELEPR', '1988-03-08'),
(50, 'Μανουήλ', 'Παυλόπουλος', 'male', '1967-07-03', 'PLASTKR', '1990-10-14'),
(51, 'Ικάριος', 'Αυγερινός', 'male', '1967-10-10', 'MUHALIS', '2001-06-09'),
(52, 'Κράτης', 'Παπαθανασίου', 'male', '1967-12-23', 'SOYAGR', '1993-03-26'),
(53, 'Άλκηστη', 'Καρέλια', 'female', '1968-02-13', 'PENTE', '2000-02-06'),
(54, 'Μάξιμος', 'Παναγούλης', 'male', '1968-03-22', 'SFAK', '2006-01-26'),
(55, 'Λήδα', 'Παπαφιλίππου', 'female', '1968-07-15', 'SARANT', '1989-07-29'),
(56, 'Σωτήριος', 'Παυλόπουλος', 'male', '1968-07-21', 'PAPASTR', '1992-08-06'),
(57, 'Αθανάσιος', 'Ανδρεαδάκης', 'male', '1969-01-27', 'ELKAL', '2005-11-05'),
(58, 'Ικάριος', 'Τσάτσος', 'male', '1969-04-24', 'PRODEA', '2010-05-25'),
(59, 'Διογένης', 'Θεοτόκης', 'male', '1969-07-03', 'SOVEL', '1994-10-31'),
(60, 'Ανουτσιάτα', 'Αλεξάνδρου', 'female', '1969-08-24', 'VIANEX', '2003-04-07'),
(61, 'Ηλέκτρα', 'Αγγελοπούλου', 'female', '1969-10-30', 'DESFA', '1992-06-23'),
(62, 'Βάιος', 'Γαλάνης', 'male', '1969-12-07', 'SEP', '2011-09-11'),
(63, 'Ευαγγελία', 'Παπαντωνίου', 'female', '1970-03-23', 'SEKA', '1993-02-26'),
(64, 'Θωμαή', 'Παπανικολάου', 'female', '1970-04-21', 'UOP', '2012-12-16'),
(65, 'Διόδοτος', 'Κοσμόπουλος', 'male', '1970-08-10', 'MEDATH', '1998-07-28'),
(66, 'Κυπάρισσος', 'Κεχαγιάς', 'male', '1970-11-17', 'NCSR', '2010-12-21'),
(67, 'Σαμπρίνα', 'Σακελλαρίου', 'female', '1971-03-14', 'PRGAS', '1997-05-09'),
(68, 'Ερμής', 'Φανουράκης', 'male', '1971-10-24', 'MEDATH', '2009-02-01'),
(69, 'Ρούλα', 'Γαλάνη', 'female', '1971-12-21', 'AUOA', '1992-07-24'),
(70, 'Κίμων', 'Δουρέντης', 'male', '1972-02-16', 'NOA', '2010-10-27'),
(71, 'Λυσίας', 'Σαμαράς', 'male', '1972-03-21', 'MUHALIS', '1994-10-09'),
(72, 'Μιλτιάδης', 'Ταμτάκος', 'male', '1972-10-05', 'EKETA', '1994-01-10'),
(73, 'Ορέστης', 'Μπότσαρης', 'male', '1972-10-20', 'UOC', '2013-04-09'),
(74, 'Φοίβος', 'Κομνηνός', 'male', '1972-11-10', 'UOC', '2004-12-09'),
(75, 'Λυκούργος', 'Κατράκης', 'male', '1972-11-23', 'DESFA', '2013-07-30'),
(76, 'Χιονία', 'Ζωγράφου', 'female', '1973-03-23', 'ELKAL', '1995-11-07'),
(77, 'Αργυρώ', 'Αντωνοπούλου', 'female', '1973-07-08', 'KETEP', '2008-11-26'),
(78, 'Οφηλία', 'Παπαθανασίου', 'female', '1973-07-25', 'NCSR', '2000-01-09'),
(79, 'Δηλία', 'Θάνου', 'female', '1973-11-15', 'SEP', '2000-11-08'),
(80, 'Θεοχάρης', 'Βιλαέτης', 'male', '1974-02-24', 'SOVEL', '2009-10-05'),
(81, 'Ήρα', 'Ιωάννου', 'female', '1974-05-09', 'DUOT', '2011-01-17'),
(82, 'Λαέρτης', 'Αντωνόπουλος', 'male', '1974-05-31', 'MUHALIS', '2011-05-27'),
(83, 'Μπία', 'Ιορδανίδου', 'female', '1974-09-02', 'NHRF', '2009-06-28'),
(84, 'Δημήτριος', 'Ζάππας', 'male', '1974-10-18', 'FARMANET', '1998-10-25'),
(85, 'Έφη', 'Παπάζογλου', 'female', '1975-01-14', 'KETEP', '2010-01-04'),
(86, 'Αθανασία', 'Κωνσταντίνου', 'female', '1975-11-05', 'UOP', '2000-06-21'),
(87, 'Καλυψώ', 'Παπανικολάου', 'female', '1975-12-17', 'PENTE', '2013-01-29'),
(88, 'Μενέλαος', 'Μουρδουκούτας', 'male', '1976-01-18', 'PRGAS', '2012-05-29'),
(89, 'Υακίνθη', 'Ιορδανίδου', 'female', '1976-04-05', 'PRGAS', '2008-06-08'),
(90, 'Δήμητρα', 'Μπενιζέλου', 'female', '1976-04-28', 'TELEPR', '2008-08-23'),
(91, 'Φοίβος', 'Σκυλακάκης', 'male', '1976-08-02', 'PRODEA', '2003-08-05'),
(92, 'Δημόφιλος', 'Διδασκάλου', 'male', '1976-10-01', 'SEP', '2013-01-17'),
(93, 'Ήρα', 'Αθανασίου', 'female', '1976-10-31', 'NTUA', '2004-06-13'),
(94, 'Μαρία', 'Σπανού', 'female', '1976-11-17', 'DESFA', '2003-11-13'),
(95, 'Ναζλή', 'Διδασκάλου', 'female', '1977-01-15', 'UOWA', '2009-01-28'),
(96, 'Μενέλαος', 'Μώραλης', 'male', '1977-05-30', 'PLASTKR', '2001-12-21'),
(97, 'Μιλτιάδης', 'Ελευθερόπουλος', 'male', '1977-07-07', 'SFAK', '2001-12-19'),
(98, 'Ευστάθιος', 'Καραμανλής', 'male', '1978-04-16', 'PENTE', '2006-07-21'),
(99, 'Κύριλλος', 'Ανδριανόπουλος', 'male', '1978-06-22', 'SEKA', '2010-10-12'),
(100, 'Κίμων', 'Δημητρακόπουλος', 'male', '1978-07-19', 'NTUA', '2003-09-01'),
(101, 'Ευκλείδης', 'Ρόκας', 'male', '1978-07-25', 'EKETA', '2003-04-11'),
(102, 'Φαίδρα', 'Παπαντωνίου', 'female', '1978-11-24', 'SOVEL', '2006-12-12'),
(103, 'Έφη', 'Παπαθανασίου', 'female', '1979-03-12', 'TELEPR', '2009-11-14'),
(104, 'Σταμάτης', 'Σπυρόπουλος', 'male', '1979-03-27', 'PAPASTR', '2013-09-04'),
(105, 'Βιθυνός', 'Γιωτόπουλος', 'male', '1979-03-28', 'FARMANET', '2009-02-18'),
(106, 'Θεαγένης', 'Τσαγανέας', 'male', '1979-04-03', 'NTUA', '2005-06-03'),
(107, 'Αχιλλέας', 'Παχής', 'male', '1979-05-07', 'MUHALIS', '2000-07-08'),
(108, 'Καρολίνα', 'Γερμανού', 'female', '1979-08-20', 'IONIO', '2002-02-13'),
(109, 'Δημόφιλος', 'Κουρμούλης', 'male', '1979-10-15', 'SEP', '2008-09-06'),
(110, 'Αχιλλέας', 'Κακριδής', 'male', '1980-01-21', 'UNIPI', '2007-10-01'),
(111, 'Γεράσιμος', 'Μανωλάς', 'male', '1980-03-21', 'SOYAGR', '2012-05-07'),
(112, 'Ηλέκτρα', 'Ανδρέου', 'female', '1980-05-12', 'EKKE', '2009-09-14'),
(113, 'Ευσταθία', 'Νικολάου', 'female', '1980-08-26', 'AUTH', '2011-02-12'),
(114, 'Αθανασία', 'Αναγνώστου', 'female', '1981-07-18', 'UOP', '2011-12-11'),
(115, 'Διαλεχτή', 'Διδασκάλου', 'female', '1982-04-23', 'NITSIAK', '2011-06-28'),
(116, 'Καρολίνα', 'Σακελλαρίου', 'female', '1982-04-26', 'PRGAS', '2006-10-08'),
(117, 'Κύριλλος', 'Λόντος', 'male', '1982-05-03', 'PENTE', '2009-02-27'),
(118, 'Αντώνιος', 'Γραμματικόπουλος', 'male', '1982-05-07', 'MUHALIS', '2011-01-15'),
(119, 'Διονυσία', 'Αντωνοπούλου', 'female', '1982-07-10', 'SOYAGR', '2013-04-23'),
(120, 'Σούλα', 'Οικονόμου', 'female', '1982-09-18', 'DESFA', '2007-02-05'),
(121, 'Ανδρέας', 'Κανακάρης', 'male', '1982-10-11', 'MUHALIS', '2004-07-16'),
(122, 'Μένανδρος', 'Μουρδουκούτας', 'male', '1982-12-06', 'SARANT', '2010-03-18'),
(123, 'Σία', 'Δημητρίου', 'female', '1983-01-05', 'ELKAL', '2011-03-02'),
(124, 'Ειρήνη', 'Βασιλείου', 'female', '1983-01-24', 'SOVEL', '2010-09-17'),
(125, 'Αρχίδαμος', 'Μήτζου', 'male', '1983-01-26', 'NITSIAK', '2005-08-10'),
(126, 'Θωμάς', 'Τσουκαλάς', 'male', '1983-02-03', 'PAPASTR', '2004-03-14'),
(127, 'Τσαμπίκα', 'Αγγελίδου', 'female', '1983-02-19', 'UNIPI', '2012-05-11'),
(128, 'Διόδοτος', 'Τζέτζης', 'male', '1983-07-08', 'NHRF', '2012-03-10'),
(129, 'Θεοχάρης', 'Παπανικολάου', 'male', '1983-09-07', 'ELKAL', '2009-04-27'),
(130, 'Βαρβάρα', 'Παπάζογλου', 'female', '1983-12-12', 'SOVEL', '2006-06-14'),
(131, 'Θωμάς', 'Κουντουριώτης', 'male', '1984-07-19', 'UOC', '2010-09-02'),
(132, 'Ναζλή', 'Παπαντωνίου', 'female', '1984-08-11', 'ELKAL', '2008-05-21'),
(133, 'Λουκία', 'Διδασκάλου', 'female', '1985-04-13', 'SOYAGR', '2005-08-09'),
(134, 'Ηλέκτρα', 'Αγγελίδου', 'female', '1985-07-17', 'PLASTKR', '2006-07-21'),
(135, 'Ζουμπουλιά', 'Νικολάου', 'female', '1985-09-17', 'NHRF', '2010-12-13'),
(136, 'Υακίνθη', 'Αθανασίου', 'female', '1985-09-24', 'EKKE', '2011-04-04'),
(137, 'Ναυσικά', 'Οικονόμου', 'female', '1986-01-01', 'FARMANET', '2009-01-08'),
(138, 'Λυκούργος', 'Αποστολίδης', 'male', '1986-04-17', 'SARANT', '2006-05-03'),
(139, 'Υρώ', 'Δημητρίου', 'female', '1986-08-06', 'SEP', '2009-01-09'),
(140, 'Κική', 'Μπακογιάννη', 'female', '1986-10-17', 'MUHALIS', '2011-09-14'),
(141, 'Θωμάς', 'Ραγκαβής', 'male', '1986-11-04', 'KETEP', '2007-08-10'),
(142, 'Χαράλαμπος', 'Ανδρεάδης', 'male', '1987-02-09', 'KETEP', '2007-05-05'),
(143, 'Ωραιοζήλη', 'Αντωνοπούλου', 'female', '1987-02-24', 'PAPASTR', '2008-11-16'),
(144, 'Κασσάνδρα', 'Καρέλια', 'female', '1987-11-24', 'NOA', '2007-12-15'),
(145, 'Διόδωρος', 'Καλομοίρης', 'male', '1988-01-20', 'DESFA', '2008-02-19'),
(146, 'Μιλτιάδης', 'Αναγνωστόπουλος', 'male', '1988-03-13', 'FARMANET', '2011-10-25'),
(147, 'Διομήδης', 'Βλαβιανός', 'male', '1988-03-14', 'ALOUMIL', '2010-11-01'),
(148, 'Αθανασία', 'Παπανικολάου', 'female', '1988-08-05', 'PENTE', '2013-09-25'),
(149, 'Φοίβη', 'Βιτάλη', 'female', '1989-01-10', 'SEP', '2012-05-02'),
(150, 'Τσαμπίκα', 'Θάνου', 'female', '1989-11-19', 'EKETA', '2006-01-23'),
(151, 'Λήδα', 'Ζωγράφου', 'female', '1990-02-12', 'NTUA', '2007-02-15'),
(152, 'Λυκούργος', 'Θεοδοσίου', 'male', '1990-10-07', 'DUOT', '2012-06-09'),
(153, 'Διονυσία', 'Μπακογιάννη', 'female', '1990-11-12', 'SEKA', '2007-08-01'),
(154, 'Αθανάσιος', 'Νάκος', 'male', '1991-01-27', 'KETEP', '2005-01-02'),
(155, 'Βανέσα', 'Αναγνώστου', 'female', '1991-10-13', 'MUHALIS', '2006-09-10'),
(156, 'Τσιτσέκα', 'Κωνσταντίνου', 'female', '1992-01-30', 'EKKE', '2013-06-10'),
(157, 'Ορέστης', 'Μητσοτάκης', 'male', '1992-07-20', 'EKETA', '2013-11-20'),
(158, 'Ανουτσιάτα', 'Παπαστεφάνου', 'female', '1992-08-20', 'PAPASTR', '2005-04-14'),
(159, 'Καλλίνικος', 'Λαμέρας', 'male', '1992-09-02', 'AUEB', '2008-01-02'),
(160, 'Κλέων', 'Στεφανής', 'male', '1992-11-09', 'UOC', '2009-10-01'),
(161, 'Σπυριδούλα', 'Αγγελοπούλου', 'female', '1992-11-17', 'NHRF', '2010-04-29'),
(162, 'Λουκάς', 'Σίδερης', 'male', '1993-02-03', 'PENTE', '2007-12-16'),
(163, 'Αλίκη', 'Αντωνοπούλου', 'female', '1994-01-10', 'NTUA', '2013-03-23'),
(164, 'Ευκλείδης', 'Κουταλιανός', 'male', '1994-07-06', 'PENTE', '2009-01-02'),
(165, 'Γεωργία', 'Καρέλια', 'female', '1995-02-12', 'NITSIAK', '2009-10-08'),
(166, 'Σωτήριος', 'Τσάτσος', 'male', '1995-06-02', 'ELKAL', '2007-05-31'),
(167, 'Μένανδρος', 'Παπαντωνίου', 'male', '1995-07-09', 'KETEP', '2012-03-03'),
(168, 'Βάιος', 'Κεδίκογλου', 'male', '1995-07-29', 'IONIO', '2005-05-17'),
(169, 'Σωτήριος', 'Αργυράκος', 'male', '1996-07-22', 'VIANEX', '2013-08-07'),
(170, 'Ερμελίντα', 'Ιωάννου', 'female', '1996-07-24', 'NHRF', '2009-03-21'),
(171, 'Θεαγένης', 'Κοκκινάκης', 'male', '1996-09-09', 'NTUA', '2009-09-16'),
(172, 'Απόστολος', 'Λαμπάκης', 'male', '1997-08-02', 'NTUA', '2006-06-22'),
(173, 'Κίμων', 'Νάκος', 'male', '1997-08-05', 'UOI', '2007-08-27'),
(174, 'Δηλία', 'Παπαστεφάνου', 'female', '1998-02-27', 'PLASTKR', '2013-11-04'),
(175, 'Στυλιανός', 'Αθανασίου', 'male', '1998-04-10', 'UOP', '2013-01-05'),
(176, 'Γλαύκος', 'Καλλιγάς', 'male', '1998-05-24', 'FORTH', '2009-02-17'),
(177, 'Κασσάνδρα', 'Παπαφιλίππου', 'female', '1998-09-06', 'UOA', '2011-01-08'),
(178, 'Θωμαή', 'Αναγνώστου', 'female', '1998-11-25', 'MUHALIS', '2013-04-16'),
(179, 'Θεαγένης', 'Γκόφας', 'male', '1998-12-04', 'KETEP', '2009-07-26'),
(180, 'Κική', 'Βιτάλη', 'female', '1999-02-10', 'SEP', '2012-05-18'),
(181, 'Οφηλία', 'Γερμανού', 'female', '1999-02-11', 'NOA', '2009-05-12'),
(182, 'Σούλα', 'Αναγνώστου', 'female', '1999-05-16', 'TELEPR', '2014-02-02'),
(183, 'Λουκάς', 'Σκυλακάκης', 'male', '1999-05-25', 'NHRF', '2009-02-11'),
(184, 'Μιλτιάδης', 'Δουμπιώτης', 'male', '1999-06-22', 'UOA', '2007-09-19'),
(185, 'Αχαιός', 'Μπλάνας', 'male', '1999-10-03', 'MUHALIS', '2006-03-28'),
(186, 'Ξενοφών', 'Βασιλείου', 'male', '1999-11-19', 'PRODEA', '2012-06-13'),
(187, 'Τριάδα', 'Καρέλια', 'female', '2000-02-16', 'SFAK', '2010-04-20'),
(188, 'Βανέσα', 'Σπανού', 'female', '2000-02-21', 'DUOT', '2009-02-23'),
(189, 'Κλέων', 'Ιωάννου', 'male', '2000-06-24', 'UOP', '2009-10-31'),
(190, 'Χαραλαμπία', 'Μπενιζέλου', 'female', '2000-08-19', 'FARMANET', '2007-04-22'),
(191, 'Υακίνθη', 'Παπαϊωάννου', 'female', '2000-11-06', 'EKETA', '2011-06-13'),
(192, 'Φοίβη', 'Παπανικολάου', 'female', '2000-11-25', 'FORTH', '2011-06-28'),
(193, 'Δηλία', 'Παπαμιχαήλ', 'female', '2001-06-24', 'UOA', '2008-09-10'),
(194, 'Κλέων', 'Τσάμης', 'male', '2001-07-21', 'UOC', '2013-05-27'),
(195, 'Τριάδα', 'Οικονόμου', 'female', '2001-09-17', 'PRGAS', '2007-09-12'),
(196, 'Αργεντίνα', 'Παπαντωνίου', 'female', '2001-09-29', 'NHRF', '2012-02-04'),
(197, 'Μπία', 'Αντωνοπούλου', 'female', '2001-10-08', 'UOA', '2013-07-23'),
(198, 'Δήμος', 'Μάμος', 'male', '2001-12-17', 'AUTH', '2007-09-08'),
(199, 'Σπυρίδων', 'Μυλωνάς', 'male', '2002-01-24', 'KETEP', '2011-07-30'),
(200, 'Λυκούργος', 'Παπαμιχαήλ', 'male', '2002-05-17', 'ALOUMIL', '2010-12-30');


-- EXECUTIVES

--   --------------

INSERT INTO `executive` (`executive_id`, `first_name`, `last_name`) VALUES
(1, 'Λουκάς', 'Αργυρός'),
(2, 'Βαρβάρα', 'Αλεξίου'),
(3, 'Δήμος', 'Στεφανόπουλος'),
(4, 'Άλκηστη', 'Γεωργίου'),
(5, 'Απόστολος', 'Βασιλόπουλος'),
(6, 'Ειρήνη', 'Μπακογιάννη'),
(7, 'Βάιος', 'Φραγκούδης'),
(8, 'Κωνσταντίνος', 'Δουμπιώτης'),
(9, 'Κύριλλος', 'Αποστολάκης'),
(10, 'Λάζαρος', 'Παχής'),
(11, 'Ευστάθιος', 'Κασιδιάρης'),
(12, 'Ρούλα', 'Παπανικολάου'),
(13, 'Σαμπρίνα', 'Παπανικολάου'),
(14, 'Υακίνθη', 'Αλεξίου'),
(15, 'Αχιλλέας', 'Ράγκος'),
(16, 'Άλκηστη', 'Ιωάννου'),
(17, 'Ιάκωβος', 'Δημαράς'),
(18, 'Σπυρίδων', 'Πρωτονοτάριος'),
(19, 'Όλγα', 'Γαλάνη'),
(20, 'Χαράλαμπος', 'Βλαβιανός'),
(21, 'Αθανάσιος', 'Τρικούπης'),
(22, 'Ιεροκλής', 'Μπλάνας'),
(23, 'Κίρκη', 'Παπάζογλου'),
(24, 'Έφη', 'Παπάζογλου'),
(25, 'Ζουμπουλιά', 'Αλεξάνδρου'),
(26, 'Βάιος', 'Μακρής'),
(27, 'Άδωνης', 'Ραγκαβής'),
(28, 'Γεννάδιος', 'Σκυλακάκης'),
(29, 'Άννα', 'Αποστόλου'),
(30, 'Παναγιώτης', 'Δοξαράς'),
(31, 'Σπυρίδων', 'Νικολάκος'),
(32, 'Βιθυνός', 'Κυπραίος'),
(33, 'Αλίκη', 'Παπαγεωργίου'),
(34, 'Γεωργία', 'Αλεξάνδρου'),
(35, 'Υρώ', 'Μπακογιάννη'),
(36, 'Χαράλαμπος', 'Τσίπρας'),
(37, 'Βαρβάρα', 'Θεοδοσίου'),
(38, 'Καλυψώ', 'Θάνου'),
(39, 'Λαέρτης', 'Γκόφας'),
(40, 'Βιθυνός', 'Τσαγανέας');

INSERT INTO `field` (`field_id`,`field_name`) VALUES 
('1','Φυσικές Επιστήμες'),
('2','Επιστήμες Μηχανικού και Τεχνολογίας'),
('3','Ιατρική και Επιστήμες Υγείας'),
('4','Γεωπονικές Επιστήμες και Τρόφιμα'),
('5','Μαθηματικά & Επιστήμες της Πληροφορίας'),
('6','Κοινωνικές Επιστήμες'),
('7','Ανθρωπιστικές Επιστήμες & Τέχνες'),
('8','Περιβάλλον & Ενέργεια'),
('9','Διοίκηση & Οικονομία της Καινοτομίας');

INSERT INTO `program` (`program_id`, `title`, `department`) VALUES
('1', 'Ενίσχυση έργων Βιώσιμης Ανάπτυξης','Δ/νση Περιβάλλον και Βιώσιμη Ανάπτυξη'),
('2', 'Εφαρμογές της νανοτεχνολογίας','Δ/νση Καινοτομίας και Τεχνολογίας'), 
('3', 'Ενίσχυση ερευνητικών έργων στην Τεχνολογία Τροφίμων','Δ/νση Γεωπονικών Επιστημών και Τροφίμων'),
('4', 'Τεχνολογίες Πληροφορίας και Επικοινωνιών','Δ/νση Μαθηματικών και Επιστήμης Υπολογιστών'),
('5', 'Βιοϊατρική Τεχνολογία','Δ/νση Καινοτομίας και Τεχνολογίας'),
('6', 'Ενίσχυση έρευνας στην Γενετική Ιατρική', 'Δ/νση Ιατρικής και Υγείας'),
('7', 'Ενίσχυση έργων εκπαιδευτικού ενδιαφέροντος', 'Δ/νση Κοινωνικών και Ανθρωπιστικών Επιστημών'),
('8', 'Μείωση ανθρακούχων εκπομπών', 'Δ/νση Περιβάλλον και Βιώσιμη Ανάπτυξη'),
('9', 'Ενισχυση έρευνητικών έργων στην Νευροεπιστήμη', 'Δ/νση Ιατρικής και Υγείας'),
('10', 'Ενίσχυση κοινωνιολογικών ερευνητικών έργων', 'Δ/νση Κοινωνικών και Ανθρωπιστικών Επιστημών'),
('11', 'Ανάπτυξή και έρευνα φαρμακευτικών προϊόντων', 'Δ/νση Ιατρικής και Υγείας'),
('12', 'Ανάπτυξη και εφαρμογές της Ρομποτικής', 'Δ/νση Καινοτομίας και Τεχνολογίας'),
('13', 'Ενίσχυση έρευνητικών έργων σε Βιολογία και Ζωολογία', 'Δ/νση Ιατρικής και Υγείας'),
('14', 'Ενίσχυση ερευνητικών έργων στο πεδίο των Μαθηματικών και της Στατιστικής', 'Δ/νση Μαθηματικών και Επιστήμης Υπολογιστών'),
('15', 'Μοντελοποίηση και ανάλυση δεδομένων', 'Δ/νση Μαθηματικών και Επιστήμης Υπολογιστών'),
('16', 'Ενίσχυση έρευνητικών έργων Ιστορία και Αρχαιολογίας', 'Δ/νση Κοινωνικών και Ανθρωπιστικών Επιστημών'),
('17', 'Γλώσσα, Τέχνη και Λαογραφία', 'Δ/νση Κοινωνικών και Ανθρωπιστικών Επιστημών'),
('18', 'Εφαρμογές και έρευνα Φυσική και Χημεία', 'Δ/νση Φυσικών Επιστημών'),
('19', 'Διοίκηση και Επιχειρηματικότητα', 'Δ/νση Διοίκηση & Οικονομία της Καινοτομίας'),
('20', 'Ενίσχυση ερευνητικών έργων σε πολιτική και κοινωνικά φαινόμενα', 'Δ/νση Κοινωνικών και Ανθρωπιστικών Επιστημών'),
('21', 'Ενίσχυση ερευνητικών έργων σε Καρδιολογία', 'Δ/νση Ιατρικής και Υγείας'),
('22', 'Ενίσχυση καινοτομίας στη Γεωπονία', 'Δ/νση Γεωπονικών Επιστημών και Τροφίμων'),
('23', 'Ενίσχυση ερευνητικών έργων σε Γεωλογία και Γεωγραφία', 'Δ/νση Φυσικών Επιστημών'),
('24', 'Η Επιστήμη στην κοινωνία και μαζί με την κοινωνία', 'Δ/νση Κοινωνικών και Ανθρωπιστικών Επιστημών'),
('25', 'Ασφαλής, καθαρή και αποδοτική ενέργεια', 'Δ/νση Περιβάλλον και Βιώσιμη Ανάπτυξη'),
('26', 'Εκσυγχρονισμός της Ελλάδας', 'Δ/νση Καινοτομίας και Τεχνολογίας'),
('27', 'Καινοτόμες δράσεις σε διάγνωση και θεραπεία ασθενειών', 'Δ/νση Ιατρικής και Υγείας'),
('28', 'Έρευνα σε δομή και ιδιότητες υλικών', 'Δ/νση Καινοτομίας και Τεχνολογίας'),
('29', 'Πανίδα και βιοποικιλότητα', 'Δ/νση Περιβάλλον και Βιώσιμη Ανάπτυξη'),
('30', 'Αξιοποίηση ηλιακής ακτινοβολίας', 'Δ/νση Διοίκηση & Οικονομία της Καινοτομίας');



INSERT INTO `project` (`title`, `amount`, `summary`, `start_date`, `end_date`, `researcher_id`, `abbreviation`, `executive_id`, `program_id`) VALUES
-- FIELD 1 (MOSTLY!)

('Σχηματισμός πολυμερικών βουρτσών σε επιφάνειες από πρόδρομα γραμμικά τρισυσταδικά τριπολυμερή για εφαρμογές στην νανοτεχνολογία', '200000.00',
'Στόχος της συγκεκριμένης έρευνας είναι η σύνθεση νέων γραμμικών τρισυσταδικών τριπολυμερών χαμηλών μοριακών
βαρών του τύπου A-b-B-b-C και Β-b-A-b-C, για εφαρμογές στη νανοτεχνολογία. A θα είναι η συστάδα του
πολυ(βουταδιενίου) (PB), B θα είναι η συστάδα του πολυστυρενίου (PS) και C η συστάδα της πολυ(διμέθυλοσιλοξάνης)
(PDMS).
Στα δείγματα που προτείνονται ο κλάδος ΡΒ θα εμφανίζει είτε υψηλή μικροδομή -1,4 (~92%) και θα συμβολίζεται ως
ΡΒ1,4
είτε υψηλή μικροδομή -1,2 (~100%) και θα συμβολίζεται ως ΡΒ1,2
. Επομένως προκύπτουν τέσσερις (4)
διαφορετικοί τύποι δειγμάτων και συγκεκριμένα: PB1,4
-b-PS-b-PDMS, PB1,2
-b-PS-b-PDMS, PS-b-PB1,4
-b-PDMS και PS-bPB1,2
-b-PDMS Λαμβάνοντας υπόψη τις απαιτήσεις στις εφαρμογές της νανοτεχνολογίας σήμερα για χαμηλές διαστάσεις
(sub-10nm) προτείνονται αρκετά χαμηλά μοριακά βάρη.', '2020-05-06','2021-05-06', '1', 'UOP','1','2');


INSERT INTO project (title, amount, summary, start_date, end_date, researcher_id, abbreviation, executive_id, program_id) VALUES
('Κβαντικές μετρήσεις με υπέρψυχρα νέφη ατόμων', '164000.00',
'Τα υπέρψυχρα αέρια έχουν επιδείξει ένα μεγάλο εύρος δυνατοτήτων με προοπτικές εφαρμογών τόσο στην
τεχνολογία όσο και στη βασική έρευνα. Για την πλήρη αξιοποίηση των ατόμων απαιτείται δυνατότητα χειρισμού
των κβαντικών χαρακτηριστικών τους προκειμένου να αξιοποιηθούν οι κβαντικοί πόροι που διαθέτουν. Η
μέτρηση βασίζεται στο φαινόμενο Faraday: γραμμικά πολωμένο φως με μήκος κύματος διαφορετικό από τον
ατομικό συντονισμό, όταν διέρχεται από ατομικό νέφος με μη-μηδενικό σπιν, υπόκειται σε οπτική περιστροφή
κατά γωνία ανάλογης του αριθμού των ατόμων. Η προτεινόμενη μέτρηση δεν καταστρέφει τις κβαντικές
συσχετίσεις και έχει πολύ μικρή επίδραση στη θερμοκρασία των ατόμων. Επομένως μπορεί να χρησιμοποιηθεί
για την πραγματοποίηση κβαντικών μετρήσεων και για την προετοιμασία των ατόμων σε ένα συμβολόμετρο. Το
μετρητικό φως εισάγει ένα μηχανισμό απώλειας ατόμων, ο οποίος θα αξιοποιηθεί για τη συρρίκνωση ενός
αρχικά μεγάλου νέφους σε συγκεκριμένο μέγεθος. Μέτρηση με ακρίβεια μεγαλύτερη του θορύβου βολής θα
οδηγήσει σε κατάσταση συμπίεσης (squeezing) του αριθμού ατόμων σε συμπύκνωμα Bose-Einstein και θα
επιτρέψει την παραγωγή καταστάσεων συμπίεσης και σύμπλεξης (entanglement) κατάλληλων για
φασματοσκοπία και συμβολομετρία. Η ευαισθησία της μέτρησης περιορίζεται από τον θόρυβο βολής των
μετρητικών φωτονίων. Προκειμένου να ξεπεραστεί αυτός ο περιορισμός, θα χρησιμοποιήσουμε μια οπτική
κοιλότητα για να ενισχύσουμε το σήμα. Η προτεινόμενη έρευνα μπορεί να βρει εφαρμογή σε ατομικά ρολόγια,
αδρανειακούς αισθητήρες, κβαντικούς υπολογιστές, κβαντικές προσομοιώσεις και πειράματα βασικής φυσικής
όπως ανιχνευτές βαρυτικών κυμάτων.', '2020-04-14','2023-04-14', '2', 'FORTH','1','18');


INSERT INTO project (title, amount, summary, start_date, end_date, researcher_id, abbreviation, executive_id, program_id) VALUES
('Προάγοντας την Αειφορία της Κατάλυσης: Νέες Συνθετικές Μεθοδολογίες και Χρήσιμες Οργανικές Αρχιτεκτονικές', '199961.03',
'Το έργο SUSTAIN θα εισάγει και θα αναπτύξει ένα ολοκληρωμένο σύνολο πρωτοποριακών συνθετικών στρατηγικών
και εργαλείων, στηριζόμενο στις αρχές της βιώσιμης χημείας και ανάπτυξης. Μεταξύ άλλων, θα αναπτυχθούν
καινοτόμες, αποδοτικές τεχνολογίες χημικών μετασχηματισμών πολλών συστατικών, αντιδράσεων καταρράκτη ή
αντιδράσεων ενεργοποίησης δεσμών C-H, σε ορισμένες περιπτώσεις εναντιοεκλεκτικά ή χρησιμοποιώντας το CO2 ως
πρώτη ύλη, σε συνδυασμό με την εφαρμογή τους στη σύνθεση ενώσεων με σημαντικές βιολογικές και τεχνολογικές
εφαρμογές. Αυτοί οι μετασχηματισμοί χαρακτηρίζονται από οικονομία σταδίων και ατόμων, οπότε είναι εγγενώς
«πράσινοι». Επιπλέον, θα έχουν σημαντική απήχηση σε διεθνές επίπεδο, χρησιμοποιώντας, για πρώτη φορά σε
αυτές τις αντιδράσεις, αειφόρα μέταλλα όπως ο Cu, ο Zn και το Mn ή οργανοκαταλύτες. Θα αναπτυχθούν επίσης
πρωτότυπα, εξαιρετικά χρήσιμα καταλυτικά συστήματα Au υψηλής απόδοσης, για τις ελάχιστα μελετημένες
αντιδράσεις σύζευξης απουσία οξειδωτικού (οι οποίες είναι οικονομικές και φιλικές προς το περιβάλλον), καθώς και
ηλεκτροκαταλυτικοί μετασχηματισμοί στηριζόμενοι στα μη σπάνια μέταλλα Co και Ni. Πρωτοποριακές ανακαλύψεις
αναμένονται επίσης μέσω των αντιδράσεων ενεργοποίησης δεσμών Csp3-H από καταλυτικά συστήματα Fe και Mn ή
μέσω της χρήσης νέων κατευθυντήριων ομάδων, που είναι απομεμακρυσμένες ή δεν αφήνουν ίχνη, στην αειφόρα
κατάλυση για ενεργοποίηση δεσμών Csp2-H.', '2021-06-07','2024-06-07', '3', 'UOA','29','1');

INSERT INTO project (title, amount, summary, start_date, end_date, researcher_id, abbreviation, executive_id, program_id) VALUES
('Χωροχρονική απεικόνιση της υψίσυχνης σεισμικής διάρρηξης με μεθόδους σεισμικής οπισθοπροβολής', '199888.00',
'Ο κύριος σκοπός του SIREN είναι η γρήγορη και ακριβής απεικόνιση της υψίσυχνης ενέργειας που εκλύεται στον χώρο
διάρρηξης μεγάλων σεισμών. Στο έργο αυτό θα πραγματοποιηθεί ανάλυση με την μέθοδο της οπισθοπροβολής σε σεισμούς με
ποιοτικά δεδομένα στην Ιαπωνία, Ιταλία, Ελλάδα, Τουρκία, Νέα Ζηλανδία και αλλού. Η προσέγγισή μας απαιτεί την αφαίρεση των
τοπικών επιδράσεων από τις καταγραφές ή τουλάχιστον την ποσοτική επιλογή των καλών σταθμών αναφοράς. Μιας και οι
τοπικές επιδράσεις δεν έχουν αφαιρεθεί έως τώρα σε παρόμοιες μελέτες, στο έργο SIREN θα αναπτυχθούν και δοκιμαστούν
τέτοιες πρακτικές με ένα γρήγορο και αξιόπιστο νέο λογισμικό παράλληλης επεξεργασίας το οποίο θα πραγματοποιεί γρήγορους
υπολογισμούς σε πολλαπλούς πυρήνες CPUs και GPUs. Η πραγματοποίηση του σχεδίου του έργου θα οδηγήσει σε μια
περαιτέρω κατανόηση της διαδικασίας της σεισμικής διάρρηξης
', '2019-06-07','2022-06-07', '4', 'NOA','29','23');

INSERT INTO project (title, amount, summary, start_date, end_date, researcher_id, abbreviation, executive_id, program_id) VALUES
-- 1 KAI KOINWN
('Εκπαιδευτική Σεισμολογία για το σχολείο και την κοινωνία: Διεπιστημονική
προσέγγιση με καινοτόμες μεθόδους θεατρικής αγωγής και ψηφιακών
τεχνολογιών', '199826.00',
'Ο χώρος της Ανατολικής Μεσογείου χαρακτηρίζεται από υψηλή σεισμικότητα, με επιπτώσεις στις κάθε είδους
ανθρώπινες δραστηριότητες και κατασκευές. Η μείωση των οικονομικών και κοινωνικών επιπτώσεων των σεισμών
προϋποθέτει την ανάπτυξη της σεισμολογικής έρευνας, την εκπαίδευση του πληθυσμού και τη βελτίωση της απόκρισης
της Πολιτείας.
Στα πλαίσια αυτά: α) οι σεισμολογικοί φορείς της χώρας έχουν ενεργή συμμετοχή στην ευαισθητοποίηση του
πληθυσμού και την εκλαΐκευση εννοιών κατανόησης του καταστροφικού φαινομένου σε ευρύτερες ομάδες πληθυσμού,
β) οι μαθητές και οι εκπαιδευτικοί αποτελούν πληθυσμιακές ομάδες που μπορούν να έχουν ρόλο στην μείωση των
επιπτώσεων μέσω της εκπαιδευτικής διαδικασίας και τη διάχυση των γνώσεων, γ) τα μέτρα προστασίας έναντι σεισμού
αποτελούν ένα σύνολο κανόνων, οι οποίοι ακολουθούνται από τον καθένα ως μέλος κοινωνικής ομάδας, με την
Εκπαιδευτική Σεισμολογία να έχει - βραχυπρόθεσμα και μακροπρόθεσμα - κοινωνική διάσταση, δ) Η Εκπαιδευτική
Σεισμολογία προεκτείνεται στη Σεισμολογία των Πολιτών, όπου ο εκπαιδευμένος για το σεισμό πολίτης γίνεται
παρατηρητής και αποστέλλει αξιόπιστες πληροφορίες στους επιστήμονες, οι οποίοι τις επεξεργάζονται και παρέχουν
πολύτιμη πληροφόρηση στην Πολιτεία για άμεση απόκριση στις πληγείσες περιοχές. Η θεατρική αγωγή στην
εκπαίδευση, καταξιωμένη ως μέσον διαμόρφωσης της συμπεριφοράς και της κριτικής σκέψης του ατόμου και
κοινωνικοποίησής του, προσφέρει πλούσιες δυνατότητες βιωματικής προσέγγισης κρίσιμων ή απαιτητικών θεμάτων ή
προκλήσεων. Ο συνδυασμός της με τη χρήση σύγχρονων ψηφιακών τεχνολογιών όπως η εικονική πραγματικότητα και
η συνύπαρξη φυσικών και ψηφιακών ηθοποιών σε υβριδικά δρώμενα, επιτρέπει την καινοτόμο πολυθεματική
προσέγγιση της εκπαίδευσης του πληθυσμού έναντι του φαινομένου του σεισμού, με το σχολείο να γίνεται πηγή
πληροφόρησης για ευρύτερες ομάδες πληθυσμού.
Στο προτεινόμενο έργο, το ΕΑΑ-ΓΙ, ως κύριος ερευνητικός και επιχειρησιακός φορέας της Πολιτείας στο πεδίο της
Σεισμολογίας, συνεργάζεται με το ΠΑΠΕΛ-ΤΘΣ για την καινοτόμο εισαγωγή και αξιοποίηση της θεατρικής αγωγής στην
Εκπαιδευτική Σεισμολογία και με το ΠαΔΑ-ΤΗΗΜ για την ενσωμάτωση πρωτοποριακών τεχνικών πολυμέσων και
επικοινωνίας στην προαναφερόμενη διαδικασία.', '2021-06-07','2024-06-07', '5', 'NOA','30','7');


-- 1 kai perivallon
INSERT INTO project (title, amount, summary, start_date, end_date, researcher_id, abbreviation, executive_id, program_id) VALUES
('Η ηλικακή ακτινοβολία στην υπηρεσία της φωτοοργανοκατάλυσης: Καινοτόμοι και πράσινοι οργανικοί μετασχηματισμοί και σύνθεση ενώσεων για τη χημική βιομηχανία', '200000.00',
'Η σημερινή εποχή και οι οικονομικές συνθήκες που επικρατούν καθιστούν αναγκαία την αναζήτηση εναλλακτικών πηγών ενέργειας. 
Η ΦωτοΟργανοκατάλυση υιοθετεί τη χρήση φωτός για την κατάλυση οργανικών αντιδράσεων που δεν είναι εφικτές μέσω κλασσικής Οργανικής Χημείας 
και αποτελεί μία επαναστατική ιδέα χρήσης εναλλακτικής πηγής ενέργειας, φιλικής προς το περιβάλλον. Αντικείμενο της παρούσας πρότασης
 αποτελεί η ανακάλυψη και η ανάπτυξη καινοτόμων φωτοχημικών μετασχηματισμών με τη χρήση οικιακών λαπτήρων ή της ηλιακής ακτινοβολίας.
 Ως φωτοκαταλύτες στις αντιδράσεις μελετώνται τόσο σύμπλοκα μετάλλων μεταπτώσεως, όσο και φθηνά μικρά οργανικά μόρια που φέρουν τα 
 κατάλληλα δομικά χαρακτηριστικά για να μετατρέπουν την ακρινοβολία σε χρήσιμη χημική ενέργεια. Τα φψτοοργανοκαταλυτικά πρωτόκολλα που 
 αναπτύσσονται έχουν ως στόχο την ευκολία αναπαραγωγής, ακόμη και από μη ειδικευμένο προσωπικό, τη φιλικότητα προς το περιβάλλον και το 
 χαμηλό κόστος.', '2019-08-27','2023-06-27', '6', 'UOA','1','1');

-- FIELD 2 
INSERT INTO project (title, amount, summary, start_date, end_date, researcher_id, abbreviation, executive_id, program_id) VALUES
('Υλοποίηση Ολοκληρωμένου Συστήματος Υποστήριξης και Αποκατάστασης Κινητικών Λειτουργιών μέσω Υβριδικής Διεπαφής Εγκεφάλου-Υπολογιστή', '190500.00',
'Το INSPiRE στοχεύει στον σχεδιασμό και την υλοποίηση ενός καινοτόμου ολοκληρωμένου συστήματος Υβριδικής Διεπαφής ΕγκεφάλουΥπολογιστή για την υποστήριξη και την ανάκτηση κινητικών λειτουργιών σε άτομα με περιορισμένη κινητικότητα (λόγω παθήσεων όπως
είναι το εγκεφαλικό και οι τραυματισμοί σπονδυλικής στήλης), αξιοποιώντας ηλεκτροεγκεφαλογραφικές (ΗΕΓ) και ηλεκτρομυογραφικές
(ΗΜΓ) καταγραφές.
Η κεντρική ιδέα του έργου είναι η δημιουργία ενός τεχνητού διαύλου επικοινωνίας μεταξύ του εγκεφάλου και των μυών ή μίας
εξωτερικής συσκευής, στοχεύοντας στα εξής:
-Παροχή ταυτόχρονης υποβοήθησης κινητικών λειτουργιών και δυνατοτήτων αποκατάστασης μέσω διέγερσης μυϊκών ινών με χρήση
εξωτερικής ηλεκτρικής διέγερσης (Σύστημα Υποστήριξης και Αποκατάστασης Κίνησης)
-Παροχή κινητικής ανεξαρτησίας μέσω ενός αυτοματοποιημένου συστήματος που αξιοποιεί εγκεφαλικά και μυϊκά σήματα για τον έλεγχο
ενός τροποποιημένου αμαξιδίου (Σύστημα Υποκατάστασης Κίνησης μέσω Αμαξιδίου)
Πλήθος νευρολογικών διαταραχών μπορούν να επηρεάσουν τις κινητικές λειτουργίες διαταράσσοντας οποιοδήποτε στάδιο του νευρομυϊκού
κινητικού διαύλου, ο οποίος περιλαμβάνει κατά βάση τον εγκέφαλο (γεννήτρια σημάτων), τη σπονδυλική στήλη και τα συνδεδεμένα σε αυτή
νεύρα (αγωγοί μετάδοσης σήματος) καθώς και τις μυϊκές ομάδες (δέκτες σήματος και μονάδες υλοποίησης κίνησης). Σε ορισμένες
περιπτώσεις, η μυϊκή ικανότητα διατηρείται σε μεγάλο ποσοστό αναλλοίωτη, με το πρόβλημα να έγκειται στην άφιξη ανεπαρκούς σήματος
ελέγχου στις μυϊκές ομάδες, λόγω ατελειών είτε κατά την παραγωγή είτε κατά τη μετάδοσή του.
Σε αυτό το πλαίσιο, το INSPiRE επιχειρεί την αξιοποίηση μη επεμβατικών καταγραφών ΗΕΓ και ΗΜΓ σε συνδυασμό με σύγχρονες
τεχνολογίες και εξειδικευμένη εκπαίδευση ασθενών, στοχεύοντας στην κινητική αποκατάσταση και ανεξαρτησία με χρήση μίας
αρχιτεκτονικής κλειστού βρόχου.', '2015-06-07','2016-06-07', '7', 'UOWA','1','5');
  
INSERT INTO project (title, amount, summary, start_date, end_date, researcher_id, abbreviation, executive_id, program_id) VALUES
('Μια νέα προσέγγιση για δυναμική, αυτόματη αναγνώριση ανθρώπινων Δραστηριοτήτων', '187260.04',
'Η έρευνα του έργου ACTIVE εστιάζει στο χώρο της Αυτόματης Αναγνώρισης ανθρώπινων Δραστηριοτήτων (ΑΑΔ), μια
βασική προϋπόθεση εφαρμογών διάχυτης νοημοσύνης και υποβοήθησης της καθημερινής διαβίωσης. Η ΑΑΔ σε οικιακό
περιβάλλον τυπικά εκτελείται με επεξεργασία δεδομένων διάφορων αισθητηριακών μονάδων, όπως (α) φορητοί
αισθητήρες (wearables), (β) IoT αισθητήρες έξυπνου σπιτιού και (γ) αισθητήρες κινητής ρομποτικής πλατφόρμας. Το έργο
ACTIVE εξελίσσει τεχνολογίες αιχμής του χώρου: (α) διερευνώντας μια νέα μέθοδο για δυναμική, βασισμένη σε ένα
διευρυμένο πλαίσιο παραγόντων (χωρο-χρονικές παράμετροι, ιδιαιτερότητες δραστηριοτήτων-στόχων, χαρακτηριστικά
αισθητήρων κ.α.), συγχώνευση πολυτροπικών δεδομένων που προκύπτουν από φορητούς και στατικούς αισθητήρες
ενός έξυπνου σπιτιού και (β) προτείνοντας μια καινοτόμο προσέγγιση για το συνδυασμό των παραπάνω, με μια επιπλέον,
δυναμική αισθητηριακή μονάδα, ρομποτικής όρασης. Συγκεκριμένα, αρχικά αναπτύσσουμε ένα νέο ιεραρχικό πλαίσιο
συγχώνευσης πολυτροπικών δεδομένων, βασισμένο σε μια ιεραρχική προσέγγιση πολλαπλών επιπέδων με συνθετικά
χαρακτηριστικά, ικανό να συγχωνεύσει με τρόπο δυναμικό που προσαρμόζεται στις εκάστοτε συνθήκες παρακολούθησης ,
δεδομένα από φορητούς αισθητήρες και αισθητήρες ΙοΤ. Παράλληλα, αναπτύσσουμε μια νέα μέθοδο δυναμικού
συντονισμού των παραπάνω αισθητηριακών μονάδων με μια ενεργή μονάδα, που αποτελείται από μια κινητή ρομποτική
πλατφόρμα με ικανότητα υπολογιστικής όρασης. Τελικός στόχος των δύο παραπάνω νέων μεθόδων θα είναι η ενίσχυση:
(α) της αποτελεσματικότητας της αναγνώρισης των ανθρώπινων δραστηριοτήτων και (β) του επιπέδου λεπτομέρειας που
παρέχεται από την ΑΑΔ, όσον αφορά τις ιδιαιτερότητες της εκτέλεσης των δραστηριοτήτων, στο πλαίσιο της προσπάθειας
κατανόησης της ανθρώπινης συμπεριφοράς. Οι προτεινόμενες μέθοδοι, βασισμένες σε (α) φορητές συσκευές και ΙοΤ
αισθητήρες και (β) φορητές συσκευές, ΙοΤ αισθητήρες και δυναμικά αναπροσαρμοζόμενη, ρομποτική όραση, θα εξεταστούν
συστηματικά ως προς την αποτελεσματικότητά τους στην ΑΑΔ. Στο πλαίσιο αυτό θα αναπτύξουμε, στη βάση της
υποδομής έξυπνου σπιτιού του ΕΚΕΤΑ/ΙΠΤΗΛ και του οικιακού ρομποτικού βοηθού RAMCIP, ένα ενδεικτικό πρωτότυπο
σύστημα που θα λειτουργεί μέσα από τις προτεινόμενες μεθόδους του έργου, σε ένα «έξυπνο σπίτι».', 
'2021-06-07','2024-06-07', '8', 'EKETA','2','12');

INSERT INTO project (title, amount, summary, start_date, end_date, researcher_id, abbreviation, executive_id, program_id) VALUES
('Εκσυγχρονισμός του Ελληνικού Δικτύου Βαρύτητας', '173192.66',
'Το δίκτυο βαρύτητας καθώς και το κατακόρυφο δίκτυο αποτελούν βασικά γεωδαιτικά δίκτυα της
εθνικής υποδομής. Τα δίκτυα αυτά υλοποιήθηκαν και μετρήθηκαν πριν αρκετές δεκαετίες,
ακολουθώντας κλασσικές μεθόδους.
Κύριος στόχος του ερευνητικού έργου είναι η διερεύνηση της δυνατότητας εκσυγχρονισμού των
παραπάνω δικτύων.
Ο στόχος αυτός θα επιτευχθεί μέσα από:
Α) Την αξιολόγηση του υφιστάμενου δικτύου βαρύτητας μέσω απόλυτων και σχετικών μετρήσεων
βαρύτητας και μετρήσεων της κατακόρυφης βαθμίδας της.
Β) Την αξιολόγηση του κατακόρυφου δικτύου και του δικτύου βαρύτητας μέσω μετρήσεων βαρύτητας,
χωροστάθμησης και GNSS σε δύο πιλοτικές περιοχές στη βόρεια και νότια Ελλάδα.
Γ) Τη διερεύνηση χρήσης, με όρους ακρίβειας, του γεωειδούς ως επιφάνεια αναφοράς του κατακόρυφου δικτύου μέσω του υπολογισμό υψηλής ανάλυσης και ακρίβειας μοντέλου γεωειδούς για τον
ευρύτερο ελλαδικό χώρο. Το μοντέλο αυτό θα αξιολογηθεί πανελλαδικά με δεδομένα GNSS /
χωροστάθμησης καθώς και με τα δεδομένα υψηλής ακρίβειας, που συλλέχθηκαν στις προαναφερθείσες
πιλοτικές περιοχές.
Δ) Τη σύνταξη τεχνικοοικονομικής μελέτης για την αξιολόγηση των βραχυπρόθεσμων και
μακροπρόθεσμων πλεονεκτημάτων και μειονεκτημάτων της υιοθέτησης του γεωειδούς ως επιφάνεια
αναφοράς του κατακόρυφου δικτύου.', '2021-06-07','2024-06-07', '9', 'AUTH','2','26');

INSERT INTO project (title, amount, summary, start_date, end_date, researcher_id, abbreviation, executive_id, program_id) VALUES
('Αστικές Συγκοινωνίες με Μηδενικούς Ρύπους: Μοντέλα Σχεδιασμού και Υποστήριξης
Αποφάσεων', '184775.00',
'Οι δυσμενείς επιπτώσεις στο περιβάλλον και τη δημόσια υγεία που σχετίζονται με τις μηχανοκίνητες
μεταφορές και τα ορυκτά καύσιμα επιτάσσουν τον επανασχεδιασμό των συστημάτων αστικών συγκοινωνιών
στο πλαίσιο της βιώσιμης κινητικότητας. Σε αυτήν την κατεύθυνση, ο αποδοτικός σχεδιασμός και λειτουργία
των συστημάτων αστικών συγκοινωνιών είναι ζωτικής σημασίας για τη μείωση των ρύπων, καθώς και για την
αύξηση της ελκυστικότητας και της οικονομικής βιωσιμότητάς τους. Η εισαγωγή της ηλεκτροκίνησης στα
συστήματα αστικών συγκοινωνιών έχει από καιρό αναγνωριστεί ως μια πολλά υποσχόμενη κατεύθυνση στα
πλαίσια της αειφόρου ανάπτυξης. Παρόλο που οι περιορισμοί εμβέλειας και απόδοσης των μπαταριών
παρεμπόδισαν την ευρεία υιοθέτηση ηλεκτρικών λεωφορείων στο παρελθόν, οι τεχνολογικές εξελίξεις τα
καθιστούν πλέον ελκυστική επιλογή για τις αστικές συγκοινωνίες. Ωστόσο, οι επιχειρησιακοί περιορισμοί και η
ανάγκη για πρόσθετες υποδομές (φόρτισης) υπογραμμίζουν την ανάγκη δημιουργίας κατάλληλων εργαλείων
λήψης αποφάσεων, ειδικά προσαρμοσμένων για την υποστήριξη του σχεδιασμού δικτύων αστικών
συγκοινωνιών με ηλεκτροκίνητο στόλο λεωφορείων. Μέχρι στιγμής παρατηρείται τόσο στη βιβλιογραφία και
όσο και στην εφαρμοσμένη πρακτική έλλειψη μεθοδολογικών προσεγγίσεων για τον σχεδιασμό ενός πλήρως
ηλεκτρικού δικτύου αστικών συγκοινωνιών.', '2019-06-07','2022-10-07', '10', 'NTUA','2','8');

-- 1 KAI 2
-- id: 11
INSERT INTO project (title, amount, summary, start_date, end_date, researcher_id, abbreviation, executive_id, program_id) VALUES
('Διερευνώντας νέες Διεργασίες για Χρήση του CO2: υποβοηθούμενη από CO2 Αφυδρογόνωση του Αιθανίου', '187590.92',
'Η χρήση ορυκτών καυσίμων στη βιομηχανία, τις μεταφορές και την παραγωγή ενέργειας απελευθερώνει τεράστιες
ποσότητες CO2 στην ατμόσφαιρα. Προκειμένου να επιτευχθεί ο μετριασμός της υπερθέρμανσης του πλανήτη, είναι
απαραίτητο να δεσμεύεται το CO2 από μεγάλες σταθερές πηγές εκπομπών, όπως οι σταθμοί παραγωγής ηλεκτρικής
ενέργειας και άλλες βιομηχανίες υψηλών ενεργειακών απαιτήσεων και στο πλαίσιο της κυκλικής οικονομίας, να
επαναχρησιμοποιείται ως πρώτη ύλη άνθρακα.
Ο στόχος του έργου CUDET, που υποστηρίζεται από το Ελληνικό Ίδρυμα Έρευνας & Καινοτομίας (HFRI-FM17-1899),
είναι η ανάπτυξη μιας νέας διεργασίας για την παραγωγή αιθυλενίου μέσω αφυδρογόνωσης αιθανίου, υποβοηθούμενης
από CO2
, το οποίο χρησιμοποιείται ως ένα ήπιο οξειδωτικό. Η ανάπτυξη δραστικών και εκλεκτικών καταλυτικών
συστημάτων καθιστά δυνατή την παραγωγή αιθυλενίου με υψηλή απόδοση, σε σχετικά χαμηλές θερμοκρασίες, ενώ
ταυτόχρονα μετατρέπει ένα αέριο του θερμοκηπίου, το CO2
, σχεδόν αποκλειστικά σε ένα προϊόν υψηλής
προστιθέμενης αξίας, το CO.
Η καλά δομημένη μεθοδολογία του έργου CUDET βασίζεται σε τρεις πυλώνες (σύνθεση καταλυτών, χαρακτηρισμός
καταλυτών/ διερεύνηση του μηχανισμού της αντίδρασης και βελτιστοποίηση αντιδραστήρα) οι οποίοι είναι αλληλένδετοι
μεταξύ τους και αποτελούν μια νέα προσέγγιση, συμβάλλοντας στην επίτευξη των επιστημονικών και τεχνικών στόχων.', '2021-06-07','2024-06-07', '11', 'AUTH','2','8');


-- 3
INSERT INTO project (title, amount, summary, start_date, end_date, researcher_id, abbreviation, executive_id, program_id) VALUES
('Ο λειτουργικός ρόλος της γενωμικής αστάθειας στην ανοσολογική απόκριση κατά τη
γήρανση', '180052.04',
'Πρόσφατα αποτελέσματα στο εργαστήριο μας οδήγησαν στην ανακάλυψη της λειτουργικής σύνδεσης μεταξύ
της γενωμικής αστάθειας και της χρόνιας φλεγμονής 9, 10 αποκαλύπτοντας ότι η απόκριση σε DNA βλάβες
είναι συνδεδεμένη με την ανοσολογική απάντηση και τη χρόνια φλεγμονή κατά τη γήρανση. Ωστόσο, δεν έχει
διευκρινιστεί ποια είναι η λειτουργική σύνδεση της επιδιόρθωσης και της σηματοδότησης των DNA βλαβών με
τους μηχανισμούς της έμφυτης ανοσοαπόκρισης ή ποιος είναι ο βαθμός εξειδίκευσης των ανοσολογικών
αποκρίσεων που επάγονται από την DDR in vivo. Πειραματικές προσεγγίσεις απαιτούνται για την αποκάλυψη
των ανοσολογικών παραγόντων που συνδέουν τα μόρια-αισθητήρες των βλαβών DNA στον πυρήνα με την
έμφυτη ανοσοαπόκριση στο κυτταρόπλασμα, του τρόπου με τον οποίο η ενεργοποίηση της έμφυτης ανοσίας
από την DDR μπορεί να επηρεάσει τη βιωσιμότητα των κυττάρων ή του βαθμού που μπορούν οι μηχανισμοί
αυτοί να χρησιμοποιηθούν για τη στόχευση κυττάρων με βλάβες DNA κατά τη γήρανση ή τον καρκίνο. Η
προτεινόμενη ερευνητική πρόταση συνδυάζει τεχνολογίες αιχμής στον ποντικό με μεθόδους πρωτεομικής,
γονιδιωματικής και μεταβολομικής ανάλυσης για την διερεύνηση της λειτουργικής σύνδεσης της
συσσώρευσης γενετικών βλαβών και της έμφυτης ανοσοαπόκρισης, την μελέτη της λειτουργικής σύνδεσης
μεταξύ της απόκρισης στις DNA βλάβες και της σηματοδότησης της έμφυτης ανοσίας και την διερεύνηση του
λειτουργικού ρόλου της χρόνιας φλεγμονής επαγόμενης από τη συσσώρευση γενετικών βλαβών στη γήρανση
και την εκδήλωση ασθενειών στα θηλαστικά.', '2021-06-07','2024-06-07', '12', 'FORTH','3','6');

INSERT INTO project (title, amount, summary, start_date, end_date, researcher_id, abbreviation, executive_id, program_id) VALUES
('Μικρο- και μεσοσκοπικής κλίμακας μελέτη των νευρωνικών αλληλεπιδράσεων και δυναμικών ιδιοτήτων νευρωνικών δικτύων που διαμεσολαβούν γνωσιακές λειτουργίες. Ρόλος διακριτών προμετωπιαίων-κροταφικών κυκλωμάτων στην προσοχή και στη μνήμη.
', '180000.00',
'Μία από τις μεγαλύτερες προκλήσεις στο πεδίο των Νευροεπιστημών παραμένει η κατανόηση του πώς ο
εγκέφαλος επιτυγχάνει την ευέλικτη επικοινωνία μεταξύ νευρωνικών πληθυσμών ανάλογα με τις ανάγκες
της συμπεριφοράς. Η προσοχή αποτελεί ένα χαρακτηριστικό παράδειγμα γνωσιακής λειτουργίας η οποία
βασίζεται σε μια τέτοια δυναμική και επιλεκτική δρομολόγηση πληροφοριών, δίνοντας προτεραιότητα
στην επεξεργασία ερεθισμάτων που σχετίζονται με τη συμπεριφορά, και φιλτράροντας μη σχετικές
πληροφορίες. Πειραματικά δεδομένα υποδεικνύουν ότι ο προμετωπικός φλοιός (PFC) αποτελεί κρίσιμη
δομή του συστήματος ελέγχου της προσοχής και ότι μέσω κατωφερών σημάτων σε οπτικές περιοχές
τροποποιεί την οπτική επεξεργασία προς όφελος ερεθισμάτων σχετικών με την τρέχουσα συμπεριφορά.
Ωστόσο, ο ρόλος διακριτών προμετωπιαίων περιοχών στην προσοχή και οι μηχανισμοί που
διαμεσολαβούν την επιλεκτική επικοινωνία και επεξεργασία πληροφορίας εντός του προμετωπιαίουοπτικού δικτύου παραμένουν ασαφή. Στο συγκεκριμένο έργο θα χρησιμοποιήσουμε ηλεκτροφυσιολογικές
μεθόδους για να εξετάσουμε:
(α) εάν και πώς νευρώνες σε διαφορετικές ανατομικές υποπεριοχές του PFC και διαφορετικοί τύποι
κυττάρων επεξεργάζονται πληροφορίες σχετικά με οπτικά χαρακτηριστικά που χρησιμοποιούνται για να
κατευθύνουν την προσοχή.
(β) την επιλεκτικότητα των νευρωνικών αλληλεπιδράσεων σε τοπικό επίπεδο και μεταξύ
απομακρυσμένων πληθυσμών σε περιοχές του προμετωπιαίου και του οπτικού φλοιού σε διαφορετικές
γνωσιακές απαιτήσεις. Στόχος μας είναι να αποκαλύψουμε τους μηχανισμούς ευρείας κλίμακας
συντονισμού της δραστηριότητας στον εγκέφαλο από ανατομικά διακριτά νευρωνικά κυκλώματα ανάλογα
με την τρέχουσα συμπεριφορά.', '2021-06-07','2024-06-07', '13', 'FORTH','3','9');

INSERT INTO project (title, amount, summary, start_date, end_date, researcher_id, abbreviation, executive_id, program_id) VALUES
('Προηγμένη έρευνα της τρισδιάστατης δομής του συνυποδοχέα των Οσφρητικών υποδοχέων των κουνουπιών.', '180000.00',
'Ο κύριος στόχος του έργου 3D-ORco είναι η εις βάθος κατανόηση των κανόνων που διέπουν την αναγνώριση
των οσμογόνων μορίων από τον επτα-διαμεμβρανικό συνυποδοχέα (ORco) των οσφρητικών υποδοχέων, ο
οποίος είναι σε υψηλό βαθμό συντηρημένος μεταξύ των τάξεων των εντόμων συμπεριλαμβανομένων των
φορέων ασθενειών και των γεωργικών παρασίτων. Σημαντικότερα, το έργο 3D-ORco αναμένεται να ανοίξει το
δρόμο για την ανακάλυψη, μέσω προσεγγίσεων που βασίζονται στη δομή του ORco, νέων και
αποτελεσματικών διαταραχτών της συμπεριφοράς αναζήτησης ξενιστή προκειμένου να χρησιμοποιηθούν στην
προσπάθεια μείωσης της εξάπλωσης μολυσματικών ασθενειών που μεταδίδονται από τα έντομα, καθώς και
στον έλεγχο εντόμων γεωργικής σημασίας.', '2022-01-07','2025-01-07', '14', 'NHRF','3','13');

-- 2 KAI 3
INSERT INTO project (title, amount, summary, start_date, end_date, researcher_id, abbreviation, executive_id, program_id) VALUES
('Εφαρμογή πολυτροπικής διεπαφής για άτομα με απώλεια φωνής για την αναπαραγωγή φυσικής ομιλίας', '190000.00',
'Ο λάρυγγας είναι ένα σημαντικό όργανο καθώς εξασφαλίζει την αναπνοή και τη φώνηση. 
Η παραγωγή της φωνής γίνεται από το συντονισμό των φωνητικών χορδών κατά την εκπνοή. 
Η απώλεια φωνής αποτελεί σημαντική αναπηρία. Επηρεάζει την ικανότητα του ατόμου να επικοινωνεί, 
να εκφράζει τα συναισθήματα του, επηρεάζει τη δουλειά του. Το έργο αυτό΄στοχέυει στην δημιουργία μιας καινοτόμου 
προσωποποιημένης πολυτροπικής διεπαφής. Οι πολυτροπικές διεπαφές θα δέχονται σαν είσοδο βίντεο απο τα χείλη του χρήστη 
καθώς και τυχόν ήχους που παράγει. Μέσω της σύντηξης της πληροφορίας από τα χείλη και τους ήχους, η εφαρμογή, μετά από την 
κατάλληλη προσαρμογή του προφίλ του χρήστη και μέσω της χρήσης λεξιλογίων θα παράγει σε γραπτό κείμενο την ομιλία του χρήστη.
 Στη συνέχεια, με τη χρήση υπάρχοντων εργαλειών θα παράγεται το φωνητικό αποτέλεσμα.', '2020-06-07','2022-06-07', '15', 'IONIO','4','5');


INSERT INTO project (title, amount, summary, start_date, end_date, researcher_id, abbreviation, executive_id, program_id) VALUES
('Εγκέφαλος και αίμα: Τα αιμοπετάλια ως ρυθμιστές των νευροβλαστικών κυττάρων μέσα στις νευρογεννητικές φωλιές,
μετά από νευροεκφύλιση και κατά την επαναμυελίνωση', '190000.00',
'Ποικίλοι πληθυσμοί νευρικών βλαστικών και προγονικών κυττάρων επιβιώνουν στον ενήλικο εγκέφαλο των τρωκτικών
και των πρωτευόντων (περιλαμβανομένου του ανθρώπινου), όπως bona fide νευρικά βλαστικά κύτταρα (ΝΒΚ),
νευροβλάστες και ολιγοδενδρογλοιακά προγονικά κύτταρα (ΟΠΚ).
Σε απόκριση στον τραυματισμό, νεαρά κύτταρα γεννώνται σε βλαστοκυτταρικές φωλιές ή τοπικά στο παρέγχυμα
και στη συνέχεια στρατολογούνται στις περιοχές της βλάβης, ένα φαινόμενο που παρατηρείται ακόμα και στον
γερασμένο εγκέφαλο του ανθρώπου. Παρόλα αυτά, τόσο η δική μας δουλειά, όσο κα αυτή άλλων ερευνητών, έχει
αποκαλύψει πως η συνεισφορά των ΝΒΚ στην αναγέννηση είναι υποδεέστερη του αναμενόμενου λόγω
χωροχρονικών περιορισμών της απόκρισης τους μέσα στις φωλιές καθώς και λόγω της αυξημένης αποτυχίας των νέων
κυττάρων να επιβιώσουν και να ωριμάσουν στις περιοχές στόχους.
Επομένως, η αναγνώριση ενδογενών παραγόντων του εγκεφάλου που ρυθμίζουν την ενεργοποίηση και
επιβίωση των ΝΒΚ και των απογόνων τους αποτελεί έναν σημαντικό στόχο στην προσπάθεια
σχεδιασμού καινούριες κυτταρικές θεραπείες, ανεξαρτήτως της πηγής των βλαστικών κυττάρων
(ενδογενλη ιστο-ειδικά, εμβρυϊκά, επαγώμενα).
Η υπόθεση εργασίας μας είναι πως τα αιμοπετάλια αποτελούν έναν νέο-ανακαλυφθέντα ενδογενή
παράγοντα ελέγχου της κυτταρογεννητικής ικανότητας των ΝΒΚ και των ΟΠΚ και προτείνουμε τη
διερεύνηση αυτής της υπόθεσης με τη χρήση ενός εύρους πειραμάτων με διαγονιδιακά ζώα και μοντέλα
νευροεκφυλιστικών ασθενειών, καθώς και μέσω κυτταρικών καλλιεργειών. Επιπλέον, θα διερευνήσουμε το μοριακό
υπόβαθρο του ενδοθηλίου που βρίσκεται μέσα στη νευροβλάστική φωλιά με στόχο την επισήμανση των μοριακών
μονοπατιών που διαμεσολαβούν την αλληλεπίδραση ΝΒΚ και αιμοφόρων αγγείων. Στοχεύουμε στην παρουσίαση
πειραματικών αποδείξεων πως τα αιμοπετάλια αποτελούν έναν σημαντικό ρυθμιστή της ενδογενούς
απόκρισης των ΝΒΚ σε ποικίλα νευροεκφυλιστικά επεισόδια και να εντοπίσουμε τους μοριακούς
μηχανισμούς που ελέγχουν αυτήν τους τη δράση.', '2019-06-07','2021-06-07', '16', 'UOP','4','9');

INSERT INTO project (title, amount, summary, start_date, end_date, researcher_id, abbreviation, executive_id, program_id) VALUES

('ΜΙΚΡΟΤΕΡΟΙ Κρύσταλλοι, ΤΑΧΥΤΕΡΑ Πειράματα, ΙΣΧΥΡΟΤΕΡΕΣ Δέσμες: Καινοτόμες προσεγγίσεις για το σχεδιασμό & την παραγωγή φαρμάκων', '180000.00',
'To CrystDRUG επικεντρώνεται στο δομικό χαρακτηρισμό νανο/μικρο-κρυστάλλων πρωτεϊνών και συμπλόκων τους. Η γνώση της δομής
βιολογικών μορίων αποτελεί βασικό στοιχείο για τον επιτυχή σχεδιασμό φαρμάκων. Προς την κατεύθυνση αυτή, τα μόρια που μελετώνται
στο συγκεκριμένο πρόγραμμα είτε αποτελούν ήδη συστατικά φαρμακευτικών σκεπασμάτων για την αντιμετώπιση ασθενειών όπως ο
διαβήτης (ινσουλίνη και ανάλογα αυτής) είτε σχετίζονται με την ανάπτυξη φαρμάκων έναντι επικίνδυνων για τη δημόσια υγεία ιών. Ο
δομικός χαρακτηρισμός πρωτεϊνών πραγματοποιείται έως σήμερα κυρίως με τη χρήση της τεχνικής περίθλασης ακτίνων-Χ από
μονοκρυστάλλους (Single Crystal X-ray diffraction/SCXD). Αν και εξαιρετικά αποδοτική, η προαναφερθείσα τεχνική παρουσιάζει
αρκετούς περιορισμούς σχετικά με την ανάπτυξη ευμεγεθών κρυστάλλων και την ταυτοποίηση μεγάλου αριθμού πολύμορφων
(κρυσταλλικών και μοριακών διαμορφώσεων), ενώ συχνά, δεν είναι εφικτή η παρατήρηση και καταγραφή δυναμικών φαινομένων (time
resolved studies). Η ερευνητική δραστηριότητα της Επιστημονικής Υπευθύνου (ΕΥ) και της ερευνητική ομάδα Βιοχημείας,
Κρυσταλλογραφίας, Δομικής Βιολογίας, του Τμήματος Βιολογίας του Πανεπιστημίου Πατρών, έχει αποδείξει πως δομές πρωτεϊνών
μπορούν να εξαχθούν από νανο/μικρο-κρυστάλλους μέσω της τεχνικής περίθλασης ακτίνων-Χ από πολυκρυσταλλικά ιζήματα (X-ray
Powder Diffraction/XRPD). Η προσέγγιση αυτή επιτρέπει τη μελέτη κρυστάλλων χαμηλής ποιότητας, την άμεση ταυτοποίηση
πολυμόρφων αλλά και την παρατήρηση δυναμικών φαινομένων κατά τη διάρκεια της εξέλιξής τους. Πέραν της XRPD μεθόδου, η
ερευνητική δραστηριότητα πραγματοποιείται συνδυαστικά με μεθόδους, όπως η περίθλαση ηλεκτρονίων (Electron Diffraction) και η
κρυσταλλογραφία με την χρήση εγκαταστάσεων X-ray Free Electron Lasers. Επιπλέον, μελέτη δειγμάτων υπό μορφή διαλύματος, θα
διενεργηθούν με τη χρήση της σκέδασης ακτίνων-Χ μικρής γωνίας', '2021-08-17','2024-08-17', '17', 'UOP','4','11');

INSERT INTO project (title, amount, summary, start_date, end_date, researcher_id, abbreviation, executive_id, program_id) VALUES
('Ανάπτυξη προηγμένης τεχνολογίας με χρήση εκλεκτικών ιοντικών ηλεκτροδίων και κατάλληλο λογισμικό για υδροπονικές καλλιέργειες κηπευτικών με έμφαση στην ανακύκλωση των απορροών σε κλειστά συστήματα', '156000.00',
'Σε χώρες με υψηλό επίπεδο ανάπτυξης στον τομέα των θερμοκηπιακών καλλιεργειών, η υδροπονία αποτελεί τον κυρίαρχο τρόπο
καλλιέργειας κηπευτικών και δρεπτών ανθέων στα θερμοκήπια. Στην Ελλάδα η υδροπονική καλλιέργεια στα θερμοκήπια, αν και
παρουσιάζει αυξητικές τάσεις, δεν αναπτύσσεται με την ταχύτητα που επιβάλλει η ανάγκη διατήρησης της βιωσιμότητας του κλάδου μέσα
στο ανταγωνιστικό σύγχρονο διεθνές περιβάλλον. Σε μεγάλο βαθμό αυτό οφείλεται σε ελλείμματα τεχνογνωσίας κυρίως όσον αφορά την
θρέψη και την άρδευση των φυτών (διαχείριση θρεπτικού διαλύματος). Η διεύρυνση της εγχώριας τεχνογνωσίας και η βελτίωση του
τεχνολογικού επιπέδου των υδροπονικών εγκαταστάσεων αποτελούν επομένως τις δύο πλέον αναγκαίες προϋποθέσεις για την
περαιτέρω ανάπτυξη του κλάδου των θερμοκηπιακών καλλιεργειών στην Ελλάδα. Σε αυτή την κατεύθυνση αποσκοπεί να συμβάλλει το
NUTRISENSE. Ταυτόχρονα, ο πιο καινοτόμος στόχος του, είναι η αυτόματη συλλογή και ανακύκλωση του διαλύματος απορροής που
προκύπτει από τη λίπανση σε κλειστά υδροπονικά συστήματα χρησιμοποιώντας ειδικά σχεδιασμένο λογισμικό και επιλεκτικά ηλεκτρόδια
ιόντων που λειτουργούν σε πραγματικό χρόνο. Πιο συγκεκριμένα, το έργο αυτό έχει ως στόχο: α) τη μελέτη των θρεπτικών αναγκών
επιλεγμένων λαχανικών που δεν έχουν ακόμη μελετηθεί σε κλειστά υδροπονικά συστήματα υπό μεσογειακές κλιματικές συνθήκες β)
ανάπτυξης εξειδικευμένης τεχνολογίας για την μέτρηση της συγκέντρωσης συγκεκριμένων ιόντων στο διάλυμα απορροής και γ)
ανάπτυξη κατάλληλου λογισμικού για την αυτοματοποιημένη αναπλήρωση του διαλύματος απορροής με νερό και θρεπτικά στοιχεία,
επιτρέποντας έτσι την ανακύκλωσή του. Το λογισμικό θα βασίζεται σε ήδη υπάρχοντα μοντέλα και αλγορίθμους που έχουν αναπτυχθεί
από το Γεωπονικό Πανεπιστήμιο Αθηνών έπειτα από προσαρμογή τους για τις ανάγκες του έργου. Τα αποτελέσματα αυτής της έρευνας
αναμένεται να προωθήσουν την ανάπτυξη της εγχώριας υδροπονικής παραγωγής, καθώς θα προέρχονται από μεσογειακές κλιματικές
συνθήκες.', '2021-06-07','2024-06-07', '18', 'AUOA','5','22');

INSERT INTO project (title, amount, summary, start_date, end_date, researcher_id, abbreviation, executive_id, program_id) VALUES
('Καινοτόμες ακινητοποιημένες λειτουργικές αρχικές καλλιέργειες: Χαρακτηρισμός και
εφαρμογή στην παραγωγή νέων τροφίμων με δυνητικά ευεργετικά οφέλη
χρησιμοποιώντας αγροτικά απόβλητα', '170000.00',
'Στις μέρες μας παρατηρείται μια συνεχής αύξηση του ενδιαφέροντος για την ανάπτυξη νέων τροφίμων εμπλουτισμένων με
ευεργετικούς μικροοργανισμούς, πρεβιοτικές ίνες και πρωτεῒνες που προάγουν την ανθρώπινη υγεία, όπως την
αποκατάσταση της φυσιολογικής ισορροπίας του εντερικού μικροβιώματος σε ασθενείς με μεταβολικά νοσήματα.
Tαυτόχρονα, η ανάγκη αξιοποίησης «βιο-αποβλήτων» για παραγωγή προϊόντων υψηλής προστιθέμενης αξίας κρίνεται
επιτακτική, κυρίως λόγω των προβλημάτων που σχετίζονται με τη διαχείρισή τους, αλλά και για λόγους οικονομικής
ανάπτυξης και κυκλικής οικονομίας.
Σε αυτά τα πλαίσια, το έργο iFUNcultures αποσκοπεί στην εκμετάλλευση αγρο-βιομηχανικών αποβλήτων και υπολειμμάτων
τροφίμων ως υποστρωμάτων καλλιέργειας λειτουργικών καλλιεργειών, καθώς και ως πρώτη ύλη για την απομόνωση
πρεβιοτικών διαιτητικών ινών ή/και πρωτεϊνών που θα χρησιμοποιηθούν ως φορείς ακινητοποίησης ευεργετικών
μικροοργανισμών. Απώτερος σκοπός αποτελεί η χρήση των ακινητοποιημένων καλλιεργειών, ως λειτουργικά συστατικά,
στην ανάπτυξη καινοτόμων τροφίμων με πιθανά οφέλη για την υγεία, εστιάζοντας στη ρύθμιση του εντερικού μικροβιώματος
στον Σακχαρώδη Διαβήτη τύπου 1 (ΣΔτ1).
Οι κύριοι στόχοι του έργου είναι:
1. Η απομόνωση δυνητικά ευεργετικών μικροβιακών καλλιεργειών από ελληνικά παραδοσιακά προϊόντα και η in vitro
αξιολόγηση των λειτουργικών τους ιδιοτήτων.
2. Η μελέτη καταλληλότητας αγρο-βιομηχανικών αποβλήτων και υπολειμμάτων τροφίμων ως υποστρωμάτων για την
ανάπτυξη λειτουργικών καλλιεργειών και η απομόνωση πρεβιοτικών διαιτητικών ινών ή/και πρωτεϊνών.
3. Η ανάπτυξη τεχνολογιών για την ενσωμάτωση των ακινητοποιημένων λειτουργικών καλλιεργειών σε πρεβιοτικές
διαιτητικές ίνες ή/και απομονωμένες πρωτεΐνες από «βιο-απόβλητα» σε διάφορα τρόφιμα.
4. Η in vitro και in vivo αξιολόγηση επιβίωσης των νέων ακινητοποιημένων λειτουργικών καλλιεργειών κατά τη διέλευση
από τον γαστρεντερικό σωλήνα και προσκόλλησης στο εντερικό επιθήλιο.
5. Η αξιολόγηση της δράσης των λειτουργικών καλλιεργειών έναντι βιοφίλμ παθογόνων βακτηρίων.
6. Η in vivo μελέτη επίδρασης της διατροφικής παρέμβασης με λειτουργικά συστατικά/τρόφιμα στη ρύθμιση του εντερικού
μικροβιώματος σε υγιή και διαβητικά τύπου 1 ζωικά πρότυπα.
7. Η διαχείριση δικαιωμάτων διανοητικής ιδιοκτησίας, η ανάλυση κόστους-οφέλους, η εκπόνηση μελέτης σκοπιμότητας και
επενδυτικού σχεδίου και η μέγιστη δυνατή διάδοση/διάχυση των επιστημονικών αποτελεσμάτων.', '2021-06-07','2023-03-07', '19', 'DUOT','5','3'),

-- 2 KI 3INSERT INTO project (title, amount, summary, start_date, end_date, researcher_id, abbreviation, executive_id, program_id) VALUES

('Καινοτόμες μέθοδοι απομόνωσης και micro-nano εγκλεισμού για προσωποποιημένα θρεπτικά προϊόντα με τη χρήση 3-D εκτυπωτή τροφίμων. Ανίχνευση προϊόντων μεταβολισμού μέσω ανάλυσης του εκπνεόμενου αέρα', '170000.00',
'Η παρούσα ερευνητική πρόταση προτείνει την ανάπτυξη καινοτόμων προϊόντων διατροφής που απευθύνονται σε ειδικές
ομάδες πληθυσμού με απώτερο στόχο την προσωποποιημένη διατροφή ανάλογα με τις ανάγκες και το διατροφικό προφίλ
του καταναλωτή. Στα πλαίσια του παρόντος έργου, θα μελετηθεί μία από τις διατροφικά απαιτητικότερες ομάδες του
πληθυσμού, οι αθλούμενοι. Θα πραγματοποιηθούν διατροφικές παρεμβάσεις προκειμένου να ανιχνευθούν στον οργανισμό
των αθλουμένων τα επίπεδα των επιθυμητών ουσιών που προσλαμβάνουν μέσω των προϊόντων διατροφής. Τα προϊόντα
διατροφής που θα αναπτυχθούν θα είναι πλούσια σε πρωτεΐνες, πολυακόρεστα λιπαρά οξέα και αντιοξειδωτικές ουσίες
ώστε να βελτιωθεί η φυσική κατάσταση των αθλουμένων και να περιοριστεί σημαντικά το φαινόμενο του καθυστερημένου
μυϊκού πόνου, το οποίο είναι επακόλουθο της εντατικής άσκησης. Συγκεκριμένα ως πηγή πρωτεΐνης θα χρησιμοποιηθούν
τα παραπροϊόντα τυροκομίων για την απομόνωση της πρωτεΐνης του ορού γάλακτος. Επίσης, διάφορα στελέχη
μικροφυκών θα χρησιμοποιηθούν ως πηγή πρωτεϊνών, ωμέγα-3 πολυακόρεστων λιπαρών οξέων και αντιοξειδωτικών.
Τέλος, θα χρησιμοποιηθούν φαινολικές ενώσεις με ισχυρή αντιοξειδωτική και αντιφλεγμονώδη δράση προερχόμενες από
τα παραπροϊόντα της παραγωγής ελαιολάδου. Φιλικές προς το περιβάλλον τεχνικές εκχύλισης με ήπιους διαλύτες
κατάλληλους για χρήση σε τρόφιμα θα εφαρμοστούν για την εκχύλιση των βιοδραστικών ουσιών από τα μικροφύκη αλλά
και την απομόνωση φαινολών από τον κατσίγαρο ελαιοτριβείων. Τα παραγόμενα ολικά εκχυλίσματα, τα οποία θα είναι
πλούσια σε βιοδραστικά συστατικά, θα εγκλειστούν σε κατάλληλες φυσικές μήτρες (πρωτεΐνες, ολιγοσακχαρίτες,
πρεβιοτικά κλπ) με την τεχνική της ηλεκτροϋδροδυναμικής διεργασίας (electrospinning, electrospraying). Με την χρήση 3-
D εκτυπωτή τροφίμων θα ενταχθούν τα εγκλεισμένα βιοδραστικά συστατικά σε προϊόντα διατροφής. 3-D προιόντα θα
δοθούν σε αθλούμενους προκειμένου να προσλάβουν τα απαραίτητα θρεπτικά συστατικά Προκειμένου να ελεγχθεί η
αποδέσμευση και βιοαπορρόφηση των βιοδραστικών ουσιών στον οργανισμό των αθλουμένων θα πραγματοποιηθούν
διατροφικές παρεμβάσεις οι οποίες θα συνδέουν τον μεταβολισμό των ενώσεων στόχων με πτητικές οργανικές ενώσεις
(VOCs) του εκπνεόμενου αέρα των αθλουμένων, χρησιμοποιώντας την τεχνική TDU-GC-MS.', '2019-06-07','2022-06-07', '20', 'NTUA','6','3');

-- EP 4 3
-- id: 21
INSERT INTO project (title, amount, summary, start_date, end_date, researcher_id, abbreviation, executive_id, program_id) VALUES
('Βιομετατροπή της γλυκερόλης σε πολυακόρεστα λιπαρά οξέα υψηλού φαρμακευτικού ενδιαφέροντος', '168000.00',
'Μια σημαντική πηγή άνθρακα που παράγεται με αυξανόμενο ρυθμό είναι η ακάθαρτη γλυκερόλη, η οποία συνιστά το κύριο
παραπροϊόν ποικίλων ελαιοχημικών διεργασιών και κυρίως της διεργασίας παραγωγής βιοντήζελ. Σκοπός της παρούσας
πρότασης είναι η ανάδειξη των δυνατοτήτων αξιοποίησης του ανωτέρω υλικού προς παραγωγή μικροβιακών λιπιδίων (ΜΛ) με τη
χρήση Ζυγομυκήτων (π.χ. στελέχη των Mortierella sp., Cunninghamella echinulata, κλπ), τα οποία θα περιέχουν σπάνια και
περιζήτητα πολυακόρεστα λιπαρά οξέα φαρμακευτικού και διατροφικού ενδιαφέροντος, με σημαντικότερο εξ αυτών το γ-λινολενικό
οξύ. Θα υπάρξει εστίαση στη μετατροπή της γλυκερόλης, από επιλεγμένους Ζυγομύκητες, μέσω διεπιστημονικής προσέγγισης, η
οποία θα ξεκινά από μελέτες κατανόησης του βασικού κυτταρικού μεταβολισμού και αριστοποίησης της παραγωγής ΜΛ σε
αναδευόμενες φιάλες, καταλήγοντας σε κλιμάκωση μεγέθους σε εργαστηριακούς βιοαντιδραστήρες (έως 10,0 L). Τα παραγόμενα
λιπίδια θα μελετηθούν και αναλυθούν ενδελεχώς ως προς τη συνολική σύστασή τους σε λιπαρά οξέα, ως προς την ποσότητα και
σύσταση των ουδετέρων κλασμάτων καθώς και ως προς αυτές των πολικών κλασμάτων. Περαιτέρω, θα μελετηθεί και η βιοσύνθεση
των ενδο-κυτταρικών παραγόμενων πολυσακχαριτών. Με βάση τα πειραματικά δεδομένα τα οποία θα προκύψουν τόσο στην
καλλιέργεια στις φιάλες όσο και στους βιοαντιδραστήρες, θα αναπτυχθούν βιοκινητικά μαθηματικά πρότυπα προσομοίωσης των
διεργασιών, ενώ θα υπάρξει χημική μετατροπή των ΜΛ σε άλατα του λιθίου ή του καλίου (FALS/FAPS). Θα λάβουν χώρα μελέτες
σχετικά με τη βιολογική δραστικότητα των FAPS/FALS έναντι διαφόρων σειρών καρκινικών κυττάρων (π.χ. PC3, DU145, LNCap,
MCF-7, HL-60, κλπ). Τέλος, σε προσέγγιση βιοδιυλιστηρίου, στερεά απόβλητα βιομηχανιών παραγωγής βιοντήζελ ή/και
ελαιοχημικών διεργασιών, καθώς και τα απόνερα των καλλιεργειών που έλαβαν χώρα για την παραγωγή μυκηλιακής μάζας και ΜΛ,
θα χρησιμοποιηθούν ως υποστρώματα για παραγωγή εδωδίμων και φαρμακευτικών μυκήτων και τα μυκο-προϊόντα (π.χ. βιοενεργά μυκήλια, ενδο-κυτταρικοί πολυσακχαρίτες, κλπ) θα μελετηθούν σε βάθος. Η προηγούμενη επιτυχής συνεργασία
ακαδημαϊκών συμμετεχόντων φορέων στην πρόταση, παρέχει σημαντικά εχέγγυα επιτυχίας και στο παρόν πρόγραμμα
συνεργασίας.', '2019-07-07','2021-07-07', '21', 'AUOA','6','11');

INSERT INTO project (title, amount, summary, start_date, end_date, researcher_id, abbreviation, executive_id, program_id) VALUES

-- FIELD 4 
('Ιόμορφα σωματίδια για αυξημένη στόχευση του RNAi στα έντομα', '152000.00',
'Η RNA παρεμβολή (RNAi) αποτελεί μια πολλά υποσχόμενη νέα προσέγγιση για τον έλεγχο επιβλαβών εντόμων, η οποία στοχεύει μόνο στα έντομα-στόχους και θεωρείται πολύ ασφαλής όσον αφορά το περιβάλλον και την υγεία του ανθρώπου. Το RNAi βασίζεται στην ιδιότητα του dsRNA να προκαλεί γονιδιακή αποσιώπηση σε ομόλογους RNA-στόχους (RNA-εξαρτώμενη γονιδιακή αποσιώπηση), ενώ εξειδικευμένα dsRNA μπορούν να έχουν τοξική επίδραση όταν οι αλληλουχίες τους ταιριάζουν με τις αλληλουχίες σημαντικών κυτταρικών γονιδίων σε επιβλαβή έντομα.
Ενώ η δυνατότητα των εξειδικευμένων μορίων dsRNA να σκοτώνουν επιβλαβή έντομα έχει δειχθεί σε αρκετές περιπτώσεις, το βασικό εμπόδιο συνεχίζει να είναι η παράδοση του dsRNA στα κύτταρα του εντόμου σε επαρκή συγκέντρωση ούτως ώστε να είναι ικανό να προκαλεί αποσιώπηση σε σημαντικά γονίδια.
Η στρατηγική που επιχειρείται στο έργο προκειμένου να διεγερθεί η πρόσληψη του dsRNA από τα έντομα βασίζεται στην εγκαψιδίωσή τους σε ιόμορφα σωμάτια (VLP). Αξιοποιείται λοιπόν η συν-εξέλιξη ιών και ξενιστών, σύμφωνα με την οποία η διαδικασία πρόσληψης από τον ξενιστή έχει βελτιστοποιηθεί σε βάθος εκτεταμένων περιόδων εξελικτικού χρόνου. Μέσω του πακεταρίσματος του dsRNA εντός των VLP πιστεύεται ότι μπορούν να παραχθούν «οχήματα παράδοσης» ανώτερης ποιότητας, τα οποία θα προκαλούν εκτεταμένη γονιδιακή αποσιώπηση σε συνδυασμό με τοξικότητα.
Στο έργο θα χρησιμοποιηθεί το σύστημα έκφρασης με χρήση μπακουλοϊών ως φορέων (BEVS) προκειμένου να εκφραστούν ταυτόχρονα τα VLP και τα dsRNA, ενώ θα αξιολογηθούν οι συνθήκες για την αποτελεσματική εγκαψιδίωσή των dsRNA στα VLPs. Κατόπιν καθαρισμού των συμπλόκων dsRNA-VLP με υπερφυγοκέντρηση, αυτά θα αξιολογηθούν ως προς την πρόσληψή τους από τα κύτταρα και την ικανότητά τους να προκαλούν γονιδιακή αποσιώπηση σε κυτταρικές σειρές εντόμων αλλά και μέσω της τροφής σε προνύμφες εντόμων. Τα VLP θα βασίζονται σε ιούς που απαντώνται στη φύση και διαθέτουν γονιδίωμα dsRNA, οι οποίοι μολύνουν λεπιδόπτερα έντομα, και ο μεταξοσκώληκας (Bombyx mori) θα χρησιμοποιηθεί ως το λεπιδόπτερο πρότυπο έντομο.', 
'2021-06-07','2024-06-07', '22', 'NCSR','7','13');

-- FIELD 5
-- id: 23
INSERT INTO project (title, amount, summary, start_date, end_date, researcher_id, abbreviation, executive_id, program_id) VALUES
('Αποδοτικοί Αλγόριθμοι Ανάλυσης Δικτύων', '170000.00',
'Πολλά φυσικά και ανθρωπογενή συστήματα μπορούν να μοντελοποιηθούν ως δίκτυα, τα οποία αποτυπώνουν τόσο τη δομή όσο και τη
δυναμική του υποκείμενου συστήματος. Παραδείγματα τέτοιων συστημάτων αποτελούν ο παγκόσμιος ιστός, μεταφορικά,
τηλεπικοινωνιακά και κοινωνικά δίκτυα, βάσεις δεδομένων, βιολογικά συστήματα, κυκλώματα και ο έλεγχος ροής υπολογιστικών
προγραμμάτων. Παρά το ευρύ φάσμα εφαρμογών των μοντέλων δικτύων, υπάρχουν προβλήματα θεμελιώδους σημασίας τα οποία
εμφανίζονται σε διαφορετικούς τύπους δικτύων και ερευνητικών περιοχών.
Στον πυρήνα αυτών των πρακτικών εφαρμογών βρίσκονται βασικά προβλήματα ανάλυσης δικτύων και βελτιστοποίησης, όπως θέματα
συνεκτικότητας, συνδετικότητας, κυριαρχίας και τομών σε γραφήματα. Αλγόριθμοι και δομές δεδομένων για τόσο θεμελιώδη
προβλήματα γραφημάτων έχουν αποτελέσει αντικείμενο εκτεταμένης έρευνας για δεκαετίες. Ωστόσο, η περιοχή της αλγοριθμικής
θεωρίας γραφημάτων εξακολουθεί να προσελκύει εξαιρετικό ενδιαφέρον και να παράγει σημαντικά αποτελέσματα, τα οποία σχετίζονται
με τα παραπάνω προβλήματα. Επιπλέον κίνητρο για την προτεινόμενη μελέτη αποτελούν πρόσφατες εφαρμογές, καθώς επίσης και
νέες παραλλαγές γνωστών προβλημάτων.
Αποσκοπούμε στη μελέτη πρωτότυπων προβλημάτων καθώς και στην πρόοδο της τεχνολογίας αλγορίθμων για γνωστά προβλήματα,
από την προοπτική τόσο της θεωρίας όσο και της πράξης, σύμφωνα με τις ακόλουθες κατευθύνσεις:
- Αλγόριθμοι συνεκτικότητας και συνδετικότητας σε στατικά και δυναμικά γραφήματα.
- Συνεκτικότητα δικτύων υπό την επίδραση σφαλμάτων.
- Σχεδίαση δικτύων με ανοχή σφαλμάτων.', '2020-04-14','2023-04-14', '23', 'UOI','7','4');

INSERT INTO project (title, amount, summary, start_date, end_date, researcher_id, abbreviation, executive_id, program_id) VALUES

('Γεωμετρική Συναρτησιακή Ανάλυση και Εφαρμογές', '170500.00',
'Στόχος μας είναι η μελέτη γεωμετρικών ιδιοτήτων αντικειμένων και χώρων με νόρμα σε
μεγάλες διαστάσεις, και της ασυμπτωτικής συμπεριφοράς των ποσοτικών τους
παραμέτρων καθώς η διάσταση τείνει στο άπειρο. Εστιάζουμε σε ισχυρές μεθόδους από
την περιοχή της γεωμετρικής συναρτησιακής ανάλυσης που αλληλεπιδρούν με επιτυχία
με άλλες περιοχές, όπως η αρμονική ανάλυση, η θεωρία πιθανοτήτων και η κυρτή
γεωμετρία. Οι κύριες ερευνητικές μας κατευθύνσεις είναι οι εξής:
1. Κατανομή του όγκου σε κυρτά σώματα μεγάλης διάστασης.
2. Ανισότητες αναδιάταξης και εφαρμογές στην κυρτή γεωμετρία.
3. Πολυπλοκότητα τυχαίων 0/1 πολυτόπων.
4. Φασματική αραιοποίηση και εφαρμογές στη γεωμετρική συναρτησιακή ανάλυση.', '2020-04-20','2023-04-20', '24', 'UOA','8','14');

INSERT INTO project (title, amount, summary, start_date, end_date, researcher_id, abbreviation, executive_id, program_id) VALUES

('ΧΩΡΟΛΟΓΟΣ: Σημασιολογική Ανάλυση και Επεξεργασία Χωρο-κειμενικών Δεδομένων', '171000.00',
'Λόγω του υψηλού βαθμού υιοθέτησης υπηρεσιών διαδικτύου, κινητών τηλεφώνων εφοδιασμένων με GPS, του Διαδικτύου
Αντικειμένων (IoT) και των κοινωνικών δικτύων, ένας ολοένα αυξανόμενος πλούτος χωρικών δεδομένων με ετικέτες
(επισημειώσεις) είναι διαθέσιμος σε καθημερινή βάση. Παρόλα αυτά, οι υπάρχουσες προσεγγίσεις για επεξεργασία
επερωτήσεων σε χωρο-κειμενικά δεδομένα στηρίζονται κυρίως σε τεχνικές επακριβούς ταιριάσματος, γεγονός που φέρει
αρνητικές επιπτώσεις στην ποιότητα των αποτελεσμάτων και στην εκφραστικότητα των επερωτήσεων. Το προτεινόμενο
έργο, που ονομάζεται ΧΩΡΟΛΟΓΟΣ, στοχεύει στην προώθηση της τεχνολογικής στάθμης για επεξεργασία χωροχρονικών-κειμενικών δεδομένων, προτείνοντας ένα καινοτόμο πλαίσιο που συνδυάζει στενά την επερώτηση χωροκειμενικών και χωρο-χρονικών δεδομένων με σημασιολογική ανάκτηση, με έμφαση στη διατύπωση εκφραστικών
επερωτήσεων πέρα από ακριβές ταίριασμα, και με στόχο την ανάκτηση βάσει ομοιότητας, βάσει προτύπων και τελικά τη
σημασιολογική ανάκτηση. Κύριοι ερευνητικοί στόχοι περιλαμβάνουν τη διατύπωση νέων τύπων επερώτησης
συνδυάζουν σημασιολογικό ταίριασμα με πολύπλοκους χωρο-χρονικούς περιορισμούς, αποτελεσματικές δομές
ευρετηρίασης για από κοινού οργάνωση χωρο-χρονικών-κειμενικών δεδομένων, καινοτόμες τεχνικές φιλτραρίσματος που
περιορίζουν δραστικά το χώρο αναζήτησης, αποδοτικούς αλγόριθμους επεξεργασίας επερωτήσεων που εκμεταλλεύονται
τα υπάρχοντα ευρετήρια, και κλιμακώσιμη ανάλυση τεράστιων όγκων χωρο-κειμενικών δεδομένων με τεχνικές
παράλληλης επεξεργασίας. Τα πεδία εφαρμογής του ΧΩΡΟΛΟΓΟΣ περιλαμβάνουν: (α) επεξεργασία και ανάλυση βάσει
θέσης κοινωνικών δεδομένων, όπως tweets επισημειωμένα με χωρική πληροφορία θέσης, και (β) εμπλουτισμένα
δεδομένα τροχιών κινούμενων αντικειμένων. Με αυτό τον τρόπο, ο ΧΩΡΟΛΟΓΟΣ θα υποστηρίξει καταρχήν εφαρμογές και
υπηρεσίες που απευθύνονται σε τουρίστες, παρέχοντας ευέλικτη και εκφραστική ανάκτηση σημείων ενδιαφέροντος σε
συνδυασμό με πολύπλοκους χωρικούς, χρονικούς και κειμενικούς περιορισμούς.', '2019-04-14','2022-10-14', '25', 'UNIPI','8','15');

INSERT INTO project (title, amount, summary, start_date, end_date, researcher_id, abbreviation, executive_id, program_id) VALUES

('Μετατροπές Κλίμακας σε Στοχαστικά Συστήματα: από τις μικροσκοπικές αλληλεπιδράσεις σε μακροσκοπικά φαινόμενα', '174500.00',
'Σκοπός του έργου είναι η μοντελοποίηση και η ανάλυση πολύπλοκων συστημάτων που εμφανίζονται σε
προβλήματα που προέρχονται από τη Φυσική και από τις επιστήμες του μηχανικού.
Η εξέλιξη αυτών των συστημάτων περιγράφεται στη μικροσκοπική κλίμακα με τη βοήθεια στοχαστικών
διαδικασιών.
Στόχος μας είναι να περιγράψουμε τα φαινόμενα που αναδύονται στη μακροσκοπική κλίμακα και να
συνδέσουμε ποσοτικά τα μακροσκοπικά χαρακτηριστικά αυτών των συστημάτων με τις παραμέτρους των
μικροσκοπικών αλληλεπιδράσεων.', '2020-04-14','2023-04-14', '26', 'UOA','9','15');

INSERT INTO project (title, amount, summary, start_date, end_date, researcher_id, abbreviation, executive_id, program_id) VALUES

('Κλιμακώσιμη Απάντηση Ερωτήσεων Εκφρασμένων σε Φυσική Γλώσσα σε Μεγάλες Γεωγραφικές Βάσεις Γνώσεων', '199000.00',
'Ο στόχος του GeoQA είναι διττός:
1. H μελέτη της επέκτασης γράφων γνώσης με γεωγραφική γνώση, όπως αυτή εμπεριέχεται σε σημαντικά γεωχωρικά
σύνολα δεδομένων που διατίθενται στον Ιστό, και
2. H ανάπτυξη αποτελεσματικών (ως προς την ακρίβεια και την ανάκληση) και αποδοτικών (ως προς τον χρόνο)
τεχνικών και συστημάτων για την απάντηση πολύπλοκων ερωτήσεων πάνω σε γεωχωρικούς γράφους γνώσης.
Στο ερευνητικό έργο αυτό:
• Κατασκευάζουμε τον γράφο γνώσης YAGO2geo, επεκτείνοντας τον δημοφιλή γράφο γνώσης YAGO2 με
γεωγραφικά δεδομένα από πλήθος αξιόπιστων συνόλων γεωχωρικών δεδομένων (π.χ. Global Administrative Areas)
• Αναπτύσσουμε αποδοτικές τεχνικές και, αντίστοιχα, λογισμικό για τη συνεχή και αυτόματη ανανέωση του YAGO2geo
ακολουθώντας τις αντίστοιχες μεταβολές στα σύνολα δεδομένων.
• Δημιουργούμε ένα πρότυπο σύνολο γεωγραφικών ερωτήσεων (>1000 ερωτήσεις) σε φυσική γλώσσα με τις
απαντήσεις τους.
• Αναπτύσσουμε την μηχανή απάντησης ερωτήσεων GeoQA2, η οποία θα είναι βασισμένη σε τεχνικές επεξεργασίας
φυσικής γλώσσας καθώς και σε τεχνικές διανυσματικής αναπαράστασης των γράφων γνώσης. Η απαντήσεις θα
είναι υπό την μορφή κειμένου αλλά και εικόνας για καλύτερη διαισθητική κατανόηση.', '2020-04-14','2023-04-14', '27', 'UOA','9','15');

INSERT INTO project (title, amount, summary, start_date, end_date, researcher_id, abbreviation, executive_id, program_id) VALUES

('Νέα Υποδείγματα στα Χρηματοοικονομικά Μαθηματικά: Μοντελοποίηση, Ανάλυση, Υπολογισμός', '175000.00',
'Αυτό το έργο ασχολείται με τις σύγχρονες προκλήσεις στη μαθηματική χρηματοοικονομία, που
προκύπτουν από τις εξελίξεις της αγοράς (π.χ. την αύξηση των προσαρμογών αποτίμησης μετά τη
χρηματοπιστωτική κρίση), καθώς και τις πρόσφατες εξελίξεις στη στατιστική ανάλυση των
χρηματοοικονομικών δεδομένων, που οδήγησαν στη δημιουργία μοντέλων τραχιάς
μεταβλητότητας. Ο στόχος αυτού του έργου είναι να αναπτύξει μαθηματικές μεθόδους για τον
υπολογισμό των φραγμάτων για τις τιμές παραγώγων παρουσία αβεβαιότητας μοντέλου, την
αποτίμηση των τιμών παραγώγων σε μοντέλα τραχιάς μεταβλητότητας, την Μαρκοβιανή
αναπαράσταση κλασματικών στοχαστικών διαδικασιών και τον υπολογισμό των τιμών παρουσία
προσαρμογών αποτίμησης. ', '2019-06-07','2022-06-07', '28', 'NTUA','10','14'),

-- FIELD 6
('Εργαλεία για την Ανάλυση και Σύνθεση Ηχοτοπίων', '169758.60',
'Στόχος του έργου SOUNDSCAPES είναι η ανάπτυξη εργαλείων για τη σχεδίαση και παραγωγή ηχητικών
σκηνών, ηχητικών εφέ και ήχων υποβάθρου, επιτρέποντας έτσι τη δημιουργία εξελισσόμενων,
διαδραστικών και δυναμικά μεταβαλλόμενων ηχητικών σκηνών χωρίς περιορισμούς διάρκειας. Η
προσέγγιση του έργου SOUNDSCAPES υποστηρίζει επομένως τη σχεδίαση και επεξεργασία ηχοτοπίων,
διευκολύνει παραγωγές όπου απαιτούνται σχετικοί αυτοματισμοί και φιλοδοξεί ότι οι προκύπτουσες
ερευνητικές καινοτομίες θα μπορούν να ενσωματωθούν εύκολα σε δημοφιλή, υφιστάμενα συστήματα
επεξεργασίας και σύνθεσης ήχων. Το έργο SOUNDSCAPES απευθύνεται σε ένα ευρύ φάσμα τομέων της
δημιουργικής βιομηχανίας, επιτρέποντας, τόσο σε επαγγελματίες μηχανικούς ήχου, όσο και σε λιγότερο
έμπειρους χρήστες, να παράγουν ηχοτοπία υψηλής ποιότητας, εμπλουτισμένα με δυναμικά
χαρακτηριστικά. Κατ’ επέκταση, το έργο SOUNDSCAPES έχει τελικώς στόχο να επιτρέψει την
αποτελεσματική, υψηλής ποιότητας, σημασιολογικά εμπλουτισμένη ανάκτηση και διαχείριση ηχητικών
σκηνών και των συνιστωσών τους.', '2020-01-18','2023-01-18', '29', 'UNIPI','10','4');

INSERT INTO project (title, amount, summary, start_date, end_date, researcher_id, abbreviation, executive_id, program_id) VALUES
('Καινοτόμες μέθοδοι και δεδομένα υψηλής ποιότητας για τη μελέτη του λαϊκισμού και του Ευρωσκεπτικισμού', '146032.00',
'Το έργο DataPopEU έχει ως στόχο την ανάπτυξη καινοτόμων μεθόδων και τεχνικών για τη συλλογή,
επεξεργασία και ανάλυση μεγάλου όγκου δεδομένων υψηλής ποιότητας για τη μελέτη του λαϊκισμού και του
Ευρωσκεπτικισμού. Μέσα από διαφορετικά ερευνητικά εργαλεία και μεθόδους συλλέγουμε, επεξεργαζόμαστε
και αναλύουμε δεδομένα που προέρχονται από διαφορετικές πηγές όπως διαδικτυακές έρευνες, μέσα
κοινωνικής δικτύωσης και άρθρα του Τύπου. Οι διαφορετικές πηγές δεδομένων επιτρέπουν την πολυεπίπεδη ανάλυση των υπό εξέταση πολιτικών φαινομένων. Η υψηλή ποιότητα των δεδομένων διασφαλίζεται
μέσα από την κατάλληλη επεξεργασία και καθαρισμό έτσι ώστε να επιτρέπεται η εναρμόνισή τους όταν αυτό
απαιτείται. Ωστόσο, δεν περιοριζόμαστε μόνο στη συλλογή δεδομένων από την κοινωνία. Μεγάλο μέρος των
δεδομένων που συλλέγονται διατίθενται στην ακαδημαϊκή και ερευνητική κοινότητα ενώ τέλος η παραγόμενη
γνώση επιστρέφεται πίσω στην κοινωνία και τους πολίτες μέσα από δράσεις διάχυσης των ερευνητικών
αποτελεσμάτων. Μία τέτοια δράση είναι η δημιουργία της Πυξίδας για το Λαϊκισμό και Ευρωσκεπτικισμό
(PopEUCompass) που βασίζεται στο συνδυασμό διαφορετικών δεδομένων και πολυδιάστατων πληροφοριών.
Πρόκειται για μια προσέγγιση που δίνει έμφαση στην αλληλεπίδραση της ερευνητικής κοινότητας με την
κοινωνία με τελικό σκοπό τη διάχυση της πληροφορίας στους πολίτες, χωρίς κανένα κόστος. Η Πυξίδα, μέσα
από μια σειρά κατανοητών και απλά διατυπωμένων ερωτήσεων, στοχεύει στην ενημέρωση των πολιτών που
την χρησιμοποιούν σχετικά με τα πολιτικά φαινόμενα του Λαϊκισμού και Ευρωσκεπτικισμού. Ταυτόχρονα, η
Πυξίδα αποτελεί μία ακόμα πηγή δεδομένων καθώς οι απαντήσεις των πολιτών στις ερωτήσεις της Πυξίδας
θα αποτελέσουν καινούργια δεδομένα για την περαιτέρω μελέτη των φαινομένων αυτών.', '2019-09-04','2022-09-04', '30', 'AUTH','11','20'),


('Δημιουργική πολυγλωσσία: Από την πράξη, στην έρευνα, στην εκπαίδευση.', '150150.00',
'Η Ελλάδα ως «χώρος», σε σχέση με την προσφυγική εμπειρία, περιγράφεται άλλοτε ως «χώρος μετάβασης» και άλλοτε ως «χώρος
αναγκαστικής παραμονής». Η ποικιλότητα στον χαρακτήρα του γεωγραφικού, πολιτικού, κοινωνικού «χώρου» επηρεάζει και τον
«χώρο» της εκπαίδευσης. Τα σημεία που μένουν σταθερά στην καθημερινή ρευστότητα είναι η υποτιθέμενη «μία και μοναδική»
προσδιορισμένη ταυτότητα του πρόσφυγα, ειδικότερα όταν προστίθεται σε αυτή η έμφυλη διάσταση (βλ. για παράδειγμα Ludwig,
2016). Οι φωνές και οι ταυτότητες των γυναικών με προσφυγική εμπειρία δεν λαμβάνονται επίσημα υπόψη σε ερευνητικές και
εκπαιδευτικές διεργασίες, οι οποίες μάλιστα τις αφορούν άμεσα (Goodkind & Deacon, 2004· McPherson, 2015).
o Σκοπός του Έργου είναι ο δημιουργικός συνδυασμός διαγλωσσικών πρακτικών και δημιουργικότητας για τη δημιουργία καινοτόμων
«χώρων» μάθησης για γυναίκες με προσφυγική εμπειρία όπου θα αξιοποιούνται και θα νομιμοποιούνται οι πολυγλωσσικές και
πολυπολιτισμικές φωνές. Οι καινοτόμοι «χώροι» μάθησης θα αποτελέσουν τη μετάβαση από τον συμβατικό αριθμητισμό και
γραμματισμό σε γραμματισμούς (πολυγραμματισμούς, ψηφιακούς γραμματισμούς) που έχουν στη βάση τους εναλλακτικές γλωσσικές
πρακτικές (διαγλωσσικότητα, μίξη κωδίκων). Απώτερος σκοπός είναι οι (ψηφιακοί) «χώροι» μάθησης να μετατραπούν σε «χώρους»
νομιμοποίησης των πολυγλωσσικών και πολυπολιτισμικών γυναικείων ταυτοτήτων και γιατί όχι σε «χώρους» νέων διαδρομών
γνώσης και ζωής', '2020-04-14','2023-04-14', '31', 'DUOT','11','7');

INSERT INTO project (title, amount, summary, start_date, end_date, researcher_id, abbreviation, executive_id, program_id) VALUES
('Η προέλευση της δυναμικότητας του κράτους και οι επιπτώσεις της στις σύγχρονες οικονομίες και στην οικονομική πολιτική', '121000.00',
'Ο σκοπός της παρούσας εργασίας είναι διττός. Στο πρώτο μέρος η ανάλυση επικεντρώνεται στους ιστορικούς λόγους
που επηρέασαν την διαμόρφωση της δημοσιονομικής δυναμικότητας στις πρώτες σύγχρονες Ευρωπαϊκές χώρες. Στην
συνέχεια συγκρίνει τους δημοσιονομικούς θεσμούς που διαμορφώθηκαν στην Ελλάδα με εκείνους στις υπόλοιπες
Ευρωπαϊκές χώρες την ίδια ιστορική περίοδο. Οι χώρες στην προ-βιομηχανική εποχή βασίζονταν σε φορολογία
μεμονωμένων ιδιωτών για τη συλλογή φόρων (tax farming μεθοδολογία). Συνεπώς, η μετάβαση από το tax farming σε
ένα συγκεντρωτικό τρόπο συλλογής φόρων, προϋποθέτει την ύπαρξη σύγχρονων δημοσιονομικών θεσμών που
ευνοούν την ανάπτυξη δημοσιονομικής δυναμικότητας. Το ερώτημα επομένως που προκύπτει και θα προσπαθήσουμε
να απαντήσουμε στο πλαίσιο της παρούσας πρότασης τόσο εμπειρικά όσο και θεωρητικά, είναι γιατί η μετάβαση
πραγματοποιήθηκε σε κάποιες μόνο χώρες και όχι σε όλες. Επίσης θα αναζητήσουμε τους ιστορικούς λόγους που
προσδιορίζουν τη χρονική στιγμή της μετάβασης.', '2020-04-14','2023-04-14', '32', 'AUEB','12','10'),

('Ανιχνεύοντας τον ρατσισμό στον αντιρατσιστικό λόγο: Μια κριτική προσέγγιση στον ευρωπαϊκό δημόσιο λόγο για τη μεταναστευτική και προσφυγική κρίση', '161700.00',
'Οι μαζικές προσφυγικές και μεταναστευτικές ροές στον ευρωπαϊκό χώρο κατά τα έτη 2015-2018 και οι επακόλουθες έντονες
συζητήσεις σε παγκόσμιο επίπεδο, οδήγησαν στην ανάδυση και την κυκλοφορία ποικίλων στάσεων και πρακτικών εκ μέρους
των ευρωπαϊκών κρατών, οι οποίες κυμαίνονται από αλληλέγγυες έως ξενοφοβικές.Κύριος σκοπός του έργου
Ο εντοπισμός και η κριτική ανάδειξη των υπόρρητων μηνυμάτων που αναπαράγουν ρατσιστικές πρακτικές και
ιδεολογίες στον αντιρατσιστικό λόγο της δημόσιας σφαίρας, ο οποίος πραγματεύεται μεταναστευτικά και
προσφυγικά ζητήματα.
Η αποκάλυψη ότι οι ρατσιστικές αντιλήψεις δεν καλλιεργούνται μόνο μέσα από τον λόγο μίσους που στιγματίζει και
δαιμονοποιεί απροκάλυπτα τους μεταναστευτικούς και προσφυγικούς πληθυσμούς, αλλά και μέσα από τον
(φαινομενικά) αντιρατσιστικό λόγο, ο οποίος, ενώ έχει στόχο να καταγγείλει ρατσιστικές πρακτικές, καταλήγει να
απηχεί ανισότητες, να τις συγκαλύπτει και να τις αναπαράγει.', '2020-04-14','2023-07-14', '33', 'UOP','12','20');
-- id : 34

INSERT INTO project (title, amount, summary, start_date, end_date, researcher_id, abbreviation, executive_id, program_id) VALUES
('Ακροδεξιά Κοινωνικά Δίκτυα: Διερεύνηση του Πολιτικού & Πολιτισμικού Ακτιβισμού', '124564.00',
'Το επιστημονικό ερευνητικό έργο θα μελετήσει σε βάθος τις κοινωνικο-πολιτικές και πολιτισμικές
διαστάσεις του ακροδεξιού λόγου που εμφανίζεται την τρέχουσα περίοδο στα μέσα κοινωνικής
δικτύωσης.', '2021-12-14','2024-12-14', '34', 'EKKE','13','20'),

-- FIELD 7

('Αρχαιολογικές και γεωφυσικές έρευνες στην περαία της Σαμοθρά', '198702.00',
'Το ερευνητικό πρόγραμμα ArcGeoPerSa διερευνά θέματα αρχαιολογίας και τοπογραφίας της αιγαιακής Θράκης,
συνδυάζοντας μεθόδους από διαφορετικά επιστημονικά πεδία, όπως την Ιστορία, την Αρχαιολογία (επιφανειακή έρευνα,
μελέτη κεραμικής και ευρημάτων) και τη Γεωπληροφορική. Επίκεντρο της έρευνας είναι η περιοχή απέναντι από την
Σαμοθράκη, γνωστή και ως σαμοθρακική περαία, η οποία ορίζεται προς βορρά από τα Ζωναία όρη και την Εγνατία οδό, στα
δυτικά από το όρος ΄Ισμαρος και το ακρωτήριο Σέρρειον και στα ανατολικά από τα Δίκελλα. Τόσο η γεωμορφολογία της
περιοχής όσο και οι αρχαιολογικές ενδείξεις ποικίλλουν κατά τόπους, καθιστώντας αναγκαίο τον συνδυασμό μεθόδων
ανάλυσης: ανάλογα με τα ιδιαίτερα χαρακτηριστικά της, η κάθε θέση διερευνάται με επιφανειακή έρευνα, γεωφυσική
διασκόπηση, τηλεπισκόπηση και μελέτη ιστορικών αεροφωτογραφιών.
Στόχοι του προγράμματος είναι:
- Ο εντοπισμός εγκαταστάσεων μέσω συστηματικής έρευνας πεδίου
- Η μελέτη της κεραμικής και λοιπών ευρημάτων για να εξακριβωθεί η διαχρονικότητα της θέσης και οι εμπορικές και
πολιτισμικές επαφές της
- Η εφαρμογή μη διεισδυτικών μεθόδων στην αρχαιολογική έρευνα: οι νέες τεχνολογίες μάς βοηθούν να
ανασυγκροτήσουμε χωρικά μοντέλα σε βάθος χρόνου, ενώ η επεξεργασία των δεδομένων της γεωφυσικής και της
τηλεπισκόπησης συμβάλλουν στην κατανόηση των θέσεων στο ευρύτερο πλαίσιο γεωγραφικό και ιστορικό του Βορείου
Αιγαίου
- Η αξιοποίηση των αποτελεσμάτων για την τοπική ιστορία και αρχαιολογική έρευνα στην αιγαιακή Θράκη μέσω ενός
γόνιμου διαλόγου μεταξύ των Ανθρωπιστικών και Θετικών Επιστημών.', '2022-03-10','2024-03-10', '35', 'DUOT','14','16'),

('Η Επικινδυνότητα της Πρόβλεψης στις Φυσικές Επιστήμες: Ιστορικές και Επιστημολογικές Όψεις', '210000.00',
'Η πρόβλεψη του μέλλοντος αποτελεί μια από τις σημαντικότερες επιδιώξεις της επιστήμης, ενώ η λήψη πολιτικών
αποφάσεων βασίζεται όλο και περισσότερο στη δυνατότητα των ανθρώπων να προβλέπουν. Πολύ σημαντικό ρόλο σε
αυτήν τη δυνατότητα παίζουν οι επιστήμες, καθώς η επιστημονική γνώση αποτελεί το κυριότερο εργαλείο πρόβλεψης.
Ωστόσο, η εξαγωγή προβλέψεων από την επιστημονική γνώση είναι περίπλοκη και επισφαλής διαδικασία. Με το
ερευνητικό πρόγραμμα PYTHIA επιθυμούμε να συμβάλουμε στη συζήτηση που διεξάγεται στην ιστορία και φιλοσοφία
της επιστήμης σχετικά με την πρόβλεψη στις φυσικές επιστήμες. Η έρευνα στο πλαίσιο του PYTHIA εστιάζει σε δύο
καίρια ερωτήματα σχετικά με την πρόβλεψη: 1) Πώς γεφυρώνεται το χάσμα ανάμεσα στις επιστημονικές θεωρίες και τις
προβλέψεις συγκεκριμένων φαινομένων; 2) Τι λογίζεται ως έγκυρη και επιτυχημένη πρόβλεψη σε διαφορετικά πεδία
των φυσικών επιστημών; Η έρευνα του PYTHIA εκτείνεται σε πέντε πεδία: τη σεισμολογία, τη φυσική υψηλών
ενεργειών, την κβαντική χημεία, την περιβαλλοντική επιστήμη, και την κλασική φυσική του 19ου αιώνα. Με δεδομένη την
αυξανόμενη σημασία της πληροφορικής για τις φυσικές επιστήμες γενικώς, αλλά και για την πρόβλεψη ειδικότερα, το
πρόγραμμα PYTHIA ενσωματώνει την ιστορία και φιλοσοφία της πληροφορικής στην ιστορία και φιλοσοφία των
φυσικών επιστημών.', '2019-07-30','2020-07-30', '36', 'UOA','14','24');

INSERT INTO project (title, amount, summary, start_date, end_date, researcher_id, abbreviation, executive_id, program_id) VALUES

('Γλωσσικές και γνωστικές στρατηγικές παρέμβασης στις γλωσσικές διαταραχές', '140000.00',
'Πρόσφατες μελέτες τονίζουν τη σημασία του γνωστικού ελέγχου –κυρίως των δεξιοτήτων επίλυσης αντιμαχόμενων
ερμηνειών– στην επίλυση της αμφισημίας. Ωστόσο, η φύση αυτών των δεξιοτήτων δεν έχει διερευνηθεί επαρκώς. Επιπλέον, ο
τρόπος επίλυσης της αμφισημίας από κλινικούς πληθυσμούς δεν έχει μελετηθεί ακόμη, ενώ άγνωστο παραμένει αν η
εφαρμογή γνωστικής παρέμβασης έχει μακροπρόθεσμα οφέλη στις γλωσσικές δεξιότητες των ατόμων με γλωσσικές και/ή
γνωστικές διαταραχές.
Κύριος σκοπός του προτεινόμενου έργου είναι η διερεύνηση των μηχανισμών γνωστικού ελέγχου που καθορίζουν την
κατανόηση της γλωσσικής αμφισημίας, με έμφαση στην επίδοση κλινικών πληθυσμών με σοβαρές διαταραχές λόγου και/ή
δεξιοτήτων γνωστικού ελέγχου (δηλαδή, εκτελεστικών λειτουργιών (ΕΛ)). Στόχοι του έργου είναι: α) Να διερευνηθεί η συμβολή
των ΕΛ στην επίλυση συντακτικής αμφισημίας τόσο από τυπικούς όσο και από μη τυπικούς εφήβους και ενήλικες. β) Να
διερευνηθούν τα μακροπρόθεσμα οφέλη μιας συμπεριφορικής γνωστικής παρέμβασης στις διαφορετικές κλινικές ομάδες με
στόχο την ενίσχυση των γλωσσικών τους δεξιοτήτων.', '2020-04-14','2023-04-14', '37', 'UOA','15','17'),

-- id: 38
('Μολυβδόβουλλα στη Βυζαντινή Θράκη: Επανεξέταση των δεδομένων, χαρτογράφηση της διασποράς των ευρημάτων και ανίχνευση των δικτύων επικοινωνίας 
', '200500.00',
'Αντικείμενο έρευνας είναι τα βυζαντινά μολυβδόβουλλα ή σφραγίδες, άμεση πηγή της Βυζαντινής Ιστορίας, η αξιοποίηση
της οποίας προάγει γενικά την έρευνα και ιδιαίτερα τη μελέτη των διοικητικών και κοινωνικών δομών, της Προσωπογραφίας
και της Ιστορικής Γεωγραφίας. Μία πτυχή που συνδέεται με τη λειτουργία των σφραγίδων, που δεν έχει διερευνηθεί ακόμη,
είναι η ανίχνευση των δικτύων επικοινωνίας και διακίνησης της γραπτής πληροφορίας κατά τον Μεσαίωνα. Στο πλαίσιο του
προγράμματος, θα μελετηθούν περισσότερες από 2000 σφραγίδες για τις οποίες γνωρίζουμε το ακριβές σημείο εύρεσής
τους και οι οποίες εντοπίστηκαν στα εδάφη που αντιστοιχούν στις πρωτοβυζαντινές επαρχίες Θράκης, Αιμιμόντου, Κάτω
Μυσίας και Μικράς Σκυθίας (4
ος-6
ος αι.) και στα μεσοβυζαντινά θέματα Θράκης και Μακεδονίας (7
ος-12ος αι.). Στόχοι του
ερευνητικού προγράμματος είναι α) η εκ νέου προσέγγιση του σφραγιστικού υλικού με βάση την ορθότερη ανάγνωση και
ακριβέστερη χρονολόγηση των παραπάνω σφραγίδων β) η χαρτογραφική αποτύπωση της διασποράς τους και γ) η
ανίχνευση των δικτύων επικοινωνίας και μεταφοράς πληροφοριών στο γεωγραφικό χώρο της Βυζαντινής Θράκης κατά τη
μέση βυζαντινή περίοδο', '2020-04-14','2023-04-14', '38', 'AUTH','15','16'),


-- 8 KAI 2
('Πορώδη Μεσοσκοπικά Πλέγματα Μη-Οξειδικών Νανοσωματιδίων για Εφαρμογές Φωτοηλεκτροκαταλυτικής Μετατροπής Ενέργειας', '169983.00',
'Η παρούσα πρόταση αποσκοπεί στην ανάπτυξη και την μελέτη των φωτοηλεκτροχημικών ιδιοτήτων μεσοπορώδων πλεγμάτων από
νανοσωματίδια χαλκογονιδίου μετάλλου (TMC). TMCs, κυρίως σπινέλια όπως CdIn2S4 and NiCo2S4
, εμφανίζουν μια ηλεκτρονιακή δομή
κατάλληλη για την φωτοδιάσπαση νερού και παρουσιάζουν εξαιρετικές ιδιότητες μεταφοράς φορτίου, ικανοποιητική χημική σταθερότητα
κυρίως σε βασικό διάλυμα, και υψηλή απόκριση στην ορατή ακτινοβολία. Επίσης, θειοσπινέλια είναι μη-τοξικά και φθηνά υλικά. Αυτά τα
χαρακτηριστικά τα καθιστούν ιδιαίτερα ελκυστικά για τεχνολογικές εφαρμογές στη φωτοκατάλυση και μετατροπή ενέργειας. Σύνθετα
μεσοπορώδη πλέγματα από νανοσωματίδια χαλκογονιδίων μετάλλων και φωσφιδίων μετάλλων μετάπτωσης (TMPs) (π.χ. Ni2P και CoP)
αποτελούν επίσης σημαντικό αντικείμενο αυτής της πρότασης. Τέτοιες σύνθετες μεσοδομές αναμένεται να συνδυάζουν διακριτές
λειτουργικότητες στην ανόργανη δομή όπως υψηλό πορώδες και φωτοηλεκτροχημική δραστικότητα, οι οποίες είναι δύσκολο να ληφθούν
σε μεμονωμένα νανοσωματίδια η συμβατικά πορώδη στερεά. Πορώδη συσσωματώματα νανοσωματιδίων TMC και TMP θα μελετηθούν
ως ηλεκτρόδια σε φωτοηλεκτροχημικές κυψέλες για τη διάσπαση του νερού προς παραγωγή υδρογόνου, κάτω από ακτινοβολία ορατού,
χωρίς συνεχή προδιάθεση (bias).', '2020-01-19','2023-01-19', '39', 'UOC','16','25');

INSERT INTO project (title, amount, summary, start_date, end_date, researcher_id, abbreviation, executive_id, program_id) VALUES
-- 8 K 1
('Ατμοσφαιρικές παράμετροι που επηρεάζουν τη φασματική ηλιακή ακτινοβολία και την ηλιακή ενέργεια (ASPIRE)', '163983.60',
'Το έργο ASPIRE στοχεύει να συμβάλει στην επιστημονική γνώση διεπιστημονικών
πτυχών που σχετίζονται με την ηλιακή ακτινοβολία. Τέτοιες πτυχές αφορούν εφαρμογές
για την έρευνα και την τεχνολογία της ηλιακής ενέργειας (π.χ. φωτοβολταϊκά συστήματα),
τον αντίκτυπο στην υγεία (μελάνωμα, καρκίνος του δέρματος και αποτελεσματικότητα
βιταμίνης D) και τη γεωργία (φωτοσυνθετικά ενεργή ακτινοβολία και παραγωγή
καλλιεργειών). Τα μέσα για την επίτευξη αυτού του στόχου είναι μία εκσυγχρονισμένη
πειραματική εκστρατεία ατμοσφαιρικών παραμέτρων που θα πραγματοποιηθεί στην
πόλη της Αθήνας, με ένα μοναδικό σύνολο οργάνων και μια συνεργατική προσέγγιση
των δεδομένων που θα αποκτηθούν. Οι μετρήσεις και τα μοντέλα που σχετίζονται με την
ατμοσφαιρική σύνθεση και την ηλιακή ακτινοβολία θα συντονιστούν στο έργο ASPIRE
προκειμένου να αξιολογηθεί η επίδραση της ηλιακής ακτινοβολίας και των παραμέτρων
που την επηρεάζουν στις προαναφερθείσες εφαρμογές.', '2021-04-24','2022-08-24', '40', 'UOA','16','30'),

('Παγκόσμια ποσοτικά πρότυπα απόκρισης των βενθικών οργανισμών στην περιβαλλοντική διατάραξη', '153300.00',
'Ο στόχος αυτής της μελέτης είναι να συγκρίνει την ανοχή / ευαισθησία στην διατάραξη διαφορετικών μακροπανιδικών taxa που προέρχονται απδιαφορετικές περιοχές της Γης. Πιο συγκεκριμένα, θα επικεντρωθούμε σε κοσμοπολίτικα βενθικά taxa για να προσδιορίσουμε εάν έχουν κοινά
εξελικτικά χαρακτηριστικά σχετικά με τον οικολογικό τους ρόλο παρά τις διαφορές στην γεωγραφική τους κατανομή. Αυτά τα χαρακτηριστικά
μπορεί να εκφράζονται από την ευαισθησία και την απόκρισή τους στην διατάραξη αλλά και σε άλλα λειτουργικά χαρακτηριστικά που θα
μπορούσαν να κατηγοριοποιηθούν και να συσχετιστούν με συγκεκριμένες οικοσυστημικές λειτουργίες.', '2020-11-16','2023-11-16', '41', 'UOC','17','29'),

-- FIELD 9
-- id: 42
('Διοίκηση Ανθρώπινου Δυναμικού στις Μικρομεσαίες Επιχειρήσεις', '162559.10',
'Το έργο HRMinSMEs -Διοίκηση Ανθρώπινου Δυναμικού στις Μικρές και Μεσαίες Επιχειρήσεις, με
επιστημονικά υπεύθυνη την επίκουρη καθηγήτρια Ελεάννα Γαλανάκη, στοχεύει στη μελέτη της ΔΑΔ
στις Μ.Μ.Ε. προκειμένου να εντοπίσει και να προτείνει τις βέλτιστες πρακτικές που υποστηρίζουν
και ενισχύουν την καινοτομία και την επιχειρηματική αποδοτικότητα. Στην έρευνα, εκτός από τον
φορέα υποδοχής, Οικονομικό Πανεπιστήμιο Αθηνών (από το οποίο συμμετέχουν επίσης οι
καθηγήτριες Λήδα Παναγιωτοπούλου, Ειρήνη Βουδούρη και Ιωάννα Δεληγιάννη), συνεργάζονται
τρία Ευρωπαϊκά Πανεπιστήμια (από Ιρλανδία, Κύπρο, Η.Β) .', '2019-05-04','2022-05-04', '42', 'AUEB','17','19');

INSERT INTO project (title, amount, summary, start_date, end_date, researcher_id, abbreviation, executive_id, program_id) VALUES

('Η Συμμετοχή της Ελλάδας στα Ευρωπαϊκά Ερευνητικά Δίκτυα (1984-2018) και η Επίδρασή της στην Παραγωγή Καινοτομίας και στην Επιχειρηματικότητα Εντάσεως Γνώσης', '175907.16',
'Ο κύριος στόχος του ερευνητικού έργου NETonKIE - που υλοποιείται από το Εργαστήριο Βιομηχανικής και
Ενεργειακής Οικονομίας (ΕΒΕΟ) του ΕΜΠ - είναι:
1. να αναλύσει σε βάθος τη συμμετοχή και τον ρόλο των ελληνικών οργανισμών (επιχειρήσεων,
πανεπιστημίων, ερευνητικών κέντρων και άλλων δημόσιων οργανισμών) στα συνεργατικά ερευνητικά δίκτυα
που σχηματίζονται μέσω των χρηματοδοτούμενων από την Ευρωπαϊκή Ένωση - με ανταγωνιστικούς όρους
- ερευνητικών κοινοπραξιών (RJVs) στα 7 Προγράμματα Πλαίσιο (ΠΠ) (1984-2013) και το Πρόγραμμα
Horizon 2020 (2014-2020).
2. να διερευνήσει σε βάθος τον αντίκτυπο της σχετικής ερευνητικής δραστηριότητας στην παραγωγή
καινοτομίας και στην προώθηση της επιχειρηματικότητας έντασης γνώσης.',  '2019-06-07','2022-06-07', '43', 'NTUA','18','26');
INSERT INTO project (title, amount, summary, start_date, end_date, researcher_id, abbreviation, executive_id, program_id) VALUES
('Διοίκηση Οργανωσιακής Καινοτομίας: Μία Πολυεπίπεδη Μελέτη των
Προσδιοριστικών Παραγόντων και των Επιπτώσεων στην Απόδοση – ΔΙΚΑΙ', '153000.00',
'Ο στόχος του ερευνητικού έργου είναι να αναπτύξει ένα πρωτότυπο θεωρητικό και εμπειρικό μοντέλο της
πολυεπίπεδης φύσης της διοίκησης της οργανωσιακής καινοτομίας για την επίτευξη υψηλής απόδοσης. Αυτό είναι
εξαιρετικά σημαντικό καθώς η σχετική έρευνα και βιβλιογραφία δεν έχει εξετάσει επαρκώς το πως οι διαφορετικοί τύποι
καινοτομίας δημιουργούνται και αναδεικνύονται σε διαφορετικά επίπεδα ανάλυσης. Συγκεκριμένα το παρόν έργο:
Εστιάζει στο πώς οι οργανισμοί διαχειρίζονται την ταυτόχρονη ανάπτυξη καινοτομιών αναζήτησης (exploratory
innovation - νέα προϊόντα και υπηρεσίες που στοχεύουν να κατακτήσουν ή να δημιουργήσουν νέες αγορές) και
καινοτομιών εκμετάλλευσης (exploitative innovation - καινοτομίες που στοχεύουν στην βελτίωση υφιστάμενων
προϊόντων ή υπηρεσιών σε υπάρχουσες αγορές), φαινόμενο που ορίζεται ως αμφιδεξιότητα (ambidexterity).
Εξετάζει τη διαχείριση της οργανωσιακής καινοτομίας υιοθετώντας μια προσέγγιση πολλαπλών επιπέδων
θεωρητικής και εμπειρικής ανάλυσης (multilevel, emergent approach) που εξηγεί πως η καινοτομία εκκινεί και
δημιουργείται από τα ιδιαίτερα χαρακτηριστικά του ατόμου/εργαζομένου, διαμορφώνεται και ενισχύεται βάσει της
δυναμικής των ομάδων εργασίας ενός οργανισμού, και τελικά αναδεικνύεται ως ένα ευρύτερο φαινόμενο και
αποτέλεσμα του συνόλου του οργανισμού .
Aναλύει πως οι παράγοντες που βρίσκονται στο δια-οργανωσιακό (μεταξύ επιχειρήσεων) επίπεδο ανάλυσης (π.χ.,
στρατηγικές συμμαχίες) επηρεάζουν την αμφιδεξιότητα και την απόδοση ενός οργανισμού.', '2019-09-09','2022-09-09', '44', 'UNIPI','18','19');

-- 44 projects so far, need to fetch more esp for the companies.
-- 8
INSERT INTO project (title, amount, summary, start_date, end_date, researcher_id, abbreviation, executive_id, program_id) VALUES
('Ρύθμιση των ιδιοτήτων  νανοδομημένων καταλυτών βασισμένων σε CuZn για εφαρμογές κυψελίδων καυσίμου', '190000.00',
 'Η κύρια καινοτομία θα είναι η ανάπτυξη καταλυτών οι οποίοι θα είναι ικανοί να λειτουργούν εκλεκτικά σε
θερμοκρασίες χαμηλότερες των 200oC. Από πειραματικής άποψης, είναι απαραίτητες σημαντικές βελτιώσεις στους
καταλύτες αναμόρφωσης της μεθανόλης σε σχέση με την ενεργότητα ανά μάζα καταλύτη, ώστε να είναι λειτουργικοί
εντός της στοχευόμενης θερμοκρασιακής περιοχής (160-180oC). Οι εδραιωμένοι καταλύτες CuZnOx λειτουργούν
αποτελεσματικά σε θερμοκρασίες >210oC, κάτι το οποίο κάνει δύσκολη τη χρήση τους σε χαμηλότερες
θερμοκρασίες. Για την επίτευξη πρακτικά λειτουργικών καταλυτών αναμόρφωσης της μεθανόλης, οι στόχοι που θα
πρέπει να επιτευχθούν, είναι οι ακόλουθοι: (i) Βελτιστοποίηση των καταλυτών CuZn, (ii) Ανάπτυξη ατομικά
διασπαρμένων καταλυτών, (iii) Διευκρίνηση των μηχανιστικών μονοπατιών της διεργασίας, (iv) Επίδειξη της
λειτουργικότητας των νανοδομημένων καταλυτών CuZn σε μία κυψελίδα καυσίμου μεθανόλης.',
'2019-10-24','2022-10-24','45', 'PRGAS','19','18');

INSERT INTO project (title, amount, summary, start_date, end_date, researcher_id, abbreviation, executive_id, program_id) VALUES

-- 3
('O ρόλος της πρωτεΐνης RhoA του ενδοθηλίου στην καρκινική μετάσταση', '180000.00',
 'Οι μεταστάσεις, δηλαδή η μετανάστευση των καρκινικών κυττάρων από τον αρχικό όγκο σε
διάφορα όργανα, αποτελούν τη σημαντικότερη αιτία θανάτου σε ασθενείς με καρκίνο. Κατά τη
διάρκεια των μεταστάσεων τα καρκινικά κύτταρα πρέπει να διαπεράσουν τη μονοστοιβάδα των
ενδοθηλιακών κυττάρων, τόσο κατά την είσοδο, όσο και κατά την έξοδό τους από τα αγγεία. Σε
πολλά είδη καρκίνου έχει παρατηρηθεί αύξηση της αγγειακής διαπερατότητας στα όργανα-στόχους
για μετάσταση, πριν από την έλευση των καρκινικών κυττάρων στα όργανα αυτά. Εδώ στοχεύουμε
να ανιχνεύσουμε πώς τα καρκινικά κύτταρα επηρεάζουν την ενδοθηλιακή μονοστοιβάδα στα
όργανα-στόχους για μετάσταση, διευκολύνοντας την πραγματοποίησή της. Από προηγούμενα
αποτελέσματά μας, γνωρίζουμε ότι η μικρή GTPάση RhoA των ενδοθηλιακών κυττάρων είναι
ρυθμιστής της αγγειακής διαπερατότητας και έχουμε δεδομένα που υποστηρίζουν ότι τα καρκινικά
κύτταρα ενεργοποιούν την ενδοθηλιακή RhoA, επιτυγχάνοντας τη μετανάστευσή τους. Εδώ
προτείνουμε: α) Να ερευνήσουμε το ρόλο της ενδοθηλιακής RhoA στην μετανάστευση των
καρκινικών κυττάρων, ως αποτέλεσμα της αναστολής της ενδοθηλιακής RhoA με συστήματα
συγκαλλιέργειας in vitro και γενετικά τροποποιημένους μύες και τη χρήση αναστολέων του
μονοπατιού της RhoA in vivo, και β) να ανιχνεύσουμε εάν το μονοπάτι της RhoA ενεργοποιείται στο
ενδοθήλιο των οργάνων-στόχους για μετάσταση. Η ανάλυση των κυττάρων που προσλαμβάνουν
εξωκυτταρικά κυστίδια σε μεταγραφικό και πρωτεομικό επίπεδο θα αποκαλύψει πιθανό ρόλο της
ενδοθηλιακής RhoA στα πρώιμα μεταστατικά στάδια, καθώς και άλλους πιθανούς ρυθμιστές.
Στόχος της πρότασης είναι να αναστείλει τη μετάσταση στον καρκίνο.',
'2017-12-10','2019-12-10','46', 'MEDATH','19','27'),

-- 3

('Διερεύνηση των μεταβολικών αποκλίσεων των Τ ρυθμιστικών κυττάρων στην αυτοανοσία για θεραπευτική στόχευση', '180250.00',
 'Τα αυτοάνοσα νοσήματα (ΑΝ), είναι χρόνιες φλεγμονώδεις ασθένειες που εμφανίζονται όταν το ανοσοποιητικό σύστημα
επιτίθεται και καταστρέφει τα δικά του κύτταρα. Αποτελούν την κύρια αιτία χρόνιων ασθενειών και επηρεάζουν την υγεία του 5-
8 % του ανθρώπινου πληθυσμού. Οι σύγχρονες θεραπείες μειώνουν μόνο τα συμπτώματα των νοσημάτων αυτών χωρίς ωστόσο
να τα καταστέλλουν. Επιπρόσθετα, παρά την συνεχώς αυξανόμενη γνώση μας για τις κυτταρικές και μοριακές διαδικασίες που
ενέχονται στην παθογένεια των ΑΝ, οι πιο αποτελεσματικοί στόχοι για ανοσοθεραπεία παραμένουν άγνωστοι. Η ανάγκη για
ανακάλυψη νέων θεραπευτικών στόχων γίνεται ακόμα πιο επιτακτική, καθώς τα ποσοστά των αυτοάνοσων εκδηλώσεων
εκτοξεύτηκαν με την χρήση της ανοσοθεραπείας στον καρκίνο. Στο παρελθόν, η ομάδα μας έχει δείξει ότι τα Τ ρυθμιστικά
κύτταρα (Τρυθ) είναι απαραίτητα για την επαγωγή της ανοσολογικής ανοχής έναντι εαυτού και ότι τα ΑΝ εκδηλώνονται γιατί τα
κύτταρα αυτά δεν καταφέρνουν να καταστείλουν τις ανεξέλεγκτες αυτοάνοσες αποκρίσεις. Ωστόσο, οι παθολογικοί μηχανισμοί
που οδηγούν σε αυτή την δυσλειτουργία των Τρυθ κυττάρων παραμένουν ανεξερεύνητοι. Τα προκαταρκτικά μας αποτελέσματα
υποδηλώνουν σημαντικές μεταβολές στην μιτοχονδριακή λειτουργία και την ανοσο-κατασταλτική δράση των Τρυθ κυττάρων
τόσο σε πειραματόζωα όσο και σε ασθενείς με ΑΝ. Βασιζόμενοι στην εκτενή εμπειρία μας στο πεδίο των Τρυθ κυττάρων στα ΑΝ
και τον καρκίνο, το AutoReg προτείνει να: 1) ενσωματώσει την μεταβολική και πρωτεομική ανάλυση, με την μιτοχονδριακή
δράση των Τρυθ κυττάρων, ώστε να δημιουργήσει την υπογραφή του AutoReg, με σκοπό την ανακάλυψη νέων θεραπευτικών
στόχων, 2) στοχεύσει τις υπογραφές του AutoReg προκειμένου να αποκαταστήσει την λειτουργία των Tρυθ, μέσω καινοτόμων
διαγονιδιακών πειραματικών μοντέλων και γονιδιωματικής τροποποίησης και 3) παρέχει μια μεταφραστική χροιά μέσω της
πιστοποίησης των υπογραφών του AutoReg σε ασθενείς με ΑΝ.',
'2019-10-01','2022-10-01','47','FARMANET','20','27'),

-- 4 κ 3
-- id: 48
('Διερεύνηση των μεταβολών της γονιμοποιητικής ικανότητας του σπέρματος του
κάπρου με χρήση βιοϊατρικών τεχνικών', '150000.00',
 'Σκοπός της πρότασης είναι η ανάπτυξη, για πρώτη φορά, ενός “προγνωστικού προτύπου” της
καταλληλότητας-γονιμότητας των σπερματοδοτών κάπρων, στο ίδιο το περιβάλλον της διαβίωσής τους
(χοιροτροφική εκμετάλλευση), με μεθοδολογία που θα αξιοποιεί σύγχρονες βιοϊατρικές τεχνικές.
Το σχετικό πρωτόκολλο υλοποιείται με λεπτομερή καταγραφή και αξιολόγηση δεδομένων που σχετίζονται
αφενός με τις μεταβολές φυσιολογικών παραμέτρων του οργανισμού των κάπρων κατά την επίβαση και τη
σπερματοληψία, και αφετέρου, με την ποιότητα και τη γονιμοποιητική ικανότητα του σπέρματος.
Κάθε ανιχνεύσιμη καταπόνηση των ζώων εκτιμάται με βιοϊατρικές τεχνικές και το σπέρμα τους αξιολογείται με
τις πλέον αντικειμενικές, σύγχρονες, μεθόδους, με τελικό στόχο την ανάπτυξη “βιο-δεικτών”, αντικειμενικής
αξιολόγησης των κάπρων.',
'2019-10-24','2022-10-24','48','NITSIAK','20','13');

INSERT INTO project (title, amount, summary, start_date, end_date, researcher_id, abbreviation, executive_id, program_id) VALUES

-- 2

('ΚυβερνοΧαρτογραφίες: Ανάπτυξη Ισχυρών Πολυτροπικών Εργαλείων Γεωοπτικοποίησης για την Κατανόηση και Επικοινωνία Γεωχωρικών Δεδομένων', '186250.80',
 'Οι χάρτες δεν είναι μόνο γραμμές, σημεία και σύμβολα, διαμορφωμένα σε εικόνες. Aποτελούν ένα από τα ισχυρότερα
γνωσιακά οχήματα εξερεύνησης και περιγραφής του κόσμου, αλλά και μεταφορικής έκφρασης.
Πλέον είμαστε περισσότερο "χαρτογραφικά εγγράμματοι" από ποτέ. Η εποχή των πανταχού παρόντων εργαλείων
και εφαρμογών και των "ψηφιακών αυτοχθόνων" βρίθει ενθουσιωδών "χαρτογράφων". Ο τρόπος με τον οποίο οι άνθρωποι,
ιδιαίτερα οι νεότεροι, αλληλεπιδρούν με την τεχνολογία, η μετάβαση από τη “θέαση από ψηλά" σε οποιαδήποτε οπτική
γωνία στον χώρο, η αύξηση των γεωχωρικών δεδομένων και η ανάγκη χρήσης χαρτογραφικών μέσων για να δοθεί νόημα
στα μεγάλα δεδομένα, ορίζουν τη μετατόπιση του χαρτογραφικού παραδείγματος και της γεωοπτικοποίησης
προς την κυβερνοχαρτογραφία.
Η μετατόπιση αυτή περιλαμβάνει, μεταξύ άλλων, την ανάπτυξη μιας καινοτόμου χαρτογραφικής γλώσσας, νέων οπτικών
μεταβλητών, πολυαισθητηριακών αναπαραστάσεων, πολυτροπικών διεπαφών και εργαλείων, που θα συμβάλλουν
στην ενίσχυση των δεξιοτήτων χωρικής σκέψης των πραγματικά χωρικά εγγράμματων πολιτών.',
'2021-10-17','2022-12-17','49','TELEPR','21','15'),

-- 2

('Προτυποποίηση και Ροή Έλαστο-Ιξωδοπλαστικών Υλικών', '188000.00',
 'Η προτεινόμενη έρευνα επικεντρώνεται στην πρόβλεψη και στον έλεγχο της παραμόρφωσης και της ροής μιας
ομάδας σύνθετων υλικών άφθονων στη φύση και στη βιομηχανία, που ονομάζονται υλικά με τάση διαρροής (Yield-Stress,
YS) ή ελάστο-ιξωδο-πλαστικά (ΕVP) υλικά. Αυτά αρχίζουν να ρέουν όταν τους εφαρμόζεται επαρκής τάση, σύμφωνα με το
κριτήριο von Mises, διαφορετικά συμπεριφέρονται ως στερεά. Η απαιτούμενη τάση για την εκκίνηση της ροής τους είναι
σημαντική στην παραγωγή, αποθήκευση, μεταφορά, συσκευασία και χρήση τους. Οι συνθήκες για την ρευστοποίησή τους
και η επιφάνεια που αυτή λαμβάνει χώρα μέσα στο υλικό, η ονομαζόμενη "επιφάνεια διαρροής", παίζουν σημαντικό ρόλο
στις σχετικές διεργασίες.
Η μετρούμενη τάση διαρροής εξαρτάται από τη μέθοδο μέτρησης και τις διαφορετικές συνθήκες διεξαγωγής της.
Υπάρχει ποικιλία προσεγγίσεων για προτυποποίηση των YS υλικών σε Βιομηχανίες και Πανεπιστήμια, χωρίς γενική
συναίνεση. Συνεπώς, η πρόκληση της πρόβλεψης της ροής τους είναι σαφής καθώς οι ερευνητές επικεντρώνονται μόνο σε
συγκεκριμένο υλικό, οικογένεια υλικών ή εφαρμογή, ενώ είναι επιτακτική η θέσπιση αποτελεσματικής και σωστής
προσέγγισης ώστε να επιτύχουμε (α) ακριβή προσδιορισμό των ρεολογικών ιδιοτήτων τους, (β) ανάπτυξη ακριβέστερων
καταστατικών προτύπων, (γ) καθιέρωση κατευθυντήριων γραμμών για βέλτιστη χρήση τους, και (δ) ακριβή υπολογισμό της
παραμόρφωσης και ροής τους σε σύνθετες γεωμετρίες, λαμβάνοντας υπόψη την ασυνεχή συμπεριφορά τους στην
επιφάνεια διαρροής.
Σκοπός αυτής της έρευνας είναι η ανάπτυξη καταστατικών προτύπων για EVP υλικά και η δοκιμή τους σε ομογενείς
ρεολογικές ροές και συγκεκριμένες πρακτικές και σύνθετες ροές και διακρίνεται στα εξής: (α) Ανάπτυξη προτύπου με
ενσωμάτωση φυσικών μηχανισμών που λαμβάνουν χώρα στη μεσοκλίμακα και δοκιμή του σε απλές ροές, (β) Χρήση
υπαρχόντων και νέων EVP προτύπων σε ροές σωματιδίων και (γ) Μελέτη χρονικά μεταβαλλόμενων ροών, όπως εκτατικές
ροές και έναρξη ροής VP και EVP υλικών.',
'2019-06-24','2022-06-24','50','PLASTKR','21','28'),

-- 8 

(' Επιπτώσεις στη βιοποικιλότητα από τη μείωση των παραδοσιακών μορφών διαχείρισης γης σε ορεινές περιοχές: παρούσα κατάσταση, προβλέψεις για το μέλλον, μέτρα αντιμετώπισης', '140400.01',
 'Η εγκατάλειψη παραδοσιακών μορφών διαχείρισης γης (ΕΧΓ), ειδικά σε ορεινές ή χαμηλής παραγωγικότητας περιοχές, είναι ένα
φαινόμενο που λαμβάνει χώρα παγκοσμίως και αποτελεί την κυρίαρχη αλλαγή χρήσης γης στην Ευρώπη.
Μέχρι σήμερα, υπάρχουν αντιφατικά αποτελέσματα σχετικά με τις επιπτώσεις της ΕΧΓ στη βιοποικιλότητα και, ως εκ τούτου,
υπάρχουν και διαφορετικές εισροές για την ανάπτυξη πολιτικών για την αντιμετώπιση αυτού του ζητήματος. Σύμφωνα με ορισμένες
δημοσιεύσεις, η ΕΧΓ θεωρείται μια μοναδική ευκαιρία «για την αποκατάσταση μέρους της χαμένης βιοποικιλότητας και των
λειτουργιών του οικοσυστήματος» στην Ευρώπη, μέσω μιας διαδικασίας που καλείται “rewilding”. Από την άλλη πλευρά, υπάρχουν
άλλες έρευνες, που καταλήγουν στο συμπέρασμα ότι η ΕΧΓ έχει αρνητικές επιπτώσεις στη βιοποικιλότητα και στις λειτουργίες του
οικοσυστήματος ή ακόμη αποτελεί μια από τις σημαντικότερες απειλές για τη βιοποικιλότητα για συγκεκριμένα είδη και ενδιαιτήματα.
Ο κύριος στόχος του έργου είναι να μελετήσει τις συνέπειες της ΕΧΓ σχετικά με τις τρεις κύριες πτυχές της ποικιλότητας των
αγγειοφύτων (ταξινομική, λειτουργική και φυλογενετική) σε ορεινές περιοχές, να προβλέψει την αλλαγή αυτών των τριών πτυχών της
βιοποικιλότητας στο μέλλον με βάση σενάρια αλλαγής στις χρήσεις γης και αλλαγής του κλίματος και να δημιουργήσει σχέδια που θα
συμβάλουν στην αποτελεσματική διατήρηση των διαφορετικών πτυχών της ποικιλότητας, βάσει τόσο των παρόντων όσο και των
μελλοντικών (προβλεπόμενων) συνθηκών.
Αλλαγές στα χαρακτηριστικά της βιοποικιλότητας λόγω της ΕΧΓ συμβαίνουν ήδη σήμερα στην Ελλάδα και στην Ευρώπη και αυτό το
φαινόμενο δεν θα διαρκέσει περισσότερο από μερικές δεκαετίες για να ολοκληρωθεί. Επομένως, πρέπει άμεσα να μελετήσουμε αυτό
το φαινόμενο και να δράσουμε μέσω μέτρων και πολιτικών διατήρησης προκειμένου να διασφαλίσουμε τις καλύτερες δυνατές
προοπτικές για τη διατήρηση της βιοποικιλότητας και τη χρήση των φυσικών πόρων από τον άνθρωπο.',
'2014-11-24','2017-11-24','51','MUHALIS','22','29');

INSERT INTO project (title, amount, summary, start_date, end_date, researcher_id, abbreviation, executive_id, program_id) VALUES

-- 8 
-- id: 52
('Σχεδιασμός τεχνητών υγροτόπων για την επεξεργασία γκρι νερού σε αστικές περιοχές της Μεσογείου', '160720.00',
 'Το γκρι νερό, το νερό δηλαδή που απορρέει από τις μπανιέρες, τους νιπτήρες και τα πλυντήρια, θεωρείται
μια αναδυόμενη εναλλακτική πηγή νερού που μπορεί να επεξεργαστεί και να επαναχρησιμοποιηθεί για μη
πόσιμες χρήσεις επιτόπια σε επίπεδο πολυκατοικίας. Μεταξύ διαφορετικών τεχνολογιών επεξεργασίας τα
συστήματα τεχνητών υγροτόπων πλεονεκτούν λόγω του μικρού λειτουργικού κόστους και των μικρών
απαιτήσεων συντήρησης.
Αντικείμενο του Green4Grey είναι ο βέλτιστος σχεδιασμός τεχνητών υγροτόπων για την επεξεργασία γκρι
νερού σε αστικό περιβάλλον και ιδιαίτερα κάτω από τις κλιματικές συνθήκες της Μεσογείου. Τα συστήματα
αυτά θα σχεδιαστούν και θα λειτουργήσουν με σκοπό την αποτελεσματική απομάκρυνση ρύπων και
μικροβίων από τα γκρι νερά έτσι ώστε να μπορεί ανακτηθεί νερό για μη πόσιμες χρήσεις (καζανάκι
τουαλέτας) και ταυτόχρονα να βελτιωθεί το μικρο-κλίμα και η αισθητική των πόλεων.',
'2020-10-24','2022-10-24','52','SOYAGR','22','22'),

-- 9

('Αποτελέσματα Διάχυσης Γνώσης που σχετίζονται με την Αποτελεσματικότητα των Διαδικασιών Επιχειρηματικής Καινοτομίας και Μάθησης με την ύπαρξη Επιχειρήσεων Υψηλής Μεγέθυνσης και Τεχνολογικής Ετερογένειας', '177812.93',
 'Ο κύριος προσανατολισμός του έργου SPILEF είναι η διερεύνηση της πολύπλευρης αποτελεσματικότητας των
διαδικασιών παραγωγής γνώσης και των δραστηριοτήτων καινοτομίας των επιχειρήσεων. H έρευνα εντάσσεται στο
πλαίσιο της τεχνολογικής ετερογένειας το οποίο επιτρέπει τη συνεξέταση των αποτελεσμάτων διάχυσης. Επιπλέον,
βασικά ερευνητικά θέματα αποτελούν οι διασυνδέσεις μεταξύ της αποτελεσματικότητας των διαδικασιών καινοτομίας και
δημιουργίας γνώσης από τη μία πλευρά και της επιχειρηματικής απόδοσης από την άλλη. Το SPILEF αναπτύσσεται
γύρω από τους ακόλουθους στόχους:
- Την υλοποίηση φιλόδοξης έρευνας για την κάλυψη ερευνητικών κενών, στη βάση εμπειρικών ευρημάτων, σχετικών
με την καινοτομία, την απόδοση και την παραγωγική αποτελεσματικότητα των Μικρομεσαίων Επιχειρήσεων (ΜΜΕ)
- Τη διευκόλυνση των ΜΜΕ και των υπευθύνων χάραξης πολιτικής, να αποκτήσουν, μέσω της συμμετοχής, έγκαιρη
πρόσβαση σε μια ισχυρή βάση γνώσεων που θα διευκολύνει τον αποτελεσματικό σχεδιασμό
- Την παροχή προκλήσεων και ευκαιριών σε νέους ερευνητές να αναπτύξουν την ερευνητική τους ικανότητα και να
εργαστούν εντός της χώρας σε κρίσιμα, οικονομικά και επιχειρηματικά θέματα.',
'2019-10-24','2022-10-24','53','PENTE','23','19'),
-- 9
('Εξερευνώντας τα χαρακτηριστικά της ποιότητας των κερδών', '170000.00',
 'Το ερευνητικό έργο Q-EQUAL στοχεύει στο γνωστικό πεδίο της ποιότητας κερδών και ειδικότερα
επιχειρεί να αποδώσει, με εμπεριστατωμένο τρόπο, εμπειρικά ευρήματα αναφορικά με την
επίδραση της πραγματικής επιχειρησιακής απόδοσης, και του τρόπου που αυτή διαμορφώνεται,
στην ποιότητα των λογιστικών κερδών.
• Ο όρος ποιότητα των λογιστικών κερδών σηματοδοτεί το βαθμό στον οποίο τα δημοσιευμένα κέρδη
έχουν πληροφοριακή αξία για την πραγματική επιχειρησιακή απόδοση στο πλαίσιο ενός μοντέλου
λήψης αποφάσεων.
• Για σκοπούς μεθοδολογίας, το ερευνητικό όραμα μας θα υλοποιηθεί με τρεις παράλληλες αλλά
αλληλένδετες δράσεις που η κάθε μία θα διερευνά ένα συγκεκριμένο χαρακτηριστικό της
πραγματικής επιχειρησιακής απόδοσης και του τρόπου που αυτό επηρεάζει την ποιότητα των
λογιστικών κερδών:
(α) την ασυμμετρία κόστους,
(β) τη στρατηγική τοποθέτηση και
(γ) την ένταση επενδύσεων σε άυλα περιουσιακά στοιχεία που δεν αναγνωρίζονται στις
δημοσιευμένες οικονομικές καταστάσεις',
'2016-08-21','2018-08-21','54','SFAK','23','19');

INSERT INTO project (title, amount, summary, start_date, end_date, researcher_id, abbreviation, executive_id, program_id) VALUES

-- 9

('Ανάπτυξη συστήματος βασισμένου στη γνώση για προβλήματα αστοχίας υλικών ναυτικού ενδιαφέροντος', '147000.00',
 'Σχεδιασμός και ανάπτυξη πληροφοριακού συστήματος διαχείρισης γνώσης,
που θα καταγράφει, ταξινομεί και ανακαλεί εύκολα και γρήγορα κάθε
πληροφορία, ιστορικό λειτουργίας και συντήρησης, συζητήσεις, μελέτες,
προμηθευτές, και συντελεστές – μάρτυρες για κάθε περιστατικό αστοχίας
υλικών, εξαρτημάτων και συστημάτων σε ένα πολύπλοκο βιομηχανικό και
επιχειρησιακό περιβάλλον, όπως αυτό ενός του Στόλου. Το σύστημα με το
όνομα NAVMAT οφείλει να ενσωματώνει διαδικασίες εμπιστευτικότητας,
πιστοποίηση χρηστών και ελεγχόμενα δικαιώματα πρόσβασης με διαφορετικές
βαθμίδες ασφαλείας. Με βάση την οντολογία της αστοχίας των υλικών και με
τη χρήση αλγορίθμων τεχνητής νοημοσύνης και μοντέρνων προσεγγίσεων
στην επεξεργασία δεδομένων, επιδιώκεται η βέλτιστη διαχείριση της αστοχίας
των υλικών ναυτικού ενδιαφέροντος και η καθιέρωση διαδικασιών που
υποστηρίζουν τη λήψη αποφάσεων επίλυσης προβλημάτων, συντήρησης,
προμηθειών, εκπαίδευσης.',
'2022-02-20','2025-02-20','55','SARANT','24','28'),

-- 2
-- id: 56
('Βελτιωμένη εξόρυξη πετρελαίου με νανοσωματίδια επικαλυμμένα με πολυμερή (EOR-PNP)', '145752.02',
 'Η συνολική ανάκτηση πετρελαίου κατά την πρωτογενή και δευτερογενή εξόρυξη κυμαίνονται από 35% έως 45%
ενώ μια τριτοβάθμια μέθοδος εξόρυξης που μπορεί να ενισχύσει τον συντελεστή ανάκτησης κατά 10-30% θα
μπορούσε να συμβάλει περαιτέρω στον ενεργειακό εφοδιασμό. Η χρήση νανοσωματιδίων στις διεργασίες
βελτιωμένης ανάκτησης πετρελαίου (EOR) αποτελεί μια αναδυόμενη και πολύ ελπιδοφόρα προσέγγιση. Ο
γενικός στόχος του προτεινόμενου έργου είναι να βελτιστοποιήσει τις ιδιότητες των επικαλυμμένων με
πολυμερή νανοσωματιδίων (PNPs) προς την κινητοποίηση υπολειπόμενου πετρελαίου από πορώδεις
ταμιευτήρες υδρογονανθράκων. Νανοσωματίδια επικαλυμμένα με πολυμερή (PNP) θα συντεθούν,
σταθεροποιηθούν σε υδατικά μέσα με σύσταση παρόμοια με εκείνη της άλμης των κοιτασμάτων
υδρογονανθράκων (π.χ. υψηλή αλατότητα) και οι ιδιότητες τους θα βελτιστοποιηθούν στη κατεύθυνση της
κινητοποίησης υπολειπόμενων και παγιδευμένων γαγγλίων πετρελαίου από τον πορώδη χώρο. Με βάση τα
PNPs, θα αναπτυχθούν και θα χαρακτηρισθούν αιωρήματα, γαλακτώματα και αφροί που θα δοκιμαστούν ως
μέσα χημικής πλημμύρας σε μοντέλα πορώδη μέσα (δίκτυα πόρων χαραγμένα σε γυαλί και κλίνες άμμου) και
πυρήνες πετρωμάτων. Με βάση τα αποτελέσματα των δοκιμών, η σύνθεση και οι ιδιότητες των «έξυπνων
ρευστών» που βασίζονται στα PNPs θα διορθώνονται συνεχώς μέσω ενός σχήματος «προσαρμοστικού
ελέγχου» ώστε να επιλεγούν τα πιο αποδοτικά από τεχνική και οικονομική πλευρά ρευστά. Παράλληλα, θα
αναπτυχθεί ένας αριθμητικός εξομοιωτής της πολυφασικής ροής και μεταφοράς των «έξυπνων ρευστών» σε
ψηφιακά πορώδη μέσα, ανακατασκευασμένα από 3-διάστατες εικόνες υπολογιστικής μικρο-τομογραφίας
πετρωμάτων κοιτασμάτων. Η ανάπτυξη και βαθμονόμηση του εξομοιωτή θα γίνει σε αναφορά με αποτελέσματα
από πειράματα σε μοντέλα πορώδη μέσα, ενώ η επαλήθευση του θα πραγματοποιηθεί σε σχέση με πειράματα
σε πυρήνες πετρωμάτων.',
'2019-10-14','2022-10-28','56','PAPASTR','24','2'),

-- 2

('Επικουρικές υπηρεσίες σε ενεργά δίκτυα διανομής βασισμένες σε τεχνικές παρακολούθησης και ελέγχου', '250000',
 'Μια από τις σημαντικότερες προκλήσεις είναι η ομαλή ενσωμάτωση της ολοένα αυξανόμενης διείσδυσης των μονάδων διανεμημένης παραγωγής. Με την επίλυση
 των προβλημάτων αυτών ασχολείται το ACTIVATE, του οποίου κύριος στόχος είναι να αναπτύξει νέες επικουρικές υπηρεσίες τοσο για τους διαχειριστές του
 δικτύου μεταφοράς όσο και του δικτύου διανομής. Πιο συγκεκριμένα, το ACTIVATE προτείνει τη σχεδίαση μιας υβριδικής στρατηγικής, η οποία συνδυάζει στοιχεία κεντρικών και αποκεντρωμένων 
 τεχνικών ελεγχου, με στόχο τη βελτίωση της λειτουργικότητας του δικτύου.',
'2019-10-24','2022-10-24','57','ELKAL','25','25');

INSERT INTO project (title, amount, summary, start_date, end_date, researcher_id, abbreviation, executive_id, program_id) VALUES
-- 2

('Ευέλικτο πολυλειτουργικό τετρΆποδο Ρομπότ παντός εδάφους για Γεωργικές εφαρμΟγές ακριβείαΣ (ΑΡΓΟΣ-ARGOS)', '188000.00',
 'Τα ρομπότ με πόδια αποτελούν εξαιρετική εναλλακτική λύση στα τροχοφόρα ρομπότ για την αυτοματοποίηση σε αδόμητα περιβάλλοντα. Το σύστημα κίνησης τους επιτρέπει
 διακριτές εδράσεις κατά τη διάσχιση ανώμαλου εδάφυς ακραίων ασυνεχειών και κλίσεων. Παρά τα βήματα προόδου, πολλά προβλήματα παραμένουν και εμποδίζουν την εφαρμογή των ερευνητικών αποτελεσμάτων στη πράξη. Σε αυτό το 
 πρόγραμμα, εστιάζουμε στε θεμελιώδεις ερευνητικούς στόχους που θα επιτρέψουν την εισαγωγή ευέλικτων τετράποδων ρομπότ με δυνατότητες επιθεώρησης 
 και χειρισμών στο τομέα της Γεωργίας Ακρίβεθας. Με γνώμονα την ανάγκη για αυξημένη ποσότητα και ποίτητα γεωργικών προιόντων, ο κύριος στόχος είναι να αναπτύξουμεavgαυτόνομους βοηθούς για σημαντικές γεωργικές εργασίες.',
'2019-10-24','2022-10-24','58','PRODEA','26','12'),

-- 1

('Εφαρμογές μη-γραμμικών φαινομένων υπεριώδους κενού παλμών αττοδευτερολέπτων', '199980.00',
 'Το NEA-APS εγκαινιάζει την θεματική περιοχή των ισχυρά μη-γραμμικών φαινομένων στο υπεριώδες κενού (ΥΚ)
και στην sub-fs χρονική κλίμακα καθώς και την εφαρμογή μη γραμμικών διαδικασιών ΥΚ χαμηλότερης τάξης για τη
μελέτη της υπερ-ταχείας δυναμικής σε άτομα και μόρια. Αξιοποιεί τις πηγές ΥΚ του Εργαστηρίου Επιστήμης και
Τεχνολογίας Αττοδευτερολέπτων (AST-Lab) του ΙΤΕ-ΙΗΔΛ, προσφέροντας παγκοσμίως μοναδικές επί του παρόντος
ενέργειες παλμών ΥΚ (μερικές εκατοντάδες μJ) με διάρκεια παλμού <1fs. Υπογραμμίζει περαιτέρω την επιστημονική
προοπτική της υπό υλοποίηση Εθνικής Ερευνητικής Υποδομής HELLAS-CH αυτού του κεντρικού εργαστηρίου. Η
μελέτη ισχυρά μη γραμμικών φαινομένων στο ΥΚ περιλαμβάνει: πολλαπλό ιονισμό ευγενών αερίων μέσω
απορρόφησης πολλών φωτονίων ΥΚ, καθώς και φασματικές μετατοπίσεις (ponderomotive shifts) που προκαλούνται
από την ακτινοβολία YK και την χρήση τους π.χ. σε μια νέα προσέγγιση της μετρολογίας παλμών αττοδευτερολέπτων.
Μελέτες υπερ-ταχείας δυναμικής σε άτομα και μικρά μόρια (H2
, O2
) αφορούν επανεξετάσεις προηγούμενων πειραμάτων
EUV-pump-EUV-probe της ομάδας, εφαρμόζοντας τώρα σήμανση CEP (CEP tagging) και χρησιμοποιώντας μικρότερου
χρονικού εύρους παλμούς, επιτρέποντας έτσι την εξαγωγή επιπρόσθετης πληροφορίας, όπως η διάρκεια
απομονωμένων παλμών asec, οι συχνότητες ταλαντώσεις σύμφωνης υπέρθεσης μοριακών ηλεκτρονικών
ιδιοκαταστάσεων του Η2 και η δυναμική του συνεχούς Schumann-Runge στο O2
. Πρόσθετοι στόχοι του έργου είναι τα
συνεχή φάσματα φωτοηλεκτρονίων του άμεσου διπλού ιονισμού στο He, η δυναμική ατομικής συμφωνίας φάσης σε
ατομικά συστήματα (He και άλλα ευγενή αέρια) των καταστάσεων άρτιας ομοτιμίας, μέτρηση φάσεων αυτοιονισμού
(Fano) μέσω κβαντικών συμβολομετρικών μεθόδων με χρήση αποκλειστικά της ακτινοβολίας ΥΚ και της δυναμικής
ισομερισμού HCCH  CCHH του ακετιλενίου.',
'2018-10-06','2022-09-06','59','SOVEL','26','26'),

-- 3 

('Δημιουργία αλλογενούς και ξενογενούς καρδιάς σε χιμαιρικούς μύες', '175700.00',
 'Σθνπόο ηεο παξνύζαο εξεπλεηηθήο πξόηαζεο είλαη ε δεκηνπξγία αλλογενούς θαη ξενογενούς θαξδηάο ζε πεηξακαηόδσα-δέθηεο
(μεληζηέο). Η πξόηαζε απηή εληάζζεηαη ζην πιαίζην ελόο επξύηεξνπ ζρεδίνπ κε ηειηθό ζηόρν ηε δεκηνπξγία ζε κεγάια δώα
εθηξνθήο (για παράδειγμα ρνίρνπο), εμαηνκηθεπκέλσλ αλζξώπηλσλ νξγάλσλ από πνιπδύλακα βιαζηηθά θύηηαξα αζζελή πνπ
ρξήδεη κεηακόζρεπζεο.
Πξώηνο ζηόρνο είλαη ε αλάπηπμε κηαο γελεηηθήο ζηξαηεγηθήο γηα ηελ θαηαζθεπή αλλογενούς θαξδηάο ζε ελδνεηδηθέο ρίκαηξεο
κπώλ, κε άιια ιόγηα, γηα ηε δεκηνπξγία κπόο-μεληζηή κε θαξδηά από θύηηαξα κπόο-δόηε δηαθνξεηηθνύ γελεηηθνύ ππόβαζξνπ. Ο
γελεηηθόο ζρεδηαζκόο γίλεηαη κε ηέηνην ηξόπν ώζηε νη ρηκαηξηθνί κύεο λα έρνπλ θαξδηά απνηεινύκελε απνθιεηζηηθά θαη κόλν
από ηα θύηηαξα ηνπ δόηε, ελώ ην ππόινηπν ζώκα ζα απνηειείηαη απνθιεηζηηθά θαη κόλν από ηα θύηηαξα ηνπ μεληζηή.
Ο δεύηεξνο ζηόρνο είλαη ε δεκηνπξγία κπώλ κε ξενογενή θαξδηά, δειαδή κπώλ κε θαξδηά επίκπσλ. Αθνινπζώληαο ηελ ίδηα
ζηξαηεγηθή, αλακηγλύνληαη βιαζηνθύηηαξα κπόο θαη επίκπνο, ηα νπνία έρνπλ ηξνπνπνηεζεί γελεηηθά έηζη ώζηε ηα θύηηαξα ηνπ
επίκπνο λα ζρεκαηίζνπλ ηελ θαξδηά θαη ηα θύηηαξα ηνπ κπόο ην ππόινηπν ζώκα ηεο δηαεηδηθήο ρίκαηξαο.',
'2020-10-27','2024-10-27','60','VIANEX','27','21');

INSERT INTO project (title, amount, summary, start_date, end_date, researcher_id, abbreviation, executive_id, program_id) VALUES
-- 3
('Υδρόθειο και Καρδιοπροστασία: πηγές, σηματοδοτικά μονοπάτια και μεταφραστικές προσεγγίσεις', '174000.00',
 NULL,
'2015-08-04','2018-08-04','61','DESFA','27','21'),

-- 3
('Η φαρμακογενετική της εξοικείωσης', '179685.00',
 'Η εξοικείωση είναι μια μορφή συμπεριφορικής πλαστικότητας που επιτρέπει στα ζώα να αγνοούν
επαναλαμβανόμενα ή παρατεταμένα μη σημαντικά ερεθίσματα, η οποία πιθανώς στηρίζει την επιλεκτική
προσοχή. Η ελαττωματική εξοικείωση έχει συνδεθεί με τη σχιζοφρένεια. Παρόλο που έχουν περιγραφεί
νευρώνες και μηχανισμοί που διέπουν την εξοικείωση αισθητήριων νευρώνων, λίγα είναι γνωστά για τους
μηχανισμούς που διέπουν την εξοικείωση στο κεντρικό νευρικό σύστημα (ΚΝΣ), οι οποίοι μεσολαβούν στις
αποφάσεις να επικεντρωθούν ή να αγνοήσουν ερεθίσματα. Έχουμε αναπτύξει δύο διαφορετικές και
συμπληρωματικές μεθοδολογίες για να μελετήσουμε την εξοικείωση σε μηχανικά (ηλεκτρικό σόκ) και οσφρητικά
ερεθίσματα στην Δροσόφιλα και έχουμε ταυτοποιήσει τουλάχιστον ένα σημαντικό μετασυναπτικό νευρικό
κύκλωμα που εμπλέκεται στην αξιολόγηση τους που ονομάζεται Μισχοειδή Σωμάτια (ΜΣ) . Έχουμε
πραγματοποιήσει γενετική σάρωση για μεταλλάξεις που επηρεάζουν αυτές τις διεργασίες και έχουμε εντοπίσει
και χαρακτηρίσει μεταλλάγματα με ελλειμματική εξοικείωση, μια κατάσταση που προσομοιάζει με τη
Σχιζοφρένεια στους ανθρώπους, ως εξής: Οι σχιζοφρενείς εμφανίζουν επίσης δυσκολία στην εξοικείωση.
Δεύτερον, δείχνουμε ότι η ελλειμματική εξοικείωση των μεταλλαγμάτων της μύγας είναι αναστρέψιμος από την
Clozapine ή την Risperidone, τα τυπικά αντιψυχωτικά φάρμακα που χρησιμοποιούνται κατά τη διάρκεια των
τελευταίων 50 ετών για τη θεραπεία των σχιζοφρενικών και των οποίων οι μηχανισμοί δράσης παραμένουν
ασαφείς μέχρι σήμερα. Τέλος, μεταλλάξεις σε ορθόλογα γονίδια της μύγας με ανθρώπινα γονιδίων που έχουν
σχετιστεί με σχιζοφρένεια από μελέτες ολικού γονιδιώματος (GWAS) εμφανίζουν ελαττωματική εξοικείωση. Η
προτεινόμενη εργασία στοχεύει στην διερεύνηση των μηχανισμών που διέπουν την εξοικείωση στην Δροσόφιλα
θεωρώντας ότι τα ευρήματά μας θα είναι καταλυτικά στη κατανόηση της γενετικής αιτιολογίας ανθρώπινης
ελλειμματικής εξοικείωσης όπως η σχιζοφρένεια και του τρόπου δράσης των τυπικών αντιψυχωτικών φαρμάκων
που χρησιμοποιούνται για την αντιμετώπιση της νόσου.',
'2022-02-04','2025-07-23','62','SEP','28','11'),

-- 3

('Οι ριβοδιακόπτες ως ρυθμιστές μοριακών μηχανισμών
μικροβιακών λοιμώξεων και αντοχής σε αντιβιοτικά', '179982.02',
 'Η μικροβιακή αντοχή απoτελεί συνεχή απειλή για όλα τα συστήματα υγείας παγκοσμίως και ένα σημαντικό ζήτημα
δημόσιας υγείας το οποίο απαιτεί εντατική έρευνα και ανάδειξη νέων μοριακών στόχων και φαρμάκων. Οι ριβοδιακόπτες
είναι ρυθμιστικά μη-κωδικά μόρια RNA που ελέγχουν τη μεταγραφή ή τη μετάφραση δυναμικών γονιδιακών δικτύων, τόσο
σε παθογόνα όσο και στο ανθρώπινο μικροβίωμα. Ταυτόχρονα, αποτελούν ρυθμιστές γονιδίων που επηρεάζουν την
αντοχή των μικροβίων έναντι αντιβιοτικών και γι’αυτό είναι ιδανικοί στόχοι για νέα και ειδικά αντιβιοτικά. Πρόσφατα
περιεγράφηκε ότι ευρέως χορηγούμενα αντιβιοτικά επηρεάζουν την ρυθμιστική ικανότητα των ριβοδιακοπτών,
αποκαλύπτοντας ένα σημαντικό επίπεδο ρύθμισης, πέρα από τα ήδη γνωστά. Είναι χαρακτηριστικό ότι όλα τα σημαντικά
Gram-θετικά παθογόνα βακτήρια διαθέτουν μια ιδιαίτερη κατηγορία ριβοδιακοπτών που είναι tRNA-εξαρτώμενοι και
ονομάζονται T-boxes. Οι μοριακοί αυτοί διακόπτες δρουν ως αισθητήρες για την διαθεσιμότητα αμινοξέων και επηρεάζουν
τον ρυθμό της μεταγραφής και της μετάφρασης σημαντικών γονιδίων. Πρόσφατα, δείξαμε οι T-boxes παθογόνων
αποτελούν στόχους αντιβιοτικών επηρεάζοντας τα μεταγραφικά επίπεδα1
, ενώ μελέτες μας έδειξαν ότι είναι μοναδικοί ως
προς τη δομή τους, γεγονός που τους καθιστά ιδανικούς για το σχεδιασμό καινοτόμων και ειδο-ειδικών αντιβιοτικών.
Στην τρέχουσα μελέτη θα συνδυαστούν μεθοδολογίες αιχμής όπως η επεξεργασία γονιδιώματος και μεταγραφωμικές
αναλύσεις, με δομικές αναλύσεις και με in vitro και in vivo τεχνικές ανίχνευσης που έχουμε αναπτύξει, προκειμένου να
διερευνήσουμε το ρόλο νέων σημαντικών Τ-box ριβοδιακοπτών σε παθογόνα και σε δείγματα μικροβιώματος του
ανθρωπίνου δέρματος, με στόχο να ταυτοποιήσουμε νέους ριβοδιακόπτες που επηρεάζονται από αντιβιοτικά. Στόχος είναι
οι νέες γνώσεις για την ποικιλομορφία και τον ρόλο των βακηριακών μη-κωδικών RNAs, η περιγραφή της πρώτης
συνεκτικής εικόνας δυναμικών δικτύων αναπρογραμματισμού της γονιδιακής έκφρασης που διαμεσολαβούνται από
ριβοδακόπτες και η μελέτη της αποτελεσματικής στόχευσής τους από νέους παράγοντες',
'2019-10-24','2022-10-24','63','SEKA','28','11');



INSERT INTO project (title, amount, summary, start_date, end_date, researcher_id, abbreviation, executive_id, program_id) VALUES
('Προηγμένο μοντέλο δομικών πληροφοριών για ασφαλέστερες κατασκευές έναντι ανθρωπογενών κινδύνων', '159845.25',
 'Οι κύριοι στόχοι του έργου είναι η ανάπτυξη καινοτόμων εργαλείων για τον σχεδιασμό υποδομών, την αξιολόγηση και
διαχείριση τους έναντι MMH. Τα επιμέρους εργαλεία θα συνεργάζονται μεταξύ τους βάσει ενός μοντέλου δομικών
πληροφοριών (BIM) και θα ενσωματωθούν σε υπάρχων λογισμικό ανάλυσης/διαστασιολόγησης. Το διεπιστημονικό
πρωτόκολλο BIM που περιλαμβάνει πληροφορίες για το στατικό, μηχανολογικό, ηλεκτρικό και υδραυλικό σύστημα μιας
κατασκευής είναι το πρώτο στοιχείο που μπορεί να προσφέρει μια ενιαία πλατφόρμα για την αξιολόγηση
ανθρωπογενών κινδύνων και να θέσει τις βάσεις για τη διαδικασία σχεδιασμού. Προκειμένου να μεγιστοποιηθεί ο
αντίκτυπος των αντισταθμιστικών μέτρων που θα εφαρμοστούν στο στάδιο του σχεδιασμού ή αργότερα κατά τη
διάρκεια της λειτουργίας της κατασκευής, θα πρέπει να ληφθούν υπόψη λειτουργικές και αρχιτεκτονικά δεδομένα. Η
δεύτερη συνιστώσα θα βοηθήσει στη γρήγορη εφαρμογή ανάλυσης ρίσκου έναντι ανθρωπογενών κινδύνων υψηλής
επικινδυνότητας σε κρίσιμες υποδομές και σε «εύκολους στόχους» στο αστικό περιβάλλον, συνδυάζοντας επιτυχώς (α)
υπολογιστικά μοντέλα στην αιχμή της τεχνολογίας για την προσομοίωση φορτίων έκρηξης, κρουστικών και φωτιάς, (β)
κανονιστικά πρότυπα για προστασία της ανθρώπινης ζωής και χαρακτηριστικά του δομημένου περιβάλλοντος.',
'2020-11-25','2022-11-25','199','KETEP','27','4'),

('Ανάπτυξη βελτιστοποιημένης πλατφόρμας μη-επανδρωμένου αεροχήματος με τη
συνδυασμένη χρήση καινοτόμων τεχνολογιών αεροδυναμικής και πρόωσης ', '199673.91',
 'Ο κύριος στόχος του προγράμματος EURRICA είναι η διερεύνηση και η αξιολόγηση της συνέργειας καινοτόμων τεχνολογιών, σε μια
πλατφόρμα μέσου-μεγέθους, σταθερής-πτέρυγας Μη-Επανδρωμένου Αεροχήματος (ΜΕΑ ή UAV), γεωμετρίας ΠτέρυγαςΕνσωματωμένης-σε-Άτρακτο (BWB). Η καινοτόμα διάταξη BWB επιλέγεται ως πλατφόρμα αναφοράς λόγω της αυξημένης
αεροδυναμικής αποδοτικότητας και του μεγάλου εσωτερικού όγκου που προσφέρει. Οι ερευνητικές δραστηριότητες επικεντρώνονται σε
τρεις κατηγορίες: τις γεωμετρικές διατάξεις (π.χ. ακροπτερύγια), τις τεχνικές ελέγχου ροής (ενεργού/παθητικού) και τις τεχνολογίες
υβριδικής-ηλεκτρικής πρόωσης. Καθώς οι περισσότερες εξ αυτών δεν έχουν εξεταστεί ακόμα για εφαρμογές UAV (αριθμοί ομοιότητας),
η ανάλυση πραγματοποιείται σε χαμηλό Επίπεδο Τεχνολογικής Ετοιμότητας (TRL). Αρχικά, ορίζονται οι απαιτήσεις σχεδιασμού και
καθορίζεται η γεωμετρία της πλατφόρμας αναφοράς του BWB UAV. Κατόπιν, οι τεχνολογίες διερευνώνται και αξιολογούνται
μεμονωμένα δίνοντας έμφαση στην δυνατότητα βελτίωσης της αεροδυναμικής απόδοσης και των πτητικών επιδόσεων. Οι βέλτιστες
τεχνολογίες επιλέγονται προς ενσωμάτωση στην πλατφόρμα του BWB UAV, όπου και αξιολογούνται συνεργετικά με τη χρήση
κατάλληλων συντελεστών απόδοσης (trade factors). Ακόμα, έχει προδιαγραφεί και η ανάπτυξη ένα μοντέλο υπό κλίμακα που θα
εκτελέσει πτητικές δοκιμές, οι οποίες θα υποστηρίξουν τους υπολογισμούς της τελικής αξιολόγησης. Το σύνολο των τεχνολογιών
αξιολογείται αρχικά με χρήση της διαθέσιμης βιβλιογραφίας καθώς και εργαλείων χαμηλής ανάλυσης (low-fidelity), για την επίσπευση
των αντίστοιχων υπολογισμών. Κατά την εξέλιξη της έρευνας, καθώς μειώνεται το πλήθος των υπό μελέτη τεχνολογιών,
χρησιμοποιούνται και υπολογιστικά εργαλεία για ακριβέστερα αποτελέσματα. Τα ερευνητικά αποτελέσματα του προγράμματος
EURRICA στοχεύουν στην ωρίμανση των εξεταζόμενων τεχνολογιών για εφαρμογές UAV, οδηγώντας σε πιο αποδοτικά και αξιόπιστα
αεροχήματα που μπορούν να αξιοποιηθούν για την προστασία ανθρώπινων ζωών και υποδομών.',
'2018-09-25','2021-11-25','200','ALOUMIL','27','12'),

('Έρευνα και καινοτομία στη διαχείρηση αστικού νερού', '410000.56', NULL, '2019-06-07','2022-09-07','10','NTUA','27','12'),
('Έρευνα και καινοτομία στην υδροπληροφορική', '254000.56', NULL,  '2019-06-07','2022-09-07','10','NTUA','27','12'),
('Παραγωγή αέριων βιοκαυσίμων από αποτσίγαρα', '450600.56', NULL, '2019-06-07','2022-09-07','10','NTUA','27','12'),
('Εφαρμογές ολοκληρωμένων μαθηματικών μοντέλων στη διαχείρηση των υδατικών πόρων και του πλημμυρικού κινδύνου σε συνθήκες κλιματικής αλλαγής', '260000.56', NULL, '2019-06-07','2022-06-07','10','NTUA','25','12'),
('Υποστηρικτικές δράσεις για απογραφές αέριων του θερμοκηπίου σε εφαρμογή ευρωπαϊκής νομοθεσίας και διεθνών συμβάσεων', '260000.56', NULL, '2019-06-07','2022-06-07','10','NTUA','25','12'),
('Ίκαρος-καινοτόμος χρήση μη επανδρωμένων αεροσκαφών για την ολοκληρωμένη διαχείριση της κατάστασης,της κυκλοφορίας οχημάτων και έκτακτων περιστατικών σε οδικά δίκτυα μεταφοράς', '268000.56', NULL, '2019-06-07','2022-09-07','10','NTUA','27','12'),
('Μελέτη, σχεδίαση, κατασκευή και έλεγχος ηλεκτρικών εγκαταστάσεων χαμηλής τάσης', '260000.56', NULL, '2018-12-25','2022-11-25','10','NTUA','27','12'),
-- 72 up
('Διερεύνηση σεισμικής συμπεριφοράς και μέτρων βελτίωσης της σεισμικής απόκρισης της αναστήλωσης του ναού του πύθιου Απόλλωνα στην αρχαία ακρόπολη της Ρόδου', '260000.56', NULL, '2018-12-25','2022-11-25','20','NTUA','27','12'),
('Εργαστηριακές δοκιμές και σύνταξη τεχνικής έκθεσης με τα αποτελέσματα των δοκίμων δυο (2) μη επανδρωμένων οχημάτων αέρος (σμηεα)', '260000.56', NULL, '2018-12-25','2022-11-25','20','NTUA','27','12'),
('Τεχνικογεωλογικη και γεωτεχνική έρευνα με την εφαρμογή συγχρόνων ψηφιακών τεχνολογιών για την σταθεροποίηση των ηφαιστειακών βραχωδών πρανών Ιερας Μονής Πανάγιας Σπηλιανης, δήμου Nισυρου', '260000.56', NULL, '2018-12-25','2022-11-25','20','NTUA','27','12'),
('Βελτιστοποίηση τοπολογίας σε εναλλάκτες θερμότητας ΙΙ', '260000.56', NULL, '2018-12-25','2022-11-25','43','NTUA','27','12'),
('Αξιοποίηση σπορών τομάτας από βιομηχανικά παραπροϊόντα επεξεργασίας τομάτας για την παραλαβή ελαίου', '260000.56', NULL, '2018-12-25','2022-11-25','43','NTUA','27','12'),
('Δοκιμες πιστοποιησης ηλεκτρονικου / ηλεκτρολογικου εξοπλισμου και εγκαταστασεων', '260000.56', NULL, '2018-12-25','2022-11-25','43','NTUA','20','12'),
('Σύστημα ποιοτικου και ποσοτικου ελεγχου υγρων καυσιμων που διακινουνται απο το δικτυο πρατηριων εκο και βπ 2022-2024', '260000.56', NULL, '2018-12-25','2022-11-25','43','NTUA','20','12'),
('Δημιουργια τεύχους οδηγιων σχεδιασμου και μεθοδολογιας στρατηγικης αναπτυξης περιπατητικων και ποδηλατικων υποδομων στην περιφερεια θεσσαλιας και εμφαση στην περιφερειακη ενοτητα τρικαλων και τα μετεωρα', '260000.56', NULL, '2018-12-25','2022-11-25','43','NTUA','20','12'),
('Ταυτοποίηση ποικιλιων αμπελου των ιονιων νησων', '260000.56', NULL, '2018-12-25','2022-11-25','43','NTUA','21','12');
INSERT INTO FieldProject (project_id, field_id) VALUES
('1','1'),
('2','1'),
('3','1'),
('4','1'),
('5','1'),
('5','6'),
('6','1'),
('6','8'),
('7','2'),
('8','2'),
('9','2'),
('10','2'),
('11','2'),
('11','1'),
('12','3'),
('13','3'),
('14','3'),
('15','3'),
('15','2'),
('16','3'),
('17','3'),
('18','3'),
('19','3'),
('20','3'),
('20','2'),
('21','3'),
('21','4'),
('22','4'),
('23','5'),
('24','5'),
('25','5'),
('26','5'),
('27','5'),
('28','5'),
('29','6'),
('30','6'),
('31','6'),
('32','6'),
('33','6'),
('34','6'),
('35','7'),
('36','7'),
('37','7'),
('38','7'),
('39','8'),
('39','1'),
('40','8'),
('40','1'),
('41','9'),
('42','9'),
('43','9'),
('44','9'),
('45','8'),
('46','3'),
('47','3'),
('48','3'),
('48','4'),
('49','2'),
('50','2'),
('51','8'),
('52','8'),
('53','9'),
('54','9'),
('55','9'),
('56','2'),
('57','2'),
('58','2'),
('59','1'),
('60','3'),
('61','3'),
('62','3'),
('63','3'),
('64','2'),
('65','2'),
('66','2'),
('66','8'),
('67','5'),
('67','8'),
('68','2'),
('68','8'),
('69','5'),
('69','8'),
('70','8'),
('71','2'),
('72','2'),

('73','1'),
('74','2'),
('75','1'),
('76','2'),
('77','4'),
('78','2'),
('79','8'),
('80','2'),
('81','4');


INSERT INTO `evaluates` (`project_id`, `researcher_id`, `rating`, `eval_date`) VALUES
(1, 65, 'A', '2020-04-14'),
(2, 58, 'B', '2020-01-23'),
(3, 126, 'A', '2021-03-31'),
(4, 136, 'A', '2019-03-26'),
(5, 91, 'B', '2021-03-16'),
(6, 162, 'B', '2017-06-02'),
(7, 124, 'B', '2015-04-02'),
(8, 131, 'B', '2021-04-09'),
(9, 192, 'A', '2021-03-10'),
(10, 96, 'B', '2019-04-22'),
(11, 191, 'B', '2021-03-17'),
(12, 16, 'B', '2021-05-03'),
(13, 196, 'A', '2021-03-25'),
(14, 7, 'B', '2021-10-20'),
(15, 153, 'A', '2020-03-12'),
(16, 162, 'A', '2019-04-01'),
(17, 13, 'B', '2021-07-09'),
(18, 23, 'B', '2021-03-21'),
(19, 14, 'B', '2021-04-24'),
(20, 187, 'A', '2019-03-13'),
(21, 72, 'B', '2019-05-14'),
(22, 48, 'A', '2021-03-24'),
(23, 86, 'B', '2020-02-04'),
(24, 198, 'B', '2020-03-22'),
(25, 38, 'A', '2019-03-27'),
(26, 29, 'A', '2020-01-16'),
(27, 71, 'B', '2020-03-07'),
(28, 127, 'A', '2019-05-24'),
(29, 73, 'A', '2019-10-31'),
(30, 182, 'A', '2019-08-01'),
(31, 194, 'A', '2020-02-22'),
(32, 170, 'A', '2020-01-19'),
(33, 15, 'B', '2020-01-25'),
(34, 155, 'B', '2021-11-18'),
(35, 156, 'B', '2022-01-20'),
(36, 12, 'B', '2019-05-18'),
(37, 42, 'A', '2020-02-20'),
(38, 141, 'A', '2020-03-04'),
(39, 76, 'A', '2019-12-03'),
(40, 80, 'A', '2021-04-06'),
(41, 22, 'A', '2020-10-02'),
(42, 16, 'B', '2019-02-07'),
(43, 24, 'A', '2019-04-27'),
(44, 102, 'B', '2019-06-10'),
(45, 173, 'B', '2019-07-25'),
(46, 132, 'A', '2017-09-21'),
(47, 117, 'A', '2019-08-15'),
(48, 20, 'A', '2019-09-21'),
(49, 186, 'B', '2021-09-17'),
(50, 148, 'A', '2019-06-07'),
(51, 147, 'A', '2014-09-15'),
(52, 167, 'B', '2020-09-21'),
(53, 97, 'B', '2019-08-18'),
(54, 3, 'A', '2016-07-10'),
(55, 27, 'B', '2022-01-02'),
(56, 11, 'A', '2019-09-30'),
(57, 1, 'A', '2019-09-10'),
(58, 40, 'B', '2019-09-16'),
(59, 89, 'A', '2018-09-21'),
(60, 15, 'B', '2020-10-02'),
(61, 89, 'B', '2015-05-09'),
(62, 13, 'B', '2022-01-12'),
(63, 176, 'A', '2019-09-14'),
(64, 148, 'A', '2020-09-05'),
(65, 183, 'B', '2018-09-13'),
(66, 155, 'B', '2019-04-03'),
(67, 82, 'B', '2019-05-23'),
(68, 7, 'A', '2019-05-11'),
(69, 127, 'A', '2019-04-23'),
(70, 193, 'B', '2019-03-30'),
(71, 141, 'B', '2019-03-15'),
(72, 139, 'B', '2018-08-06'),
(73, 107, 'B', '2018-07-12'),
(74, 36, 'A', '2018-07-25'),
(75, 15, 'B', '2018-09-09'),
(76, 175, 'A', '2018-08-27'),
(77, 48, 'B', '2018-09-03'),
(78, 126, 'A', '2018-07-19'),
(79, 196, 'A', '2018-06-25'),
(80, 27, 'A', '2018-09-07'),
(81, 162, 'A', '2018-09-10');


INSERT INTO WorksOn (researcher_id, project_id) VALUES 
('1', '1'),
('2', '2'),
('3', '3'),
('4', '4'),
('5', '5'),
('6', '6'),
('7', '7'),
('8', '8'),
('9', '9'),
('10', '10'),
('11', '11'),
('12', '12'),
('13', '13'),
('14', '14'),
('15', '15'),
('16', '16'),
('17', '17'),
('18', '18'),
('19', '19'),
('20', '20'),
('21', '21'),
('22', '22'),
('23', '23'),
('24', '24'),
('25', '25'),
('26', '26'),
('27', '27'),
('28', '28'),
('29', '29'),
('30', '30'),
('31', '31'),
('32', '32'),
('33', '33'),
('34', '34'),
('35', '35'),
('36', '36'),
('37', '37'),
('38', '38'),
('39', '39'),
('40', '40'),
('41', '41'),
('42', '42'),
('43', '43'),
('44', '44'),
('45', '45'),
('46', '46'),
('47', '47'),
('48', '48'),
('49', '49'),
('50', '50'),
('51', '51'),
('52', '52'),
('53', '53'),
('54', '54'),
('55', '55'),
('56', '56'),
('57', '57'),
('58', '58'),
('59', '59'),
('60', '60'),
('61', '61'),
('62', '62'),
('63', '63'),
-- NEW
('199', '64'),
('200', '65'),
('10', '66'),
('10', '67'),
('10', '68'),
('10', '69'),
('10', '70'),
('10', '71'),
('10', '72'),
('20', '73'),
('20', '74'),
('20', '75'),
('43', '76'),
('43', '77'),
('43', '78'),
('43', '79'),
('43', '80'),
('43', '81'),

('64', '1'), 
('65', '46'),
('66', '22'),
('67', '45'),
('68', '46'),
('69', '18'),
('69', '21'),
('70', '4'),
('70', '5'),
('71', '51'),
('72', '8'),
('73', '39'),
('74', '41'),
('75', '61'),
('76', '57'),
('77', '64'),
('78', '22'),
('79', '62'),
('80', '59'),
('81', '19'),
('82', '51'),
('83', '14'),
('84', '47'),
('85', '64'),
('86', '16'),
('86', '17'),
('87', '53'),
('88', '45'),
('89', '45'),
('90', '49'),
('91', '58'),
('92', '62'),
('93', '10'),
('93', '20'),
('94', '61'),
('95', '7'),
('96', '50'),
('97', '54'),
('98', '53'),
('99', '63'),
('100', '20'),
('101', '8'),
('102', '59'),
('103', '49'),
('104', '56'),
('105', '47'),
('106', '28'),
('107', '51'),
('108', '15'),
('109', '62'),
('110', '25'),
('111', '52'),
('112', '34'),
('113', '9'),
('113', '11'),
('114', '33'),
('115', '48'),
('116', '45'),
('117', '53'),
('118', '51'),
('119', '52'),
('120', '61'),
('121', '51'),
('122', '55'),
('123', '57'),
('124', '59'),
('125', '48'),
('126', '56'),
('127', '29'),
('128', '14'),
('129', '57'),
('130', '59'),
('131', '39'),
('132', '57'),
('133', '52'),
('134', '50'),
('135', '14'),
('136', '34'),
('137', '47'),
('138', '55'),
('139', '62'),
('140', '51'),
('141', '64'),
('142', '64'),
('143', '56'),
('144', '5'),
('145', '61'),
('146', '47'),
('147', '65'),
('148', '53'),
('149', '62'),
('150', '8'),
('151', '28'),
('152', '31'),
('153', '63'),
('154', '64'),
('155', '51'),

('156', '34'),
('157', '8'),
('158', '56'),
('159', '32'),
('160', '41'),
('161', '14'),
('162', '53'),
('163', '43'),
('164', '53'),
('165', '48'),
('166', '57'),
('167', '64'),
('168', '15');
INSERT INTO WorksOn (researcher_id, project_id) VALUES 
('169', '60'),
('170', '14'),
('171', '10'),
('172', '20'),
('173', '23'),
('174', '50'),
('175', '33'),
('176', '12'),
('177', '3'),
('177', '40'),
('177', '27'),
('177', '37'),
('177', '24'),
('177', '26'),
('178', '51'),
('179', '64'),
('180', '62'),
('181', '5'),
('182', '49'),
('183', '14'),
('184', '6'),
('184', '40'),
('185', '51'),
('186', '58'),
('187', '54'),
('188', '35'),
('189', '1'),
('190', '47'),
('191', '8'),
('192', '13'),
('193', '24'),
('193', '3'),
('193', '6'),
('193', '40'),
('193', '36'),
('193', '27'),
('193', '37'),
('194', '41'),
('195', '45'),
('196', '14'),
('197', '37'),
('198', '30');

INSERT INTO deliverable (deliverable_id, summary, project_id) VALUES
('Οριστικοποίηση της προτεινόμενης μεθοδολογίας', 
'Το 1ο Παραδοτέο αποτελεί την «Οριστικοποίηση της προτεινόμενης μεθοδολογίας» του έργου και περιλαμβάνει την ανάπτυξη της πλήρους μεθοδολογίας με επιμέρους επεξηγηματικές ενότητες σε κύρια σημεία του προτεινόμενου σχεδιασμού όπως:  Αποσαφήνιση και οριοθέτηση του αντικειμένου της αξιολόγησης. Μέθοδοι και Εργαλεία αξιολόγησης,  Κριτήρια Αξιολόγησης. Αξιολογικά Ερωτήματα και Δείκτες. Σχεδιασμός Ερευνών Πεδίου. Χρονοδιάγραμμα υλοποίησης της αξιολόγησης. Ανάπτυξη πλάνου Διαχείρισης Κινδύνων. Οδηγούς Συζήτησης και Ερωτηματολόγια για την διεξαγωγή των πρωτογενών ερευνών των ομάδων στόχου', 
'1'),
('Η Συμμετοχή της Ελλάδας στα Ευρωπαϊκά Ερευνητικά Δίκτυα - παραδοτέο πρώτο', 
'Η πρώτη ομάδα αποτελείται από τους ενδιαφερόμενους που έλαβαν υποστήριξη από τα Τοπικά Γραφεία Επιχειρηματικότητας σε Ελλάδα και Βουλγαρία. Στο πλαίσιο του ερωτηματολογίου η ομάδα καλείται να αξιολογήσει την συμπεριφορά και τον βαθμό εξυπηρέτησης τον οποίο έλαβαν από τα Γραφεία Κοινωνικής Επιχειρηματικότητας σε Ελλάδα και Βουλγαρία τόσο κατά τη διάρκεια της επικοινωνίας τους όσο και μετά από αυτήν.  ' 
, '1'),
( 'Σχεδιασμός και υλοποίηση ποιοτικής έρευνας' , 
'Επιλογή και προετοιμασία των ερευνητικών εργαλείων και μεθόδων για τη διενέργεια της έρευνας. Διοργάνωση ομάδας εστιασμένης συζήτησης- focus groups με εκπροσώπους θεσμικών φορέων. Διοργάνωση ομάδας εστιασμένης συζήτησης- focus groups με εκπροσώπους ΜΚΟ και φορέων παροχής υπηρεσιών υγείας. Διοργάνωση ομάδας εστιασμένης συζήτησης- focus groups με οικογενειακούς φροντιστές. Διεξαγωγή Έρευνας σε χρήστες υπηρεσιών ' , 
'2'),
( 'Σχεδιασμός και υλοποίηση ποσοτικής έρευνας από δευτερογενείς πηγές' , 
'Διερεύνηση των διαθέσιμων ερευνών της ΕΛΣΤΑΤ και προσδιορισμός των απαιτούμενων δεδομένων και μεταβλητών. Οριστικοποίηση της μεθοδολογίας επεξεργασίας των δεδομένων. Ανάπτυξη συστήματος επικοινωνίας με στελέχη της ΕΛΣΤΑΤ. Παραλαβή και έλεγχος των ποσοτικών δεδομένων. Επεξεργασία και ανάλυση των αποτελεσμάτων της ποσοτικής έρευνας – συγγραφή έκθεσης. Παρουσίαση και διαβούλευση των αποτελεσμάτων' 
, '1'),
('Εκτεταμένη Παρουσίαση' , 
'Ενδεικτικά παραδοτέα για τις προτάσεις που θα υποβληθούν μπορεί να είναι: Η έντυπη ή ηλεκτρονική έκδοση βιβλίων, μονογραφιών ή/και δημοσιεύσεων σε διεθνή περιοδικά. Η παραγωγή οπτικοακουστικού υλικού (π.χ. ντοκιμαντέρ, ταινία, τηλεοπτική σειρά, κινούμενα σχέδια κλπ.) ή αναπαράσταση με πολυμέσα (εικαστικά βίντεο, πολλαπλά και νέα μέσα, ψηφιακές μορφές τέχνης) ή οποιαδήποτε μορφή Τέχνης (θεατρική αναπαράσταση, μουσική, ζωγραφική, γλυπτική, χαρακτική, φωτογραφία, καλλιτεχνικές εγκαταστάσεις κλπ.). Διοργάνωση ημερίδων, επιμορφωτικών σεμιναρίων κλπ. Διοργάνωση διαδραστικών εκθέσεων (εφαρμογές ψηφιακής τρισδιάστατης αναπαράστασης/προβολές εικονικής πραγματικότητας κλπ.). Έκθεση φωτογραφίας.' , 
'1'),
( 'Αναλυτικός προϋπολογισμός του έργου', 
'Δαπάνες Προσωπικού, Αναλώσιμα, Δαπάνες για αγορά εξοπλισμού ή πρόσβαση σε εξοπλισμό, υποδομές ή άλλους πόρους, Δαπάνες Ταξιδιών και Μετακινήσεων, Δαπάνες Δημοσιότητας/Προβολής, Δαπάνες για τη σύναψη συμβάσεων για παροχή προϊόντων και υπηρεσιών, Λοιπές Δαπάνες , Έμμεσες Δαπάνες (Έξοδα διαχείρισης & Γενικά λειτουργικά έξοδα)' , 
'1'),
( 'Οργάνωση, Διοίκηση και Παρακολούθηση του Έργου' , 
'Σχεδιασμός Πλάνου Διαχείρισης και Παρακολούθησης της Υλοποίησης του Έργου και της αντιμετώπισης των κινδύνων του έργου, Διοίκηση έργου και συντονισμός των εργασιών της ομάδας έργου' 
, '1'),
( 'Ανασκόπηση της βιβλιογραφίας και της νομοθεσίας που σχετίζεται άμεσα ή έμμεσα' , 
'Ανασκόπηση της βιβλιογραφίας και της νομοθεσίας που σχετίζεται άμεσα ή έμμεσα. Κωδικοποίηση και ταξινόμηση της υφιστάμενης γενικής βιβλιογραφίας και Νομοθεσίας που καταγράφηκε και αποτυπώθηκε Σχολιασμός της υφιστάμενης γενικής βιβλιογραφίας και Νομοθεσίας και καταχώρηση της στη βάση δεδομένων. Προσδιορισμός  και παρουσίαση των ανασταλτικών παραγόντων του νομικού και θεσμικού πλαισίου για το υπό διερεύνηση θέμα και συγγραφή Τεύχους παρουσίασης των ανασταλτικών παραγόντων νομικού και θεσμικού πλαισίου' 
, '1'),
('Η Συμμετοχή της Ελλάδας στα Ευρωπαϊκά Ερευνητικά Δίκτυα - παραδοτέο δεύτερο',
 'Η δεύτερη ομάδα αφορά όλους όσους συμμετείχαν στα εκπαιδευτικά σεμινάρια που διοργανώθηκαν σε Ελλάδα και Βουλγαρία. Επιπλέον, τα ερωτηματολόγια απευθύνονται στις δύο κοινωνικές επιχειρήσεις που κέρδισαν μία θέση στη θερμοκοιτίδα της Τεχνόπολης βάσει των επιχειρηματικών σχεδίων που κατέθεσαν μετά από την Ανοιχτή  πρόκληση υποβολής επιχειρηματικών σχεδίων από τον Δήμο Πυλαίας - Χορτιάτη. Τα στοιχεία που αντλούνται από το δεύτερο ερωτηματολόγιο αφορούν το βαθμό ικανοποίησής τους από τα εκπαιδευτικά σεμινάρια και τις υπηρεσίες που παρέχονται στις επιχειρήσεις που ανήκουν στη θερμοκοιτίδα. '
 , '2'),
('Ολοκλήρωση της έρευνας και παρουσίαση των αποτελεσμάτων' 
, 'Με την ολοκλήρωση της έρευνας θα επάρχει σύνθεση των αποτελεσμάτων των ερευνών και διαμόρφωση συμπερασμάτων, Παρουσίαση και διαβούλευση των αποτελεσμάτων του έργου, Εκπόνηση τελικού κειμένου της έρευνας ' 
, '3'),
( 'Αξιολόγηση του Έργου' ,
 'Η μελέτη που εκπονήθηκε που υλοποιήθηκε στο πλαίσιο του διασυνοριακού προγράμματος INTERREG V-A Greece – Bulgaria 2014 – 2020. Η αξιολόγηση πραγματοποιήθηκε μέσω της διανομής τριών ερωτηματολογίων, το καθένα εκ των οποίων απευθύνεται σε τρεις ξεχωριστές ομάδες στόχους.' 
 , '2'),
('Η Συμμετοχή της Ελλάδας στα Ευρωπαϊκά Ερευνητικά Δίκτυα - παραδοτέο τρίτο', 
'Η τρίτη ομάδα αναφέρεται στους εταίρους του έργου, αυτούς δηλαδή που υλοποίησαν το έργο της κοινωνικής επιχειρηματικότητας. Το τρίτο ερωτηματολόγιο δίνει απαντήσεις σχετικά με τις δυσκολίες που εμφανίστηκαν κατά τη υλοποίηση του έργου, το ενδιαφέρον των συμμετεχόντων και τελικά την ευαισθητοποίησή τους απέναντι στην κοινωνική επιχειρηματικότητα. '
 , '1'),
('Ενδιάμεσο παραδοτέο της αξιολόγησης του σχεδιασμού', 
'Ενδιάμεσο παραδοτέο της αξιολόγησης του σχεδιασμού των προγραμμάτων με έμφαση στις διαδικασίες υλοποίησης και αξιολόγησης των αποτελεσμάτων της δράσης ως προς τους στόχους των επιμέρους Επιχειρησιακών Προγραμμάτων',
 '3'),
('Ενδιάμεσο παραδοτέο της αξιολόγησης των αποτελεσμάτων της δράσης ως προς τον ωφελούμενο πληθυσμό', 
'Στο Παραδοτέο αυτό καταγράφονται τα αποτελέσματα της δεύτερης συνάντησης της Ε.Ο. με την επιχείρηση, κατά την οποία τέθηκε το θεωρητικό και ερευνητικό πλαίσιο για τη συνέχιση της υλοποίησης του Έργου. Αναλυτικότερα, στη συνάντηση αυτή συζητήθηκε η διαδικασία υποστήριξης και υλοποίησης του Παραδοτέου που σχετίζεται με τις ψηφιακές αφηγήσεις, καθώς και οι παράμετροι που αφορούσαν τον σχεδιασμό αλλά και την ανάπτυξη διαδικτυακών λογισμικών για την προβολή των αφηγήσεων. Επίσης, συζητήθηκε η διαδικασία υποστήριξης και υλοποίησης του Παραδοτέου που αφορά την αξιοποίηση των τεχνολογιών επαυξημένης πραγματικότητας.' 
,'1'),
('Ανατροφοδότηση για βελτίωση λογισμικών',
 'Στο συγκεκριμένο Παραδοτέο επιχειρήθηκε μια συνθετική παρουσίαση των κύριων διαπιστώσεων που προέκυψαν από την έρευνα που υλοποιήθηκε στις ομάδες εργασίας του Έργου, αλλά και από χρήστες/τριες αυτού. Από την ανάλυση των αποτελεσμάτων της συγκεκριμένης εσωτερικής αξιολόγησης προέκυψε ότι στα περισσότερα θέματα και στην πλειονότητα των απαντήσεών τους, τα άτομα του δείγματος συγκλίνουν και επομένως προκρίνεται μια συλλογική άποψη για την πορεία Έργου έως εκείνη την περίοδο. Μικρές διαφοροποιήσεις, κυρίως χρηστών, έδωσαν τα αναγκαία ερεθίσματα για βελτιωτικές παρεμβάσεις στη συνέχεια υλοποίησης του Έργου.' 
 ,'1');

-- 1,10,13 Η Συμμετοχή της Ελλάδας στα Ευρωπαϊκά Ερευνητικά Δίκτυα (1984-2018) και η Επίδρασή της στην Παραγωγή Καινοτομίας και στην Επιχειρηματικότητα Εντάσεως Γνώσης' ntua
-- 3,4,11  Οι ριβοδιακόπτες ως ρυθμιστές μοριακών μηχανισμών μικροβιακών λοιμώξεων και αντοχής σε αντιβιοτικά, seka
-- 9, 12
