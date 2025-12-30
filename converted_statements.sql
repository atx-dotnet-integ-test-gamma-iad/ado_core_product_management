/*
================================================================================
CONVERTED SQL STATEMENTS CATALOG
Microsoft SQL Server to PostgreSQL Migration - DMS MCP Tool Conversion
================================================================================
This file contains all PostgreSQL-converted SQL statements from the DMS MCP tool.
Each statement is paired with its original MS SQL version and DMS tool output.

Total Statements: 7
Conversion Tool: AWS DMS MCP (dms-mcp____statement_conversion_tool)
Schema Transformation: dbo.Products → productmanagement_dbo.products
================================================================================
*/

/*
--------------------------------------------------------------------------------
STATEMENT 1: GetAllProductsAsync
--------------------------------------------------------------------------------
Method: GetAllProductsAsync()
Conversion Status: SUCCESS
DMS Tool Status: success
Schema Changes: Products → productmanagement_dbo.products
Notable PostgreSQL Changes:
  - Lowercase identifiers (productid, avgprice, etc.)
  - Added NULLS FIRST to ORDER BY clauses
  - Schema prefix: productmanagement_dbo
--------------------------------------------------------------------------------
*/

-- ORIGINAL MS SQL:
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

/*
--------------------------------------------------------------------------------
STATEMENT 2: GetProductByIdAsync
--------------------------------------------------------------------------------
Method: GetProductByIdAsync(int productId)
Conversion Status: SUCCESS
DMS Tool Status: success
Schema Changes: Products → productmanagement_dbo.products
Notable PostgreSQL Changes:
  - LAG function converted correctly
  - LEFT JOIN → LEFT OUTER JOIN
  - Lowercase identifiers
--------------------------------------------------------------------------------
*/

-- ORIGINAL MS SQL:
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

/*
--------------------------------------------------------------------------------
STATEMENT 3: GetProductsByPriceRangeAsync
--------------------------------------------------------------------------------
Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
Conversion Status: SUCCESS
DMS Tool Status: success
Schema Changes: Products → productmanagement_dbo.products
Notable PostgreSQL Changes:
  - RANK and PERCENT_RANK functions converted correctly
  - percent_rank() lowercase
  - BETWEEN clause preserved
--------------------------------------------------------------------------------
*/

-- ORIGINAL MS SQL:
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

/*
--------------------------------------------------------------------------------
STATEMENT 4: GetLowStockProductsAsync
--------------------------------------------------------------------------------
Method: GetLowStockProductsAsync(int threshold)
Conversion Status: SUCCESS
DMS Tool Status: success
Schema Changes: Products → productmanagement_dbo.products
Notable PostgreSQL Changes:
  - AVG, MIN, MAX window functions converted correctly
  - ROUND function preserved
  - Lowercase identifiers
--------------------------------------------------------------------------------
*/

-- ORIGINAL MS SQL:
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

/*
--------------------------------------------------------------------------------
STATEMENT 5: InsertProductAsync
--------------------------------------------------------------------------------
Method: InsertProductAsync(Product product)
Conversion Status: MANUAL_AFTER_DMS_FAILURE
DMS Tool Status: error
DMS Error: "Metadata model creation failed: {'error': 'Metadata model creation failed: {'default_error_details': {'message': 'Statement definition is not valid.'}}}"
Reason for Manual Conversion: DMS tool could not process transaction block with DECLARE before BEGIN TRANSACTION
Schema Changes: Products → productmanagement_dbo.products, ProductHistory → productmanagement_dbo.producthistory, ProductStats → productmanagement_dbo.productstats
Notable PostgreSQL Changes:
  - Removed DECLARE @NewProductId INT and BEGIN TRANSACTION/COMMIT (handled at ADO.NET level)
  - SCOPE_IDENTITY() → RETURNING productid
  - GETDATE() → CURRENT_TIMESTAMP
  - Lowercase identifiers
  - Schema prefixes added
Manual Conversion Note: The transaction boundaries will be managed by the Npgsql ADO.NET code using BeginTransactionAsync/CommitAsync
--------------------------------------------------------------------------------
*/

-- ORIGINAL MS SQL:
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

-- CONVERTED POSTGRESQL (MANUAL):
-- Insert the new product
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- NOTE: The following statements would be executed in the C# code within a transaction block:
-- After getting the returned productid, execute:
/*
INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

UPDATE productmanagement_dbo.productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = CURRENT_TIMESTAMP
WHERE statid = 1;
*/

