/*******************************************************************************
 * CONVERTED SQL STATEMENTS CATALOG
 * Microsoft SQL Server to PostgreSQL Migration
 * Source: extracted_statements.sql
 * Total Statements Converted: 7
 * Conversion Date: 2025-01-16
 * 
 * Conversion Summary:
 * - Successfully converted by DMS tool: 6 statements
 * - Manual conversion after DMS failure: 1 statement (Statement 3)
 * 
 * CRITICAL NOTES:
 * - DMS tool converted schema from "dbo" to "productmanagement_dbo"
 * - All table references must use "productmanagement_dbo" schema prefix
 * - Column names converted to lowercase by DMS
 * - GETDATE() converted to clock_timestamp()
 * - Parameter syntax remains @ParameterName (compatible with Npgsql)
 ******************************************************************************/

/*******************************************************************************
 * STATEMENT 1: GetAllProductsAsync
 * Conversion Method: DMS_TOOL
 * Conversion Status: SUCCESS
 * Schema Changes: Products → productmanagement_dbo.products
 ******************************************************************************/

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

-- CONVERTED POSTGRESQL STATEMENT:
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

-- DMS TOOL OUTPUT: success (converted_sql_count: 1)

/*******************************************************************************
 * STATEMENT 2: GetProductByIdAsync
 * Conversion Method: DMS_TOOL
 * Conversion Status: SUCCESS
 * Schema Changes: Products → productmanagement_dbo.products
 * Parameters: @ProductId
 ******************************************************************************/

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

-- CONVERTED POSTGRESQL STATEMENT:
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

-- DMS TOOL OUTPUT: success (converted_sql_count: 1)

/*******************************************************************************
 * STATEMENT 3: InsertProductAsync
 * Conversion Method: MANUAL_AFTER_DMS_FAILURE
 * Conversion Status: DMS_FAILURE - Manual conversion applied
 * Schema Changes: Products → productmanagement_dbo.products
 *                 ProductHistory → productmanagement_dbo.producthistory
 *                 ProductStats → productmanagement_dbo.productstats
 * Parameters: @Name, @Description, @Price, @StockQuantity
 * 
 * CRITICAL NOTE: This statement will be split into multiple commands in 
 * ADO.NET code due to RETURNING clause and transaction management requirements.
 ******************************************************************************/

-- ORIGINAL SQL SERVER STATEMENT:
/*
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
*/

-- CONVERTED POSTGRESQL STATEMENT (MANUAL):
-- NOTE: Transaction management moved to ADO.NET level
-- This will be implemented as 3 separate commands:

-- Command 1: Insert and get new product ID
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- Command 2: Log the insertion (executed after getting ID from Command 1)
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- Command 3: Update product statistics
UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = NOW()
WHERE statid = 1;

-- DMS TOOL OUTPUT: error
-- Error: Metadata model creation failed: Statement definition is not valid
-- Manual conversion rationale: SCOPE_IDENTITY() replaced with RETURNING clause,
-- GETDATE() replaced with NOW(), transaction management moved to ADO.NET level

/*******************************************************************************
 * STATEMENT 4: UpdateProductAsync
 * Conversion Method: DMS_TOOL
 * Conversion Status: SUCCESS (with warnings about transaction management)
 * Schema Changes: Products → productmanagement_dbo.products
 *                 ProductHistory → productmanagement_dbo.producthistory
 *                 ProductStats → productmanagement_dbo.productstats
 * Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
 * 
 * WARNING: [7807 - Severity CRITICAL - PostgreSQL does not support explicit 
 * transaction management commands such as BEGIN TRAN, SAVE TRAN in functions. 
 * Convert your source code manually.]
 * Transaction management will be handled at ADO.NET level.
 ******************************************************************************/

-- ORIGINAL SQL SERVER STATEMENT:
/*
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
*/

-- CONVERTED POSTGRESQL STATEMENT:
DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
    /*
    [7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction management commands such as BEGIN TRAN, SAVE TRAN in functions. Convert your source code manually.]
    BEGIN TRANSACTION;
    */
    /* Store old values for history */
    SELECT
        price AS var_OldPrice, stockquantity AS var_OldStock
        FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    /* Update the product */
    UPDATE productmanagement_dbo.products
    SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = clock_timestamp()
        WHERE productid = @ProductId;
    /* Log the changes */
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, clock_timestamp());
    /* Update product statistics */
    UPDATE productmanagement_dbo.productstats
    SET averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts, lastupdated = clock_timestamp()
        WHERE statid = 1;
    COMMIT;
END;

-- DMS TOOL OUTPUT: success (converted_sql_count: 1)
-- NOTE: Transaction BEGIN/COMMIT will be removed and managed at ADO.NET level

