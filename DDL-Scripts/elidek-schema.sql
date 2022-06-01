-- Creating the ELIDEK Database Schema 
-- Project Group 3

-- ----- third DRAFT -------
-- ----- NATALIA ------------
-- current notes/ issues: ---
-- --------------------------
-- 
-- changed organizations.
-- CARDINALITY: is it properly set up 
-- DELIVERABLE: relationship + entity set have been fused. is that ok?
-- Warnings: 20:02:26	CREATE TABLE phone (  phone VARCHAR(20) NOT NULL,  abbreviation VARCHAR(15) NOT NULL,  CONSTRAINT pk_customer_phone PRIMARY KEY(abbreviation, phone),  CONSTRAINT fk_organization_phone FOREIGN KEY (abbreviation)    REFERENCES organization (abbreviation) ON UPDATE CASCADE ON DELETE CASCADE )	0 row(s) affected, 1 warning(s): 1280 Name 'pk_customer_phone' ignored for PRIMARY key.

DROP SCHEMA IF EXISTS elidek;
CREATE SCHEMA elidek;
USE elidek;

-- ----------------------------------------
-- --------------- ENTITIES ---------------
-- ----------------------------------------


CREATE TABLE organization ( -- inserted
	abbreviation VARCHAR(15) NOT NULL,
    name VARCHAR(70),
    type ENUM('uni','co','inst'),
    budget JSON,
    street VARCHAR(50),
    street_number INT UNSIGNED,
	postal_code INT(10) DEFAULT NULL,
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

CREATE TABLE executive ( -- inserted
	executive_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
	first_name VARCHAR(45) NOT NULL,
	last_name VARCHAR(45) NOT NULL,
	PRIMARY KEY (executive_id)
);

-- Table structure for table 'field'

CREATE TABLE field ( -- inserted
	field_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    field_name VARCHAR(70),
    PRIMARY KEY (field_id)
);

-- Table structure for table 'researcher'

CREATE TABLE researcher ( -- inserted
	researcher_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
	first_name VARCHAR(45) NOT NULL,
	last_name VARCHAR(45) NOT NULL,
	gender ENUM('male', 'female') ,
	birth_date DATE,	-- FORMAT: YYYY-MM-DD --
	PRIMARY KEY (researcher_id)
);

-- Table structure for table 'project'

CREATE TABLE project ( -- inserted
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
    CONSTRAINT check_dates CHECK (start_date < end_date),
	PRIMARY KEY (project_id),
    -- FOREIGN KEY CONSTRAINTS --
    CONSTRAINT fk_project_manager FOREIGN KEY (researcher_id)
		REFERENCES researcher (researcher_id) ON DELETE RESTRICT ON UPDATE CASCADE,
	CONSTRAINT fk_project_organization FOREIGN KEY (abbreviation)
		REFERENCES organization (abbreviation) ON DELETE RESTRICT ON UPDATE CASCADE,
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

CREATE TABLE organization__phone ( -- inserted
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

CREATE TABLE FieldProject ( -- inserted
	project_id INT UNSIGNED NOT NULL REFERENCES project (project_id),
    field_id INT UNSIGNED NOT NULL REFERENCES field (field_id),
    PRIMARY KEY (project_id, field_id),
    CONSTRAINT fk_fieldproj_project FOREIGN KEY (project_id)
		REFERENCES project (project_id) ON DELETE RESTRICT ON UPDATE CASCADE,
	CONSTRAINT fk_fieldproj_field FOREIGN KEY (field_id)
		REFERENCES field (field_id) ON DELETE RESTRICT ON UPDATE CASCADE
);

-- Table structure for table 'WorksOn'  (researchers WorkOn rojects)

CREATE TABLE WorksOn ( -- inserted
	project_id INT UNSIGNED NOT NULL REFERENCES project (project_id),
    researcher_id INT UNSIGNED NOT NULL REFERENCES researcher (researcher_id),
    PRIMARY KEY (project_id, researcher_id),
    CONSTRAINT fk_workson_project FOREIGN KEY (project_id)
		REFERENCES project (project_id) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT fk_worksfon_researcher FOREIGN KEY (researcher_id)
		REFERENCES researcher (researcher_id) ON DELETE CASCADE ON UPDATE CASCADE
);


-- Table structure for table 'WorksFor' (researchers WorkFor an organization)

CREATE TABLE WorksFor ( -- inserted XWRIS SINCE DATE
	abbreviation VARCHAR(15) NOT NULL,
    researcher_id INT UNSIGNED NOT NULL,
    since_date DATE,
    PRIMARY KEY (researcher_id, abbreviation),
    CONSTRAINT fk_worksfor_organization FOREIGN KEY (abbreviation)
		REFERENCES organization (abbreviation) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT fk_worksfor_researcher FOREIGN KEY (researcher_id)
		REFERENCES researcher (researcher_id) ON DELETE CASCADE ON UPDATE CASCADE
);

-- Table structure for table 'evaluates'

CREATE TABLE evaluates (
	project_id INT UNSIGNED NOT NULL,
    researcher_id INT UNSIGNED NOT NULL,
    rating ENUM('A', 'B'),      -- we assume it must have recieved an A or a B to have been funded 
    eval_date DATE,
    PRIMARY KEY (project_id, researcher_id),
	CONSTRAINT fk_evalutes_project FOREIGN KEY (project_id)
		REFERENCES project (project_id) ON DELETE CASCADE ON UPDATE CASCADE,
	CONSTRAINT fk_evaluates_researcher FOREIGN KEY (researcher_id)
		REFERENCES researcher (researcher_id) ON DELETE CASCADE ON UPDATE CASCADE
);

