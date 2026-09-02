/*
=====================================================================
 Project      : SQL-HR-Analytics-Project
 Module       : 05 - Views
 File         : 05_Views.sql
 Database     : PostgreSQL
 Author       : Sajlendra Pandey

 Description:
 Production-style reporting views for PeoplePulse HR Analytics.

 This module provides reusable SQL views for:
 - Employee Master Data
 - Active Workforce
 - Salary Analytics
 - Manager Analytics
 - Compensation Benchmarking
 - Workforce Risk
 - Department Performance
 - Executive Reporting

 Difficulty:
 Advanced → Expert

 Total Views:
 20

=====================================================================
*/

SET search_path TO peoplepulse;


-- ==================================================================
-- Q1. Employee Master View
-- ==================================================================
-- Purpose:
-- Centralized employee master information for HR reporting.
-- ==================================================================

CREATE OR REPLACE VIEW vw_employee_master AS
SELECT
    e.emp_code AS "Employee Code",

    CONCAT_WS(' ', e.fname, e.lname) AS "Employee Name",

    e.email AS "Email",

    d.department_name AS "Department",

    j.job_title AS "Job Title",

    e.employment_status AS "Employment Status",

    e.basic_salary AS "Basic Salary",

    l.city AS "Location",

    c.country_name AS "Country"

FROM employees e

JOIN departments d
    ON e.department_id = d.department_id

JOIN job_roles j
    ON e.job_role_id = j.job_role_id

JOIN locations l
    ON d.location_id = l.location_id

JOIN countries c
    ON l.country_id = c.country_id;


-- ==================================================================
-- Q2. Active Employee View
-- ==================================================================
-- Purpose:
-- Provides the current active workforce for HR operations.
-- ==================================================================

CREATE OR REPLACE VIEW vw_active_employees AS
SELECT
    e.emp_code AS "Employee Code",

    CONCAT_WS(' ', e.fname, e.lname) AS "Employee Name",

    d.department_name AS "Department",

    j.job_title AS "Job Title",

    e.basic_salary AS "Salary",

    e.hire_date AS "Hire Date"

FROM employees e

JOIN departments d
    ON e.department_id = d.department_id

JOIN job_roles j
    ON e.job_role_id = j.job_role_id

WHERE e.employment_status = 'Active';


-- ==================================================================
-- Q3. Department Salary Summary
-- ==================================================================
-- Purpose:
-- Department-level compensation summary.
-- ==================================================================

CREATE OR REPLACE VIEW vw_department_salary_summary AS
SELECT
    d.department_name AS "Department",

    COUNT(e.emp_id) AS "Employee Count",

    SUM(e.basic_salary) AS "Total Salary",

    ROUND(AVG(e.basic_salary), 2) AS "Average Salary",

    MAX(e.basic_salary) AS "Highest Salary",

    MIN(e.basic_salary) AS "Lowest Salary",

    MAX(e.basic_salary) - MIN(e.basic_salary) AS "Salary Gap"

FROM departments d

JOIN employees e
    ON d.department_id = e.department_id

GROUP BY
    d.department_id,
    d.department_name;


-- ==================================================================
-- Q4. Manager Team Summary
-- ==================================================================
-- Purpose:
-- Measures manager span of control and team compensation.
-- ==================================================================

CREATE OR REPLACE VIEW vw_manager_team_summary AS
SELECT
    m.emp_id AS "Manager ID",

    CONCAT_WS(' ', m.fname, m.lname) AS "Manager Name",

    d.department_name AS "Department",

    COUNT(e.emp_id) AS "Team Size",

    SUM(e.basic_salary) AS "Total Team Salary",

    ROUND(AVG(e.basic_salary), 2) AS "Average Team Salary",

    MAX(e.basic_salary) AS "Highest Team Salary",

    MIN(e.basic_salary) AS "Lowest Team Salary"

FROM employees m

JOIN employees e
    ON e.manager_id = m.emp_id

JOIN departments d
    ON m.department_id = d.department_id

GROUP BY
    m.emp_id,
    m.fname,
    m.lname,
    d.department_id,
    d.department_name;


-- ==================================================================
-- Q5. Employee Salary Benchmark
-- ==================================================================
-- Purpose:
-- Compares employee salary against their department average.
-- ==================================================================

