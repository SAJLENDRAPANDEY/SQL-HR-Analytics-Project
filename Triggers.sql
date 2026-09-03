/*
=====================================================================
 Project      : PeoplePulse HR Analytics PostgreSQL
 Module       : 08 - Triggers
 File         : Triggers.sql
 Database     : PostgreSQL
 Author       : Sajlendra Pandey

 Purpose:
 Database-level automation, validation and audit tracking
 using PostgreSQL Trigger Functions.

 Trigger Areas:
 - Automatic Timestamp Management
 - Salary Validation
 - Hire Date Validation
 - Manager Validation
 - Employee Audit Logging
 - Salary Change Tracking
 - Employment Status Tracking
 - Employee Delete Audit
 - Manager Protection
 - Manager Assignment Validation
 - Employee History
 - Department Transfer Tracking
 - Enterprise Change Audit

 Difficulty:
 Advanced → Expert

 Total Case Studies:
 15
=====================================================================
*/


-- ===================================================================
-- 0. DATABASE CONTEXT
-- ===================================================================

SET search_path TO peoplepulse;


/*
=====================================================================
 CASE STUDY 1
 Automatic Employee Updated Timestamp
=====================================================================

Business Requirement:
Whenever an employee record is updated, updated_at should
automatically contain the current timestamp.

Trigger Type:
BEFORE UPDATE

Concepts:
- Trigger Function
- NEW
- BEFORE UPDATE
- Automatic timestamp
=====================================================================
*/


DROP FUNCTION IF EXISTS fn_employee_updated_at();

CREATE OR REPLACE FUNCTION fn_employee_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN

    NEW.updated_at := CURRENT_TIMESTAMP;

    RETURN NEW;

END;
$$;


DROP TRIGGER IF EXISTS trg_employee_updated_at
ON employees;

CREATE TRIGGER trg_employee_updated_at
BEFORE UPDATE
ON employees
FOR EACH ROW
EXECUTE FUNCTION fn_employee_updated_at();


/*
Test:

UPDATE employees
SET basic_salary = basic_salary + 1000
WHERE emp_id = 1;

SELECT emp_id, updated_at
FROM employees
WHERE emp_id = 1;
*/


/*
=====================================================================
 CASE STUDY 2
 Automatic Department Updated Timestamp
=====================================================================

Business Requirement:
Whenever department information changes, updated_at should
automatically be refreshed.
=====================================================================
*/


DROP FUNCTION IF EXISTS fn_department_updated_at();

CREATE OR REPLACE FUNCTION fn_department_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN

    NEW.updated_at := CURRENT_TIMESTAMP;

    RETURN NEW;

END;
$$;


DROP TRIGGER IF EXISTS trg_department_updated_at
ON departments;

CREATE TRIGGER trg_department_updated_at
BEFORE UPDATE
ON departments
FOR EACH ROW
EXECUTE FUNCTION fn_department_updated_at();


/*
=====================================================================
 CASE STUDY 3
 Employee Salary Validation
=====================================================================

Business Requirement:
Employee salary must remain within the salary range defined
by the employee's job role.

Rule:

basic_salary >= job_roles.min_salary
AND
basic_salary <= job_roles.max_salary

Trigger:
BEFORE INSERT OR UPDATE

If invalid:
Raise an exception.
=====================================================================
*/


DROP FUNCTION IF EXISTS fn_validate_employee_salary();

CREATE OR REPLACE FUNCTION fn_validate_employee_salary()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_min_salary NUMERIC(10,2);
    v_max_salary NUMERIC(10,2);
