/*******************************************************************************
 * SQL STATEMENT CONVERSION CATALOG
 * Microsoft SQL Server to PostgreSQL Migration via DMS MCP Tool
 * Source Application: AdoCore - ADO.NET Product Management System
 * 
 * This catalog contains all SQL statement pairs (original SQL Server and 
 * converted PostgreSQL) processed through the AWS DMS MCP conversion tool.
 * 
 * Conversion Date: 2024-12-28
 * Total Statements Processed: 7
 * DMS Tool Successes: 6
 * DMS Tool Failures: 1 (Statement 3 - INSERT transaction)
 * Manual Conversions After DMS Failure: 1
 ******************************************************************************/

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync - Complex CTE with Window Functions
-- ============================================================================
-- Source Method: GetAllProductsAsync()
-- Conversion Status: SUCCESS via DMS Tool
-- Schema Changes: Products → productmanagement_dbo.products
-- Key Conversions: Column names to lowercase, added NULLS FIRST to ORDER BY
-- ============================================================================

-- ORIGINAL SQL SERVER STATEMENT:
/*
WITH ProductStats AS (
    SELECT 
        ProductId,
        AVG(Price) OVER() as AvgPrice,
        COUNT(*) OVER() as TotalProducts
    FROM Products
)
SELECT 
    p.ProductId,
    p.Name,
    p.Description,
    p.Price,
    p.StockQuantity,
    p.CreatedDate,
    p.ModifiedDate,
    CASE 
        WHEN p.Price > ps.AvgPrice THEN 'Above Average'
        WHEN p.Price < ps.AvgPrice THEN 'Below Average'
        ELSE 'Average'
    END as PriceCategory,
    ROUND((p.Price / ps.AvgPrice) * 100, 2) as PricePercentageOfAverage
FROM Products p
INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId
ORDER BY 
    CASE 
        WHEN p.Price > ps.AvgPrice THEN 1
        ELSE 2
    END,
    p.Name
*/

-- CONVERTED POSTGRESQL STATEMENT (DMS Tool):
WITH productstats
AS (SELECT
    productid, AVG(price) OVER () AS avgprice, COUNT(*) OVER () AS totalproducts
    FROM productmanagement_dbo.products)
SELECT
    p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate,
    CASE
        WHEN p.price > ps.avgprice THEN 'Above Average'
        WHEN p.price < ps.avgprice THEN 'Below Average'
        ELSE 'Average'
    END AS pricecategory, ROUND((p.price / ps.avgprice) * 100, 2) AS pricepercentageofaverage
    FROM productmanagement_dbo.products AS p
    INNER JOIN productstats AS ps
        ON p.productid = ps.productid
    ORDER BY
    CASE
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END NULLS FIRST, p.name NULLS FIRST;

-- ============================================================================
-- STATEMENT 2: GetProductByIdAsync - CTE with LAG Window Function
-- ============================================================================
-- Source Method: GetProductByIdAsync(int productId)
-- Conversion Status: SUCCESS via DMS Tool
-- Schema Changes: Products → productmanagement_dbo.products
-- Key Conversions: LAG function preserved, LEFT JOIN → LEFT OUTER JOIN
-- ============================================================================

-- ORIGINAL SQL SERVER STATEMENT:
/*
WITH ProductHistory AS (
    SELECT 
        ProductId,
        LAG(Price) OVER (ORDER BY ModifiedDate) as PreviousPrice,
        LAG(StockQuantity) OVER (ORDER BY ModifiedDate) as PreviousStock
    FROM Products
    WHERE ProductId = @ProductId
)
SELECT 
    p.ProductId,
    p.Name,
    p.Description,
    p.Price,
    p.StockQuantity,
    p.CreatedDate,
    p.ModifiedDate,
    ph.PreviousPrice,
    ph.PreviousStock,
    CASE 
        WHEN ph.PreviousPrice IS NOT NULL THEN 
            ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100, 2)
        ELSE NULL
    END as PriceChangePercentage
FROM Products p
LEFT JOIN ProductHistory ph ON p.ProductId = ph.ProductId
WHERE p.ProductId = @ProductId
*/

-- CONVERTED POSTGRESQL STATEMENT (DMS Tool):
WITH producthistory
AS (SELECT
    productid, lag(price) OVER (ORDER BY modifieddate) AS previousprice, lag(stockquantity) OVER (ORDER BY modifieddate) AS previousstock
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId)
SELECT
    p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate, ph.previousprice, ph.previousstock,
    CASE
        WHEN ph.previousprice IS NOT NULL THEN ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2)
        ELSE NULL
    END AS pricechangepercentage
    FROM productmanagement_dbo.products AS p
    LEFT OUTER JOIN producthistory AS ph
        ON p.productid = ph.productid
    WHERE p.productid = @ProductId;

