/*
=====================================================================
 Project      : PeoplePulse HR Analytics PostgreSQL
 Module       : 07 - Stored Procedures
 File         : HR_Stored_Procedures.sql
 Database     : PostgreSQL
 Author       : Sajlendra Pandey

 Purpose:
 Business operations and transactional workflows using
 PostgreSQL Stored Procedures.

 Topics:
 - CREATE PROCEDURE
 - IN Parameters
 - CALL
 - INSERT Operations
 - UPDATE Operations
 - DELETE/Relationship Operations
 - Validation
 - Conditional Logic
 - Exception Handling
 - Multi-table Operations
 - Self Join
 - Transaction-safe Business Logic
 - Compensation Control
 - Workforce Management

 Difficulty:
 Advanced → Expert

 Total Case Studies:
 15
=====================================================================
*/

SET search_path TO peoplepulse;


/*
=====================================================================
 Q1 — Update Employee Salary
=====================================================================

Business Requirement:
HR needs a reusable procedure to update an employee's salary.

Rules:
- Employee must exist.
- Salary cannot be negative.
- NULL salary is not allowed.
- Existing employee salary will be replaced.

=====================================================================
*/

DROP PROCEDURE IF EXISTS update_employee_salary(BIGINT, NUMERIC);

CREATE OR REPLACE PROCEDURE update_employee_salary(
    IN p_emp_id BIGINT,
    IN p_new_salary NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_old_salary NUMERIC;
BEGIN

    -- Validate employee
    SELECT basic_salary
    INTO v_old_salary
    FROM employees
    WHERE emp_id = p_emp_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Employee with ID % does not exist.',
            p_emp_id;
    END IF;

    -- Validate salary
    IF p_new_salary IS NULL OR p_new_salary < 0 THEN
        RAISE EXCEPTION
            'Invalid salary %. Salary must be >= 0.',
            p_new_salary;
    END IF;

    -- Update salary
    UPDATE employees
    SET
        basic_salary = p_new_salary,
        updated_at = CURRENT_TIMESTAMP
    WHERE emp_id = p_emp_id;

    RAISE NOTICE
        'Employee % salary updated from % to %.',
        p_emp_id,
        v_old_salary,
        p_new_salary;

END;
$$;


/*
Example:
CALL update_employee_salary(1, 130000);
*/


/*
=====================================================================
 Q2 — Update Employee Employment Status
=====================================================================

Business Requirement:
HR needs to change an employee's employment status.

Allowed:
- Active
- On Leave
- Resigned
- Terminated

is_active must be synchronized automatically.

=====================================================================
*/

DROP PROCEDURE IF EXISTS update_employee_status(BIGINT, VARCHAR);

CREATE OR REPLACE PROCEDURE update_employee_status(
    IN p_emp_id BIGINT,
    IN p_new_status VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM employees
        WHERE emp_id = p_emp_id
    ) THEN
        RAISE EXCEPTION
            'Employee with ID % does not exist.',
            p_emp_id;
    END IF;

    IF p_new_status NOT IN
        ('Active', 'On Leave', 'Resigned', 'Terminated')
    THEN
        RAISE EXCEPTION
            'Invalid employment status: %.',
            p_new_status;
    END IF;

    UPDATE employees
    SET
        employment_status = p_new_status,
        is_active =
            CASE
                WHEN p_new_status IN ('Active', 'On Leave')
                    THEN TRUE
                ELSE FALSE
            END,
        updated_at = CURRENT_TIMESTAMP
    WHERE emp_id = p_emp_id;

    RAISE NOTICE
        'Employee % status changed to %.',
        p_emp_id,
        p_new_status;

END;
$$;


/*
Example:
CALL update_employee_status(5, 'On Leave');
*/


/*
=====================================================================
 Q3 — Add New Employee
=====================================================================

Business Requirement:
HR wants a controlled procedure for employee onboarding.

Validation:
- Employee code unique
- Email unique
- Department exists
- Job role exists
- Manager exists if supplied
- Salary >= 0
- DOB < Hire Date
- Hire Date <= Current Date

=====================================================================
*/

DROP PROCEDURE IF EXISTS add_employee(
    VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR, VARCHAR,
    DATE, DATE, BIGINT, BIGINT, BIGINT, VARCHAR, NUMERIC
);

CREATE OR REPLACE PROCEDURE add_employee(
    IN p_emp_code VARCHAR,
    IN p_fname VARCHAR,
    IN p_lname VARCHAR,
    IN p_email VARCHAR,
    IN p_phone_number VARCHAR,
    IN p_gender VARCHAR,
    IN p_date_of_birth DATE,
    IN p_hire_date DATE,
    IN p_department_id BIGINT,
    IN p_job_role_id BIGINT,
    IN p_manager_id BIGINT,
    IN p_employment_status VARCHAR,
    IN p_basic_salary NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_new_emp_id BIGINT;
BEGIN

    IF EXISTS (
        SELECT 1
        FROM employees
        WHERE emp_code = p_emp_code
    ) THEN
        RAISE EXCEPTION
            'Employee code % already exists.',
            p_emp_code;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM employees
        WHERE email = p_email
    ) THEN
        RAISE EXCEPTION
            'Email % already exists.',
            p_email;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM departments
        WHERE department_id = p_department_id
    ) THEN
        RAISE EXCEPTION
            'Department ID % does not exist.',
            p_department_id;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM job_roles
        WHERE job_role_id = p_job_role_id
    ) THEN
        RAISE EXCEPTION
            'Job role ID % does not exist.',
            p_job_role_id;
    END IF;

    IF p_manager_id IS NOT NULL
       AND NOT EXISTS (
           SELECT 1
           FROM employees
           WHERE emp_id = p_manager_id
       )
    THEN
        RAISE EXCEPTION
            'Manager ID % does not exist.',
            p_manager_id;
    END IF;

    IF p_basic_salary IS NULL OR p_basic_salary < 0 THEN
        RAISE EXCEPTION
            'Salary must be greater than or equal to 0.';
    END IF;

    IF p_date_of_birth >= p_hire_date THEN
        RAISE EXCEPTION
            'Date of birth must be earlier than hire date.';
    END IF;

    IF p_hire_date > CURRENT_DATE THEN
        RAISE EXCEPTION
            'Hire date cannot be in the future.';
    END IF;

    INSERT INTO employees
    (
        emp_code,
        fname,
        lname,
        email,
        phone_number,
        gender,
        date_of_birth,
        hire_date,
        department_id,
        job_role_id,
        manager_id,
        employment_status,
        basic_salary
    )
    VALUES
    (
        p_emp_code,
        p_fname,
        p_lname,
        p_email,
        p_phone_number,
        p_gender,
        p_date_of_birth,
        p_hire_date,
        p_department_id,
        p_job_role_id,
        p_manager_id,
        p_employment_status,
        p_basic_salary
    )
    RETURNING emp_id
    INTO v_new_emp_id;

    RAISE NOTICE
        'Employee created successfully. Employee ID: %',
        v_new_emp_id;

