/*
=====================================================================
 Project      : PeoplePulse HR Analytics PostgreSQL
 Module       : 09 - Indexing
 File         : Indexing_Practice.sql
 Database     : PostgreSQL
 Author       : Sajlendra Pandey

 Purpose:
 Database indexing and query performance optimization.

 Topics Covered:
 - B-Tree Index
 - Single Column Index
 - Composite Index
 - Unique Index
 - Partial Index
 - Expression Index
 - INCLUDE Index
 - EXPLAIN
 - EXPLAIN ANALYZE
 - EXPLAIN ANALYZE BUFFERS
 - Index Scan
 - Sequential Scan
 - Bitmap Scan
 - Index Only Scan
 - Index Statistics
 - Index Size Analysis
 - Index Audit
 - Query Optimization

 Difficulty:
 Advanced → Expert

 Total Case Studies:
 20

=====================================================================
*/


-- ================================================================
-- DATABASE CONTEXT
-- ================================================================

SET search_path TO peoplepulse;


-- ================================================================
-- Q1 — Employee Department Lookup
-- ================================================================

/*
Business Requirement:

HR frequently searches employees using department_id.

Task:
Create an index on employees.department_id.

Expected Index:
idx_employees_department_id
*/

DROP INDEX IF EXISTS idx_employees_department_id;

CREATE INDEX idx_employees_department_id
ON employees(department_id);


-- Verify Query Plan

EXPLAIN
SELECT *
FROM employees
WHERE department_id = 1;


EXPLAIN ANALYZE
SELECT *
FROM employees
WHERE department_id = 1;


-- ================================================================
-- Q2 — Employee Email Lookup
-- ================================================================

/*
Business Requirement:

The application frequently searches employees by email.

Important:
email already has a UNIQUE constraint.

PostgreSQL creates a unique index to enforce the constraint.

Therefore:
DO NOT create another duplicate email index.
*/

SELECT
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'peoplepulse'
AND tablename = 'employees';


EXPLAIN
SELECT *
FROM employees
WHERE email = 'rahul.sharma@peoplepulse.com';


EXPLAIN ANALYZE
SELECT *
FROM employees
WHERE email = 'rahul.sharma@peoplepulse.com';


-- ================================================================
-- Q3 — Salary Filtering
-- ================================================================

/*
Business Requirement:

Finance frequently searches employees
whose salary is greater than 100000.

Create an index on basic_salary.
*/

DROP INDEX IF EXISTS idx_employees_basic_salary;

CREATE INDEX idx_employees_basic_salary
ON employees(basic_salary);


EXPLAIN
SELECT
    emp_code,
    fname,
    lname,
    basic_salary
FROM employees
WHERE basic_salary > 100000;


EXPLAIN ANALYZE
SELECT
    emp_code,
    fname,
    lname,
    basic_salary
FROM employees
WHERE basic_salary > 100000;


-- ================================================================
-- Q4 — Department + Salary Composite Index
-- ================================================================

/*
Business Requirement:

Finance frequently searches employees by:

1. Department
2. Salary threshold

Create a composite index.

Column Order:

department_id
basic_salary
*/

DROP INDEX IF EXISTS idx_employees_department_salary;

CREATE INDEX idx_employees_department_salary
ON employees(department_id, basic_salary);


EXPLAIN ANALYZE
SELECT *
FROM employees
WHERE department_id = 1
AND basic_salary > 70000;


-- ================================================================
-- Q5 — Composite Index Column Order Analysis
-- ================================================================

/*
Business Requirement:

Compare different composite index column orders.

Index A:
(department_id, basic_salary)

Index B:
(basic_salary, department_id)

This exercise demonstrates the importance
of column order in composite indexes.
*/

DROP INDEX IF EXISTS idx_test_department_salary;
DROP INDEX IF EXISTS idx_test_salary_department;

CREATE INDEX idx_test_department_salary
ON employees(department_id, basic_salary);

CREATE INDEX idx_test_salary_department
ON employees(basic_salary, department_id);


-- Query A

EXPLAIN ANALYZE
SELECT *
FROM employees
WHERE department_id = 1;


-- Query B

EXPLAIN ANALYZE
SELECT *
FROM employees
WHERE basic_salary > 70000;


-- Query C

EXPLAIN ANALYZE
SELECT *
FROM employees
WHERE department_id = 1
AND basic_salary > 70000;


-- ================================================================
-- Q6 — Department + Employment Status
-- ================================================================

/*
Business Requirement:

HR frequently retrieves active employees
from a specific department.
*/

DROP INDEX IF EXISTS idx_employees_department_status;

CREATE INDEX idx_employees_department_status
ON employees(department_id, employment_status);


EXPLAIN ANALYZE
SELECT
    emp_code,
    fname,
    lname,
    basic_salary
FROM employees
WHERE department_id = 1
AND employment_status = 'Active';


-- ================================================================
-- Q7 — Active Employee Partial Index
-- ================================================================