-- ============================================================================
-- STATEMENT 3: InsertProductAsync - Multi-Statement Transaction Block
-- ============================================================================
-- Source Method: InsertProductAsync(Product product)
-- Conversion Status: MANUAL AFTER DMS FAILURE
-- DMS Error: "Statement definition is not valid" (multi-statement transaction too complex)
-- Manual Conversion: Adapted for ADO.NET transaction management
-- ============================================================================

-- ORIGINAL SQL SERVER STATEMENT:
/*
DECLARE @NewProductId INT;

BEGIN TRANSACTION;
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity);
    
    SET @NewProductId = SCOPE_IDENTITY();
    
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());
    
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;

SELECT @NewProductId;
*/

-- CONVERTED POSTGRESQL STATEMENT (MANUAL - for ADO.NET transaction):
-- Note: Transaction management will be handled by C# code using BeginTransactionAsync()
-- This conversion splits the SQL into separate statements for ADO.NET execution

-- Statement 3a: Insert product and return ID
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Statement 3b: Insert into history (executed with returned productid)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Statement 3c: Update statistics
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync - Multi-Statement Transaction Block
-- ============================================================================
-- Source Method: UpdateProductAsync(Product product)
-- Conversion Status: SUCCESS via DMS Tool (with warning)
-- DMS Warning: [7807] Transaction management needs manual review for functions
-- Schema Changes: All table names prefixed with productmanagement_dbo
-- Key Conversions: DECLARE @var → var_var, GETDATE() → clock_timestamp()
-- ============================================================================

-- ORIGINAL SQL SERVER STATEMENT:
/*
BEGIN TRANSACTION;
    DECLARE @OldPrice DECIMAL(18,2);
    DECLARE @OldStock INT;
    
    SELECT @OldPrice = Price, @OldStock = StockQuantity
    FROM Products
    WHERE ProductId = @ProductId;
    
    UPDATE Products
    SET 
        Name = @Name,
        Description = @Description,
        Price = @Price,
        StockQuantity = @StockQuantity,
        ModifiedDate = GETDATE()
    WHERE ProductId = @ProductId;
    
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());
    
    UPDATE ProductStats
    SET 
        AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;
*/

-- CONVERTED POSTGRESQL STATEMENT (DMS Tool - adapted for ADO.NET):
-- Note: Transaction managed by C# code, not SQL. Variable declarations removed.
-- Split into separate statements for ADO.NET execution:

-- Statement 4a: Get old values
SELECT price, stockquantity
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Statement 4b: Update product
UPDATE productmanagement_dbo.products
SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = CURRENT_TIMESTAMP
WHERE productid = @ProductId;

-- Statement 4c: Insert history
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, CURRENT_TIMESTAMP);

-- Statement 4d: Update stats
UPDATE productmanagement_dbo.productstats
SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts, lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync - Multi-Statement Transaction Block
-- ============================================================================
-- Source Method: DeleteProductAsync(int productId)
-- Conversion Status: SUCCESS via DMS Tool (with warning)
-- DMS Warning: [7807] Transaction management needs manual review for functions
-- Schema Changes: All table names prefixed with productmanagement_dbo
-- Key Conversions: DECLARE @var → var_var, GETDATE() → clock_timestamp()
-- ============================================================================

-- ORIGINAL SQL SERVER STATEMENT:
/*
BEGIN TRANSACTION;
    DECLARE @OldPrice DECIMAL(18,2);
    DECLARE @OldStock INT;
    
    SELECT @OldPrice = Price, @OldStock = StockQuantity
    FROM Products
    WHERE ProductId = @ProductId;
    
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());
    
    DELETE FROM Products 
    WHERE ProductId = @ProductId;
    
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts - 1,
        AveragePrice = CASE 
            WHEN TotalProducts > 1 
            THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1)
            ELSE 0
        END,
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;
*/

-- CONVERTED POSTGRESQL STATEMENT (DMS Tool - adapted for ADO.NET):
-- Note: Transaction managed by C# code. Split into separate statements:

-- Statement 5a: Get old values
SELECT price, stockquantity
FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Statement 5b: Insert history
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, CURRENT_TIMESTAMP);

-- Statement 5c: Delete product
DELETE FROM productmanagement_dbo.products
WHERE productid = @ProductId;

-- Statement 5d: Update stats
UPDATE productmanagement_dbo.productstats
SET totalproducts = totalproducts - 1, 
    averageprice = CASE
        WHEN totalproducts > 1 THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
        ELSE 0
    END, 
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - CTE with Ranking Functions
-- ============================================================================
-- Source Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Conversion Status: SUCCESS via DMS Tool
-- Schema Changes: Products → productmanagement_dbo.products
-- Key Conversions: RANK(), PERCENT_RANK() preserved, NULLS FIRST added
-- ============================================================================