END;
$$;


/*
=====================================================================
 Q4 — Transfer Employee
=====================================================================

Business Requirement:
Move an employee from one department to another.

Rules:
- Employee must exist.
- New department must exist.
- Current and new department cannot be same.

=====================================================================
*/

DROP PROCEDURE IF EXISTS transfer_employee(BIGINT, BIGINT);

CREATE OR REPLACE PROCEDURE transfer_employee(
    IN p_emp_id BIGINT,
    IN p_new_department_id BIGINT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_current_department BIGINT;
BEGIN

    SELECT department_id
    INTO v_current_department
    FROM employees
    WHERE emp_id = p_emp_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Employee ID % does not exist.',
            p_emp_id;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM departments
        WHERE department_id = p_new_department_id
    ) THEN
        RAISE EXCEPTION
            'Department ID % does not exist.',
            p_new_department_id;
    END IF;

    IF v_current_department = p_new_department_id THEN
        RAISE EXCEPTION
            'Employee % is already in department %.',
            p_emp_id,
            p_new_department_id;
    END IF;

    UPDATE employees
    SET
        department_id = p_new_department_id,
        updated_at = CURRENT_TIMESTAMP
    WHERE emp_id = p_emp_id;

    RAISE NOTICE
        'Employee % transferred from department % to department %.',
        p_emp_id,
        v_current_department,
        p_new_department_id;

