/*
=====================================================================
 Project      : PeoplePulse HR Analytics PostgreSQL
 Module       : 10 - Query Optimization
 File         : Explain_Analyze.sql
 Database     : PostgreSQL
 Author       : Sajlendra Pandey

 Purpose:
 Query performance analysis and optimization using PostgreSQL.

 Topics:
 - EXPLAIN
 - EXPLAIN ANALYZE
 - Sequential Scan
 - Index Scan
 - Bitmap Index Scan
 - Cost Estimation
 - Actual Execution Time
 - Rows Estimation
 - Filtering
 - Sorting
 - Aggregation
 - JOIN Optimization
 - Index Effectiveness
 - Composite Indexes
 - Partial Indexes
 - Function-based Filtering
 - Query Rewriting
 - CTE Performance
 - Subquery Optimization
 - Window Function Optimization
 - Before vs After Performance

 Difficulty:
 Advanced → Expert

 Total Case Studies:
 15
=====================================================================
*/

-- 🟢 LEVEL 1 — Understanding Execution Plans
-- Q1 — Basic EXPLAIN

-- Company wants to understand how PostgreSQL executes an employee search.

-- Query:

-- SELECT *
-- FROM employees
-- WHERE department_id = 1;
-- Task

-- Run:

-- EXPLAIN
-- SELECT *
-- FROM employees
-- WHERE department_id = 1;
-- Analyze

-- Identify:

-- Scan type
-- Estimated cost
-- Estimated rows
-- Filter condition
-- Whether PostgreSQL is using an index

-- ============================================================
-- Q1: Basic EXPLAIN — Employee Department Search
-- ============================================================


EXPLAIN
SELECT *
FROM employees
WHERE department_id = 1;


-- Analyze actual execution
EXPLAIN ANALYZE
SELECT *
FROM employees
WHERE department_id = 1;