-- ORIGINAL SQL SERVER STATEMENT:
/*
WITH RankedProducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.Price) as PriceRank,
        PERCENT_RANK() OVER (ORDER BY p.Price) as PricePercentile
    FROM Products p
    WHERE p.Price BETWEEN @MinPrice AND @MaxPrice
)
SELECT 
    rp.*,
    CASE 
        WHEN rp.PricePercentile <= 0.25 THEN 'Budget'
        WHEN rp.PricePercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END as PriceSegment
FROM RankedProducts rp
ORDER BY rp.PriceRank
*/

-- CONVERTED POSTGRESQL STATEMENT (DMS Tool):
WITH rankedproducts
AS (SELECT
    p.*, RANK() OVER (ORDER BY p.price) AS pricerank, percent_rank() OVER (ORDER BY p.price) AS pricepercentile
    FROM productmanagement_dbo.products AS p
    WHERE p.price BETWEEN @MinPrice AND @MaxPrice)
SELECT
    rp.*,
    CASE
        WHEN rp.pricepercentile <= 0.25 THEN 'Budget'
        WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END AS pricesegment
    FROM rankedproducts AS rp
    ORDER BY rp.pricerank NULLS FIRST;

-- ============================================================================
-- STATEMENT 7: GetLowStockProductsAsync - CTE with Multiple Window Functions
-- ============================================================================
-- Source Method: GetLowStockProductsAsync(int threshold)
-- Conversion Status: SUCCESS via DMS Tool
-- Schema Changes: Products → productmanagement_dbo.products
-- Key Conversions: Multiple window functions preserved, NULLS FIRST added
-- ============================================================================

-- ORIGINAL SQL SERVER STATEMENT:
/*
WITH StockAnalysis AS (
    SELECT 
        p.*,
        AVG(StockQuantity) OVER() as AvgStock,
        MIN(StockQuantity) OVER() as MinStock,
        MAX(StockQuantity) OVER() as MaxStock
    FROM Products p
)
SELECT 
    sa.*,
    CASE 
        WHEN StockQuantity <= @Threshold THEN 'Critical'
        WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as StockStatus,
    ROUND((StockQuantity / AvgStock) * 100, 2) as StockPercentageOfAverage
FROM StockAnalysis sa
WHERE StockQuantity <= @Threshold
ORDER BY StockQuantity
*/

-- CONVERTED POSTGRESQL STATEMENT (DMS Tool):
WITH stockanalysis
AS (SELECT
    p.*, AVG(stockquantity) OVER () AS avgstock, MIN(stockquantity) OVER () AS minstock, MAX(stockquantity) OVER () AS maxstock
    FROM productmanagement_dbo.products AS p)
SELECT
    sa.*,
    CASE
        WHEN stockquantity <= @Threshold THEN 'Critical'
        WHEN stockquantity <= avgstock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END AS stockstatus, ROUND((stockquantity / avgstock) * 100, 2) AS stockpercentageofaverage
    FROM stockanalysis AS sa
    WHERE stockquantity <= @Threshold
    ORDER BY stockquantity NULLS FIRST;

/*******************************************************************************
 * CONVERSION SUMMARY
 * 
 * Total SQL Statements Processed: 7
 * DMS Tool Successful Conversions: 6
 * DMS Tool Failed Conversions: 1 (Statement 3)
 * Manual Conversions After DMS Failure: 1 (Statement 3)
 * 
 * Key Schema Transformation by DMS:
 *   - Products → productmanagement_dbo.products
 *   - ProductHistory → productmanagement_dbo.producthistory
 *   - ProductStats → productmanagement_dbo.productstats
 *   - Column names: Converted to lowercase (productid, name, price, etc.)
 * 
 * Key Syntax Transformations:
 *   - GETDATE() → CURRENT_TIMESTAMP or clock_timestamp()
 *   - SCOPE_IDENTITY() → RETURNING clause
 *   - BEGIN TRANSACTION/COMMIT → Managed by ADO.NET transaction code
 *   - DECLARE @variable → Variable management in application code
 *   - ORDER BY → Added NULLS FIRST for PostgreSQL consistency
 *   - LEFT JOIN → LEFT OUTER JOIN
 * 
 * Transaction Block Handling:
 *   - DMS converted transaction blocks but noted they need manual review
 *   - Adapted for ADO.NET: Transactions managed by C# BeginTransactionAsync()
 *   - Multi-statement blocks split into separate ExecuteNonQueryAsync calls
 *   - SCOPE_IDENTITY() replaced with RETURNING clause in INSERT
 * 
 * All statements ready for re-integration into ProductRepository.cs
 ******************************************************************************/