/*******************************************************************************
 * STATEMENT 5: DeleteProductAsync
 * Conversion Method: DMS_TOOL
 * Conversion Status: SUCCESS (with warnings about transaction management)
 * Schema Changes: Products → productmanagement_dbo.products
 *                 ProductHistory → productmanagement_dbo.producthistory
 *                 ProductStats → productmanagement_dbo.productstats
 * Parameters: @ProductId
 * 
 * WARNING: [7807 - Severity CRITICAL - PostgreSQL does not support explicit 
 * transaction management commands such as BEGIN TRAN, SAVE TRAN in functions. 
 * Convert your source code manually.]
 * Transaction management will be handled at ADO.NET level.
 ******************************************************************************/

-- ORIGINAL SQL SERVER STATEMENT:
/*
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
*/

-- CONVERTED POSTGRESQL STATEMENT:
DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
    /*
    [7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction management commands such as BEGIN TRAN, SAVE TRAN in functions. Convert your source code manually.]
    BEGIN TRANSACTION;
    */
    /* Store product info for history */
    SELECT
        price AS var_OldPrice, stockquantity AS var_OldStock
        FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    /* Log the deletion */
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, clock_timestamp());
    /* Delete the product */
    DELETE FROM productmanagement_dbo.products
        WHERE productid = @ProductId;
    /* Update product statistics */
    UPDATE productmanagement_dbo.productstats
    SET totalproducts = totalproducts - 1, averageprice =
    CASE
        WHEN totalproducts > 1 THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
        ELSE 0
    END, lastupdated = clock_timestamp()
        WHERE statid = 1;
    COMMIT;
END;

-- DMS TOOL OUTPUT: success (converted_sql_count: 1)
-- NOTE: Transaction BEGIN/COMMIT will be removed and managed at ADO.NET level

/*******************************************************************************
 * STATEMENT 6: GetProductsByPriceRangeAsync
 * Conversion Method: DMS_TOOL
 * Conversion Status: SUCCESS
 * Schema Changes: Products → productmanagement_dbo.products
 * Parameters: @MinPrice, @MaxPrice
 ******************************************************************************/

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

-- CONVERTED POSTGRESQL STATEMENT:
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

-- DMS TOOL OUTPUT: success (converted_sql_count: 1)

/*******************************************************************************
 * STATEMENT 7: GetLowStockProductsAsync
 * Conversion Method: DMS_TOOL
 * Conversion Status: SUCCESS
 * Schema Changes: Products → productmanagement_dbo.products
 * Parameters: @Threshold
 ******************************************************************************/

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

-- CONVERTED POSTGRESQL STATEMENT:
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

-- DMS TOOL OUTPUT: success (converted_sql_count: 1)

/*******************************************************************************
 * CONVERSION SUMMARY
 * 
 * Total Statements: 7
 * DMS Tool Success: 6 statements (Statements 1, 2, 4, 5, 6, 7)
 * DMS Tool Failures: 1 statement (Statement 3)
 * Manual Conversions: 1 statement (Statement 3)
 * 
 * Key Schema Changes by DMS:
 * - Schema name: "dbo" → "productmanagement_dbo"
 * - Table: Products → productmanagement_dbo.products
 * - Table: ProductHistory → productmanagement_dbo.producthistory
 * - Table: ProductStats → productmanagement_dbo.productstats
 * - All column names converted to lowercase
 * 
 * Key Syntax Transformations:
 * - GETDATE() → clock_timestamp() or NOW()
 * - SCOPE_IDENTITY() → RETURNING clause (Statement 3)
 * - Window functions: Syntax compatible, no changes needed
 * - CASE expressions: Syntax compatible, no changes needed
 * - CTEs: Syntax compatible, name converted to lowercase
 * - Parameters: @ParameterName format maintained (Npgsql compatible)
 * - ORDER BY: Added "NULLS FIRST" for PostgreSQL consistency
 * 
 * Transaction Management Notes:
 * - Statements 3, 4, 5 contain transaction blocks
 * - Transaction BEGIN/COMMIT must be removed from SQL
 * - Transaction management will be handled at ADO.NET level using:
 *   * NpgsqlTransaction.BeginTransactionAsync()
 *   * NpgsqlTransaction.CommitAsync()
 *   * NpgsqlTransaction.RollbackAsync()
 * 
 * Next Steps:
 * 1. Validate SQL equivalency using sql-equivalency___validate_sql_equivalence
 * 2. Re-integrate converted statements into ProductRepository.cs
 * 3. Update ADO.NET code to use Npgsql classes
 * 4. Handle transaction management at application level
 ******************************************************************************/