CREATE OR REPLACE VIEW vw_employee_salary_benchmark AS
SELECT
    e.emp_code AS "Employee Code",

    CONCAT_WS(' ', e.fname, e.lname) AS "Employee Name",

    d.department_name AS "Department",

    e.basic_salary AS "Employee Salary",

    ROUND(
        AVG(e.basic_salary) OVER (
            PARTITION BY e.department_id
        ),
        2
    ) AS "Department Average Salary",

    ROUND(
        e.basic_salary
        -
        AVG(e.basic_salary) OVER (
            PARTITION BY e.department_id
        ),
        2
    ) AS "Salary Difference",

    ROUND(
        (
            (
                e.basic_salary
                -
                AVG(e.basic_salary) OVER (
                    PARTITION BY e.department_id
                )
            )
            /
            NULLIF(
                AVG(e.basic_salary) OVER (
                    PARTITION BY e.department_id
                ),
                0
            )
        ) * 100,
        2
    ) AS "Salary Difference %"

FROM employees e

JOIN departments d
    ON e.department_id = d.department_id;


-- ==================================================================
-- Q6. Salary Risk View
-- ==================================================================
-- Purpose:
-- Identifies employees whose salary is significantly above
-- their department benchmark.
-- ==================================================================

CREATE OR REPLACE VIEW vw_salary_risk AS
WITH salary_benchmark AS (

    SELECT
        e.emp_code,
        CONCAT_WS(' ', e.fname, e.lname) AS employee_name,
        d.department_name,
        e.basic_salary,

        AVG(e.basic_salary) OVER (
            PARTITION BY e.department_id
        ) AS department_average

    FROM employees e

    JOIN departments d
        ON e.department_id = d.department_id
)

SELECT
    emp_code AS "Employee Code",

    employee_name AS "Employee Name",

    department_name AS "Department",

    basic_salary AS "Salary",

    ROUND(department_average, 2) AS "Department Average",

    ROUND(
        (
            (basic_salary - department_average)
            / NULLIF(department_average, 0)
        ) * 100,
        2
    ) AS "Difference %",

    CASE
        WHEN basic_salary >= department_average * 1.30
            THEN 'High Risk'

        WHEN basic_salary >= department_average * 1.10
            THEN 'Medium Risk'

        ELSE 'Normal'
    END AS "Salary Risk"

FROM salary_benchmark;


-- ==================================================================
-- Q7. Top Paid Employee Ranking
-- ==================================================================
-- Purpose:
-- Company-wide and department-level compensation ranking.
-- ==================================================================

CREATE OR REPLACE VIEW vw_top_paid_employees AS
SELECT
    e.emp_code AS "Employee Code",

    CONCAT_WS(' ', e.fname, e.lname) AS "Employee Name",

    d.department_name AS "Department",

    e.basic_salary AS "Salary",

    DENSE_RANK() OVER (
        ORDER BY e.basic_salary DESC
    ) AS "Company Rank",

    DENSE_RANK() OVER (
        PARTITION BY e.department_id
        ORDER BY e.basic_salary DESC
    ) AS "Department Rank"

FROM employees e

JOIN departments d
    ON e.department_id = d.department_id;


-- ==================================================================
-- Q8. Department Performance View
-- ==================================================================
-- Purpose:
-- Executive-level department compensation performance.
-- ==================================================================

CREATE OR REPLACE VIEW vw_department_performance AS
WITH department_summary AS (

    SELECT
        d.department_id,
        d.department_name,

        COUNT(e.emp_id) AS employee_count,

        ROUND(AVG(e.basic_salary), 2) AS average_salary,

        SUM(e.basic_salary) AS total_salary

    FROM departments d

    JOIN employees e
        ON d.department_id = e.department_id

    GROUP BY
        d.department_id,
        d.department_name
)

SELECT
    department_name AS "Department",

    employee_count AS "Employee Count",

    average_salary AS "Average Salary",

    total_salary AS "Total Salary",

    ROUND(
        AVG(average_salary) OVER (),
        2
    ) AS "Company Average Salary",

    ROUND(
        average_salary - AVG(average_salary) OVER (),
        2
    ) AS "Difference From Company Average",

    DENSE_RANK() OVER (
        ORDER BY total_salary DESC
    ) AS "Department Salary Rank"

FROM department_summary;


-- ==================================================================
-- Q9. Manager Compensation Risk
-- ==================================================================
-- Purpose:
-- Identifies managers whose direct reports earn more on average.
-- ==================================================================

