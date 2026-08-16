/*
====================================================================
Project  : SQL HR Analytics Project
Module   : 004 - Manager Reports
Database : PostgreSQL

Purpose:
Manager-level workforce, team structure, and compensation analytics.

Business Areas:
- Management Hierarchy
- Span of Control
- Team Compensation
- Team Composition
- Manager Performance
- Reporting Structure
- Team Risk

Difficulty:
Advanced → Expert

====================================================================
*/


/*
====================================================================
CASE STUDY 1 — Manager Direct Reports & Team Salary Analysis
====================================================================

Required Output:
- Manager Name
- Department
- Direct Reports
- Average Team Salary
- Highest Team Salary
- Lowest Team Salary

Business Rule:
- Show only actual managers with at least one direct report.
- Sort managers by number of direct reports, highest first.
====================================================================
*/

SELECT
    CONCAT_WS(' ', m.fname, m.lname) AS manager_name,
    d.department_name AS department,
    COUNT(e.emp_id) AS direct_reports,
    ROUND(AVG(e.basic_salary), 2) AS average_team_salary,
    MAX(e.basic_salary) AS highest_team_salary,
    MIN(e.basic_salary) AS lowest_team_salary
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
HAVING COUNT(e.emp_id) >= 1
ORDER BY
    direct_reports DESC,
    manager_name;


/*
====================================================================
CASE STUDY 2 — Manager Team Compensation Summary
====================================================================

Required Output:
- Manager
- Department
- Team Size
- Average Team Salary
- Total Team Salary

Business Rule:
- Show managers with at least 2 direct reports.
- Sort by team size, largest team first.
====================================================================
*/

SELECT
    CONCAT_WS(' ', m.fname, m.lname) AS manager,
    d.department_name AS department,
    COUNT(e.emp_id) AS team_size,
    ROUND(AVG(e.basic_salary), 2) AS average_team_salary,
    SUM(e.basic_salary) AS total_team_salary
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
HAVING COUNT(e.emp_id) >= 2
ORDER BY
    team_size DESC,
    manager;


/*
====================================================================
CASE STUDY 3
====================================================================

Reserved for future manager analytics.
====================================================================
*/


/*
====================================================================
CASE STUDY 4 — Highest Paid Team Member
====================================================================

Required Output:
- Manager Name
- Department
- Highest Paid Team Member
- Team Member Salary

Business Rule:
- For each manager, identify the highest-paid direct report.
- If multiple team members have the same highest salary,
  show all tied employees.
====================================================================
*/

SELECT
    CONCAT_WS(' ', m.fname, m.lname) AS manager_name,
    d.department_name AS department,
    CONCAT_WS(' ', e.fname, e.lname) AS highest_paid_team_member,
    e.basic_salary AS team_member_salary
FROM employees m
JOIN employees e
    ON e.manager_id = m.emp_id
JOIN departments d
    ON m.department_id = d.department_id
WHERE e.basic_salary = (
    SELECT MAX(e2.basic_salary)
    FROM employees e2
    WHERE e2.manager_id = e.manager_id
)
ORDER BY
    manager_name,
    highest_paid_team_member;


/*
====================================================================
CASE STUDY 5 — Complete Manager Team Compensation
====================================================================

Required Output:
- Manager Name
- Department
- Team Size
- Total Team Salary
- Average Team Salary
- Highest Team Salary
- Lowest Team Salary

Business Rule:
- Show managers with direct reports.
- Sort by team size, largest team first.
====================================================================
*/

SELECT
    CONCAT_WS(' ', m.fname, m.lname) AS manager_name,
    d.department_name AS department,
    COUNT(e.emp_id) AS team_size,
    SUM(e.basic_salary) AS total_team_salary,
    ROUND(AVG(e.basic_salary), 2) AS average_team_salary,
    MAX(e.basic_salary) AS highest_team_salary,
    MIN(e.basic_salary) AS lowest_team_salary
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
ORDER BY
    team_size DESC,
    manager_name;


/*
====================================================================
CASE STUDY 6 — Department-Wise Largest Management Team
====================================================================

Required Output:
- Manager
- Department
- Team Size
- Average Team Salary

Business Rule:
- Find the manager with the largest team in each department.
- If multiple managers have the same team size,
  show all tied managers.
====================================================================
*/

