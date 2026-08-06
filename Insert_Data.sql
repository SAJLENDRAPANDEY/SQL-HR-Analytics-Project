/*
=====================================================================
 Project      : PeoplePulse HR Analytics (PostgreSQL)
 File         : Insert_Data.sql
 Folder       : 03_DML
 Author       : Sajlendra Pandey

 Description:
 This script inserts master and transactional sample data into
 the PeoplePulse HR Analytics database.

 Tables Covered
 ----------------
 1. Countries
 2. Locations
 3. Departments
 4. Job Roles
 5. Employees

 Execute After:
 - Create_Schema.sql
 - Create_Tables.sql

=====================================================================
*/

BEGIN;

SET search_path TO peoplepulse;

-- ==============================================================
-- 1. COUNTRIES
-- ==============================================================

INSERT INTO countries
(
    country_name,
    country_code,
    currency,
    timezone
)
VALUES
('India','IN','Indian Rupee','Asia/Kolkata'),
('United States','US','US Dollar','America/New_York'),
('Canada','CA','Canadian Dollar','America/Toronto'),
('United Kingdom','GB','Pound Sterling','Europe/London'),
('Germany','DE','Euro','Europe/Berlin'),
('Australia','AU','Australian Dollar','Australia/Sydney'),
('Japan','JP','Japanese Yen','Asia/Tokyo'),
('Singapore','SG','Singapore Dollar','Asia/Singapore'),
('United Arab Emirates','AE','UAE Dirham','Asia/Dubai'),
('France','FR','Euro','Europe/Paris');

-- ==============================================================
-- 2. LOCATIONS
-- ==============================================================

INSERT INTO locations
(
    address,
    city,
    state,
    postal_code,
    country_id
)
VALUES
('Electronic City Phase 1','Bengaluru','Karnataka','560100',1),
('HITEC City','Hyderabad','Telangana','500081',1),
('Sector 62','Noida','Uttar Pradesh','201309',1),
('Times Square','New York','New York','10036',2),
('Downtown','Toronto','Ontario','M5H2N2',3),
('Canary Wharf','London','England','E14 5AB',4),
('Alexanderplatz','Berlin','Berlin','10178',5),
('Sydney CBD','Sydney','New South Wales','2000',6),
('Shinjuku','Tokyo','Tokyo','1600022',7),
('Marina Bay','Singapore','Singapore','018956',8);

-- ==============================================================
-- 3. DEPARTMENTS
-- ==============================================================

INSERT INTO departments
(
    department_name,
    department_code,
    budget,
    location_id
)
VALUES
('Information Technology','IT',5000000.00,1),
('Human Resources','HR',1200000.00,3),
('Finance','FIN',2500000.00,6),
('Sales','SAL',3000000.00,9),
('Marketing','MKT',1800000.00,4),
('Data Analytics','DA',3500000.00,5),
('Operations','OPS',2800000.00,2),
('Research & Development','RND',4500000.00,10);

-- ==============================================================
-- 4. JOB ROLES
-- ==============================================================

INSERT INTO job_roles
(
    job_title,
    job_code,
    min_salary,
    max_salary,
    experience_level,
    description
)
VALUES
...