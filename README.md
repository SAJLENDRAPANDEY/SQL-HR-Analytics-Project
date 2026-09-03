# PeoplePulse HR Analytics — PostgreSQL

> An end-to-end HR Analytics project built with PostgreSQL to transform employee workforce data into actionable business insights for HR leaders, managers, finance teams, and executives.

![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15%2B-336791?style=for-the-badge&logo=postgresql&logoColor=white)
![SQL](https://img.shields.io/badge/SQL-Advanced-4479A1?style=for-the-badge&logo=mysql&logoColor=white)
![Analytics](https://img.shields.io/badge/Analytics-HR%20Analytics-2E7D32?style=for-the-badge)
![Project](https://img.shields.io/badge/Project-Portfolio-F59E0B?style=for-the-badge)

---

## 📌 Project Overview

PeoplePulse HR Analytics is an end-to-end PostgreSQL analytics project designed to simulate a real-world organization's HR data environment.

The project focuses on analyzing:

- Workforce structure
- Employee compensation
- Department performance
- Management hierarchy
- Salary distribution
- Query performance and optimization

The primary objective is to demonstrate how SQL can be used not only to retrieve data, but also to answer business questions and support data-driven decision-making.

> **Note:** Attendance, Recruitment, Attrition, and Performance modules are **planned/extended modules** — they represent the analytical direction of the project but require their own supporting tables. Only mark them as "implemented" in this README once those tables and data exist in your schema.

---

## 🎯 Business Objective

HR and business leadership need reliable answers to questions such as:

- How large is the current workforce?
- Which departments have the highest payroll?
- Which employees are highly compensated?
- How does each department compare with the company average?
- Which managers have the largest teams?
- Are managers appropriately compensated compared with their teams?
- How is salary distributed across the organization?
- Which departments contribute most to total payroll?
- How can HR identify compensation anomalies?
- How can SQL queries be optimized for production-scale workloads?

PeoplePulse converts these business questions into reusable SQL analytics.

---

## 🏗️ Project Architecture

```text
PeoplePulse-HR-Analytics-PostgreSQL/
│
├── 01_Database_Design/
│   ├── ER_Diagram.png
│   └── Schema.sql
│
├── 02_DDL/
│   └── Create_Tables.sql
│
├── 03_DML/
│   └── Insert_Data.sql
│
├── 04_SQL_Case_Studies/
│   ├── 001_HR_Analytics.sql
│   ├── 002_Finance_Analytics.sql
│   ├── 003_CEO_Reports.sql
│   ├── 004_Manager_Reports.sql
│   ├── 005_Salary_Analytics.sql
│   └── 010_Advanced_Window_Functions.sql
│
├── 05_Views/
│   └── HR_Views.sql
│
├── 06_Functions/
│   └── HR_Functions.sql
│
├── 07_Stored_Procedures/
│   └── HR_Procedures.sql
│
├── 08_Triggers/
│   └── HR_Triggers.sql
│
├── 09_Indexing/
│   └── HR_Indexes.sql
│
├── 10_Optimization/
│   └── Explain_Analyze.sql
│
└── README.md
```

---

## 🗄️ Database Architecture

The database uses a relational structure centered around the `employees` table.

### Core Tables

| Table         | Purpose                                     |
| ------------- | -------------------------------------------- |
| `countries`   | Stores country and regional information     |
| `locations`   | Stores office/location information           |
| `departments` | Stores organizational departments             |
| `job_roles`   | Stores employee job roles and salary ranges  |
| `employees`   | Stores employee master data                   |

---

## 🔗 Data Relationships

```text
COUNTRIES → LOCATIONS → DEPARTMENTS → EMPLOYEES → JOB_ROLES

EMPLOYEES.manager_id → EMPLOYEES.emp_id  (self join, reporting hierarchy)
```

The `employees` table contains a self-referencing `manager_id`, allowing the project to model organizational reporting structures.

---

## 🧱 Database Design

### Countries
Country name, country code, currency, timezone, active status.

### Locations
Address, city, state, postal code, country relationship.

### Departments
Department name, department code, budget, location, department manager.

### Job Roles
Job title, job code, minimum salary, maximum salary, experience level, description.

### Employees
Employee code, name, email, phone, gender, date of birth, hire date, department, job role, manager, employment status, basic salary.

---

## 🛠️ Technologies Used

- PostgreSQL
- SQL
- PL/pgSQL
- pgAdmin
- Git / GitHub

---

## 📊 SQL Skills Demonstrated

**Basic SQL** — SELECT, WHERE, ORDER BY, LIMIT, DISTINCT, BETWEEN, IN, LIKE, CASE, COALESCE

**Aggregation** — COUNT, SUM, AVG, MIN, MAX, GROUP BY, HAVING

**Joins** — INNER JOIN, LEFT JOIN, SELF JOIN, CROSS JOIN, multi-table joins

**Advanced SQL** — CTEs, subqueries, correlated subqueries, window functions, ranking, conditional aggregation, salary benchmarking, percentage calculations, distribution analysis

**Window Functions** — `RANK()`, `DENSE_RANK()`, `ROW_NUMBER()`, `NTILE()`, `PERCENT_RANK()`, `LAG()`, `LEAD()`, `AVG() OVER()`, `SUM() OVER()`, `COUNT() OVER()`

---

## 📈 Analytics Modules

### 001 — HR Analytics
Employee master analysis, workforce filtering, department analysis, salary analysis, employee ranking, workforce distribution.

*Example questions:* Who are the highest-paid employees? Which departments have the most employees? What is the average company salary?

### 002 — Finance Analytics
Department payroll, salary bands, payroll contribution, benchmarking, compensation distribution.

*Example questions:* Which department consumes the highest payroll? What percentage of total payroll belongs to each department?

### 003 — CEO Reports
Executive workforce KPIs — total employees, active employees, average salary, total payroll, highest/lowest salary, department payroll rank, top-20% salary contribution.

### 004 — Manager Reports
Management hierarchy, span of control, team size, team salary, manager compensation.

*Example questions:* Which managers have the largest teams? Which managers earn less than their direct reports?

### 005 — Salary Analytics
Salary distribution, salary bands, department benchmarking, salary gaps, compensation anomalies.

```text
< 50,000          → Low
50,000–100,000    → Medium
100,001–150,000   → High
> 150,000         → Executive
```

### 010 — Advanced Window Functions
Ranking, percentiles, department comparisons, salary benchmarking, top-N analysis, distribution analysis, sequential analysis.

### 📋 Planned / Extended Modules
The following modules are part of the project's roadmap and will be implemented once the supporting tables (attendance, recruitment, attrition, performance) are added to the schema:

- **006 — Attendance Analytics**
- **007 — Recruitment Analytics**
- **008 — Attrition Analytics**
- **009 — Performance Analytics**

---

## 👁️ Views

Reusable reporting layers, e.g. `vw_employee_master`, `vw_active_employees`, `vw_department_salary_summary`. Views provide a clean abstraction layer for analysts and reporting systems instead of repeatedly writing complex joins.

## ⚙️ Functions

PostgreSQL user-defined functions encapsulate reusable business logic (employee full name, salary calculations, department analytics) using `CREATE FUNCTION`, `RETURNS`, PL/pgSQL, parameters, and conditional logic.

## 🔄 Stored Procedures

Used for operational database workflows: parameterized operations, data modification, transaction-oriented logic, reusable business processes.

## ⚡ Triggers

Demonstrate automated database behavior: audit logging, automatic timestamps, data validation, change tracking.

## 🚀 Indexing

Single-column indexes, composite indexes, partial indexes, expression indexes, index selection and trade-offs.

```sql
CREATE INDEX idx_employees_department_id
ON employees(department_id);
```

## 🔍 Query Optimization

Uses `EXPLAIN`, `EXPLAIN ANALYZE`, and `EXPLAIN (ANALYZE, BUFFERS)` to evaluate sequential scans, index scans, bitmap scans, nested loops, hash joins, sort/aggregate cost, actual rows, execution time, planning time, and buffer usage.

---

## 🧠 Example Business Analysis

Department salary benchmarking against the company average:

```sql
SELECT
    d.department_name,
    AVG(e.basic_salary) AS department_average,
    AVG(AVG(e.basic_salary)) OVER () AS company_average
FROM employees e
JOIN departments d
    ON e.department_id = d.department_id
GROUP BY d.department_name;
```

**Finding:** A department may show payroll significantly above the company average relative to its headcount.
**Business implication:** Leadership should review whether compensation concentration in that department aligns with workforce size and budget allocation.
**Action:** Compare payroll contribution against headcount and department budget before finalizing compensation decisions.

---

## 📌 Key Business Metrics

**Workforce:** total employees, active/inactive employees, department headcount, team size, span of control

**Compensation:** average salary, percentile analysis, highest/lowest salary, salary gap, total payroll, payroll percentage, salary rank

**Management:** direct reports, team average salary, team payroll, manager vs. team compensation

---

## 📐 Analytical Approach

```text
Business Problem → Understand Data Model → Identify Required Tables
→ Build SQL Query → Validate Results → Apply Advanced SQL
→ Create Reusable Views / Functions → Optimize Query
→ Analyze Execution Plan → Generate Business Insight
```

---

## 🧩 Data Quality & Validation

```sql
CHECK (basic_salary >= 0)
CHECK (date_of_birth < hire_date)
CHECK (employment_status IN ('Active', 'On Leave', 'Resigned', 'Terminated'))
```

## 🔐 Referential Integrity

- `employees.department_id → departments.department_id`
- `employees.job_role_id → job_roles.job_role_id`
- `employees.manager_id → employees.emp_id` (self-referencing)

---

## 📊 Why This Project Is Relevant for Data Analyst Roles

1. **Understand business requirements** — convert questions from HR, Finance, Managers, and Executives into SQL problems.
2. **Work with relational data** — model relationships across Employees, Departments, Job Roles, Locations, Countries.
3. **Perform analytical transformations** — JOIN, GROUP BY, HAVING, CASE, CTEs, subqueries, window functions.
4. **Build reusable analytics** — Views, Functions, Stored Procedures.
5. **Think about production performance** — Indexes, EXPLAIN, EXPLAIN ANALYZE, query optimization.
6. **Translate SQL output into business decisions** — not just "write a query," but "use data to support a decision."

---

## 🧪 How to Run the Project

| Step | Action | File(s) |
|------|--------|---------|
| 1 | Create database | `CREATE DATABASE peoplepulse;` |
| 2 | Run schema | `01_Database_Design/Schema.sql` |
| 3 | Create tables | `02_DDL/Create_Tables.sql` |
| 4 | Insert data | `03_DML/Insert_Data.sql` |
| 5 | Run analytics | `04_SQL_Case_Studies/*.sql` (in numeric order) |
| 6 | Create views | `05_Views/HR_Views.sql` |
| 7 | Create functions | `06_Functions/HR_Functions.sql` |
| 8 | Create stored procedures | `07_Stored_Procedures/HR_Procedures.sql` |
| 9 | Create triggers | `08_Triggers/HR_Triggers.sql` |
| 10 | Create indexes | `09_Indexing/HR_Indexes.sql` |
| 11 | Analyze performance | `10_Optimization/Explain_Analyze.sql` |

---

## 🧰 Recommended Environment

- PostgreSQL 15+
- pgAdmin 4
- VS Code
- Git / GitHub

---

## 💼 Portfolio Highlights

Advanced PostgreSQL · Data Modeling · Relational Database Design · Business Analytics · HR & Financial Analytics · Executive & Manager Reporting · Window Functions · CTEs · Complex Joins · Views · Functions · Stored Procedures · Triggers · Indexing · Query Optimization · EXPLAIN ANALYZE

---

## 🎯 Final Outcome

PeoplePulse HR Analytics demonstrates an end-to-end SQL analytics workflow — from database design and sample data creation to advanced business analytics and performance optimization — spanning both:

- **Analytics** — "What does the data tell us?"
- **Engineering** — "How can we make the data system reliable, reusable, and performant?"

Suitable as a portfolio project for: Data Analyst, Business Analyst, SQL Analyst, Reporting Analyst, HR Analyst, and Junior Analytics Engineer roles.

---

## 👨‍💻 Author

**Sajlendra Pandey**
SQL | PostgreSQL | Data Analytics | Business Analytics

[GitHub](https://github.com/SAJLENDRAPANDEY) · [Portfolio](https://sajlendrapandey.netlify.app) · [LinkedIn](https://linkedin.com/in/sajlendra-pandey-37378627b)

---

⭐ If you find this project useful, consider giving the repository a star.
