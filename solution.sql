-- ==============================================================================
-- PROJECT TITLE: Enterprise Sales Analytics & Data Governance System
-- TARGET DATABASE: AdventureWorks2022 (OLTP)
-- AUTHOR: Junior Data Analyst / SQL Analytics Engineer
-- DESCRIPTION: End-to-End T-SQL Analytics Project covering Financial KPIs, 
--              Customer RFM Segmentation, Pareto Product Classification, 
--              BI Readiness Views, Dynamic Stored Procedures, Audit Triggers, 
--              and Index Optimization.
-- ==============================================================================

USE AdventureWorks2022;
GO

-- ==============================================================================
-- SECTION 1: FINANCIAL PERFORMANCE & YOY GROWTH ANALYTICS
-- ==============================================================================

-- 1.1 Calculate Yearly Sales, Overhead Costs, Net Revenue, and YoY Growth %
WITH YearlySales AS (
    SELECT 
        YEAR(oh.OrderDate) AS SalesYear,
        SUM(oh.SubTotal) AS GrossRevenue,
        SUM(oh.TaxAmt + oh.Freight) AS OverheadCosts,
        SUM(oh.TotalDue) AS TotalRevenue,
        LAG(SUM(oh.SubTotal)) OVER (ORDER BY YEAR(oh.OrderDate)) AS PriorYearRevenue
    FROM Sales.SalesOrderHeader oh
    GROUP BY YEAR(oh.OrderDate)
)
SELECT 
    SalesYear,
    ROUND(GrossRevenue, 2) AS GrossRevenue,
    ROUND(OverheadCosts, 2) AS OverheadCosts,
    ROUND(TotalRevenue, 2) AS TotalRevenue,
    ROUND(((GrossRevenue - PriorYearRevenue) / NULLIF(PriorYearRevenue, 0)) * 100, 2) AS YoY_Growth_Percent
FROM YearlySales
ORDER BY SalesYear DESC;
GO

-- ==============================================================================
-- SECTION 2: CUSTOMER SEGMENTATION (RFM ANALYSIS)
-- ==============================================================================

-- 2.1 RFM (Recency, Frequency, Monetary) Customer Scoring using Window Functions
WITH CustomerRFM_Base AS (
    SELECT 
        c.CustomerID,
        CONCAT(p.FirstName, ' ', ISNULL(p.LastName, '')) AS CustomerName,
        MAX(oh.OrderDate) AS LastOrderDate,
        DATEDIFF(day, MAX(oh.OrderDate), (SELECT MAX(OrderDate) FROM Sales.SalesOrderHeader)) AS RecencyDays,
        COUNT(DISTINCT oh.SalesOrderID) AS Frequency,
        SUM(oh.SubTotal) AS MonetaryValue
    FROM Sales.Customer c
    JOIN Person.Person p ON c.PersonID = p.BusinessEntityID
    JOIN Sales.SalesOrderHeader oh ON c.CustomerID = oh.CustomerID
    GROUP BY c.CustomerID, p.FirstName, p.LastName
),
RFM_Scores AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY RecencyDays DESC) AS R_Score,
        NTILE(5) OVER (ORDER BY Frequency ASC) AS F_Score,
        NTILE(5) OVER (ORDER BY MonetaryValue ASC) AS M_Score
    FROM CustomerRFM_Base
)
SELECT 
    CustomerID,
    CustomerName,
    RecencyDays,
    Frequency,
    ROUND(MonetaryValue, 2) AS MonetaryValue,
    R_Score, F_Score, M_Score,
    CASE 
        WHEN R_Score >= 4 AND F_Score >= 4 AND M_Score >= 4 THEN 'Champions'
        WHEN R_Score >= 3 AND F_Score >= 3 THEN 'Loyal Customers'
        WHEN R_Score >= 3 AND F_Score <= 2 THEN 'Promising / New'
        WHEN R_Score <= 2 AND F_Score >= 4 THEN 'At Risk (High Value)'
        WHEN R_Score <= 2 AND F_Score <= 2 THEN 'Lost / Churned'
        ELSE 'Needs Attention'
    END AS CustomerSegment
