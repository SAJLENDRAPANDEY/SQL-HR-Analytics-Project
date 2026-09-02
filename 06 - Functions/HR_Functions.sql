/*
=====================================================================
 Project      : PeoplePulse HR Analytics PostgreSQL
 Module       : 06 - Functions
 File         : HR_Functions.sql
 Database     : PostgreSQL
 Author       : Sajlendra Pandey

 Purpose:
 Reusable business logic using PostgreSQL User-Defined Functions.

 Topics:
 - Scalar Functions
 - Function Parameters
 - Return Values
 - Conditional Logic
 - Date Functions
 - Salary Calculations
 - Employee Analytics
 - Department Analytics
 - Table-Returning Functions
 - Window Functions inside Functions
 - Business Rules

 Difficulty:
 Advanced → Expert

 Total Functions:
 15
=====================================================================
*/


SET search_path TO peoplepulse;


-- ===================================================================
-- LEVEL 1 — BASIC SCALAR FUNCTIONS
-- ===================================================================


/*
=====================================================================
Q1 — Employee Full Name Function
=====================================================================

Business Requirement:
Return the complete name of an employee using Employee ID.

Input:
    Employee ID

Output:
    Employee Full Name

Example:
    SELECT get_employee_full_name(1);

Expected:
    Rahul Sharma
=====================================================================
*/

DROP FUNCTION IF EXISTS get_employee_full_name(BIGINT);

CREATE OR REPLACE FUNCTION get_employee_full_name(
    p_emp_id BIGINT
)
RETURNS VARCHAR
LANGUAGE plpgsql
AS $$
DECLARE
    v_full_name VARCHAR;
BEGIN

    SELECT CONCAT_WS(' ', fname, lname)
    INTO v_full_name
    FROM employees
    WHERE emp_id = p_emp_id;

    RETURN v_full_name;

END;
$$;


-- Test
SELECT get_employee_full_name(1);

-- Non-existing employee → NULL
SELECT get_employee_full_name(9999);



/*
=====================================================================
Q2 — Employee Salary Function
=====================================================================

Business Requirement:
Return the current basic salary of an employee.

Input:
    Employee ID

Output:
    Basic Salary

If employee does not exist:
    Return NULL.
=====================================================================
*/

DROP FUNCTION IF EXISTS get_employee_salary(BIGINT);

CREATE OR REPLACE FUNCTION get_employee_salary(
    p_emp_id BIGINT
)
RETURNS NUMERIC(10,2)
LANGUAGE plpgsql
AS $$
DECLARE
    v_salary NUMERIC(10,2);
BEGIN

    SELECT basic_salary
    INTO v_salary
    FROM employees
    WHERE emp_id = p_emp_id;

    RETURN v_salary;

END;
$$;


-- Test
SELECT get_employee_salary(1);

SELECT get_employee_salary(9999);



/*
=====================================================================
Q3 — Salary Band Function
=====================================================================

Business Requirement:
Classify employee salary into predefined salary bands.

Rules:

< 50000           → Low
50000–100000      → Medium
100001–150000     → High
> 150000          → Executive

Input:
    Salary

Output:
    Salary Band
=====================================================================
*/

DROP FUNCTION IF EXISTS get_salary_band(NUMERIC);

CREATE OR REPLACE FUNCTION get_salary_band(
    p_salary NUMERIC
)
RETURNS VARCHAR
LANGUAGE plpgsql
AS $$
BEGIN

    RETURN CASE

        WHEN p_salary < 50000
            THEN 'Low'

        WHEN p_salary BETWEEN 50000 AND 100000
            THEN 'Medium'

        WHEN p_salary BETWEEN 100001 AND 150000
            THEN 'High'

        WHEN p_salary > 150000
            THEN 'Executive'

        ELSE 'Unknown'

    END;

END;
$$;


-- Tests
SELECT get_salary_band(40000);
SELECT get_salary_band(75000);
SELECT get_salary_band(120000);
SELECT get_salary_band(180000);



-- ===================================================================
-- LEVEL 2 — EMPLOYEE BUSINESS LOGIC
-- ===================================================================


/*
=====================================================================
Q4 — Employee Experience Function
=====================================================================

Business Requirement:
Calculate completed years of experience for an employee.

Input:
    Employee ID

Output:
    Experience in completed years.

Based on:
    hire_date
=====================================================================
*/

