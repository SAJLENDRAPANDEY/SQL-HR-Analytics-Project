/*
============================================================
PROJECT: Finance Salary Analysis
DATABASE: MySQL 8+
LEVEL: Intermediate to Advanced SQL

DESCRIPTION:
Real-world Finance and HR analytics business problems
using employee salary data.

KEY SQL CONCEPTS:
JOIN, GROUP BY, HAVING, CASE WHEN, CTEs, Aggregate Functions,
Window Functions, RANK, DENSE_RANK, ROW_NUMBER,
GROUP_CONCAT, Percentage Calculations
============================================================
*/


/*
============================================================
BUSINESS PROBLEM 1
============================================================

Finance wants to know the monthly salary expense of every
department.

Required Output:
- Department Name
- Total Employees
- Total Salary Expense
- Average Salary
- Highest Salary
- Lowest Salary

Sort:
Highest Salary Expense First
============================================================
*/

SELECT
    d.department_name,
    COUNT(e.emp_id) AS total_employees,
    SUM(e.basic_salary) AS total_salary_expense,
    ROUND(AVG(e.basic_salary), 2) AS average_salary,
    MAX(e.basic_salary) AS highest_salary,
    MIN(e.basic_salary) AS lowest_salary
FROM employees e
JOIN departments d
    ON e.department_id = d.department_id
GROUP BY d.department_name
ORDER BY total_salary_expense DESC;


/*
============================================================
BUSINESS PROBLEM 2
============================================================

Finance wants to classify employees into salary bands.

Salary Rules:
- Below 50,000       -> Low
- 50,000-100,000     -> Medium
- 100,001-150,000    -> High
- Above 150,000      -> Executive

Required Output:
- Employee Name
- Department
- Salary
- Salary Band
============================================================
*/

SELECT
    CONCAT_WS(' ', e.fname, e.lname) AS employee_name,
    d.department_name,
    e.basic_salary AS salary,
    CASE
        WHEN e.basic_salary < 50000 THEN 'Low'
        WHEN e.basic_salary BETWEEN 50000 AND 100000 THEN 'Medium'
        WHEN e.basic_salary BETWEEN 100001 AND 150000 THEN 'High'
        ELSE 'Executive'
    END AS salary_band
FROM employees e
JOIN departments d
    ON e.department_id = d.department_id;


/*
============================================================
BUSINESS PROBLEM 4
============================================================

Finance wants the Top 5 highest-paid employees.

If multiple employees have the same salary at Rank 5,
show all of them.

Required Output:
- Employee
- Department
- Salary
- Rank
============================================================
*/

WITH employee_ranking AS (
    SELECT
        CONCAT_WS(' ', e.fname, e.lname) AS employee_name,
        d.department_name,
        e.basic_salary AS salary,
        DENSE_RANK() OVER (
            ORDER BY e.basic_salary DESC
        ) AS salary_rank
    FROM employees e
    JOIN departments d
        ON e.department_id = d.department_id
)
SELECT
    employee_name,
    department_name,
    salary,
    salary_rank
FROM employee_ranking
WHERE salary_rank <= 5
ORDER BY salary_rank, salary DESC;


/*
============================================================
BUSINESS PROBLEM 5
============================================================

Finance wants to identify employees whose salary is at least
30% higher than their department average.

Required Output:
- Employee
- Department
- Salary
- Department Average
- Difference
- Percentage Difference
============================================================
*/

WITH employee_salary AS (
    SELECT
        CONCAT_WS(' ', e.fname, e.lname) AS employee_name,
        d.department_name,
        e.basic_salary AS salary,
        ROUND(
            AVG(e.basic_salary) OVER (
                PARTITION BY d.department_name
            ),
            2
        ) AS department_average
    FROM employees e
    JOIN departments d
        ON e.department_id = d.department_id
)
SELECT
    employee_name,
    department_name,
    salary,
    department_average,
    ROUND(salary - department_average, 2) AS difference,
    ROUND(
        ((salary - department_average) * 100.0)
        / department_average,
        2
    ) AS percentage_difference
FROM employee_salary
WHERE salary >= department_average * 1.30
ORDER BY percentage_difference DESC;


/*
============================================================
BUSINESS PROBLEM 7
============================================================

Finance wants salary ranking inside every department.

Required Output:
- Employee
- Department
- Salary
- Salary Rank
- Dense Rank
- Row Number
============================================================
*/

SELECT
    CONCAT_WS(' ', e.fname, e.lname) AS employee_name,
    d.department_name,
    e.basic_salary AS salary,

    RANK() OVER (
        PARTITION BY d.department_name
        ORDER BY e.basic_salary DESC
    ) AS salary_rank,

    DENSE_RANK() OVER (
        PARTITION BY d.department_name
        ORDER BY e.basic_salary DESC
    ) AS dense_rank,

    ROW_NUMBER() OVER (
        PARTITION BY d.department_name
        ORDER BY e.basic_salary DESC
    ) AS row_number

FROM employees e
JOIN departments d
    ON e.department_id = d.department_id
ORDER BY d.department_name, salary DESC;


/*
============================================================
BUSINESS PROBLEM 8
============================================================

Finance suspects duplicate salary structures.

Find salaries that are assigned to more than one employee.

Required Output:
- Salary
- Number of Employees
- Employee Names
============================================================
*/

SELECT
    basic_salary AS salary,
    COUNT(*) AS number_of_employees,
    GROUP_CONCAT(
        CONCAT_WS(' ', fname, lname)
        ORDER BY fname
        SEPARATOR ', '
    ) AS employee_names
FROM employees
GROUP BY basic_salary
HAVING COUNT(*) > 1
ORDER BY basic_salary DESC;


/*
============================================================
BUSINESS PROBLEM 9
============================================================

Find department(s) whose salary expense is the highest
in the entire company.

If there is a tie, show all departments.

Required Output:
- Department Name
- Total Salary Expense
============================================================
*/

WITH department_expense AS (
    SELECT
        d.department_name,
        SUM(e.basic_salary) AS total_salary_expense,
        DENSE_RANK() OVER (
            ORDER BY SUM(e.basic_salary) DESC
        ) AS expense_rank
    FROM departments d
    JOIN employees e
        ON d.department_id = e.department_id
    GROUP BY d.department_name
)
SELECT
    department_name,
    total_salary_expense
FROM department_expense
WHERE expense_rank = 1;


/*
============================================================
BUSINESS PROBLEM 10
============================================================

Generate one complete department salary report.

Required Output:
- Department
- Employees
- Average Salary
- Highest Salary
- Lowest Salary
- Total Salary
- Payroll %
- Rank by Payroll
============================================================
*/

WITH department_summary AS (
    SELECT
        d.department_name,
        COUNT(e.emp_id) AS employees,
        ROUND(AVG(e.basic_salary), 2) AS average_salary,
        MAX(e.basic_salary) AS highest_salary,
        MIN(e.basic_salary) AS lowest_salary,
        SUM(e.basic_salary) AS total_salary
    FROM departments d
    JOIN employees e
        ON d.department_id = e.department_id
    GROUP BY d.department_name
)
SELECT
    department_name,
    employees,
    average_salary,
    highest_salary,
    lowest_salary,
    total_salary,
    ROUND(
        (total_salary * 100.0)
        / SUM(total_salary) OVER (),
        2
    ) AS payroll_percentage,
    DENSE_RANK() OVER (
        ORDER BY total_salary DESC
    ) AS payroll_rank
FROM department_summary
ORDER BY payroll_rank;
