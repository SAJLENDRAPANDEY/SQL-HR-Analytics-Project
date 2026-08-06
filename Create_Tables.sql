/*
===========================================================
 Project      : SQL-HR-Analytics-Project
 File         : Create_Tables.sql
 Description  : Database Schema (DDL)
 Author       : Sajlendra Pandey
 Database     : PostgreSQL
===========================================================

This script creates the complete database schema for the
HR Analytics Project.

Objects Created:
1. Schema
2. Countries
3. Locations
4. Departments
5. Job Roles
6. Employees

===========================================================
*/

-- ========================================================
-- Create Schema
-- ========================================================

CREATE SCHEMA peoplepulse;

SET search_path TO peoplepulse;

-- ========================================================
-- Table: Countries
-- ========================================================

CREATE TABLE countries (
    country_id BIGSERIAL PRIMARY KEY,
    country_name VARCHAR(150) NOT NULL UNIQUE,
    country_code CHAR(2) NOT NULL UNIQUE,
    currency VARCHAR(50) NOT NULL,
    timezone VARCHAR(100) NOT NULL,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ========================================================
-- Table: Locations
-- ========================================================

CREATE TABLE locations (
    location_id BIGSERIAL PRIMARY KEY,
    address TEXT NOT NULL,
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL,
    postal_code VARCHAR(50) NOT NULL,

    country_id BIGINT NOT NULL,

    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_location_country
        FOREIGN KEY (country_id)
        REFERENCES countries(country_id)
);

-- ========================================================
-- Table: Departments
-- ========================================================

CREATE TABLE departments (
    department_id BIGSERIAL PRIMARY KEY,

    department_name VARCHAR(100) NOT NULL UNIQUE,
    department_code VARCHAR(100) NOT NULL UNIQUE,

    budget NUMERIC(15,2) NOT NULL,

    manager_id BIGINT NOT NULL,
    location_id BIGINT NOT NULL,

    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_department_location
        FOREIGN KEY (location_id)
        REFERENCES locations(location_id)
);

-- Manager will be linked after employee creation

ALTER TABLE departments
ALTER COLUMN manager_id DROP NOT NULL;

-- ========================================================
-- Table: Job Roles
-- ========================================================

CREATE TABLE job_roles (
    job_role_id BIGSERIAL PRIMARY KEY,

    job_title VARCHAR(100) NOT NULL,
    job_code VARCHAR(20) NOT NULL UNIQUE,

    min_salary NUMERIC(10,2),
    max_salary NUMERIC(10,2),

    CHECK (min_salary >= 0),
    CHECK (max_salary >= 0),
    CHECK (min_salary <= max_salary),

    experience_level VARCHAR(50) NOT NULL,
    CHECK (experience_level IN ('Junior', 'Mid', 'Senior')),

    description TEXT,

    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ========================================================
-- Table: Employees
-- ========================================================

CREATE TABLE employees (
    emp_id BIGSERIAL PRIMARY KEY,

    emp_code VARCHAR(20) NOT NULL UNIQUE,

    fname VARCHAR(100) NOT NULL,
    lname VARCHAR(100) NOT NULL,

    email VARCHAR(150) NOT NULL UNIQUE,
    phone_number VARCHAR(15) NOT NULL,

    gender VARCHAR(20) NOT NULL,
    CHECK (gender IN ('Male', 'Female', 'Other')),

    date_of_birth DATE NOT NULL,
    hire_date DATE NOT NULL,

    CHECK (date_of_birth < hire_date),
    CHECK (hire_date <= CURRENT_DATE),

    department_id BIGINT NOT NULL,
    job_role_id BIGINT NOT NULL,
    manager_id BIGINT,

    employment_status VARCHAR(20) NOT NULL,
    CHECK (
        employment_status IN
        ('Active', 'On Leave', 'Resigned', 'Terminated')
    ),

    basic_salary NUMERIC(10,2),
    CHECK (basic_salary >= 0),

    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_employee_department
        FOREIGN KEY (department_id)
        REFERENCES departments(department_id),

    CONSTRAINT fk_employee_job_role
        FOREIGN KEY (job_role_id)
        REFERENCES job_roles(job_role_id),

    CONSTRAINT fk_employee_manager
        FOREIGN KEY (manager_id)
        REFERENCES employees(emp_id)
);

-- ========================================================
-- End of DDL Script
-- ========================================================