/*
Business Requirement:

Most HR queries work only with active employees.

Instead of indexing all employees,
create a partial index containing only Active employees.

This can reduce index size and maintenance overhead.
*/

DROP INDEX IF EXISTS idx_active_employees_department;

CREATE INDEX idx_active_employees_department
ON employees(department_id)
WHERE employment_status = 'Active';


EXPLAIN ANALYZE
SELECT *
FROM employees
WHERE employment_status = 'Active'
AND department_id = 1;


-- ================================================================
-- Q8 — Active Employee Salary Partial Index
-- ================================================================

/*
Business Requirement:

Finance mainly analyzes salaries of active employees.

Create a partial index for:

Active employees
+
Salary
*/

DROP INDEX IF EXISTS idx_active_employee_salary;

CREATE INDEX idx_active_employee_salary
ON employees(basic_salary)
WHERE employment_status = 'Active';


EXPLAIN ANALYZE
SELECT
    emp_code,
    basic_salary
FROM employees
WHERE employment_status = 'Active'
AND basic_salary > 100000;


-- ================================================================
-- Q9 — Case-Insensitive Email Search
-- ================================================================

/*
Business Requirement:

Application performs case-insensitive email searches.

Query uses:

LOWER(email)

Therefore create an expression index.
*/

DROP INDEX IF EXISTS idx_employees_lower_email;

CREATE INDEX idx_employees_lower_email
ON employees(LOWER(email));


EXPLAIN ANALYZE
SELECT *
FROM employees
WHERE LOWER(email) = 'rahul.sharma@peoplepulse.com';


-- ================================================================
-- Q10 — Full Name Expression Index
-- ================================================================

/*
Business Requirement:

HR searches employees by complete name.

Search expression:

LOWER(CONCAT_WS(' ', fname, lname))
*/

DROP INDEX IF EXISTS idx_employees_full_name;

CREATE INDEX idx_employees_full_name
ON employees(
    LOWER(CONCAT_WS(' ', fname, lname))
);


EXPLAIN ANALYZE
SELECT *
FROM employees
WHERE LOWER(CONCAT_WS(' ', fname, lname))
      = 'rahul sharma';


-- ================================================================
-- Q11 — Department Salary Dashboard
-- ================================================================

/*
Business Requirement:

Finance frequently generates salary summaries
for Active employees grouped by department.
*/

DROP INDEX IF EXISTS idx_active_department_salary;

CREATE INDEX idx_active_department_salary
ON employees(department_id, basic_salary)
WHERE employment_status = 'Active';


EXPLAIN (ANALYZE, BUFFERS)
SELECT
    department_id,
    COUNT(*) AS employees,
    SUM(basic_salary) AS total_salary,
    AVG(basic_salary) AS average_salary
FROM employees
WHERE employment_status = 'Active'
GROUP BY department_id;


-- ================================================================
-- Q12 — Manager Team Lookup
-- ================================================================

/*
Business Requirement:

Manager dashboards frequently retrieve
all employees reporting to a manager.
*/

DROP INDEX IF EXISTS idx_employees_manager_id;

CREATE INDEX idx_employees_manager_id
ON employees(manager_id);


EXPLAIN (ANALYZE, BUFFERS)
SELECT
    emp_id,
    emp_code,
    fname,
    lname,
    basic_salary
FROM employees
WHERE manager_id = 1;


-- ================================================================
-- Q13 — Manager + Salary Analysis
-- ================================================================

/*
Business Requirement:

Management frequently retrieves:

- Employees reporting to a manager
- Salary above a threshold
- Sorted by salary descending

Create a composite index supporting
manager filtering and salary ordering.
*/

DROP INDEX IF EXISTS idx_manager_salary;

CREATE INDEX idx_manager_salary
ON employees(manager_id, basic_salary DESC);


EXPLAIN (ANALYZE, BUFFERS)
SELECT
    emp_code,
    fname,
    lname,
    basic_salary
FROM employees
WHERE manager_id = 1
AND basic_salary > 70000
ORDER BY basic_salary DESC;


-- ================================================================
-- Q14 — Index Only Scan using INCLUDE
-- ================================================================

/*
Business Requirement:

Finance frequently retrieves:

department_id
basic_salary

Create an index where:

Search column:
department_id

Included column:
basic_salary
*/

DROP INDEX IF EXISTS idx_department_include_salary;

CREATE INDEX idx_department_include_salary
ON employees(department_id)
INCLUDE (basic_salary);


EXPLAIN (ANALYZE, BUFFERS)
SELECT
    department_id,
    basic_salary
FROM employees
WHERE department_id = 1;


-- ================================================================
-- Q15 — CEO Dashboard Optimization
-- ================================================================

/*
Business Requirement:

CEO dashboard displays department-level
salary statistics for active employees.

Step 1:
Analyze query.

Step 2:
Create an appropriate index.

Step 3:
Analyze query again.
*/


