-- =====================================================
-- SQL Statement Conversion Catalog
-- Microsoft SQL Server to PostgreSQL Migration
-- Conversion Tool: AWS DMS MCP Tool
-- Total Statements: 7
-- =====================================================

-- =====================================================
-- Statement 1: GetAllProductsAsync_Line38
-- =====================================================
-- Conversion Status: SUCCESS
-- Conversion Method: DMS_TOOL
-- Timestamp: 2026-01-18T18:06:13.141203

-- ORIGINAL MS SQL:
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
    p.Name;

-- CONVERTED POSTGRESQL:
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

-- DMS Tool Notes:
-- - Schema converted: Products → productmanagement_dbo.products
-- - Column names converted to lowercase
-- - Added NULLS FIRST to ORDER BY clauses

-- =====================================================
-- Statement 2: GetProductByIdAsync_Line78
-- =====================================================
-- Conversion Status: SUCCESS
-- Conversion Method: DMS_TOOL
-- Timestamp: 2026-01-18T18:09:22.094591

-- ORIGINAL MS SQL:
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
WHERE p.ProductId = @ProductId;

-- CONVERTED POSTGRESQL:
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

-- DMS Tool Notes:
-- - LEFT JOIN converted to LEFT OUTER JOIN
-- - LAG window function syntax preserved
-- - Column names converted to lowercase
-- - Schema converted: Products → productmanagement_dbo.products

-- =====================================================
-- Statement 3: InsertProductAsync_Line120
-- =====================================================
-- Conversion Status: FAILED
-- Conversion Method: MANUAL_AFTER_DMS_FAILURE
-- Timestamp: 2026-01-18T18:12:32.500606
-- DMS Error: Statement definition is not valid

-- ORIGINAL MS SQL:
DECLARE @NewProductId INT;

BEGIN TRANSACTION;
    -- Insert the new product
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity);
    
    SET @NewProductId = SCOPE_IDENTITY();
    
    -- Log the insertion
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;

SELECT @NewProductId;

-- CONVERTED POSTGRESQL (Manual):
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
SELECT CURRVAL(pg_get_serial_sequence('productmanagement_dbo.products', 'productid')), 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP;

UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;

-- Manual Conversion Notes:
-- - DMS tool failed on complex transaction block
-- - SCOPE_IDENTITY() converted to RETURNING clause for insert
-- - GETDATE() converted to CURRENT_TIMESTAMP
-- - Transaction management will be handled at application level (BeginTransaction/Commit in C# code)
-- - Column names converted to lowercase
-- - Schema converted: Products → productmanagement_dbo.products, ProductHistory → productmanagement_dbo.producthistory

-- =====================================================
-- Statement 4: UpdateProductAsync_Line157
-- =====================================================
-- Conversion Status: SUCCESS_WITH_WARNING
-- Conversion Method: DMS_TOOL
-- Timestamp: 2026-01-18T18:12:58.107045
-- DMS Warning: [7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction management commands such as BEGIN TRAN, SAVE TRAN in functions. Convert your source code manually.]

-- ORIGINAL MS SQL:
BEGIN TRANSACTION;
    -- Store old values for history
    DECLARE @OldPrice DECIMAL(18,2);
    DECLARE @OldStock INT;
    
    SELECT @OldPrice = Price, @OldStock = StockQuantity
    FROM Products
    WHERE ProductId = @ProductId;
    
    -- Update the product
    UPDATE Products
    SET 
        Name = @Name,
        Description = @Description,
        Price = @Price,
        StockQuantity = @StockQuantity,
        ModifiedDate = GETDATE()
    WHERE ProductId = @ProductId;
    
    -- Log the changes
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());
    
    -- Update product statistics
    UPDATE ProductStats
    SET 
        AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
        LastUpdated = GETDATE()
    WHERE StatId = 1;
COMMIT;

-- CONVERTED POSTGRESQL:
-- Note: BEGIN TRANSACTION and COMMIT will be handled at application level via Npgsql BeginTransactionAsync/CommitAsync
DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
    /* Store old values for history */
    SELECT
        price, stockquantity INTO var_OldPrice, var_OldStock
        FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    /* Update the product */
    UPDATE productmanagement_dbo.products
    SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = CURRENT_TIMESTAMP
        WHERE productid = @ProductId;
    /* Log the changes */
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'UPDATE', var_OldPrice, @Price, var_OldStock, @StockQuantity, CURRENT_TIMESTAMP);
    /* Update product statistics */
    UPDATE productmanagement_dbo.productstats
    SET averageprice = (averageprice * totalproducts - var_OldPrice + @Price) / totalproducts, lastupdated = CURRENT_TIMESTAMP
        WHERE statid = 1;