/*
--------------------------------------------------------------------------------
STATEMENT 6: UpdateProductAsync
--------------------------------------------------------------------------------
Method: UpdateProductAsync(Product product)
Conversion Status: SUCCESS_WITH_WARNINGS
DMS Tool Status: success
DMS Warning: "[7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction management commands such as BEGIN TRAN, SAVE TRAN in functions. Convert your source code manually.]"
Schema Changes: Products → productmanagement_dbo.products, ProductHistory → productmanagement_dbo.producthistory, ProductStats → productmanagement_dbo.productstats
Notable PostgreSQL Changes:
  - DECLARE @Variable → var_Variable
  - GETDATE() → clock_timestamp()
  - Transaction boundaries commented out (handled at ADO.NET level)
  - BEGIN/END block structure for procedural code
  - Lowercase identifiers
--------------------------------------------------------------------------------
*/

-- ORIGINAL MS SQL:
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

-- CONVERTED POSTGRESQL (DMS):
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

-- CONVERTED POSTGRESQL (SIMPLIFIED FOR ADO.NET - Transaction managed externally):
DO $$
DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
    -- Store old values for history
    SELECT price, stockquantity INTO var_OldPrice, var_OldStock
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId;
    
    -- Update the product
    UPDATE productmanagement_dbo.products
    SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = CURRENT_TIMESTAMP
    WHERE productid = @ProductId;
    
    -- Log the changes
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'UPDATE', var_OldPrice, @Price, var_OldStock, @StockQuantity, CURRENT_TIMESTAMP);
    
    -- Update product statistics
    UPDATE productmanagement_dbo.productstats
    SET averageprice = (averageprice * totalproducts - var_OldPrice + @Price) / totalproducts, lastupdated = CURRENT_TIMESTAMP
    WHERE statid = 1;
END $$;

/*
--------------------------------------------------------------------------------
STATEMENT 7: DeleteProductAsync
--------------------------------------------------------------------------------
Method: DeleteProductAsync(int productId)
Conversion Status: SUCCESS_WITH_WARNINGS
DMS Tool Status: success
DMS Warning: "[7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction management commands such as BEGIN TRAN, SAVE TRAN in functions. Convert your source code manually.]"
Schema Changes: Products → productmanagement_dbo.products, ProductHistory → productmanagement_dbo.producthistory, ProductStats → productmanagement_dbo.productstats
Notable PostgreSQL Changes:
  - DECLARE @Variable → var_Variable
  - GETDATE() → clock_timestamp()
  - Transaction boundaries commented out
  - CASE expression preserved
--------------------------------------------------------------------------------
*/

-- ORIGINAL MS SQL:
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

-- CONVERTED POSTGRESQL (DMS):
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

-- CONVERTED POSTGRESQL (SIMPLIFIED FOR ADO.NET - Transaction managed externally):
DO $$
DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
    -- Store product info for history
    SELECT price, stockquantity INTO var_OldPrice, var_OldStock
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId;
    
    -- Log the deletion
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE', var_OldPrice, NULL, var_OldStock, NULL, CURRENT_TIMESTAMP);
    
    -- Delete the product
    DELETE FROM productmanagement_dbo.products 
    WHERE productid = @ProductId;
    
    -- Update product statistics
    UPDATE productmanagement_dbo.productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - var_OldPrice) / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = CURRENT_TIMESTAMP
    WHERE statid = 1;
END $$;

/*
================================================================================
CONVERSION SUMMARY
================================================================================
Total Statements: 7

DMS Tool Success: 6 statements
  - GetAllProductsAsync (Statement 1)
  - GetProductByIdAsync (Statement 2)
  - GetProductsByPriceRangeAsync (Statement 3)
  - GetLowStockProductsAsync (Statement 4)
  - UpdateProductAsync (Statement 6) - with warnings about transaction management
  - DeleteProductAsync (Statement 7) - with warnings about transaction management

DMS Tool Failure: 1 statement
  - InsertProductAsync (Statement 5) - manual conversion required

Key Schema Transformations (Consistent across ALL statements):
- dbo.Products → productmanagement_dbo.products
- dbo.ProductHistory → productmanagement_dbo.producthistory
- dbo.ProductStats → productmanagement_dbo.productstats

Common PostgreSQL Transformations:
- GETDATE() → CURRENT_TIMESTAMP or clock_timestamp()
- SCOPE_IDENTITY() → RETURNING clause
- Mixed case identifiers → lowercase (ProductId → productid)
- Transaction management moved from SQL to ADO.NET code layer
- Added NULLS FIRST to ORDER BY clauses
- Variable declarations: @Variable → var_Variable (in DMS output)

CRITICAL NOTE FOR CODE RE-INTEGRATION:
- ALL schema object names MUST use the new schema: productmanagement_dbo.products
- DO NOT revert to 'Products' - this would break the migration
- Transaction boundaries (BEGIN TRANSACTION/COMMIT) must be handled in C# code using
  NpgsqlTransaction, not in SQL statements
================================================================================
*/