CREATE OR REPLACE VIEW vw_manager_compensation_risk AS
WITH manager_teams AS (

    SELECT
        m.emp_id AS manager_id,

        CONCAT_WS(' ', m.fname, m.lname) AS manager_name,

        d.department_name,

        m.basic_salary AS manager_salary,

        AVG(e.basic_salary) AS team_average_salary

    FROM employees m

    JOIN employees e
        ON e.manager_id = m.emp_id

    JOIN departments d
        ON m.department_id = d.department_id

    GROUP BY
        m.emp_id,
        m.fname,
        m.lname,
        d.department_name,
        m.basic_salary
)

SELECT
    manager_name AS "Manager",

    department_name AS "Department",

    manager_salary AS "Manager Salary",

    ROUND(team_average_salary, 2) AS "Team Average Salary",

    ROUND(
        team_average_salary - manager_salary,
        2
    ) AS "Salary Gap",

    CASE
        WHEN manager_salary < team_average_salary
            THEN 'Compensation Risk'

        ELSE 'Normal'
    END AS "Risk Level"

FROM manager_teams;


-- ==================================================================
-- Q10. Executive Workforce Dashboard
-- ==================================================================
-- Purpose:
-- Single-row CEO workforce KPI report.
-- ==================================================================

CREATE OR REPLACE VIEW vw_executive_workforce_dashboard AS
SELECT
    COUNT(*) AS "Total Employees",

    COUNT(
        CASE
            WHEN employment_status = 'Active'
            THEN 1
        END
    ) AS "Active Employees",

    COUNT(
        CASE
            WHEN employment_status = 'On Leave'
            THEN 1
        END
    ) AS "On Leave Employees",

    COUNT(
        CASE
            WHEN employment_status = 'Resigned'
            THEN 1
        END
    ) AS "Resigned Employees",

    COUNT(
        CASE
            WHEN employment_status = 'Terminated'
            THEN 1
        END
    ) AS "Terminated Employees",

    SUM(basic_salary) AS "Total Payroll",

    ROUND(AVG(basic_salary), 2) AS "Average Salary",

    MAX(basic_salary) AS "Highest Salary",

    MIN(basic_salary) AS "Lowest Salary"

FROM employees;


-- ==================================================================
-- Q11. Department Payroll Contribution
-- ==================================================================
-- Purpose:
-- Shows each department's contribution to total company payroll.
-- ==================================================================

CREATE OR REPLACE VIEW vw_department_payroll_contribution AS
WITH department_payroll AS (

    SELECT
        d.department_id,
        d.department_name,
        SUM(e.basic_salary) AS department_payroll

    FROM departments d

    JOIN employees e
        ON d.department_id = e.department_id

    GROUP BY
        d.department_id,
        d.department_name
)

SELECT
    department_name AS "Department",

    department_payroll AS "Department Payroll",

    SUM(department_payroll) OVER ()
        AS "Company Payroll",

    ROUND(
        department_payroll * 100.0
        /
        NULLIF(
            SUM(department_payroll) OVER (),
            0
        ),
        2
    ) AS "Payroll %",

    DENSE_RANK() OVER (
        ORDER BY department_payroll DESC
    ) AS "Payroll Rank"

FROM department_payroll;


-- ==================================================================
-- Q12. Employee Compensation Position
-- ==================================================================
-- Purpose:
-- Classifies employee compensation against department benchmark.
-- ==================================================================

CREATE OR REPLACE VIEW vw_employee_compensation_position AS
WITH salary_data AS (

    SELECT
        e.emp_code,

        CONCAT_WS(' ', e.fname, e.lname) AS employee_name,

        d.department_name,

        e.basic_salary,

        AVG(e.basic_salary) OVER (
            PARTITION BY e.department_id
        ) AS department_average

    FROM employees e

    JOIN departments d
        ON e.department_id = d.department_id
)

SELECT
    emp_code AS "Employee Code",

    employee_name AS "Employee",

    department_name AS "Department",

    basic_salary AS "Salary",

    ROUND(department_average, 2)
        AS "Department Average",

    CASE
        WHEN basic_salary >= department_average * 1.20
            THEN 'Above Market'

        WHEN basic_salary >= department_average * 0.90
            THEN 'Competitive'

        ELSE 'Below Market'
    END AS "Salary Position"

FROM salary_data;


-- ==================================================================
-- Q13. Department Headcount Distribution
-- ==================================================================
-- Purpose:
-- Shows each department's share of total workforce.
-- ==================================================================

