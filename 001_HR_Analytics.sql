/*
===============================================================================
 Project     : PeoplePulse — Enterprise HR Analytics System
 Module      : 001 - Workforce & Compensation Analytics
 Author      : Sajlendra Pandey
 Database    : PostgreSQL

 Description :
   A collection of real-world HR analytics SQL case studies covering
   workforce summaries, diversity reporting, compensation analysis,
   and organizational structure queries.

 Difficulty  : Easy → Medium → Advanced

 Schema (referenced tables):
   employees   (emp_id, fname, lname, department_id, job_role_id,
                manager_id, gender, is_active, basic_salary, ...)
   departments (department_id, department_name)
   job_roles   (job_role_id, job_title)
   locations   (location_id, ...)
   countries   (country_id, ...)
===============================================================================
*/


-- ===============================================================
-- Case Study 1: Department-wise Workforce Summary
-- ===============================================================
-- Business Problem:
--   The HR Director wants a department-wise workforce summary showing
--   total headcount alongside active, on-leave, resigned, and
--   terminated employee counts, sorted by highest headcount first.
--
-- Required Output:
--   Department Name | Total Employees | Active Employees |
--   Employees On Leave | Resigned Employees | Terminated Employees
-- ===============================================================

SELECT
    d.department_name,
    COUNT(e.emp_id)                                            AS total_employees,
    COUNT(CASE WHEN e.employment_status = 'Active'     THEN 1 END) AS active_employees,
    COUNT(CASE WHEN e.employment_status = 'On Leave'   THEN 1 END) AS on_leave_employees,
    COUNT(CASE WHEN e.employment_status = 'Resigned'   THEN 1 END) AS resigned_employees,
    COUNT(CASE WHEN e.employment_status = 'Terminated' THEN 1 END) AS terminated_employees
FROM employees e
JOIN departments d
    ON e.department_id = d.department_id
GROUP BY d.department_name
ORDER BY total_employees DESC;


-- ===============================================================
-- Case Study 2: Departments With Over 70% Active Employees
-- ===============================================================
-- Business Problem:
--   HR wants to identify departments where more than 70% of
--   employees are currently active.
--
-- Required Output:
--   Department Name | Total Employees | Active Employees | Active %
-- ===============================================================

SELECT
    d.department_name,
    COUNT(e.emp_id) AS total_employees,
    COUNT(CASE WHEN e.is_active THEN 1 END) AS active_employees,
    ROUND(
        COUNT(CASE WHEN e.is_active THEN 1 END) * 100.0 / COUNT(e.emp_id),
        2
    ) AS active_percentage
FROM employees e
JOIN departments d
    ON e.department_id = d.department_id
GROUP BY d.department_name
HAVING COUNT(CASE WHEN e.is_active THEN 1 END) * 100.0 / COUNT(e.emp_id) > 70
ORDER BY active_percentage DESC;


-- ===============================================================
-- Case Study 3: Gender Diversity Report
-- ===============================================================
-- Business Problem:
--   HR wants a gender diversity breakdown by department.
--
-- Required Output:
--   Department Name | Male Employees | Female Employees |
--   Other Employees | Male % | Female % | Other %
-- ===============================================================

SELECT
    d.department_name,
    COUNT(CASE WHEN e.gender = 'Male' THEN 1 END) AS male_employees,
    ROUND(
        COUNT(CASE WHEN e.gender = 'Male' THEN 1 END) * 100.0 / COUNT(e.emp_id),
        2
    ) AS male_percentage,
    COUNT(CASE WHEN e.gender = 'Female' THEN 1 END) AS female_employees,
    ROUND(
        COUNT(CASE WHEN e.gender = 'Female' THEN 1 END) * 100.0 / COUNT(e.emp_id),
        2
    ) AS female_percentage,
    COUNT(CASE WHEN e.gender NOT IN ('Male', 'Female') THEN 1 END) AS other_employees,
    ROUND(
        COUNT(CASE WHEN e.gender NOT IN ('Male', 'Female') THEN 1 END) * 100.0 / COUNT(e.emp_id),
        2
    ) AS other_percentage
FROM employees e
JOIN departments d
    ON e.department_id = d.department_id
GROUP BY d.department_name
ORDER BY d.department_name;


-- ===============================================================
-- Case Study 4: Employees Earning 15%+ Above Department Average
-- ===============================================================
-- Business Problem:
--   Find employees whose salary is at least 15% higher than their
--   department's average salary.
--
-- Required Output:
--   Employee Name | Department | Salary | Department Average | Difference
-- ===============================================================

WITH salary_with_dept_avg AS (
    SELECT
        CONCAT_WS(' ', e.fname, e.lname) AS employee_name,
        d.department_name,
        e.basic_salary,
        AVG(e.basic_salary) OVER (PARTITION BY d.department_name) AS department_avg_salary
    FROM employees e
    JOIN departments d
        ON e.department_id = d.department_id
)

SELECT
    employee_name,
    department_name,
    basic_salary,
    ROUND(department_avg_salary, 2)              AS department_avg_salary,
    ROUND(basic_salary - department_avg_salary, 2) AS difference
FROM salary_with_dept_avg
WHERE basic_salary >= department_avg_salary * 1.15
ORDER BY difference DESC;


-- ===============================================================
-- Case Study 5: Highest-Paid Employee(s) Per Department
-- ===============================================================
-- Business Problem:
--   HR wants to identify the highest-paid employee(s) in each
--   department. If multiple employees are tied for the highest
--   salary, all of them should be shown.
--
-- Required Output:
--   Employee Name | Department | Salary | Department Rank
-- ===============================================================

WITH ranked_salaries AS (
    SELECT
        CONCAT_WS(' ', e.fname, e.lname) AS employee_name,
        d.department_name,
        e.basic_salary,
        RANK() OVER (PARTITION BY d.department_name ORDER BY e.basic_salary DESC) AS department_rank
    FROM employees e
    JOIN departments d
        ON e.department_id = d.department_id
)

SELECT
    employee_name,
    department_name,
    basic_salary,
    department_rank
FROM ranked_salaries
WHERE department_rank = 1
ORDER BY department_name;


-- ===============================================================
-- Case Study 6: Employees Without a Manager
-- ===============================================================
-- Business Problem:
--   HR wants a report of employees who don't have an assigned
--   manager (e.g., top-level leadership or unassigned records).
--
-- Required Output:
--   Employee Name | Department | Job Role | Salary
-- ===============================================================

SELECT
    CONCAT_WS(' ', e.fname, e.lname) AS employee_name,
    d.department_name,
    j.job_title,
    e.basic_salary
FROM employees e
JOIN departments d
    ON e.department_id = d.department_id
JOIN job_roles j
    ON e.job_role_id = j.job_role_id
WHERE e.manager_id IS NULL
ORDER BY d.department_name, e.basic_salary DESC;