DROP FUNCTION IF EXISTS get_employee_experience(BIGINT);

CREATE OR REPLACE FUNCTION get_employee_experience(
    p_emp_id BIGINT
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_hire_date DATE;
BEGIN

    SELECT hire_date
    INTO v_hire_date
    FROM employees
    WHERE emp_id = p_emp_id;

    IF v_hire_date IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN EXTRACT(
        YEAR FROM AGE(CURRENT_DATE, v_hire_date)
    )::INTEGER;

END;
$$;


-- Test
SELECT
    emp_code,
    get_employee_experience(emp_id) AS experience_years
FROM employees;



/*
=====================================================================
Q5 — Employee Age Function
=====================================================================

Business Requirement:
Calculate current age of an employee.

Input:
    Employee ID

Output:
    Age in completed years.

Based on:
    date_of_birth
=====================================================================
*/

DROP FUNCTION IF EXISTS get_employee_age(BIGINT);

CREATE OR REPLACE FUNCTION get_employee_age(
    p_emp_id BIGINT
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_dob DATE;
BEGIN

    SELECT date_of_birth
    INTO v_dob
    FROM employees
    WHERE emp_id = p_emp_id;

    IF v_dob IS NULL THEN
        RETURN NULL;
    END IF;

    RETURN EXTRACT(
        YEAR FROM AGE(CURRENT_DATE, v_dob)
    )::INTEGER;

END;
$$;


-- Test
SELECT
    emp_code,
    get_employee_age(emp_id) AS employee_age
FROM employees;



/*
=====================================================================
Q6 — Salary Increment Calculator
=====================================================================

Business Requirement:
Calculate new salary after applying a percentage increment.

Formula:

New Salary =
Current Salary +
(Current Salary × Percentage / 100)

Input:
    Employee ID
    Increment Percentage

Example:
    Salary = 100000
    Increment = 10%

    New Salary = 110000
=====================================================================
*/

DROP FUNCTION IF EXISTS calculate_salary_increment(BIGINT, NUMERIC);

CREATE OR REPLACE FUNCTION calculate_salary_increment(
    p_emp_id BIGINT,
    p_percentage NUMERIC
)
RETURNS NUMERIC(12,2)
LANGUAGE plpgsql
AS $$
DECLARE
    v_current_salary NUMERIC(10,2);
    v_new_salary NUMERIC(12,2);
BEGIN

    SELECT basic_salary
    INTO v_current_salary
    FROM employees
    WHERE emp_id = p_emp_id;

    IF v_current_salary IS NULL THEN
        RETURN NULL;
    END IF;

    v_new_salary :=
        v_current_salary +
        (v_current_salary * p_percentage / 100);

    RETURN ROUND(v_new_salary, 2);

END;
$$;


-- Test
SELECT calculate_salary_increment(1, 10);

SELECT calculate_salary_increment(1, 15);



-- ===================================================================
-- LEVEL 3 — CONDITIONAL BUSINESS FUNCTIONS
-- ===================================================================


/*
=====================================================================
Q7 — Employee Risk Level
=====================================================================

Business Requirement:
Classify employees according to compensation,
experience and employment status.

Business Rules:

High Risk:
    - Resigned / Terminated
      OR
    - Salary below 50000

Medium Risk:
    - Salary below 70000
      OR
    - Experience below 2 years

Low Risk:
    - All other employees

Input:
    Employee ID

Output:
    Risk Level
=====================================================================
*/

DROP FUNCTION IF EXISTS get_employee_risk(BIGINT);

CREATE OR REPLACE FUNCTION get_employee_risk(
    p_emp_id BIGINT
)
RETURNS VARCHAR
LANGUAGE plpgsql
AS $$
DECLARE
    v_salary NUMERIC;
    v_status VARCHAR;
    v_hire_date DATE;
    v_experience INTEGER;
BEGIN

    SELECT
        basic_salary,
        employment_status,
        hire_date
    INTO
        v_salary,
        v_status,
        v_hire_date
    FROM employees
    WHERE emp_id = p_emp_id;

    IF v_salary IS NULL THEN
        RETURN NULL;
    END IF;

    v_experience :=
        EXTRACT(
            YEAR FROM AGE(CURRENT_DATE, v_hire_date)
        )::INTEGER;

    IF v_status IN ('Resigned', 'Terminated')
       OR v_salary < 50000 THEN

        RETURN 'High Risk';

    ELSIF v_salary < 70000
       OR v_experience < 2 THEN

        RETURN 'Medium Risk';

    ELSE

        RETURN 'Low Risk';

    END IF;

END;
$$;


-- Test
SELECT
    emp_code,
    get_employee_risk(emp_id) AS risk_level
FROM employees;



/*
=====================================================================
Q8 — Department Average Salary
=====================================================================

Business Requirement:
Return the average salary of a department.

Input:
    Department ID

Output:
    Average Department Salary

If department has no employees:
    NULL
=====================================================================
*/

DROP FUNCTION IF EXISTS get_department_avg_salary(BIGINT);

CREATE OR REPLACE FUNCTION get_department_avg_salary(
    p_department_id BIGINT
)
RETURNS NUMERIC(12,2)
LANGUAGE plpgsql
AS $$
DECLARE
    v_average_salary NUMERIC(12,2);
BEGIN

    SELECT ROUND(AVG(basic_salary), 2)
    INTO v_average_salary
    FROM employees
    WHERE department_id = p_department_id;

    RETURN v_average_salary;

END;
$$;


-- Test
SELECT get_department_avg_salary(1);



/*
=====================================================================
Q9 — Employee Salary Position
=====================================================================

Business Requirement:
Compare an employee's salary with the average salary
of their department.

Output:

Above Average
Below Average
Equal Average
=====================================================================
*/

DROP FUNCTION IF EXISTS get_salary_position(BIGINT);

CREATE OR REPLACE FUNCTION get_salary_position(
    p_emp_id BIGINT
)
RETURNS VARCHAR
LANGUAGE plpgsql
AS $$
DECLARE
    v_salary NUMERIC;
    v_department_id BIGINT;
    v_department_avg NUMERIC;
BEGIN

    SELECT
        basic_salary,
        department_id
    INTO
        v_salary,
        v_department_id
    FROM employees
    WHERE emp_id = p_emp_id;

    IF v_salary IS NULL THEN
        RETURN NULL;
    END IF;

    SELECT AVG(basic_salary)
    INTO v_department_avg
    FROM employees
    WHERE department_id = v_department_id;

    IF v_salary > v_department_avg THEN

        RETURN 'Above Average';

    ELSIF v_salary < v_department_avg THEN

        RETURN 'Below Average';

    ELSE

        RETURN 'Equal Average';

    END IF;

END;
$$;


-- Test
SELECT
    emp_code,
    get_salary_position(emp_id) AS salary_position
FROM employees;



-- ===================================================================
-- LEVEL 4 — ADVANCED FUNCTIONS
-- ===================================================================


/*
=====================================================================
Q10 — Employee Salary Gap
=====================================================================

Business Requirement:
Calculate the difference between employee salary
and department average salary.

Formula:

Employee Salary
-
Department Average Salary

Positive value:
    Employee earns above department average.

Negative value:
    Employee earns below department average.
=====================================================================
*/

DROP FUNCTION IF EXISTS get_salary_gap(BIGINT);

CREATE OR REPLACE FUNCTION get_salary_gap(
    p_emp_id BIGINT
)
RETURNS NUMERIC(12,2)
LANGUAGE plpgsql
AS $$
DECLARE
    v_salary NUMERIC;
    v_department_id BIGINT;
    v_avg_salary NUMERIC;
BEGIN

    SELECT
        basic_salary,
        department_id
    INTO
        v_salary,
        v_department_id
    FROM employees
    WHERE emp_id = p_emp_id;

    IF v_salary IS NULL THEN
        RETURN NULL;
    END IF;

    SELECT AVG(basic_salary)
    INTO v_avg_salary
    FROM employees
    WHERE department_id = v_department_id;

    RETURN ROUND(
        v_salary - v_avg_salary,
        2
    );

END;
$$;


-- Test
SELECT
    emp_code,
    get_salary_gap(emp_id) AS salary_gap
FROM employees;



/*
=====================================================================
Q11 — Department Payroll
=====================================================================

Business Requirement:
Calculate total salary expense of a department.

Formula:

SUM(basic_salary)

Input:
    Department ID

Output:
    Total Department Payroll
=====================================================================
*/

DROP FUNCTION IF EXISTS get_department_payroll(BIGINT);

CREATE OR REPLACE FUNCTION get_department_payroll(
    p_department_id BIGINT
)
RETURNS NUMERIC(15,2)
LANGUAGE plpgsql
AS $$
DECLARE
    v_payroll NUMERIC(15,2);
BEGIN

    SELECT COALESCE(SUM(basic_salary), 0)
    INTO v_payroll
    FROM employees
    WHERE department_id = p_department_id;

    RETURN v_payroll;

END;
$$;


-- Test
SELECT get_department_payroll(1);



/*
=====================================================================
Q12 — Department Budget Utilization
=====================================================================

Business Requirement:
Calculate what percentage of a department's budget
is consumed by employee salary cost.

Formula:

Department Payroll
------------------ × 100
Department Budget

Return:
    Percentage rounded to 2 decimals.
=====================================================================
*/

DROP FUNCTION IF EXISTS get_budget_utilization(BIGINT);

CREATE OR REPLACE FUNCTION get_budget_utilization(
    p_department_id BIGINT
)
RETURNS NUMERIC(12,2)
LANGUAGE plpgsql
AS $$
DECLARE
    v_budget NUMERIC;
    v_payroll NUMERIC;
BEGIN

    SELECT budget
    INTO v_budget
    FROM departments
    WHERE department_id = p_department_id;

    IF v_budget IS NULL OR v_budget = 0 THEN
        RETURN NULL;
    END IF;

    SELECT COALESCE(SUM(basic_salary), 0)
    INTO v_payroll
    FROM employees
    WHERE department_id = p_department_id;

    RETURN ROUND(
        (v_payroll * 100.0) / v_budget,
        2
    );

END;
$$;


-- Test
SELECT
    department_name,
    get_budget_utilization(department_id) AS budget_utilization
FROM departments;



-- ===================================================================
-- LEVEL 5 — TABLE RETURNING FUNCTIONS
-- ===================================================================


/*
=====================================================================
Q13 — Employee Detail Function
=====================================================================

Business Requirement:
Return complete employee master information.

Output:

Employee Code
Employee Name
Email
Department
Job Title
Salary
Employment Status
Location
Country

Function:
    get_employee_details(emp_id)

Concepts:
    - RETURNS TABLE
    - RETURN QUERY
    - Multiple JOINs
=====================================================================
*/

DROP FUNCTION IF EXISTS get_employee_details(BIGINT);

CREATE OR REPLACE FUNCTION get_employee_details(
    p_emp_id BIGINT
)
RETURNS TABLE (
    employee_code VARCHAR,
    employee_name VARCHAR,
    email VARCHAR,
    department VARCHAR,
    job_title VARCHAR,
    salary NUMERIC,
    employment_status VARCHAR,
    location VARCHAR,
    country VARCHAR
)
LANGUAGE plpgsql
AS $$
BEGIN

    RETURN QUERY

    SELECT
        e.emp_code,
        CONCAT_WS(' ', e.fname, e.lname)::VARCHAR,
        e.email,
        d.department_name,
        j.job_title,
        e.basic_salary,
        e.employment_status,
        l.city,
        c.country_name

    FROM employees e

    JOIN departments d
        ON e.department_id = d.department_id

    JOIN job_roles j
        ON e.job_role_id = j.job_role_id

    JOIN locations l
        ON d.location_id = l.location_id

    JOIN countries c
        ON l.country_id = c.country_id

    WHERE e.emp_id = p_emp_id;

END;
$$;


-- Test
SELECT *
FROM get_employee_details(1);



/*
=====================================================================
Q14 — Department Employee Report
=====================================================================

Business Requirement:
Return all employees belonging to a department.

Output:

Employee Code
Employee Name
Job Title
Salary
Employment Status
Hire Date
=====================================================================
*/

DROP FUNCTION IF EXISTS get_department_employees(BIGINT);

CREATE OR REPLACE FUNCTION get_department_employees(
    p_department_id BIGINT
)
RETURNS TABLE (
    employee_code VARCHAR,
    employee_name VARCHAR,
    job_title VARCHAR,
    salary NUMERIC,
    employment_status VARCHAR,
    hire_date DATE
)
LANGUAGE plpgsql
AS $$
BEGIN

    RETURN QUERY

    SELECT
        e.emp_code,
        CONCAT_WS(' ', e.fname, e.lname)::VARCHAR,
        j.job_title,
        e.basic_salary,
        e.employment_status,
        e.hire_date

    FROM employees e

    JOIN job_roles j
        ON e.job_role_id = j.job_role_id

    WHERE e.department_id = p_department_id

    ORDER BY e.basic_salary DESC;

END;
$$;


-- Test
SELECT *
FROM get_department_employees(1);



-- ===================================================================
-- LEVEL 6 — EXPERT FUNCTION
-- ===================================================================


/*
=====================================================================
Q15 — Executive Employee Compensation Report
=====================================================================

Business Requirement:
Generate a complete compensation report for one employee.

Output:

Employee Name
Department
Job Title
Current Salary
Department Average Salary
Salary Difference
Salary Difference %
Salary Band
Company Salary Rank
Department Salary Rank

Concepts:

- JOIN
- CASE
- Aggregate Functions
- Window Functions
- DENSE_RANK()
- Percentage Calculation
- RETURNS TABLE
- RETURN QUERY
=====================================================================
*/

DROP FUNCTION IF EXISTS get_employee_compensation_report(BIGINT);

CREATE OR REPLACE FUNCTION get_employee_compensation_report(
    p_emp_id BIGINT
)
RETURNS TABLE (
    employee_name VARCHAR,
    department VARCHAR,
    job_title VARCHAR,
    current_salary NUMERIC,
    department_average_salary NUMERIC,
    salary_difference NUMERIC,
    salary_difference_percentage NUMERIC,
    salary_band VARCHAR,
    company_salary_rank BIGINT,
    department_salary_rank BIGINT
)
LANGUAGE plpgsql
AS $$
BEGIN

    RETURN QUERY

    WITH employee_data AS (

        SELECT
            e.emp_id,
            CONCAT_WS(' ', e.fname, e.lname)::VARCHAR AS emp_name,
            d.department_name,
            j.job_title,
            e.basic_salary,

            AVG(e.basic_salary) OVER (
                PARTITION BY e.department_id
            ) AS dept_avg_salary,

            DENSE_RANK() OVER (
                ORDER BY e.basic_salary DESC
            ) AS company_rank,

            DENSE_RANK() OVER (
                PARTITION BY e.department_id
                ORDER BY e.basic_salary DESC
            ) AS dept_rank

        FROM employees e

        JOIN departments d
            ON e.department_id = d.department_id

        JOIN job_roles j
            ON e.job_role_id = j.job_role_id
    )

    SELECT

        ed.emp_name,

        ed.department_name,

        ed.job_title,

        ed.basic_salary,

        ROUND(ed.dept_avg_salary, 2),

        ROUND(
            ed.basic_salary - ed.dept_avg_salary,
            2
        ),

        ROUND(
            (
                (ed.basic_salary - ed.dept_avg_salary)
                / NULLIF(ed.dept_avg_salary, 0)
            ) * 100,
            2
        ),

        CASE

            WHEN ed.basic_salary < 50000
                THEN 'Low'

            WHEN ed.basic_salary BETWEEN 50000 AND 100000
                THEN 'Medium'

            WHEN ed.basic_salary BETWEEN 100001 AND 150000
                THEN 'High'

            ELSE 'Executive'

        END::VARCHAR,

        ed.company_rank,

        ed.dept_rank

    FROM employee_data ed

    WHERE ed.emp_id = p_emp_id;

END;
$$;


-- Test
SELECT *
FROM get_employee_compensation_report(1);



-- ===================================================================
-- FINAL FUNCTION VERIFICATION
-- ===================================================================


/*
Run the following queries to verify that all functions
have been successfully created.
*/


-- Q1
SELECT get_employee_full_name(1);

-- Q2
SELECT get_employee_salary(1);

-- Q3
SELECT get_salary_band(120000);

-- Q4
SELECT get_employee_experience(1);

-- Q5
SELECT get_employee_age(1);

-- Q6
SELECT calculate_salary_increment(1, 10);

-- Q7
SELECT get_employee_risk(1);

-- Q8
SELECT get_department_avg_salary(1);

-- Q9
SELECT get_salary_position(1);

-- Q10
SELECT get_salary_gap(1);

-- Q11
SELECT get_department_payroll(1);

-- Q12
SELECT get_budget_utilization(1);

-- Q13
SELECT *
FROM get_employee_details(1);

-- Q14
SELECT *
FROM get_department_employees(1);

-- Q15
SELECT *
FROM get_employee_compensation_report(1);


/*
=====================================================================
END OF HR_Functions.sql
=====================================================================
*/
