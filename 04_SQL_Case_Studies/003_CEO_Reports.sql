/*
====================================================================
Project  : SQL HR Analytics Project
Module   : 003 - CEO Reports
Database : PostgreSQL

Purpose:
Executive-level HR and financial reporting for CEO decision-making.

Business Areas:
- Workforce
- Compensation
- Department Performance
- Management
- Workforce Risk
- Salary Distribution

Difficulty:
Advanced -> Expert

Author:
Sajlendra Pandey
====================================================================
*/


/*
====================================================================
CASE STUDY 1 — EXECUTIVE WORKFORCE DASHBOARD
====================================================================

Business Requirement:
CEO needs a single-row executive KPI summary containing:

- Total Employees
- Active Employees
- Employees On Leave
- Resigned Employees
- Terminated Employees
- Total Salary Cost
- Average Salary
- Highest Salary
- Lowest Salary

Output:
Single-row executive KPI report.
====================================================================
*/

SELECT
    COUNT(*) AS total_employees,

    COUNT(*) FILTER (
        WHERE employment_status = 'Active'
    ) AS active_employees,

    COUNT(*) FILTER (
        WHERE employment_status = 'Leave'
    ) AS employees_on_leave,

    COUNT(*) FILTER (
        WHERE employment_status = 'Resigned'
    ) AS resigned_employees,

    COUNT(*) FILTER (
        WHERE employment_status = 'Terminated'
    ) AS terminated_employees,

    SUM(basic_salary) AS total_salary_cost,

    ROUND(AVG(basic_salary), 2) AS average_salary,

    MAX(basic_salary) AS highest_salary,

    MIN(basic_salary) AS lowest_salary

FROM employees;


/*
====================================================================
CASE STUDY 2 — DEPARTMENT COMPENSATION ANALYSIS
====================================================================

Business Requirement:
CEO wants department-level compensation performance.

Required Output:
- Department Name
- Employee Count
- Total Salary Cost
- Average Salary
- Highest Salary
- Lowest Salary
- Salary Cost % of Company
- Department Rank by Salary Cost

Rules:
- Highest salary cost = Rank 1
- Same salary cost = Same rank
- Highest salary cost first
====================================================================
*/

WITH department_summary AS (

    SELECT
        d.department_name,

        COUNT(*) AS employee_count,

        SUM(e.basic_salary) AS total_salary_cost,

        AVG(e.basic_salary) AS average_salary,

        MAX(e.basic_salary) AS highest_salary,

        MIN(e.basic_salary) AS lowest_salary

    FROM employees e
    JOIN departments d
        ON e.department_id = d.department_id

    GROUP BY d.department_name
),

company_summary AS (

    SELECT
        SUM(total_salary_cost) AS company_salary_cost
    FROM department_summary
)

SELECT
    ds.department_name,
    ds.employee_count,
    ds.total_salary_cost,

    ROUND(ds.average_salary, 2) AS average_salary,

    ds.highest_salary,
    ds.lowest_salary,

    ROUND(
        (
            ds.total_salary_cost
            * 100.0
            / NULLIF(cs.company_salary_cost, 0)
        )::numeric,
        2
    ) AS salary_cost_percentage,

    DENSE_RANK() OVER (
        ORDER BY ds.total_salary_cost DESC
    ) AS department_rank

FROM department_summary ds
CROSS JOIN company_summary cs

ORDER BY
    department_rank,
    ds.department_name;


/*
====================================================================
CASE STUDY 3 — DEPARTMENT SIZE & SALARY COST BENCHMARKING
====================================================================

Business Requirement:
Compare every department against the company-wide average department.

Required Output:
- Department
- Employee Count
- Total Salary
- Average Salary
- Salary Cost Difference from Average Department Cost
- Employee Count Difference from Average Department Size

Interpretation:
Positive difference  -> Above company average
Negative difference  -> Below company average
====================================================================
*/

WITH department_summary AS (

    SELECT
        d.department_name,

        COUNT(*) AS employee_count,

        SUM(e.basic_salary) AS total_salary,

        AVG(e.basic_salary) AS average_salary

    FROM departments d
    JOIN employees e
        ON d.department_id = e.department_id

    GROUP BY d.department_name
),

company_benchmark AS (

    SELECT
        department_name,
        employee_count,
        total_salary,
        average_salary,

        AVG(total_salary) OVER () AS average_department_salary_cost,

        AVG(employee_count) OVER () AS average_department_size

    FROM department_summary
)

SELECT
    department_name AS department,

    employee_count,

    total_salary,

    ROUND(average_salary, 2) AS average_salary,

    ROUND(
        (
            total_salary
            - average_department_salary_cost
        )::numeric,
        2
    ) AS salary_cost_difference,

    ROUND(
        (
            employee_count
            - average_department_size
        )::numeric,
        2
    ) AS employee_count_difference

FROM company_benchmark

ORDER BY
    total_salary DESC;


/*
====================================================================
CASE STUDY 4 — TOP 20% EMPLOYEE SALARY CONCENTRATION
====================================================================

Business Requirement:
CEO wants to understand how much of the company's total payroll
is concentrated among the highest-paid 20% of employees.

Required Output:
- Total Employees
- Top 20% Employee Count
- Total Company Salary
- Top 20% Salary Cost
- Top 20% Payroll Percentage

Method:
NTILE(5) divides employees into five approximately equal groups.

Bucket 1 = Highest-paid 20%
====================================================================
*/

