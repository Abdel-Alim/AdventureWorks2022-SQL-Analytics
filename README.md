# Enterprise Sales Analytics & Data Governance System

**An End-to-End SQL Analytics Engineering Project | Microsoft SQL Server | AdventureWorks2022**

[![SQL Server](https://img.shields.io/badge/SQL%20Server-T--SQL-CC2927?logo=microsoftsqlserver&logoColor=white)](https://www.microsoft.com/en-us/sql-server)
[![Analytics](https://img.shields.io/badge/Domain-Sales%20Analytics-2563EB)](#-analytical-capabilities)
[![Data Governance](https://img.shields.io/badge/Focus-Data%20Governance-0F766E)](#-data-governance--auditing)
[![BI Ready](https://img.shields.io/badge/BI-Power%20BI%20%7C%20Tableau-F2C811)](#-business-intelligence-integration)
[![Database](https://img.shields.io/badge/Database-AdventureWorks2022-64748B)](#-database--environment)

A comprehensive SQL analytics solution built on Microsoft's **AdventureWorks2022** database, transforming transactional sales data into actionable business intelligence through advanced T-SQL analytics, customer segmentation, product portfolio analysis, BI-ready views, automated reporting, data auditing, and index optimization.

This project demonstrates how SQL can support the complete analytical workflow—from querying operational data and calculating business KPIs to preparing reporting datasets and implementing data governance mechanisms.

---

## 📌 Table of Contents

- [Project Overview](#-project-overview)
- [Business Objectives](#-business-objectives)
- [Analytical Capabilities](#-analytical-capabilities)
- [Technical Implementation](#-technical-implementation)
- [Business Intelligence Integration](#-business-intelligence-integration)
- [Data Governance & Auditing](#-data-governance--auditing)
- [Performance Optimization](#-performance-optimization)
- [Technology Stack](#-technology-stack)
- [Database & Environment](#-database--environment)
- [Getting Started](#-getting-started)
- [Example Usage](#-example-usage)
- [Key Skills Demonstrated](#-key-skills-demonstrated)
- [Future Enhancements](#-future-enhancements)
- [Author](#-author)
- [License](#-license)

---

## 🚀 Project Overview

Modern organizations need more than raw sales reports. They need reliable metrics, customer intelligence, product prioritization, consistent reporting datasets, and mechanisms for tracking changes to important business records.

The **Enterprise Sales Analytics & Data Governance System** addresses these needs through a collection of SQL-based analytical and database engineering components.

The solution includes:

- Financial performance analysis and year-over-year growth calculations.
- Customer segmentation using Recency, Frequency, and Monetary (RFM) analysis.
- Product revenue contribution analysis based on the Pareto principle.
- Reusable analytical views for Business Intelligence tools.
- Parameterized stored procedures for territory performance reporting.
- Audit tables and DML triggers for tracking changes to sales records.
- Nonclustered covering indexes designed to support analytical query patterns.

**Project objective:** Build a maintainable, analytics-focused SQL solution that bridges operational database systems and business decision-making.

## 🎯 Business Objectives

| Business Challenge | SQL-Based Solution |
|---|---|
| Limited visibility into historical sales performance | Annual revenue analysis and YoY growth calculations |
| Difficulty identifying valuable customer groups | RFM scoring and customer segmentation |
| Need to prioritize revenue-generating products | Product ranking and cumulative revenue contribution |
| Repeated reporting logic across BI dashboards | Reusable SQL analytical views |
| Manual territory performance reporting | Parameterized stored procedures and target benchmarks |
| Limited visibility into changes to sales records | Audit tables and update triggers |
| Potential inefficiencies in analytical queries | Targeted nonclustered index design |

---

## 📊 Analytical Capabilities

### 1. Financial Performance & YoY Growth Analytics

Evaluates historical financial performance using annual sales aggregations and SQL window functions.

**Key metrics:**

- **Gross Revenue:** Aggregated sales order subtotals.
- **Overhead Costs:** Combined tax and freight amounts.
- **Total Revenue:** Aggregated order totals, including applicable charges.
- **Year-over-Year Growth:** Percentage change in annual subtotal revenue compared with the previous year.

**Technical implementation:**

- Common Table Expressions (CTEs).
- Aggregate functions such as `SUM()`.
- Window functions using `LAG()`.
- Date-based grouping with `YEAR()`.
- Safe division using `NULLIF()`.
- Numeric formatting using `ROUND()`.

**Business value:** Helps analysts evaluate historical performance, identify growth patterns, and establish a foundation for financial reporting.

### 2. Customer Segmentation — RFM Analysis

Implements an RFM framework to assess customer purchasing behavior using three dimensions.

| Dimension | Definition | Business Purpose |
|---|---|---|
| Recency (R) | Days since the customer's latest order relative to the latest order in the dataset | Understand purchasing freshness |
| Frequency (F) | Number of distinct sales orders | Measure purchase frequency |
| Monetary (M) | Sum of order subtotals | Estimate customer spending contribution |

The solution uses `NTILE(5)` to divide customer metrics into five scoring groups and applies SQL `CASE` expressions to assign customer segments.

**Segments included:**

- Champions
- Loyal Customers
- Promising / New
- At Risk (High Value)
- Lost / Churned
- Needs Attention

**Business value:** Supports customer retention analysis, loyalty initiatives, targeted marketing, and identification of potentially valuable customers.

> **Scoring note:** Before interpreting segment assignments in production, validate the direction of the Recency score. Lower recency days should generally receive higher RFM scores because more recent purchasing activity is preferable. The scoring expression in the current script should be reviewed accordingly.

### 3. Product Portfolio & Pareto Analysis

Analyzes product-level revenue contribution to identify the products responsible for the largest share of sales.

**Analytical workflow:**

1. Aggregate revenue by product and category.
2. Calculate total revenue across the selected product population.
3. Compute cumulative revenue using a windowed `SUM()`.
4. Calculate cumulative revenue contribution as a percentage of global product revenue.
5. Classify products into revenue contribution groups using the 80/20 principle.

**SQL techniques:**

- Multi-table joins.
- Aggregate functions.
- Window functions with explicit row frames.
- Cumulative percentage calculations.
- Conditional classification using `CASE`.

**Business value:** Helps prioritize product analysis, identify major revenue contributors, and support product portfolio decisions.

*Note: The 80/20 principle is a useful analytical guideline, not a guarantee that exactly 80% of revenue will come from 20% of products.*

### 4. Business Intelligence-Ready Analytical Views

Creates a reusable SQL view:

`Sales.vw_MonthlyRegionalSales`

The view consolidates monthly sales metrics across sales territories and countries.

**Included fields and metrics:**

- Order year and month.
- Month name.
- Region and country.
- Distinct order count.
- Net sales.
- Total tax.
- Total freight.
- Gross sales.

**Benefits:**

- Centralizes recurring aggregation logic.
- Provides a consistent dataset for downstream reporting.
- Reduces the need to recreate the same joins and calculations in every report.
- Supports integration with Power BI and Tableau.

### 5. Dynamic Territory Performance Reporting

Creates the stored procedure:

`Sales.sp_GetTerritorySalesPerformance`

The procedure accepts configurable reporting parameters:

| Parameter | Description |
|---|---|
| `@StartYear` | Beginning of the reporting period |
| `@EndYear` | End of the reporting period |
| `@MinSalesTarget` | Revenue benchmark; defaults to 1,000,000 |

**Output metrics:**

- Territory name.
- Regional group.
- Order count.
- Total revenue.
- Average order value.
- Target status.

The procedure classifies each territory as `Target Achieved` or `Underperforming` according to the configured benchmark.

**Business value:** Enables reusable, parameter-driven reporting without manually rewriting the underlying SQL query for each reporting period.

---

## 🛡️ Data Governance & Auditing

### Audit Table

The project defines:

`Sales.SalesOrderHeader_Audit`

This table stores information about changes to sales order subtotals.

| Column | Purpose |
|---|---|
| `AuditID` | Unique audit record identifier |
| `SalesOrderID` | Identifier of the modified sales order |
| `OldSubTotal` | Previous subtotal value |
| `NewSubTotal` | Updated subtotal value |
| `ModifiedBy` | Database execution context recorded for the change |
| `ModifiedDate` | Timestamp recorded for the audit event |
| `ActionType` | Type of modification recorded |

### DML Audit Trigger

The trigger:

`Sales.trg_AuditSalesHeaderUpdates`

executes after updates to `Sales.SalesOrderHeader`.

It compares the `deleted` and `inserted` logical tables to identify changed subtotal values and inserts the old and new values into the audit table.

**Governance capabilities:**

- Tracks subtotal changes.
- Preserves before-and-after values for audited updates.
- Records modification metadata.
- Supports investigation and accountability.
- Uses a set-based approach that can process multiple updated rows in a single statement.

**Important limitation:** The trigger audits subtotal changes only. It does not provide complete auditing for inserts, deletes, or modifications to every other column. The recorded database user and timestamp should also be understood as database execution context and trigger execution time, respectively.

---

## ⚡ Performance Optimization

### Nonclustered Covering Index

The project defines:

`IX_SalesOrderHeader_OrderDate_Territory_Covering`

**Index structure:**

- **Key columns:** `OrderDate`, `TerritoryID`
- **Included columns:** `CustomerID`, `SubTotal`, `TaxAmt`, `Freight`, `TotalDue`

The index is designed around date-based filtering, territory-level analysis, and frequently accessed sales measures.

**Potential benefits:**

- May reduce the need for additional base-table lookups when a query can be satisfied by the index.
- May improve queries filtering or grouping around the indexed columns.
- Can support analytical workloads that repeatedly access the included sales attributes.

Index effectiveness depends on actual query patterns, data distribution, execution plans, and database workload. Performance improvements should be validated through execution-plan inspection and before-and-after measurements.

---

## 🧰 Technical Implementation

The project brings together several important SQL Server techniques.

| Technique | Application |
|---|---|
| CTEs | Organizing multi-stage analytical queries |
| Window Functions | Previous-period comparisons, scoring, and cumulative revenue |
| Aggregate Functions | Sales, cost, and order metrics |
| Joins | Combining sales, customer, product, territory, and geography data |
| `CASE` Expressions | Customer and performance classification |
| Views | Reusable BI reporting datasets |
| Stored Procedures | Parameterized territory reports |
| DML Triggers | Change detection and audit logging |
| System Catalog Queries | Checking existing database objects |
| Nonclustered Indexes | Supporting analytical query patterns |

---

## 🔗 Business Intelligence Integration

The project prepares aggregated data for use in business intelligence platforms.

**Supported integration approach:**

1. Connect Power BI or Tableau to the SQL Server database.
2. Import or query `Sales.vw_MonthlyRegionalSales`.
3. Configure appropriate date, geographic, and numeric data types.
4. Build sales performance dashboards and regional comparisons.
5. Validate dashboard totals against the source SQL queries.

**Potential dashboard metrics:**

- Annual revenue and YoY growth.
- Monthly sales trends.
- Regional and country performance.
- Total orders and average order value.
- Customer segment distribution.
- Product revenue contribution.

The repository currently provides the SQL foundation for these reporting scenarios; dashboard implementation is a separate deliverable unless additional files are included.

---

## 🛠️ Technology Stack

| Technology | Purpose |
|---|---|
| Microsoft SQL Server | Relational database engine |
| T-SQL | Querying, analytics, and database programming |
| AdventureWorks2022 | Sample transactional database |
| SQL Server Management Studio (SSMS) | Query development and execution |
| Power BI | Potential reporting and visualization integration |
| Tableau | Potential reporting and visualization integration |
| Git & GitHub | Version control and project documentation |

---

## 🗄️ Database & Environment

**Target database:** `AdventureWorks2022`

The project uses existing AdventureWorks schemas and tables, including:

- `Sales.SalesOrderHeader`
- `Sales.SalesOrderDetail`
- `Sales.Customer`
- `Sales.SalesTerritory`
- `Person.Person`
- `Person.CountryRegion`
- `Production.Product`
- `Production.ProductSubcategory`
- `Production.ProductCategory`

The script also creates analytical and governance objects under the `Sales` schema.

**Prerequisites:**

- SQL Server with the AdventureWorks2022 sample database installed.
- SQL Server Management Studio or a compatible SQL client.
- Sufficient permissions to create views, procedures, tables, triggers, and indexes.
- Appropriate permissions to query and modify the relevant sales tables.

---

## 🚀 Getting Started

### Step 1 — Install the Database

Install Microsoft SQL Server and restore or attach the AdventureWorks2022 sample database.

### Step 2 — Clone the Repository

```bash
git clone https://github.com/Abdel-Alim/REPOSITORY-NAME.git
cd REPOSITORY-NAME
```

Replace `REPOSITORY-NAME` with the actual GitHub repository name.

### Step 3 — Open the SQL Script

Open the project `.sql` file in SQL Server Management Studio.

### Step 4 — Select the Target Database

```sql
USE AdventureWorks2022;
GO
```

Verify that the database exists and that the required tables are available.

### Step 5 — Review Before Execution

**Important:** The current script contains `DROP TABLE`, `DROP VIEW`, `DROP PROCEDURE`, `DROP TRIGGER`, and `DROP INDEX` operations for objects with specified names.

In particular, dropping `Sales.SalesOrderHeader_Audit` will remove its existing audit history. Do not execute the complete script against a production database or a database containing audit records you need to preserve.

Use a development or test database, review the object lifecycle statements, and back up relevant data before running the script.

### Step 6 — Execute and Validate

Execute the analytical queries and database object definitions in appropriate sections. Validate the returned metrics, object definitions, and audit behavior before using the results in reporting.

---

## 💻 Example Usage

### Execute the Territory Performance Procedure

```sql
EXEC Sales.sp_GetTerritorySalesPerformance
    @StartYear = 2013,
    @EndYear = 2014,
    @MinSalesTarget = 1000000.00;
GO
```

This example requests territory performance for the specified years using a revenue benchmark of 1,000,000. The results depend on the data present in the database.

### Query the Monthly Regional Sales View

```sql
SELECT
    OrderYear,
    OrderMonth,
    MonthName,
    RegionName,
    CountryName,
    TotalOrders,
    NetSales,
    GrossSales
FROM Sales.vw_MonthlyRegionalSales
ORDER BY
    OrderYear,
    OrderMonth,
    RegionName;
GO
```

### Inspect the Audit Records

```sql
SELECT
    AuditID,
    SalesOrderID,
    OldSubTotal,
    NewSubTotal,
    ModifiedBy,
    ModifiedDate,
    ActionType
FROM Sales.SalesOrderHeader_Audit
ORDER BY AuditID DESC;
GO
```

Audit records will appear only after qualifying updates have been processed by the trigger.

---

## 🧠 Key Skills Demonstrated

This project showcases practical experience with:

- **SQL Analytics:** KPI calculation, historical performance analysis, and revenue aggregation.
- **Advanced SQL:** CTEs, window functions, multi-table joins, and conditional logic.
- **Customer Analytics:** RFM methodology and customer behavior segmentation.
- **Product Analytics:** Revenue contribution and cumulative Pareto analysis.
- **Database Development:** Views, stored procedures, triggers, and relational database objects.
- **Data Governance:** Audit logging and change tracking.
- **BI Data Preparation:** Reusable datasets for reporting and visualization.
- **Performance Engineering:** Index design based on analytical access patterns.
- **Analytical Problem Solving:** Translating business questions into structured SQL solutions.

---

## 🔮 Future Enhancements

Potential next steps to extend the project include:

- [ ] Correct and validate RFM scoring direction and segment definitions.
- [ ] Add date-range filtering and parameter validation to reporting procedures.
- [ ] Expand audit coverage to additional operations and important business columns.
- [ ] Introduce a safer, non-destructive database deployment process.
- [ ] Add automated data quality checks and reconciliation queries.
- [ ] Compare query execution plans and benchmark index performance.
- [ ] Build a Power BI executive dashboard using the analytical views.
- [ ] Add test cases for KPI calculations, segmentation rules, and audit behavior.
- [ ] Document expected outputs and sample results using verified database executions.

---

## 👨‍💻 Author

**Abdel-Alim**  
Data Analytics | SQL | Business Intelligence | Machine Learning | NLP

I build data-driven projects that combine analytical problem-solving, database technologies, and practical business intelligence to turn raw data into meaningful insights.

- **GitHub Profile:** [github.com/Abdel-Alim](https://github.com/Abdel-Alim)
- **Explore More Projects:** [GitHub Repositories](https://github.com/Abdel-Alim?tab=repositories)

---

## 📄 License

No project-specific license has been specified in this README. Add an appropriate `LICENSE` file to the repository before declaring the project open source. The AdventureWorks2022 sample database is a separate Microsoft-provided resource and remains subject to its applicable terms.

---

*Built to demonstrate the intersection of SQL analytics, database development, business intelligence, and data governance.*