CREATE OR REPLACE VIEW vw_department_headcount AS
WITH department_headcount AS (

    SELECT
        d.department_id,
        d.department_name,
        COUNT(e.emp_id) AS employee_count

    FROM departments d

    LEFT JOIN employees e
        ON d.department_id = e.department_id

    GROUP BY
        d.department_id,
        d.department_name
)

SELECT
    department_name AS "Department",

    employee_count AS "Employee Count",

    SUM(employee_count) OVER ()
        AS "Company Employee Count",

    ROUND(
        employee_count * 100.0
        /
        NULLIF(
            SUM(employee_count) OVER (),
            0
        ),
        2
    ) AS "Headcount %"

FROM department_headcount;


-- ==================================================================
-- Q14. Manager Span of Control
-- ==================================================================
-- Purpose:
-- Categorizes managers according to their number of direct reports.
-- ==================================================================

CREATE OR REPLACE VIEW vw_manager_span_of_control AS
WITH manager_data AS (

    SELECT
        m.emp_id AS manager_id,

        CONCAT_WS(' ', m.fname, m.lname) AS manager_name,

        d.department_name,

        COUNT(e.emp_id) AS direct_reports

    FROM employees m

    JOIN employees e
        ON e.manager_id = m.emp_id

    JOIN departments d
        ON m.department_id = d.department_id

    GROUP BY
        m.emp_id,
        m.fname,
        m.lname,
        d.department_name
)

SELECT
    manager_id AS "Manager ID",

    manager_name AS "Manager",

    department_name AS "Department",

    direct_reports AS "Direct Reports",

    CASE
        WHEN direct_reports <= 2
            THEN 'Small Team'

        WHEN direct_reports <= 5
            THEN 'Normal Team'

        WHEN direct_reports <= 10
            THEN 'Large Team'

        ELSE 'Very Large Team'
    END AS "Span Category"

FROM manager_data;


-- ==================================================================
-- Q15. Department Salary Inequality
-- ==================================================================
-- Purpose:
-- Measures salary dispersion inside each department.
-- ==================================================================

CREATE OR REPLACE VIEW vw_department_salary_inequality AS
SELECT
    d.department_name AS "Department",

    MAX(e.basic_salary) AS "Highest Salary",

    MIN(e.basic_salary) AS "Lowest Salary",

    ROUND(AVG(e.basic_salary), 2) AS "Average Salary",

    MAX(e.basic_salary)
        - MIN(e.basic_salary) AS "Salary Gap",

    ROUND(
        (
            (
                MAX(e.basic_salary)
                - MIN(e.basic_salary)
            )
            /
            NULLIF(AVG(e.basic_salary), 0)
        ) * 100,
        2
    ) AS "Gap %"

FROM departments d

JOIN employees e
    ON d.department_id = e.department_id

GROUP BY
    d.department_id,
    d.department_name;


-- ==================================================================
-- Q16. Employee Ranking Dashboard
-- ==================================================================
-- Purpose:
-- Comprehensive employee salary ranking report.
-- ==================================================================

CREATE OR REPLACE VIEW vw_employee_ranking_dashboard AS
SELECT
    e.emp_code AS "Employee Code",

    CONCAT_WS(' ', e.fname, e.lname) AS "Employee",

    d.department_name AS "Department",

    e.basic_salary AS "Salary",

    DENSE_RANK() OVER (
        ORDER BY e.basic_salary DESC
    ) AS "Company Rank",

    DENSE_RANK() OVER (
        PARTITION BY e.department_id
        ORDER BY e.basic_salary DESC
    ) AS "Department Rank",

    ROUND(
        PERCENT_RANK() OVER (
            ORDER BY e.basic_salary
        ) * 100,
        2
    ) AS "Salary Percentile",

    NTILE(4) OVER (
        ORDER BY e.basic_salary DESC
    ) AS "Salary Quartile"

FROM employees e

JOIN departments d
    ON e.department_id = d.department_id;


-- ==================================================================
-- Q17. Department Leadership View
-- ==================================================================
-- Purpose:
-- Compares manager compensation with team compensation.
-- ==================================================================