BEGIN

    SELECT
        min_salary,
        max_salary
    INTO
        v_min_salary,
        v_max_salary
    FROM job_roles
    WHERE job_role_id = NEW.job_role_id;


    IF v_min_salary IS NOT NULL
       AND NEW.basic_salary < v_min_salary THEN

        RAISE EXCEPTION
            'Employee salary % is below the minimum salary % for job role %.',
            NEW.basic_salary,
            v_min_salary,
            NEW.job_role_id;

    END IF;


    IF v_max_salary IS NOT NULL
       AND NEW.basic_salary > v_max_salary THEN

        RAISE EXCEPTION
            'Employee salary % exceeds the maximum salary % for job role %.',
            NEW.basic_salary,
            v_max_salary,
            NEW.job_role_id;

    END IF;


    RETURN NEW;

END;
$$;


DROP TRIGGER IF EXISTS trg_validate_employee_salary
ON employees;

CREATE TRIGGER trg_validate_employee_salary
BEFORE INSERT OR UPDATE OF basic_salary, job_role_id
ON employees
FOR EACH ROW
EXECUTE FUNCTION fn_validate_employee_salary();


/*
=====================================================================
 CASE STUDY 4
 Hire Date Validation
=====================================================================

Business Requirement:
Employee hire date cannot be in the future.

Rule:

hire_date <= CURRENT_DATE

Trigger:
BEFORE INSERT OR UPDATE
=====================================================================
*/


DROP FUNCTION IF EXISTS fn_validate_hire_date();

CREATE OR REPLACE FUNCTION fn_validate_hire_date()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN

    IF NEW.hire_date > CURRENT_DATE THEN

        RAISE EXCEPTION
            'Employee hire date % cannot be in the future.',
            NEW.hire_date;

    END IF;


    RETURN NEW;

END;
$$;


DROP TRIGGER IF EXISTS trg_validate_hire_date
ON employees;

CREATE TRIGGER trg_validate_hire_date
BEFORE INSERT OR UPDATE OF hire_date
ON employees
FOR EACH ROW
EXECUTE FUNCTION fn_validate_hire_date();


/*
=====================================================================
 CASE STUDY 5
 Prevent Self Manager Assignment
=====================================================================

Business Requirement:
An employee cannot become their own manager.

Invalid:

emp_id = 10
manager_id = 10

Trigger:
BEFORE INSERT OR UPDATE
=====================================================================
*/


DROP FUNCTION IF EXISTS fn_validate_self_manager();

CREATE OR REPLACE FUNCTION fn_validate_self_manager()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN

    IF NEW.manager_id IS NOT NULL
       AND NEW.emp_id = NEW.manager_id THEN

        RAISE EXCEPTION
            'Employee % cannot be their own manager.',
            NEW.emp_id;

    END IF;


    RETURN NEW;

END;
$$;


DROP TRIGGER IF EXISTS trg_validate_self_manager
ON employees;

CREATE TRIGGER trg_validate_self_manager
BEFORE INSERT OR UPDATE OF manager_id
ON employees
FOR EACH ROW
EXECUTE FUNCTION fn_validate_self_manager();


/*
=====================================================================
 CASE STUDY 6
 Employee Audit Table
=====================================================================

Purpose:
Maintain audit information whenever important employee data changes.

Tracked information:
- Salary
- Employment Status
=====================================================================
*/