END;
$$;


/*
=====================================================================
 Q5 — Promote Employee
=====================================================================

Business Requirement:
Promote an employee to another job role and update salary.

Rules:
- Employee exists.
- Job role exists.
- Salary >= role minimum.
- Salary <= role maximum.

=====================================================================
*/

DROP PROCEDURE IF EXISTS promote_employee(BIGINT, BIGINT, NUMERIC);

CREATE OR REPLACE PROCEDURE promote_employee(
    IN p_emp_id BIGINT,
    IN p_new_job_role_id BIGINT,
    IN p_new_salary NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_min_salary NUMERIC;
    v_max_salary NUMERIC;
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM employees
        WHERE emp_id = p_emp_id
    ) THEN
        RAISE EXCEPTION
            'Employee ID % does not exist.',
            p_emp_id;
    END IF;

    SELECT min_salary, max_salary
    INTO v_min_salary, v_max_salary
    FROM job_roles
    WHERE job_role_id = p_new_job_role_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Job role ID % does not exist.',
            p_new_job_role_id;
    END IF;

    IF p_new_salary < v_min_salary
       OR p_new_salary > v_max_salary
    THEN
        RAISE EXCEPTION
            'Salary % is outside job role salary range [% - %].',
            p_new_salary,
            v_min_salary,
            v_max_salary;
    END IF;

    UPDATE employees
    SET
        job_role_id = p_new_job_role_id,
        basic_salary = p_new_salary,
        updated_at = CURRENT_TIMESTAMP
    WHERE emp_id = p_emp_id;

    RAISE NOTICE
        'Employee % promoted successfully.',
        p_emp_id;

END;
$$;


/*
=====================================================================
 Q6 — Apply Employee Salary Increment
=====================================================================
*/

DROP PROCEDURE IF EXISTS apply_salary_increment(BIGINT, NUMERIC);

CREATE OR REPLACE PROCEDURE apply_salary_increment(
    IN p_emp_id BIGINT,
    IN p_increment_percentage NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_old_salary NUMERIC;
    v_new_salary NUMERIC;
    v_max_salary NUMERIC;
BEGIN

    SELECT e.basic_salary, j.max_salary
    INTO v_old_salary, v_max_salary
    FROM employees e
    JOIN job_roles j
        ON e.job_role_id = j.job_role_id
    WHERE e.emp_id = p_emp_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Employee ID % does not exist.',
            p_emp_id;
    END IF;

    IF p_increment_percentage < 0
       OR p_increment_percentage > 100
    THEN
        RAISE EXCEPTION
            'Increment percentage must be between 0 and 100.';
    END IF;

    v_new_salary :=
        v_old_salary +
        (v_old_salary * p_increment_percentage / 100);

    IF v_new_salary > v_max_salary THEN
        RAISE EXCEPTION
            'New salary % exceeds job role maximum salary %.',
            v_new_salary,
            v_max_salary;
    END IF;

    UPDATE employees
    SET
        basic_salary = v_new_salary,
        updated_at = CURRENT_TIMESTAMP
    WHERE emp_id = p_emp_id;

    RAISE NOTICE
        'Salary updated from % to %.',
        v_old_salary,
        v_new_salary;

END;
$$;


/*
=====================================================================
 Q7 — Department-Wide Salary Increment
=====================================================================

Business Requirement:
Apply salary increment to all employees of a department.

Important:
If any employee exceeds their job-role salary maximum,
the procedure must fail before performing the update.

=====================================================================
*/

DROP PROCEDURE IF EXISTS apply_department_increment(BIGINT, NUMERIC);

CREATE OR REPLACE PROCEDURE apply_department_increment(
    IN p_department_id BIGINT,
    IN p_increment_percentage NUMERIC
)
LANGUAGE plpgsql
AS $$
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM departments
        WHERE department_id = p_department_id
    ) THEN
        RAISE EXCEPTION
            'Department ID % does not exist.',
            p_department_id;
    END IF;

    IF p_increment_percentage < 0
       OR p_increment_percentage > 100
    THEN
        RAISE EXCEPTION
            'Increment percentage must be between 0 and 100.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM employees e
        JOIN job_roles j
            ON e.job_role_id = j.job_role_id
        WHERE e.department_id = p_department_id
          AND (
              e.basic_salary +
              (e.basic_salary * p_increment_percentage / 100)
          ) > j.max_salary
    )
    THEN
        RAISE EXCEPTION
            'Increment cannot be applied because one or more employees would exceed their job role maximum salary.';
    END IF;

    UPDATE employees
    SET
        basic_salary =
            basic_salary +
            (basic_salary * p_increment_percentage / 100),
        updated_at = CURRENT_TIMESTAMP
    WHERE department_id = p_department_id;

    RAISE NOTICE
        'Department % salary increment of %%% applied successfully.',
        p_department_id,
        p_increment_percentage;