CREATE OR REPLACE VIEW vw_department_leadership AS
WITH manager_team AS (

    SELECT
        m.emp_id AS manager_id,

        CONCAT_WS(' ', m.fname, m.lname) AS manager_name,

        d.department_name,

        m.basic_salary AS manager_salary,

        COUNT(e.emp_id) AS team_size,

        AVG(e.basic_salary) AS team_average_salary

    FROM employees m

    JOIN employees e
        ON e.manager_id = m.emp_id

    JOIN departments d
        ON m.department_id = d.department_id

    GROUP BY
        m.emp_id,
        m.fname,
        m.lname,
        d.department_name,
        m.basic_salary
)

SELECT
    manager_name AS "Manager",

    department_name AS "Department",

    manager_salary AS "Manager Salary",

    team_size AS "Team Size",

    ROUND(team_average_salary, 2)
        AS "Team Average Salary",

    ROUND(
        manager_salary - team_average_salary,
        2
    ) AS "Manager vs Team Average",

    CASE
        WHEN manager_salary > team_average_salary
            THEN 'Above Team Average'

        WHEN manager_salary < team_average_salary
            THEN 'Below Team Average'

        ELSE 'Equal'
    END AS "Leadership Compensation Status"

FROM manager_team;


-- ==================================================================
-- Q18. Workforce Risk Dashboard
-- ==================================================================
-- Purpose:
-- Employee-level workforce risk classification.
-- ==================================================================

CREATE OR REPLACE VIEW vw_workforce_risk_dashboard AS
WITH salary_benchmark AS (

    SELECT
        e.emp_code,

        CONCAT_WS(' ', e.fname, e.lname)
            AS employee_name,

        d.department_name,

        e.employment_status,

        e.basic_salary,

        AVG(e.basic_salary) OVER (
            PARTITION BY e.department_id
        ) AS department_average

    FROM employees e

    JOIN departments d
        ON e.department_id = d.department_id
)

SELECT
    emp_code AS "Employee Code",

    employee_name AS "Employee",

    department_name AS "Department",

    employment_status AS "Employment Status",

    basic_salary AS "Salary",

    ROUND(department_average, 2)
        AS "Department Average",

    CASE
        WHEN employment_status = 'Terminated'
            THEN 'Critical'

        WHEN employment_status = 'Resigned'
            THEN 'High'

        WHEN employment_status = 'Active'
             AND basic_salary < department_average
            THEN 'Medium'

        ELSE 'Low'
    END AS "Risk Level"

FROM salary_benchmark;


-- ==================================================================
-- Q19. Department Health View
-- ==================================================================
-- Purpose:
-- Executive-level department health and payroll analysis.
-- ==================================================================

CREATE OR REPLACE VIEW vw_department_health AS
WITH department_summary AS (

    SELECT
        d.department_id,

        d.department_name,

        COUNT(e.emp_id) AS employee_count,

        ROUND(AVG(e.basic_salary), 2)
            AS average_salary,

        SUM(e.basic_salary)
            AS total_payroll,

        MAX(e.basic_salary)
            AS highest_salary,

        MIN(e.basic_salary)
            AS lowest_salary

    FROM departments d

    JOIN employees e
        ON d.department_id = e.department_id

    GROUP BY
        d.department_id,
        d.department_name
),

company_metrics AS (

    SELECT
        *,
        AVG(average_salary) OVER ()
            AS company_average_salary,

        SUM(total_payroll) OVER ()
            AS company_payroll

    FROM department_summary
)

SELECT
    department_name AS "Department",

    employee_count AS "Employees",

    average_salary AS "Average Salary",

    total_payroll AS "Total Payroll",

    ROUND(
        total_payroll * 100.0
        /
        NULLIF(company_payroll, 0),
        2
    ) AS "Payroll %",

    highest_salary AS "Highest Salary",

    lowest_salary AS "Lowest Salary",

    highest_salary - lowest_salary
        AS "Salary Gap",

    DENSE_RANK() OVER (
        ORDER BY total_payroll DESC
    ) AS "Payroll Rank",

    CASE
        WHEN DENSE_RANK() OVER (
            ORDER BY total_payroll DESC
        ) = 1
            THEN 'Critical Review'

        WHEN (
            total_payroll * 100.0
            /
            NULLIF(company_payroll, 0)
        ) > 25
            THEN 'High Attention'

        WHEN average_salary > company_average_salary
            THEN 'Healthy'

        ELSE 'Normal'
    END AS "Health Status"

FROM company_metrics;


-- ==================================================================
-- Q20. Executive HR Intelligence View
-- ==================================================================
-- Purpose:
-- Final executive-level consolidated HR intelligence report.
--
-- This view combines:
-- Workforce
-- Compensation
-- Payroll
-- Department Ranking
-- Management
-- Salary Benchmarking
-- Department Health
-- ==================================================================