CREATE TABLE IF NOT EXISTS employee_audit
(
    audit_id BIGSERIAL PRIMARY KEY,

    emp_id BIGINT NOT NULL,

    action_type VARCHAR(50) NOT NULL,

    old_salary NUMERIC(10,2),
    new_salary NUMERIC(10,2),

    old_status VARCHAR(20),
    new_status VARCHAR(20),

    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


/*
=====================================================================
 CASE STUDY 7
 Salary Change Audit
=====================================================================

Business Requirement:
When employee salary changes, store old and new salary.

No audit record should be created if salary remains unchanged.

Action:
SALARY_UPDATE
=====================================================================
*/


DROP FUNCTION IF EXISTS fn_audit_salary_change();

CREATE OR REPLACE FUNCTION fn_audit_salary_change()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN

    IF OLD.basic_salary IS DISTINCT FROM NEW.basic_salary THEN

        INSERT INTO employee_audit
        (
            emp_id,
            action_type,
            old_salary,
            new_salary,
            changed_at
        )
        VALUES
        (
            NEW.emp_id,
            'SALARY_UPDATE',
            OLD.basic_salary,
            NEW.basic_salary,
            CURRENT_TIMESTAMP
        );

    END IF;


    RETURN NEW;

END;
$$;


DROP TRIGGER IF EXISTS trg_audit_salary_change
ON employees;

CREATE TRIGGER trg_audit_salary_change
AFTER UPDATE OF basic_salary
ON employees
FOR EACH ROW
EXECUTE FUNCTION fn_audit_salary_change();


/*
=====================================================================
 CASE STUDY 8
 Employment Status Audit
=====================================================================

Business Requirement:
Track changes in employee employment status.

Example:

Active -> Resigned

Action:
STATUS_CHANGE
=====================================================================
*/


DROP FUNCTION IF EXISTS fn_audit_status_change();

CREATE OR REPLACE FUNCTION fn_audit_status_change()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN

    IF OLD.employment_status IS DISTINCT FROM NEW.employment_status THEN

        INSERT INTO employee_audit
        (
            emp_id,
            action_type,
            old_status,
            new_status,
            changed_at
        )
        VALUES
        (
            NEW.emp_id,
            'STATUS_CHANGE',
            OLD.employment_status,
            NEW.employment_status,
            CURRENT_TIMESTAMP
        );

    END IF;


    RETURN NEW;

END;
$$;


DROP TRIGGER IF EXISTS trg_audit_status_change
ON employees;

CREATE TRIGGER trg_audit_status_change
AFTER UPDATE OF employment_status
ON employees
FOR EACH ROW
EXECUTE FUNCTION fn_audit_status_change();


/*
=====================================================================
 CASE STUDY 9
 Employee Delete Audit
=====================================================================

Business Requirement:
Before an employee is permanently deleted, preserve important
employee information in a separate audit table.

Concept:
OLD
AFTER DELETE
=====================================================================
*/


CREATE TABLE IF NOT EXISTS employee_delete_audit
(
    audit_id BIGSERIAL PRIMARY KEY,

    emp_id BIGINT NOT NULL,
    emp_code VARCHAR(20),
    employee_name VARCHAR(250),

    department_id BIGINT,
    basic_salary NUMERIC(10,2),

    employment_status VARCHAR(20),

    deleted_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


DROP FUNCTION IF EXISTS fn_employee_delete_audit();

CREATE OR REPLACE FUNCTION fn_employee_delete_audit()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN

    INSERT INTO employee_delete_audit
    (
        emp_id,
        emp_code,
        employee_name,
        department_id,
        basic_salary,
        employment_status,
        deleted_at
    )
    VALUES
    (
        OLD.emp_id,
        OLD.emp_code,
        CONCAT_WS(' ', OLD.fname, OLD.lname),
        OLD.department_id,
        OLD.basic_salary,
        OLD.employment_status,
        CURRENT_TIMESTAMP
    );


    RETURN OLD;

END;
$$;


DROP TRIGGER IF EXISTS trg_employee_delete_audit
ON employees;

CREATE TRIGGER trg_employee_delete_audit
AFTER DELETE
ON employees
FOR EACH ROW
EXECUTE FUNCTION fn_employee_delete_audit();


/*
=====================================================================
 CASE STUDY 10
 Prevent Deletion of Managers
=====================================================================

Business Requirement:
An employee who currently manages other employees cannot be deleted.

Example:

Employee A
    |
    +--- Employee B
    +--- Employee C

Employee A cannot be deleted until reporting relationships
are handled.
=====================================================================
*/


DROP FUNCTION IF EXISTS fn_prevent_manager_deletion();

CREATE OR REPLACE FUNCTION fn_prevent_manager_deletion()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_direct_reports INTEGER;
BEGIN

    SELECT COUNT(*)
    INTO v_direct_reports
    FROM employees
    WHERE manager_id = OLD.emp_id;


    IF v_direct_reports > 0 THEN

        RAISE EXCEPTION
            'Cannot delete employee %. Employee has % direct report(s).',
            OLD.emp_id,
            v_direct_reports;

    END IF;


    RETURN OLD;

END;
$$;


DROP TRIGGER IF EXISTS trg_prevent_manager_deletion
ON employees;

CREATE TRIGGER trg_prevent_manager_deletion
BEFORE DELETE
ON employees
FOR EACH ROW
EXECUTE FUNCTION fn_prevent_manager_deletion();


/*
=====================================================================
 CASE STUDY 11
 Manager Department Validation
=====================================================================

Business Requirement:
An employee's manager must belong to the same department.

Example:

Employee:
IT

Manager:
Finance

Result:
REJECT

Also prevents self-manager assignment.
=====================================================================
*/


DROP FUNCTION IF EXISTS fn_validate_manager_department();

CREATE OR REPLACE FUNCTION fn_validate_manager_department()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_manager_department BIGINT;
BEGIN

    IF NEW.manager_id IS NULL THEN
        RETURN NEW;
    END IF;


    IF NEW.manager_id = NEW.emp_id THEN

        RAISE EXCEPTION
            'Employee % cannot be their own manager.',
            NEW.emp_id;

    END IF;


    SELECT department_id
    INTO v_manager_department
    FROM employees
    WHERE emp_id = NEW.manager_id;


    IF v_manager_department IS NULL THEN

        RAISE EXCEPTION
            'Manager % does not exist.',
            NEW.manager_id;

    END IF;


    IF v_manager_department <> NEW.department_id THEN

        RAISE EXCEPTION
            'Manager % must belong to the same department as employee %.',
            NEW.manager_id,
            NEW.emp_id;

    END IF;


    RETURN NEW;

END;
$$;


DROP TRIGGER IF EXISTS trg_validate_manager_department
ON employees;

CREATE TRIGGER trg_validate_manager_department
BEFORE INSERT OR UPDATE OF manager_id, department_id
ON employees
FOR EACH ROW
EXECUTE FUNCTION fn_validate_manager_department();


/*
=====================================================================
 CASE STUDY 12
 Employee History Table
=====================================================================

Purpose:
Track important employee changes:

- Department
- Job Role
- Salary
=====================================================================
*/


CREATE TABLE IF NOT EXISTS employee_history
(
    history_id BIGSERIAL PRIMARY KEY,

    emp_id BIGINT NOT NULL,
    emp_code VARCHAR(20),

    old_department_id BIGINT,
    new_department_id BIGINT,

    old_job_role_id BIGINT,
    new_job_role_id BIGINT,

    old_salary NUMERIC(10,2),
    new_salary NUMERIC(10,2),

    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


/*
=====================================================================
 CASE STUDY 13
 Employee History Trigger
=====================================================================

Business Requirement:
Whenever department, job role or salary changes, preserve
old and new values.

Only create history when an actual change occurs.
=====================================================================
*/


DROP FUNCTION IF EXISTS fn_employee_history();

CREATE OR REPLACE FUNCTION fn_employee_history()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN

    IF OLD.department_id IS DISTINCT FROM NEW.department_id
       OR OLD.job_role_id IS DISTINCT FROM NEW.job_role_id
       OR OLD.basic_salary IS DISTINCT FROM NEW.basic_salary
    THEN

        INSERT INTO employee_history
        (
            emp_id,
            emp_code,

            old_department_id,
            new_department_id,

            old_job_role_id,
            new_job_role_id,

            old_salary,
            new_salary,

            changed_at
        )
        VALUES
        (
            NEW.emp_id,
            NEW.emp_code,

            OLD.department_id,
            NEW.department_id,

            OLD.job_role_id,
            NEW.job_role_id,

            OLD.basic_salary,
            NEW.basic_salary,

            CURRENT_TIMESTAMP
        );

    END IF;


    RETURN NEW;

END;
$$;


DROP TRIGGER IF EXISTS trg_employee_history
ON employees;

CREATE TRIGGER trg_employee_history
AFTER UPDATE
ON employees
FOR EACH ROW
EXECUTE FUNCTION fn_employee_history();


/*
=====================================================================
 CASE STUDY 14
 Department Transfer Detection
=====================================================================

Business Requirement:
If an employee changes department, create a transfer record.

Action:
DEPARTMENT_TRANSFER

Only department changes should create this record.
=====================================================================
*/


CREATE TABLE IF NOT EXISTS employee_transfer_audit
(
    transfer_id BIGSERIAL PRIMARY KEY,

    emp_id BIGINT NOT NULL,
    emp_code VARCHAR(20),

    old_department_id BIGINT NOT NULL,
    new_department_id BIGINT NOT NULL,

    transfer_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


DROP FUNCTION IF EXISTS fn_employee_transfer_audit();

CREATE OR REPLACE FUNCTION fn_employee_transfer_audit()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN

    IF OLD.department_id IS DISTINCT FROM NEW.department_id THEN

        INSERT INTO employee_transfer_audit
        (
            emp_id,
            emp_code,
            old_department_id,
            new_department_id,
            transfer_date
        )
        VALUES
        (
            NEW.emp_id,
            NEW.emp_code,
            OLD.department_id,
            NEW.department_id,
            CURRENT_TIMESTAMP
        );

    END IF;


    RETURN NEW;

END;
$$;


DROP TRIGGER IF EXISTS trg_employee_transfer_audit
ON employees;

CREATE TRIGGER trg_employee_transfer_audit
AFTER UPDATE OF department_id
ON employees
FOR EACH ROW
EXECUTE FUNCTION fn_employee_transfer_audit();


/*
=====================================================================
 CASE STUDY 15
 ENTERPRISE EMPLOYEE CHANGE AUDIT
=====================================================================

Business Requirement:
Create one centralized audit mechanism capable of detecting:

1. INSERT
2. SALARY_CHANGE
3. DEPARTMENT_TRANSFER
4. JOB_ROLE_CHANGE
5. STATUS_CHANGE
6. MULTIPLE_CHANGES
7. DELETE

This represents an enterprise-style employee lifecycle audit system.
=====================================================================
*/


CREATE TABLE IF NOT EXISTS employee_change_audit
(
    audit_id BIGSERIAL PRIMARY KEY,

    emp_id BIGINT NOT NULL,
    emp_code VARCHAR(20),

    action_type VARCHAR(50) NOT NULL,

    old_department_id BIGINT,
    new_department_id BIGINT,

    old_job_role_id BIGINT,
    new_job_role_id BIGINT,

    old_salary NUMERIC(10,2),
    new_salary NUMERIC(10,2),

    old_status VARCHAR(20),
    new_status VARCHAR(20),

    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


/*
---------------------------------------------------------------------
Enterprise INSERT / UPDATE / DELETE Trigger
---------------------------------------------------------------------
*/


DROP FUNCTION IF EXISTS fn_employee_change_audit();

CREATE OR REPLACE FUNCTION fn_employee_change_audit()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE

    v_action_type VARCHAR(50);

    v_salary_changed BOOLEAN := FALSE;
    v_department_changed BOOLEAN := FALSE;
    v_job_role_changed BOOLEAN := FALSE;
    v_status_changed BOOLEAN := FALSE;

BEGIN


    /*
    ================================================================
    INSERT
    ================================================================
    */

    IF TG_OP = 'INSERT' THEN

        INSERT INTO employee_change_audit
        (
            emp_id,
            emp_code,
            action_type,

            new_department_id,
            new_job_role_id,
            new_salary,
            new_status,

            changed_at
        )
        VALUES
        (
            NEW.emp_id,
            NEW.emp_code,
            'INSERT',

            NEW.department_id,
            NEW.job_role_id,
            NEW.basic_salary,
            NEW.employment_status,

            CURRENT_TIMESTAMP
        );


        RETURN NEW;

    END IF;


    /*
    ================================================================
    DELETE
    ================================================================
    */

    IF TG_OP = 'DELETE' THEN

        INSERT INTO employee_change_audit
        (
            emp_id,
            emp_code,
            action_type,

            old_department_id,
            old_job_role_id,
            old_salary,
            old_status,

            changed_at
        )
        VALUES
        (
            OLD.emp_id,
            OLD.emp_code,
            'DELETE',

            OLD.department_id,
            OLD.job_role_id,
            OLD.basic_salary,
            OLD.employment_status,

            CURRENT_TIMESTAMP
        );


        RETURN OLD;

    END IF;


    /*
    ================================================================
    UPDATE
    ================================================================
    */

    IF TG_OP = 'UPDATE' THEN

        v_salary_changed :=
            OLD.basic_salary IS DISTINCT FROM NEW.basic_salary;

        v_department_changed :=
            OLD.department_id IS DISTINCT FROM NEW.department_id;

        v_job_role_changed :=
            OLD.job_role_id IS DISTINCT FROM NEW.job_role_id;

        v_status_changed :=
            OLD.employment_status IS DISTINCT FROM NEW.employment_status;


        /*
        ------------------------------------------------------------
        Multiple Changes
        ------------------------------------------------------------
        */

        IF (
            v_salary_changed::INTEGER +
            v_department_changed::INTEGER +
            v_job_role_changed::INTEGER +
            v_status_changed::INTEGER
        ) > 1 THEN

            v_action_type := 'MULTIPLE_CHANGES';


        /*
        ------------------------------------------------------------
        Salary Change
        ------------------------------------------------------------
        */

        ELSIF v_salary_changed THEN

            v_action_type := 'SALARY_CHANGE';


        /*
        ------------------------------------------------------------
        Department Transfer
        ------------------------------------------------------------
        */

        ELSIF v_department_changed THEN

            v_action_type := 'DEPARTMENT_TRANSFER';


        /*
        ------------------------------------------------------------
        Job Role Change
        ------------------------------------------------------------
        */

        ELSIF v_job_role_changed THEN

            v_action_type := 'JOB_ROLE_CHANGE';


        /*
        ------------------------------------------------------------
        Employment Status Change
        ------------------------------------------------------------
        */

        ELSIF v_status_changed THEN

            v_action_type := 'STATUS_CHANGE';


        /*
        ------------------------------------------------------------
        No meaningful change
        ------------------------------------------------------------
        */

        ELSE

            RETURN NEW;

        END IF;


        /*
        ------------------------------------------------------------
        Insert Audit Record
        ------------------------------------------------------------
        */

        INSERT INTO employee_change_audit
        (
            emp_id,
            emp_code,
            action_type,

            old_department_id,
            new_department_id,

            old_job_role_id,
            new_job_role_id,

            old_salary,
            new_salary,

            old_status,
            new_status,

            changed_at
        )
        VALUES
        (
            NEW.emp_id,
            NEW.emp_code,
            v_action_type,

            OLD.department_id,
            NEW.department_id,

            OLD.job_role_id,
            NEW.job_role_id,

            OLD.basic_salary,
            NEW.basic_salary,

            OLD.employment_status,
            NEW.employment_status,

            CURRENT_TIMESTAMP
        );


        RETURN NEW;

    END IF;


    RETURN NEW;

END;
$$;


/*
---------------------------------------------------------------------
Create Enterprise Trigger
---------------------------------------------------------------------
*/


DROP TRIGGER IF EXISTS trg_employee_change_audit
ON employees;

CREATE TRIGGER trg_employee_change_audit
AFTER INSERT OR UPDATE OR DELETE
ON employees
FOR EACH ROW
EXECUTE FUNCTION fn_employee_change_audit();


/*
=====================================================================
 TESTING SECTION
=====================================================================

Run these tests individually.

IMPORTANT:
Use test records carefully in your development database.
=====================================================================
*/


/*
---------------------------------------------------------------------
TEST 1 — Updated Timestamp
---------------------------------------------------------------------

UPDATE employees
SET basic_salary = basic_salary + 1000
WHERE emp_id = 1;

SELECT emp_id, updated_at
FROM employees
WHERE emp_id = 1;
*/


/*
---------------------------------------------------------------------
TEST 2 — Salary Validation
---------------------------------------------------------------------

This should fail if salary is outside the job-role range.

Example:

UPDATE employees
SET basic_salary = 999999
WHERE emp_id = 1;
*/


/*
---------------------------------------------------------------------
TEST 3 — Self Manager Validation
---------------------------------------------------------------------

This should fail:

UPDATE employees
SET manager_id = emp_id
WHERE emp_id = 1;
*/


/*
---------------------------------------------------------------------
TEST 4 — Salary Audit
---------------------------------------------------------------------

UPDATE employees
SET basic_salary = basic_salary + 5000
WHERE emp_id = 2;

SELECT *
FROM employee_audit
WHERE emp_id = 2
ORDER BY changed_at DESC;
*/


/*
---------------------------------------------------------------------
TEST 5 — Status Audit
---------------------------------------------------------------------

UPDATE employees
SET employment_status = 'On Leave'
WHERE emp_id = 3;

SELECT *
FROM employee_audit
WHERE emp_id = 3
ORDER BY changed_at DESC;
*/


/*
---------------------------------------------------------------------
TEST 6 — Employee History
---------------------------------------------------------------------

UPDATE employees
SET basic_salary = basic_salary + 3000
WHERE emp_id = 4;

SELECT *
FROM employee_history
WHERE emp_id = 4
ORDER BY changed_at DESC;
*/


/*
---------------------------------------------------------------------
TEST 7 — Department Transfer
---------------------------------------------------------------------

UPDATE employees
SET department_id = 6
WHERE emp_id = 5;

SELECT *
FROM employee_transfer_audit
WHERE emp_id = 5
ORDER BY transfer_date DESC;
*/


/*
---------------------------------------------------------------------
TEST 8 — Enterprise Audit
---------------------------------------------------------------------

SELECT
    audit_id,
    emp_id,
    emp_code,
    action_type,
    old_department_id,
    new_department_id,
    old_job_role_id,
    new_job_role_id,
    old_salary,
    new_salary,
    old_status,
    new_status,
    changed_at
FROM employee_change_audit
ORDER BY changed_at DESC;
*/


/*
=====================================================================
 AUDIT REPORTS
=====================================================================
*/


-- Salary Change Report

SELECT
    emp_id,
    action_type,
    old_salary,
    new_salary,
    changed_at
FROM employee_audit
WHERE action_type = 'SALARY_UPDATE'
ORDER BY changed_at DESC;


-- Status Change Report

SELECT
    emp_id,
    action_type,
    old_status,
    new_status,
    changed_at
FROM employee_audit
WHERE action_type = 'STATUS_CHANGE'
ORDER BY changed_at DESC;


-- Department Transfer Report

SELECT
    transfer_id,
    emp_id,
    emp_code,
    old_department_id,
    new_department_id,
    transfer_date
FROM employee_transfer_audit
ORDER BY transfer_date DESC;


-- Complete Employee Change Audit

SELECT
    audit_id,
    emp_id,
    emp_code,
    action_type,
    old_department_id,
    new_department_id,
    old_job_role_id,
    new_job_role_id,
    old_salary,
    new_salary,
    old_status,
    new_status,
    changed_at
FROM employee_change_audit
ORDER BY changed_at DESC;


/*
=====================================================================
 END OF TRIGGERS MODULE
=====================================================================
*/