-- BEFORE INDEX

EXPLAIN (ANALYZE, BUFFERS)
SELECT
    d.department_name,
    COUNT(e.emp_id) AS employees,
    SUM(e.basic_salary) AS total_salary,
    AVG(e.basic_salary) AS average_salary
FROM employees e
JOIN departments d
    ON e.department_id = d.department_id
WHERE e.employment_status = 'Active'
GROUP BY d.department_name
ORDER BY total_salary DESC;


-- INDEX FOR CEO DASHBOARD

DROP INDEX IF EXISTS idx_ceo_active_department_salary;

CREATE INDEX idx_ceo_active_department_salary
ON employees(department_id, basic_salary)
WHERE employment_status = 'Active';


-- AFTER INDEX

EXPLAIN (ANALYZE, BUFFERS)
SELECT
    d.department_name,
    COUNT(e.emp_id) AS employees,
    SUM(e.basic_salary) AS total_salary,
    AVG(e.basic_salary) AS average_salary
FROM employees e
JOIN departments d
    ON e.department_id = d.department_id
WHERE e.employment_status = 'Active'
GROUP BY d.department_name
ORDER BY total_salary DESC;


-- ================================================================
-- Q16 — Find Existing Employee Indexes
-- ================================================================

/*
Business Requirement:

Database administrator wants to audit
all indexes on employees table.
*/

SELECT
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'peoplepulse'
AND tablename = 'employees'
ORDER BY indexname;


-- ================================================================
-- Q17 — Identify Potentially Redundant Indexes
-- ================================================================

/*
Business Requirement:

Identify indexes that may overlap.

Example:

(department_id)

and

(department_id, basic_salary)

The second index may support some queries
that the first index supports.

However, redundancy must be evaluated
against the actual workload.
*/

SELECT
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'peoplepulse'
AND tablename = 'employees'
ORDER BY indexname;


-- ================================================================
-- Q18 — Index Size Analysis
-- ================================================================

/*
Business Requirement:

Database administrator wants to understand
how much storage each employee index consumes.
*/

SELECT
    indexrelname AS index_name,
    pg_size_pretty(
        pg_relation_size(indexrelid)
    ) AS index_size
FROM pg_stat_user_indexes
WHERE schemaname = 'peoplepulse'
AND relname = 'employees'
ORDER BY pg_relation_size(indexrelid) DESC;


-- ================================================================
-- Q19 — Index Usage Statistics
-- ================================================================

/*
Business Requirement:

Identify which indexes are actually being used.

Metrics:

- Index Scans
- Tuples Read
- Tuples Fetched
*/

SELECT
    relname AS table_name,
    indexrelname AS index_name,
    idx_scan AS index_scans,
    idx_tup_read AS tuples_read,
    idx_tup_fetch AS tuples_fetched
FROM pg_stat_user_indexes
WHERE schemaname = 'peoplepulse'
AND relname = 'employees'
ORDER BY idx_scan DESC;


-- ================================================================
-- Q20 — FINAL INDUSTRY-LEVEL INDEX AUDIT
-- ================================================================

/*
Business Requirement:

CEO dashboard and HR application execute
the following queries frequently.

Your task is to design a complete
indexing strategy for employees table.
*/


-- Query A
-- Department lookup

EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM employees
WHERE department_id = 1;


-- Query B
-- Department + Salary

EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM employees
WHERE department_id = 1
AND basic_salary > 70000;


-- Query C
-- Active Department Employees

EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM employees
WHERE employment_status = 'Active'
AND department_id = 1;


-- Query D
-- Manager Team Salary

EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM employees
WHERE manager_id = 1
ORDER BY basic_salary DESC;


-- Query E
-- Case-insensitive Email

EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM employees
WHERE LOWER(email) =
      'rahul.sharma@peoplepulse.com';


-- ================================================================
-- FINAL INDEX INVENTORY
-- ================================================================

SELECT
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'peoplepulse'
AND tablename = 'employees'
ORDER BY indexname;


-- ================================================================
-- FINAL INDEX USAGE REPORT
-- ================================================================

SELECT
    relname AS table_name,
    indexrelname AS index_name,
    idx_scan AS index_scans,
    idx_tup_read AS tuples_read,
    idx_tup_fetch AS tuples_fetched
FROM pg_stat_user_indexes
WHERE schemaname = 'peoplepulse'
AND relname = 'employees'
ORDER BY idx_scan DESC;


-- ================================================================
-- FINAL INDEX SIZE REPORT
-- ================================================================

SELECT
    indexrelname AS index_name,
    pg_size_pretty(
        pg_relation_size(indexrelid)
    ) AS index_size
FROM pg_stat_user_indexes
WHERE schemaname = 'peoplepulse'
AND relname = 'employees'
ORDER BY pg_relation_size(indexrelid) DESC;



=====================================================================
 END OF FILE
=====================================================================
*/