CREATE OR REPLACE VIEW vw_executive_hr_intelligence AS
WITH department_summary AS (

    SELECT
        d.department_id,

        d.department_name,

        COUNT(e.emp_id) AS employee_count,

        ROUND(AVG(e.basic_salary), 2)
            AS average_salary,

        SUM(e.basic_salary)
            AS total_payroll,

        MAX(e.basic_salary)
            AS highest_salary,

        MIN(e.basic_salary)
            AS lowest_salary

    FROM departments d

    JOIN employees e
        ON d.department_id = e.department_id

    GROUP BY
        d.department_id,
        d.department_name
),

department_metrics AS (

    SELECT
        ds.*,

        SUM(total_payroll) OVER ()
            AS company_payroll,

        AVG(average_salary) OVER ()
            AS company_average_salary,

        DENSE_RANK() OVER (
            ORDER BY total_payroll DESC
        ) AS department_rank

    FROM department_summary ds
),

manager_summary AS (

    SELECT
        m.department_id,

        CONCAT_WS(' ', m.fname, m.lname)
            AS manager_name,

        COUNT(e.emp_id)
            AS team_size,

        ROW_NUMBER() OVER (
            PARTITION BY m.department_id
            ORDER BY COUNT(e.emp_id) DESC,
                     m.emp_id
        ) AS manager_rank

    FROM employees m

    JOIN employees e
        ON e.manager_id = m.emp_id

    GROUP BY
        m.department_id,
        m.emp_id,
        m.fname,
        m.lname
),

department_managers AS (

    SELECT
        department_id,
        manager_name,
        team_size

    FROM manager_summary

    WHERE manager_rank = 1
)

SELECT
    dm.department_name AS "Department",

    dm.employee_count AS "Employee Count",

    dm.average_salary AS "Average Salary",

    dm.total_payroll AS "Total Payroll",

    ROUND(
        dm.total_payroll * 100.0
        /
        NULLIF(dm.company_payroll, 0),
        2
    ) AS "Payroll %",

    dm.department_rank AS "Department Rank",

    ROUND(
        dm.average_salary
        - dm.company_average_salary,
        2
    ) AS "Average Salary vs Company",

    dm.highest_salary AS "Highest Salary",

    dm.lowest_salary AS "Lowest Salary",

    dm.highest_salary - dm.lowest_salary
        AS "Salary Gap",

    COALESCE(dmg.manager_name, 'No Manager Assigned')
        AS "Manager",

    COALESCE(dmg.team_size, 0)
        AS "Team Size",

    CASE
        WHEN dm.department_rank = 1
            THEN 'Critical Review'

        WHEN (
            dm.total_payroll * 100.0
            /
            NULLIF(dm.company_payroll, 0)
        ) > 25
            THEN 'High Attention'

        WHEN dm.average_salary > dm.company_average_salary
            THEN 'Healthy'

        ELSE 'Normal'
    END AS "Department Health"

FROM department_metrics dm

LEFT JOIN department_managers dmg
    ON dm.department_id = dmg.department_id;


/*
=====================================================================
                    VIEW VALIDATION
=====================================================================

Run these queries after creating the views.

=====================================================================
*/

SELECT * FROM vw_employee_master;

SELECT * FROM vw_active_employees;

SELECT * FROM vw_department_salary_summary;

SELECT * FROM vw_manager_team_summary;

SELECT * FROM vw_employee_salary_benchmark;

SELECT * FROM vw_salary_risk;

SELECT * FROM vw_top_paid_employees;

SELECT * FROM vw_department_performance;

SELECT * FROM vw_manager_compensation_risk;

SELECT * FROM vw_executive_workforce_dashboard;

SELECT * FROM vw_department_payroll_contribution;

SELECT * FROM vw_employee_compensation_position;

SELECT * FROM vw_department_headcount;

SELECT * FROM vw_manager_span_of_control;

SELECT * FROM vw_department_salary_inequality;

SELECT * FROM vw_employee_ranking_dashboard;

SELECT * FROM vw_department_leadership;

SELECT * FROM vw_workforce_risk_dashboard;

SELECT * FROM vw_department_health;

SELECT * FROM vw_executive_hr_intelligence;


/*
=====================================================================
 End of 05_Views.sql
=====================================================================
*/