FROM RFM_Scores
ORDER BY MonetaryValue DESC;
GO

-- ==============================================================================
-- SECTION 3: PRODUCT PORTFOLIO & PARETO ANALYSIS (80/20 PRINCIPLE)
-- ==============================================================================

-- 3.1 Cumulative Revenue Analysis to Identify Top 80% Revenue Contributors
WITH ProductSales AS (
    SELECT 
        p.ProductID,
        p.Name AS ProductName,
        cat.Name AS CategoryName,
        SUM(od.LineTotal) AS Revenue
    FROM Sales.SalesOrderDetail od
    JOIN Production.Product p ON od.ProductID = p.ProductID
    JOIN Production.ProductSubcategory sub ON p.ProductSubcategoryID = sub.ProductSubcategoryID
    JOIN Production.ProductCategory cat ON sub.ProductCategoryID = cat.ProductCategoryID
    GROUP BY p.ProductID, p.Name, cat.Name
),
ParetoCalculations AS (
    SELECT *,
        SUM(Revenue) OVER () AS GlobalRevenue,
        SUM(Revenue) OVER (
            ORDER BY Revenue DESC 
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) AS CumulativeRevenue
    FROM ProductSales
)
SELECT 
    ProductID,
    ProductName,
    CategoryName,
    ROUND(Revenue, 2) AS Revenue,
    ROUND((CumulativeRevenue / GlobalRevenue) * 100, 2) AS CumulativeRevenuePercent,
    CASE 
        WHEN (CumulativeRevenue / GlobalRevenue) <= 0.80 THEN 'Top Contributor (Class A - 80% Revenue)'
        ELSE 'Regular Contributor (Class B/C - Remaining 20%)'
    END AS ParetoClass
FROM ParetoCalculations
ORDER BY Revenue DESC;
GO

-- ==============================================================================
-- SECTION 4: BI READINESS & ANALYTICAL VIEWS
-- ==============================================================================

-- 4.1 Monthly Regional Sales Analytics View for Power BI / Tableau Integration
IF OBJECT_ID('Sales.vw_MonthlyRegionalSales', 'V') IS NOT NULL
    DROP VIEW Sales.vw_MonthlyRegionalSales;
GO

CREATE VIEW Sales.vw_MonthlyRegionalSales
AS
SELECT 
    YEAR(oh.OrderDate) AS OrderYear,
    MONTH(oh.OrderDate) AS OrderMonth,
    DATENAME(month, oh.OrderDate) AS MonthName,
    st.Name AS RegionName,
    cr.Name AS CountryName,
    COUNT(DISTINCT oh.SalesOrderID) AS TotalOrders,
    ROUND(SUM(oh.SubTotal), 2) AS NetSales,
    ROUND(SUM(oh.TaxAmt), 2) AS TotalTax,
    ROUND(SUM(oh.Freight), 2) AS TotalFreight,
    ROUND(SUM(oh.TotalDue), 2) AS GrossSales
FROM Sales.SalesOrderHeader oh
JOIN Sales.SalesTerritory st ON oh.TerritoryID = st.TerritoryID
JOIN Person.CountryRegion cr ON st.CountryRegionCode = cr.CountryRegionCode
GROUP BY 
    YEAR(oh.OrderDate), 
    MONTH(oh.OrderDate), 
    DATENAME(month, oh.OrderDate), 
    st.Name, 
    cr.Name;
GO

-- ==============================================================================
-- SECTION 5: DYNAMIC STORED PROCEDURES & REPORTING
-- ==============================================================================

-- 5.1 Dynamic Sales Territory Reporting Procedure with Target Benchmark Evaluation
IF OBJECT_ID('Sales.sp_GetTerritorySalesPerformance', 'P') IS NOT NULL
    DROP PROCEDURE Sales.sp_GetTerritorySalesPerformance;