WITH manager_team AS (
    SELECT
        m.emp_id AS manager_id,
        CONCAT_WS(' ', m.fname, m.lname) AS manager,
        d.department_name AS department,
        COUNT(e.emp_id) AS team_size,
        AVG(e.basic_salary) AS average_team_salary
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
),

ranked_managers AS (
    SELECT
        manager,
        department,
        team_size,
        average_team_salary,
        DENSE_RANK() OVER (
            PARTITION BY department
            ORDER BY team_size DESC
        ) AS team_size_rank
    FROM manager_team
)

SELECT
    manager AS "Manager",
    department AS "Department",
    team_size AS "Team Size",
    ROUND(average_team_salary, 2) AS "Average Team Salary"
FROM ranked_managers
WHERE team_size_rank = 1
ORDER BY
    department,
    manager;


/*
====================================================================
CASE STUDY 7 / BUSINESS PROBLEM 8
— Manager vs Company Average Salary
====================================================================

Business Problem:
Identify managers whose team's average salary is higher than
the overall company average salary.

Required Output:
- Manager
- Department
- Team Size
- Team Average Salary
- Company Average Salary
- Difference

Condition:
Team Average Salary > Company Average Salary

Concepts:
- Self Join
- CTE
- Aggregate Functions
- CROSS JOIN
====================================================================
*/

WITH company_average AS (
    SELECT
        AVG(basic_salary) AS company_average_salary
    FROM employees
),

manager_teams AS (
    SELECT
        m.emp_id AS manager_id,
        CONCAT_WS(' ', m.fname, m.lname) AS manager,
        d.department_name AS department,
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
        d.department_name
)

SELECT
    mt.manager AS "Manager",
    mt.department AS "Department",
    mt.team_size AS "Team Size",
    ROUND(mt.team_average_salary, 2) AS "Team Average Salary",
    ROUND(ca.company_average_salary, 2) AS "Company Average Salary",
    ROUND(
        mt.team_average_salary - ca.company_average_salary,
        2
    ) AS "Difference"
FROM manager_teams mt
CROSS JOIN company_average ca
WHERE mt.team_average_salary > ca.company_average_salary
ORDER BY
    "Difference" DESC,
    "Manager";


/*
====================================================================
CASE STUDY 8 / BUSINESS PROBLEM 9
— Manager Compensation Risk
====================================================================

Business Problem:
Identify managers whose salary is less than the average salary
of their direct reports.

Required Output:
- Manager
- Department
- Manager Salary
- Team Average Salary
- Salary Gap

Condition:
Manager Salary < Team Average Salary

Business Interpretation:
A positive salary gap may indicate a potential management
compensation imbalance.
====================================================================
*/

WITH manager_teams AS (
    SELECT
        m.emp_id AS manager_id,
        CONCAT_WS(' ', m.fname, m.lname) AS manager,
        d.department_name AS department,
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
    manager AS "Manager",
    department AS "Department",
    manager_salary AS "Manager Salary",
    ROUND(team_average_salary, 2) AS "Team Average Salary",
    ROUND(
        team_average_salary - manager_salary,
        2
    ) AS "Salary Gap"
FROM manager_teams
WHERE manager_salary < team_average_salary
ORDER BY
    "Salary Gap" DESC,
    "Manager";


/*
====================================================================
CASE STUDY 9 / BUSINESS PROBLEM 10
— Manager Team Salary Ranking
====================================================================

Business Problem:
Rank managers according to the total salary of their direct reports.

Required Output:
- Manager
- Department
- Team Size
- Total Team Salary
- Team Salary Rank

Business Rules:
- Highest total team salary = Rank 1.
- Managers with the same total team salary receive the same rank.
- DENSE_RANK() is used to maintain consecutive ranking.
====================================================================
*/

WITH manager_teams AS (
    SELECT
        m.emp_id AS manager_id,
        CONCAT_WS(' ', m.fname, m.lname) AS manager,
        d.department_name AS department,
        COUNT(e.emp_id) AS team_size,
        SUM(e.basic_salary) AS total_team_salary
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
    manager AS "Manager",
    department AS "Department",
    team_size AS "Team Size",
    total_team_salary AS "Total Team Salary",
    DENSE_RANK() OVER (
        ORDER BY total_team_salary DESC
    ) AS "Team Salary Rank"
FROM manager_teams
ORDER BY
    "Team Salary Rank",
    "Manager";