END;
$$;


/*
=====================================================================
 Q8 — Assign Manager
=====================================================================
*/

DROP PROCEDURE IF EXISTS assign_manager(BIGINT, BIGINT);

CREATE OR REPLACE PROCEDURE assign_manager(
    IN p_employee_id BIGINT,
    IN p_manager_id BIGINT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_employee_department BIGINT;
    v_manager_department BIGINT;
BEGIN

    SELECT department_id
    INTO v_employee_department
    FROM employees
    WHERE emp_id = p_employee_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Employee ID % does not exist.',
            p_employee_id;
    END IF;

    IF p_employee_id = p_manager_id THEN
        RAISE EXCEPTION
            'An employee cannot be their own manager.';
    END IF;

    SELECT department_id
    INTO v_manager_department
    FROM employees
    WHERE emp_id = p_manager_id
      AND employment_status = 'Active';

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Manager ID % does not exist or manager is not active.',
            p_manager_id;
    END IF;

    IF v_employee_department <> v_manager_department THEN
        RAISE EXCEPTION
            'Employee and manager must belong to the same department.';
    END IF;

    UPDATE employees
    SET
        manager_id = p_manager_id,
        updated_at = CURRENT_TIMESTAMP
    WHERE emp_id = p_employee_id;

    RAISE NOTICE
        'Manager % assigned to employee %.',
        p_manager_id,
        p_employee_id;

END;
$$;


/*
=====================================================================
 Q9 — Remove Manager
=====================================================================
*/

DROP PROCEDURE IF EXISTS remove_manager(BIGINT);

CREATE OR REPLACE PROCEDURE remove_manager(
    IN p_emp_id BIGINT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_manager_id BIGINT;
BEGIN

    SELECT manager_id
    INTO v_manager_id
    FROM employees
    WHERE emp_id = p_emp_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Employee ID % does not exist.',
            p_emp_id;
    END IF;

    IF v_manager_id IS NULL THEN
        RAISE NOTICE
            'Employee % has no manager assigned.',
            p_emp_id;
        RETURN;
    END IF;

    UPDATE employees
    SET
        manager_id = NULL,
        updated_at = CURRENT_TIMESTAMP
    WHERE emp_id = p_emp_id;

    RAISE NOTICE
        'Manager removed from employee %.',
        p_emp_id;

END;
$$;


/*
=====================================================================
 Q10 — Transfer Employee With New Department Manager
=====================================================================

Business Requirement:
Transfer employee to another department and automatically
assign the new department manager.

=====================================================================
*/

DROP PROCEDURE IF EXISTS transfer_employee_with_manager(BIGINT, BIGINT);

CREATE OR REPLACE PROCEDURE transfer_employee_with_manager(
    IN p_emp_id BIGINT,
    IN p_new_department_id BIGINT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_new_manager_id BIGINT;
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM employees
        WHERE emp_id = p_emp_id
    ) THEN
        RAISE EXCEPTION
            'Employee ID % does not exist.',
            p_emp_id;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM departments
        WHERE department_id = p_new_department_id
    ) THEN
        RAISE EXCEPTION
            'Department ID % does not exist.',
            p_new_department_id;
    END IF;

    SELECT manager_id
    INTO v_new_manager_id
    FROM departments
    WHERE department_id = p_new_department_id;

    IF v_new_manager_id IS NULL THEN
        RAISE EXCEPTION
            'New department % does not have a manager assigned.',
            p_new_department_id;
    END IF;

    IF v_new_manager_id = p_emp_id THEN
        RAISE EXCEPTION
            'Employee cannot be assigned as their own manager.';
    END IF;

    UPDATE employees
    SET
        department_id = p_new_department_id,
        manager_id = v_new_manager_id,
        updated_at = CURRENT_TIMESTAMP
    WHERE emp_id = p_emp_id;

    RAISE NOTICE
        'Employee % transferred to department % under manager %.',
        p_emp_id,
        p_new_department_id,
        v_new_manager_id;

END;
$$;


/*
=====================================================================
 Q11 — Controlled Salary Adjustment
=====================================================================

Business Requirement:
Salary must remain within the job role salary range.

=====================================================================
*/

DROP PROCEDURE IF EXISTS adjust_employee_salary(BIGINT, NUMERIC);

CREATE OR REPLACE PROCEDURE adjust_employee_salary(
    IN p_emp_id BIGINT,
    IN p_new_salary NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_old_salary NUMERIC;
    v_min_salary NUMERIC;
    v_max_salary NUMERIC;
    v_salary_change NUMERIC;
BEGIN

    SELECT
        e.basic_salary,
        j.min_salary,
        j.max_salary
    INTO
        v_old_salary,
        v_min_salary,
        v_max_salary
    FROM employees e
    JOIN job_roles j
        ON e.job_role_id = j.job_role_id
    WHERE e.emp_id = p_emp_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Employee ID % does not exist.',
            p_emp_id;
    END IF;

    IF p_new_salary < v_min_salary
       OR p_new_salary > v_max_salary
    THEN
        RAISE EXCEPTION
            'Salary % must be between % and %.',
            p_new_salary,
            v_min_salary,
            v_max_salary;
    END IF;

    v_salary_change :=
        p_new_salary - v_old_salary;

    UPDATE employees
    SET
        basic_salary = p_new_salary,
        updated_at = CURRENT_TIMESTAMP
    WHERE emp_id = p_emp_id;

    RAISE NOTICE 'Employee ID: %', p_emp_id;
    RAISE NOTICE 'Old Salary: %', v_old_salary;
    RAISE NOTICE 'New Salary: %', p_new_salary;
    RAISE NOTICE 'Salary Change: %', v_salary_change;

END;
$$;


/*
=====================================================================
 Q12 — Terminate Employee
=====================================================================

Business Requirement:
Terminate employee only if they have no direct reports.

Changes:
- employment_status = Terminated
- is_active = FALSE
- manager_id = NULL

=====================================================================
*/

DROP PROCEDURE IF EXISTS terminate_employee(BIGINT);

CREATE OR REPLACE PROCEDURE terminate_employee(
    IN p_emp_id BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM employees
        WHERE emp_id = p_emp_id
    ) THEN
        RAISE EXCEPTION
            'Employee ID % does not exist.',
            p_emp_id;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM employees
        WHERE manager_id = p_emp_id
    ) THEN
        RAISE EXCEPTION
            'Employee % cannot be terminated because direct reports are assigned to this employee.',
            p_emp_id;
    END IF;

    UPDATE employees
    SET
        employment_status = 'Terminated',
        is_active = FALSE,
        manager_id = NULL,
        updated_at = CURRENT_TIMESTAMP
    WHERE emp_id = p_emp_id;

    RAISE NOTICE
        'Employee % terminated successfully.',
        p_emp_id;

END;
$$;


/*
=====================================================================
 Q13 — Deactivate Department
=====================================================================

Business Requirement:
Deactivate a department.

Active employees of that department are moved to:
On Leave

Resigned/Terminated employees remain unchanged.

=====================================================================
*/

DROP PROCEDURE IF EXISTS deactivate_department(BIGINT);

CREATE OR REPLACE PROCEDURE deactivate_department(
    IN p_department_id BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM departments
        WHERE department_id = p_department_id
    ) THEN
        RAISE EXCEPTION
            'Department ID % does not exist.',
            p_department_id;
    END IF;

    UPDATE departments
    SET
        is_active = FALSE,
        updated_at = CURRENT_TIMESTAMP
    WHERE department_id = p_department_id;

    UPDATE employees
    SET
        employment_status = 'On Leave',
        updated_at = CURRENT_TIMESTAMP
    WHERE department_id = p_department_id
      AND employment_status = 'Active';

    RAISE NOTICE
        'Department % deactivated successfully.',
        p_department_id;

END;
$$;


/*
=====================================================================
 Q14 — Employee Promotion Workflow
=====================================================================

Business Requirement:
Complete promotion workflow.

Steps:
1. Validate employee
2. Validate employee is active
3. Validate job role
4. Validate salary range
5. Update job role
6. Update salary
7. Display promotion summary

=====================================================================
*/

DROP PROCEDURE IF EXISTS promote_employee_workflow(BIGINT, BIGINT, NUMERIC);

CREATE OR REPLACE PROCEDURE promote_employee_workflow(
    IN p_emp_id BIGINT,
    IN p_new_job_role_id BIGINT,
    IN p_new_salary NUMERIC
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_employee_name VARCHAR;
    v_old_role VARCHAR;
    v_new_role VARCHAR;
    v_old_salary NUMERIC;
    v_salary_increase NUMERIC;
    v_increase_percentage NUMERIC;
    v_min_salary NUMERIC;
    v_max_salary NUMERIC;
BEGIN

    SELECT
        CONCAT_WS(' ', e.fname, e.lname),
        j.job_title,
        e.basic_salary
    INTO
        v_employee_name,
        v_old_role,
        v_old_salary
    FROM employees e
    JOIN job_roles j
        ON e.job_role_id = j.job_role_id
    WHERE e.emp_id = p_emp_id
      AND e.employment_status = 'Active';

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Employee % does not exist or is not active.',
            p_emp_id;
    END IF;

    SELECT
        job_title,
        min_salary,
        max_salary
    INTO
        v_new_role,
        v_min_salary,
        v_max_salary
    FROM job_roles
    WHERE job_role_id = p_new_job_role_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'Job role % does not exist.',
            p_new_job_role_id;
    END IF;

    IF p_new_salary < v_min_salary
       OR p_new_salary > v_max_salary
    THEN
        RAISE EXCEPTION
            'New salary % is outside role salary range [% - %].',
            p_new_salary,
            v_min_salary,
            v_max_salary;
    END IF;

    v_salary_increase :=
        p_new_salary - v_old_salary;

    IF v_old_salary > 0 THEN
        v_increase_percentage :=
            (v_salary_increase / v_old_salary) * 100;
    ELSE
        v_increase_percentage := NULL;
    END IF;

    UPDATE employees
    SET
        job_role_id = p_new_job_role_id,
        basic_salary = p_new_salary,
        updated_at = CURRENT_TIMESTAMP
    WHERE emp_id = p_emp_id;

    RAISE NOTICE '===========================================';
    RAISE NOTICE 'EMPLOYEE PROMOTION SUMMARY';
    RAISE NOTICE '===========================================';
    RAISE NOTICE 'Employee       : %', v_employee_name;
    RAISE NOTICE 'Old Role       : %', v_old_role;
    RAISE NOTICE 'New Role       : %', v_new_role;
    RAISE NOTICE 'Old Salary     : %', v_old_salary;
    RAISE NOTICE 'New Salary     : %', p_new_salary;
    RAISE NOTICE 'Salary Increase: %', v_salary_increase;
    RAISE NOTICE 'Increase %%     : %', ROUND(v_increase_percentage, 2);
    RAISE NOTICE '===========================================';

END;
$$;


/*
=====================================================================
 Q15 — Executive Department Restructure
=====================================================================

Business Requirement:
CEO wants to move all employees from one department to another.

Process:
1. Validate old department.
2. Validate new department.
3. Validate new manager.
4. New manager must be active.
5. Move all employees.
6. Assign new manager.
7. Deactivate old department.
8. Display restructure summary.

=====================================================================
*/

DROP PROCEDURE IF EXISTS restructure_department(BIGINT, BIGINT, BIGINT);

CREATE OR REPLACE PROCEDURE restructure_department(
    IN p_old_department_id BIGINT,
    IN p_new_department_id BIGINT,
    IN p_new_manager_id BIGINT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_employee_count BIGINT;
    v_manager_name VARCHAR;
BEGIN

    -- Validate old department
    IF NOT EXISTS (
        SELECT 1
        FROM departments
        WHERE department_id = p_old_department_id
    ) THEN
        RAISE EXCEPTION
            'Old department ID % does not exist.',
            p_old_department_id;
    END IF;

    -- Validate new department
    IF NOT EXISTS (
        SELECT 1
        FROM departments
        WHERE department_id = p_new_department_id
    ) THEN
        RAISE EXCEPTION
            'New department ID % does not exist.',
            p_new_department_id;
    END IF;

    -- Prevent same department
    IF p_old_department_id = p_new_department_id THEN
        RAISE EXCEPTION
            'Old and new department cannot be the same.';
    END IF;

    -- Validate manager
    SELECT CONCAT_WS(' ', fname, lname)
    INTO v_manager_name
    FROM employees
    WHERE emp_id = p_new_manager_id
      AND employment_status = 'Active';

    IF NOT FOUND THEN
        RAISE EXCEPTION
            'New manager ID % does not exist or is not active.',
            p_new_manager_id;
    END IF;

    -- Count employees before movement
    SELECT COUNT(*)
    INTO v_employee_count
    FROM employees
    WHERE department_id = p_old_department_id;

    -- Move employees
    UPDATE employees
    SET
        department_id = p_new_department_id,
        manager_id = p_new_manager_id,
        updated_at = CURRENT_TIMESTAMP
    WHERE department_id = p_old_department_id;

    -- Deactivate old department
    UPDATE departments
    SET
        is_active = FALSE,
        updated_at = CURRENT_TIMESTAMP
    WHERE department_id = p_old_department_id;

    -- Executive summary
    RAISE NOTICE '===========================================';
    RAISE NOTICE 'DEPARTMENT RESTRUCTURE COMPLETED';
    RAISE NOTICE '===========================================';
    RAISE NOTICE 'Employees Moved : %', v_employee_count;
    RAISE NOTICE 'Old Department  : %', p_old_department_id;
    RAISE NOTICE 'New Department  : %', p_new_department_id;
    RAISE NOTICE 'New Manager     : %', v_manager_name;
    RAISE NOTICE '===========================================';

END;
$$;


/*
=====================================================================
 PROCEDURE TESTING SECTION
=====================================================================

Run these individually after creating the procedures.

=====================================================================
*/

-- Q1
-- CALL update_employee_salary(1, 130000);

-- Q2
-- CALL update_employee_status(5, 'On Leave');

-- Q3
-- CALL add_employee(
--     'EMP016',
--     'Aman',
--     'Sharma',
--     'aman.sharma@peoplepulse.com',
--     '9876500016',
--     'Male',
--     '1998-04-15',
--     CURRENT_DATE,
--     1,
--     1,
--     NULL,
--     'Active',
--     60000
-- );

-- Q4
-- CALL transfer_employee(7, 3);

-- Q5
-- CALL promote_employee(3, 2, 90000);

-- Q6
-- CALL apply_salary_increment(3, 10);

-- Q7
-- CALL apply_department_increment(1, 5);

-- Q8
-- CALL assign_manager(2, 1);

-- Q9
-- CALL remove_manager(2);

-- Q10
-- CALL transfer_employee_with_manager(7, 3);

-- Q11
-- CALL adjust_employee_salary(3, 70000);

-- Q12
-- CALL terminate_employee(3);

-- Q13
-- CALL deactivate_department(5);

-- Q14
-- CALL promote_employee_workflow(3, 2, 90000);

-- Q15
-- CALL restructure_department(1, 6, 11);


/*
=====================================================================
 END OF STORED PROCEDURES MODULE
=====================================================================
*/