GO

CREATE PROCEDURE Sales.sp_GetTerritorySalesPerformance
    @StartYear INT,
    @EndYear INT,
    @MinSalesTarget DECIMAL(18,2) = 1000000.00
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        st.Name AS TerritoryName,
        st.[Group] AS RegionGroup,
        COUNT(DISTINCT oh.SalesOrderID) AS OrderCount,
        ROUND(SUM(oh.SubTotal), 2) AS TotalRevenue,
        ROUND(AVG(oh.SubTotal), 2) AS AverageOrderValue,
        CASE 
            WHEN SUM(oh.SubTotal) >= @MinSalesTarget THEN 'Target Achieved'
            ELSE 'Underperforming'
        END AS TargetStatus
    FROM Sales.SalesOrderHeader oh
    JOIN Sales.SalesTerritory st ON oh.TerritoryID = st.TerritoryID
    WHERE YEAR(oh.OrderDate) BETWEEN @StartYear AND @EndYear
    GROUP BY st.Name, st.[Group]
    ORDER BY TotalRevenue DESC;
END;
GO

-- ==============================================================================
-- SECTION 6: DATA AUDITING & GOVERNANCE (TRIGGERS)
-- ==============================================================================

-- 6.1 Audit Table Structure for Order Amount Adjustments
IF OBJECT_ID('Sales.SalesOrderHeader_Audit', 'U') IS NOT NULL
    DROP TABLE Sales.SalesOrderHeader_Audit;
GO

CREATE TABLE Sales.SalesOrderHeader_Audit (
    AuditID INT IDENTITY(1,1) PRIMARY KEY,
    SalesOrderID INT NOT NULL,
    OldSubTotal DECIMAL(18,4) NOT NULL,
    NewSubTotal DECIMAL(18,4) NOT NULL,
    ModifiedBy NVARCHAR(100) NOT NULL DEFAULT SYSTEM_USER,
    ModifiedDate DATETIME NOT NULL DEFAULT GETDATE(),
    ActionType NVARCHAR(10) NOT NULL
);
GO

-- 6.2 DML Audit Trigger for SalesOrderHeader Modifications
IF OBJECT_ID('Sales.trg_AuditSalesHeaderUpdates', 'TR') IS NOT NULL
    DROP TRIGGER Sales.trg_AuditSalesHeaderUpdates;
GO

CREATE TRIGGER Sales.trg_AuditSalesHeaderUpdates
ON Sales.SalesOrderHeader
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    INSERT INTO Sales.SalesOrderHeader_Audit (
        SalesOrderID, 
        OldSubTotal, 
        NewSubTotal, 
        ActionType
    )
    SELECT 
        d.SalesOrderID,
        d.SubTotal AS OldSubTotal,
        i.SubTotal AS NewSubTotal,
        'UPDATE'
    FROM Deleted d 
    JOIN Inserted i ON d.SalesOrderID = i.SalesOrderID 
    WHERE d.SubTotal <> i.SubTotal;
END;
GO

-- ==============================================================================
-- SECTION 7: INDEXING & PERFORMANCE OPTIMIZATION
-- ==============================================================================

-- 7.1 Non-Clustered Covering Index for Sales Aggregations
IF EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_SalesOrderHeader_OrderDate_Territory_Covering' AND object_id = OBJECT_ID('Sales.SalesOrderHeader'))
    DROP INDEX IX_SalesOrderHeader_OrderDate_Territory_Covering ON Sales.SalesOrderHeader;
GO

CREATE NONCLUSTERED INDEX IX_SalesOrderHeader_OrderDate_Territory_Covering
ON Sales.SalesOrderHeader (OrderDate, TerritoryID)
INCLUDE (CustomerID, SubTotal, TaxAmt, Freight, TotalDue);
GO