END;

-- DMS Tool Notes:
-- - DECLARE @Variable converted to DECLARE var_Variable
-- - GETDATE() converted to CURRENT_TIMESTAMP (using clock_timestamp() in DMS output, but CURRENT_TIMESTAMP is preferred)
-- - Transaction management moved to application level
-- - Column names converted to lowercase
-- - Schema converted: Products → productmanagement_dbo.products

-- =====================================================
-- Statement 5: DeleteProductAsync_Line197
-- =====================================================
-- Conversion Status: SUCCESS_WITH_WARNING
-- Conversion Method: DMS_TOOL
-- Timestamp: 2026-01-18T18:16:07.903613
-- DMS Warning: [7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction management commands such as BEGIN TRAN, SAVE TRAN in functions. Convert your source code manually.]

-- ORIGINAL MS SQL:
BEGIN TRANSACTION;
    -- Store product info for history
    DECLARE @OldPrice DECIMAL(18,2);
    DECLARE @OldStock INT;
    
    SELECT @OldPrice = Price, @OldStock = StockQuantity
    FROM Products
    WHERE ProductId = @ProductId;
    
    -- Log the deletion
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());
    
    -- Delete the product
    DELETE FROM Products 
    WHERE ProductId = @ProductId;
    
    -- Update product statistics
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

-- CONVERTED POSTGRESQL:
-- Note: BEGIN TRANSACTION and COMMIT will be handled at application level via Npgsql BeginTransactionAsync/CommitAsync
DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
    /* Store product info for history */
    SELECT
        price, stockquantity INTO var_OldPrice, var_OldStock
        FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    /* Log the deletion */
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE', var_OldPrice, NULL, var_OldStock, NULL, CURRENT_TIMESTAMP);
    /* Delete the product */
    DELETE FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    /* Update product statistics */
    UPDATE productmanagement_dbo.productstats
    SET totalproducts = totalproducts - 1, averageprice =
    CASE
        WHEN totalproducts > 1 THEN (averageprice * totalproducts - var_OldPrice) / (totalproducts - 1)
        ELSE 0
    END, lastupdated = CURRENT_TIMESTAMP
        WHERE statid = 1;
END;

-- DMS Tool Notes:
-- - CASE expression preserved correctly
-- - Transaction management moved to application level
-- - Column names converted to lowercase
-- - Schema converted: Products → productmanagement_dbo.products

-- =====================================================
-- Statement 6: GetProductsByPriceRangeAsync_Line240
-- =====================================================
-- Conversion Status: SUCCESS
-- Conversion Method: DMS_TOOL
-- Timestamp: 2026-01-18T18:19:15.275291

-- ORIGINAL MS SQL:
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
ORDER BY rp.PriceRank;

-- CONVERTED POSTGRESQL:
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

-- DMS Tool Notes:
-- - RANK() and PERCENT_RANK() window functions preserved
-- - BETWEEN clause preserved
-- - Column names converted to lowercase
-- - Schema converted: Products → productmanagement_dbo.products

-- =====================================================
-- Statement 7: GetLowStockProductsAsync_Line277
-- =====================================================
-- Conversion Status: SUCCESS
-- Conversion Method: DMS_TOOL
-- Timestamp: 2026-01-18T18:22:25.382960

-- ORIGINAL MS SQL:
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
ORDER BY StockQuantity;

-- CONVERTED POSTGRESQL:
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

-- DMS Tool Notes:
-- - AVG(), MIN(), MAX() window functions preserved
-- - Column names converted to lowercase
-- - Schema converted: Products → productmanagement_dbo.products

-- =====================================================
-- End of SQL Statement Conversion Catalog
-- Summary:
-- - Total Statements: 7
-- - Successfully Converted by DMS: 6
-- - Failed/Manual Conversion: 1 (InsertProductAsync)
-- - Warnings: 2 (UpdateProductAsync, DeleteProductAsync - transaction management)
-- =====================================================