WITH salary_buckets AS (

    SELECT
        employee_id,
        basic_salary,

        NTILE(5) OVER (
            ORDER BY basic_salary DESC
        ) AS salary_bucket

    FROM employees
),

salary_summary AS (

    SELECT

        COUNT(*) AS total_employees,

        SUM(basic_salary) AS total_company_salary,

        COUNT(*) FILTER (
            WHERE salary_bucket = 1
        ) AS top_20_employee_count,

        SUM(
            CASE
                WHEN salary_bucket = 1
                    THEN basic_salary
                ELSE 0
            END
        ) AS top_20_salary_cost

    FROM salary_buckets
)

SELECT
    total_employees,

    top_20_employee_count,

    total_company_salary,

    top_20_salary_cost,

    ROUND(
        (
            top_20_salary_cost
            * 100.0
            / NULLIF(total_company_salary, 0)
        )::numeric,
        2
    ) AS top_20_payroll_percentage

FROM salary_summary;


/*
====================================================================
CASE STUDY 5 — EMPLOYEES EARNING 50% ABOVE DEPARTMENT AVERAGE
====================================================================

Business Requirement:
Identify employees whose salary is more than 50% above the
average salary of their own department.

Required Output:
- Employee Name
- Department
- Employee Salary
- Department Average Salary
- Difference
- Percentage Above Department Average

Sorting:
Highest percentage difference first.
====================================================================
*/

WITH employee_salary_analysis AS (

    SELECT
        CONCAT_WS(' ', e.fname, e.lname) AS employee_name,

        d.department_name,

        e.basic_salary AS employee_salary,

        AVG(e.basic_salary) OVER (
            PARTITION BY d.department_name
        ) AS department_average_salary

    FROM employees e
    JOIN departments d
        ON e.department_id = d.department_id
)

SELECT
    employee_name,

    department_name,

    employee_salary,

    ROUND(
        department_average_salary::numeric,
        2
    ) AS department_average_salary,

    ROUND(
        (
            employee_salary
            - department_average_salary
        )::numeric,
        2
    ) AS salary_difference,

    ROUND(
        (
            (
                employee_salary
                - department_average_salary
            )
            / NULLIF(department_average_salary, 0)
            * 100
        )::numeric,
        2
    ) AS percentage_above_department_average

FROM employee_salary_analysis

WHERE
    (
        (
            employee_salary
            - department_average_salary
        )
        / NULLIF(department_average_salary, 0)
        * 100
    ) > 50

ORDER BY
    percentage_above_department_average DESC;


/*
====================================================================
CASE STUDY 6
====================================================================

Note:
Case Study 6 was not included in the provided specification.
It should be added here when the business requirement is defined.
====================================================================
*/


/*
====================================================================
CASE STUDY 7 — DEPARTMENT SALARY DISTRIBUTION
====================================================================

Business Requirement:
Analyze salary spread within every department.

Required Output:
- Department
- Highest Salary
- Lowest Salary
- Salary Gap
- Average Salary
- Salary Gap as % of Average Salary

Sorting:
Highest salary gap percentage first.
====================================================================
*/

WITH department_salary AS (

    SELECT
        d.department_name,

        MAX(e.basic_salary) AS highest_salary,

        MIN(e.basic_salary) AS lowest_salary,

        AVG(e.basic_salary) AS average_salary

    FROM departments d
    JOIN employees e
        ON d.department_id = e.department_id

    GROUP BY d.department_name
)

SELECT
    department_name AS department,

    highest_salary,

    lowest_salary,

    highest_salary - lowest_salary AS salary_gap,

    ROUND(
        average_salary::numeric,
        2
    ) AS average_salary,

    ROUND(
        (
            (
                highest_salary
                - lowest_salary
            )
            * 100.0
            / NULLIF(average_salary, 0)
        )::numeric,
        2
    ) AS salary_gap_percentage

FROM department_salary

ORDER BY
    salary_gap_percentage DESC,
    department_name;


/*
====================================================================
CASE STUDY 8 — COMPANY SALARY RANKING
====================================================================

Business Requirement:
CEO wants a complete salary ranking report.

Required Output:
- Employee
- Department
- Salary
- Company Rank
- Department Rank
- Company Salary Percentile

Rules:
- Highest salary = Rank 1
- Same salary = Same rank
- Company ranking is based on all employees
- Department ranking resets for each department
====================================================================
*/

WITH salary_ranking AS (

    SELECT

        CONCAT_WS(' ', e.fname, e.lname) AS employee_name,

        d.department_name,

        e.basic_salary AS salary,

        DENSE_RANK() OVER (
            ORDER BY e.basic_salary DESC
        ) AS company_rank,

        DENSE_RANK() OVER (
            PARTITION BY d.department_name
            ORDER BY e.basic_salary DESC
        ) AS department_rank,

        PERCENT_RANK() OVER (
            ORDER BY e.basic_salary
        ) AS company_salary_percentile

    FROM employees e
    JOIN departments d
        ON e.department_id = d.department_id
)

SELECT

    employee_name,

    department_name,

    salary,

    company_rank,

    department_rank,

    ROUND(
        (
            company_salary_percentile * 100
        )::numeric,
        2
    ) AS company_salary_percentile

FROM salary_ranking

ORDER BY
    company_rank,
    employee_name;


/*
====================================================================
END OF MODULE 003 — CEO REPORTS
====================================================================
*/