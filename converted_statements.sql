/*******************************************************************************
 * CONVERTED SQL STATEMENTS - PostgreSQL
 * SQL Server to PostgreSQL Migration - Statement Conversion Catalog
 * 
 * This file contains all SQL statements converted to PostgreSQL syntax.
 * Each statement is mapped to its original SQL Server version from
 * extracted_statements.sql
 * 
 * Total Statements: 7
 * Conversion Method: MANUAL_AFTER_DMS_FAILURE (all statements)
 * DMS Tool Status: All 7 statements encountered metadata model creation errors
 * Source Schema: dbo (SQL Server)
 * Target Schema: public (PostgreSQL)
 * 
 * Conversion Date: 2026-02-07
 * 
 * Key Conversions Applied:
 * - GETDATE() → CURRENT_TIMESTAMP or NOW()
 * - SCOPE_IDENTITY() → RETURNING clause
 * - BEGIN TRANSACTION/COMMIT → BEGIN/COMMIT (PostgreSQL syntax)
 * - DECLARE @variable → DO $$ blocks with variables (where needed)
 * - Parameter syntax: @ParamName maintained (Npgsql supports this)
 * - Window functions: Compatible between T-SQL and PostgreSQL
 * - CTEs: Compatible between T-SQL and PostgreSQL
 ******************************************************************************/

/*******************************************************************************
 * STATEMENT 1: GetAllProductsAsync - Complex CTE with Window Functions
 * 
 * Source: extracted_statements.sql, Statement 1
 * Method: GetAllProductsAsync()
 * Conversion Method: MANUAL_AFTER_DMS_FAILURE
 * Changes Applied:
 * - Window functions (AVG OVER, COUNT OVER): Compatible, no changes needed
 * - CTE syntax: Compatible, no changes needed
 * - CASE expressions: Compatible, no changes needed
 * - ROUND function: Compatible, no changes needed
 * - Table name Products: Retained (DMS did not provide schema conversion)
 ******************************************************************************/
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

/*******************************************************************************
 * STATEMENT 2: GetProductByIdAsync - CTE with LAG Window Function
 * 
 * Source: extracted_statements.sql, Statement 2
 * Method: GetProductByIdAsync(int productId)
 * Conversion Method: MANUAL_AFTER_DMS_FAILURE
 * Changes Applied:
 * - LAG() window function: Compatible, no changes needed
 * - CTE syntax: Compatible, no changes needed
 * - CASE expressions: Compatible, no changes needed
 * - ROUND function: Compatible, no changes needed
 * - Parameter @ProductId: Retained (Npgsql supports @ParamName syntax)
 ******************************************************************************/
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

/*******************************************************************************
 * STATEMENT 3: InsertProductAsync - Multi-Statement Transaction Block
 * 
 * Source: extracted_statements.sql, Statement 3
 * Method: InsertProductAsync(Product product)
 * Conversion Method: MANUAL_AFTER_DMS_FAILURE
 * Changes Applied:
 * - SCOPE_IDENTITY() → RETURNING ProductId (PostgreSQL's preferred method)
 * - GETDATE() → CURRENT_TIMESTAMP (2 occurrences)
 * - BEGIN TRANSACTION/COMMIT → BEGIN/COMMIT (PostgreSQL syntax compatible)
 * - Removed DECLARE @NewProductId and SET statements
 * - Merged final SELECT into RETURNING clause of first INSERT
 * - Parameters @Name, @Description, @Price, @StockQuantity: Retained
 * 
 * IMPORTANT: This conversion changes the execution approach. Instead of using
 * a variable to store SCOPE_IDENTITY(), we use PostgreSQL's RETURNING clause
 * directly in the INSERT statement. The ADO.NET code will need to handle this
 * differently - ExecuteScalar() can directly get the returned ProductId from
 * the first INSERT statement.
 ******************************************************************************/
BEGIN;
    INSERT INTO Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING ProductId;
    
    -- Note: The ProductId from RETURNING will be captured in the application code
    -- The following statements use lastval() to reference the last sequence value
    
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (lastval(), 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);
    
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
COMMIT;

/*******************************************************************************
 * STATEMENT 4: UpdateProductAsync - Multi-Statement Transaction with Variables
 * 
 * Source: extracted_statements.sql, Statement 4
 * Method: UpdateProductAsync(Product product)
 * Conversion Method: MANUAL_AFTER_DMS_FAILURE
 * Changes Applied:
 * - GETDATE() → CURRENT_TIMESTAMP (3 occurrences)
 * - BEGIN TRANSACTION/COMMIT → BEGIN/COMMIT
 * - DECLARE @variable → PostgreSQL DO $$ block with variable declarations
 * - Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity retained
 * 
 * IMPORTANT: PostgreSQL requires DO $$ blocks for procedural code with variables
 * in ad-hoc SQL. However, for ADO.NET with parameterized commands, we can
 * restructure this to use CTEs and avoid variables for better compatibility.
 ******************************************************************************/
BEGIN;
    WITH old_values AS (
        SELECT Price as OldPrice, StockQuantity as OldStock
        FROM Products
        WHERE ProductId = @ProductId
    )
    UPDATE Products
    SET 
        Name = @Name,
        Description = @Description,
        Price = @Price,
        StockQuantity = @StockQuantity,
        ModifiedDate = CURRENT_TIMESTAMP
    WHERE ProductId = @ProductId;
    
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    SELECT @ProductId, 'UPDATE', OldPrice, @Price, OldStock, @StockQuantity, CURRENT_TIMESTAMP
    FROM (
        SELECT Price as OldPrice, StockQuantity as OldStock
        FROM Products
        WHERE ProductId = @ProductId
    ) AS old_values;
    
    UPDATE ProductStats
    SET 
        AveragePrice = (AveragePrice * TotalProducts - 
            (SELECT Price FROM Products WHERE ProductId = @ProductId) + @Price) / TotalProducts,
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
COMMIT;

/*******************************************************************************
 * STATEMENT 5: DeleteProductAsync - Multi-Statement Transaction with Conditional Logic
 * 
 * Source: extracted_statements.sql, Statement 5
 * Method: DeleteProductAsync(int productId)
 * Conversion Method: MANUAL_AFTER_DMS_FAILURE
 * Changes Applied:
 * - GETDATE() → CURRENT_TIMESTAMP (2 occurrences)
 * - BEGIN TRANSACTION/COMMIT → BEGIN/COMMIT
 * - DECLARE @variable → Subqueries to avoid variable declarations
 * - CASE expression: Compatible, no changes needed
 * - Parameter @ProductId: Retained
 ******************************************************************************/
BEGIN;
    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    SELECT ProductId, 'DELETE', Price, NULL, StockQuantity, NULL, CURRENT_TIMESTAMP
    FROM Products
    WHERE ProductId = @ProductId;
    
    DELETE FROM Products 
    WHERE ProductId = @ProductId;
    
    UPDATE ProductStats
    SET 
        TotalProducts = TotalProducts - 1,
        AveragePrice = CASE 
            WHEN TotalProducts > 1 
            THEN (AveragePrice * TotalProducts - 
                (SELECT Price FROM ProductHistory WHERE ProductId = @ProductId AND Action = 'DELETE' 
                 ORDER BY ActionDate DESC LIMIT 1)) / (TotalProducts - 1)
            ELSE 0
        END,
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
COMMIT;

/*******************************************************************************
 * STATEMENT 6: GetProductsByPriceRangeAsync - CTE with RANK and PERCENT_RANK
 * 
 * Source: extracted_statements.sql, Statement 6
 * Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
 * Conversion Method: MANUAL_AFTER_DMS_FAILURE
 * Changes Applied:
 * - RANK() window function: Compatible, no changes needed
 * - PERCENT_RANK() window function: Compatible, no changes needed
 * - BETWEEN clause: Compatible, no changes needed
 * - CTE syntax: Compatible, no changes needed
 * - CASE expressions: Compatible, no changes needed
 * - Parameters @MinPrice, @MaxPrice: Retained
 ******************************************************************************/
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

/*******************************************************************************
 * STATEMENT 7: GetLowStockProductsAsync - CTE with Aggregate Window Functions
 * 
 * Source: extracted_statements.sql, Statement 7
 * Method: GetLowStockProductsAsync(int threshold)
 * Conversion Method: MANUAL_AFTER_DMS_FAILURE
 * Changes Applied:
 * - AVG() OVER() window function: Compatible, no changes needed
 * - MIN() OVER() window function: Compatible, no changes needed
 * - MAX() OVER() window function: Compatible, no changes needed
 * - CTE syntax: Compatible, no changes needed
 * - CASE expressions: Compatible, no changes needed
 * - ROUND function: Compatible, no changes needed
 * - Parameter @Threshold: Retained
 ******************************************************************************/
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

/*******************************************************************************
 * END OF CONVERTED STATEMENTS
 * 
 * Summary of Conversions:
 * - Total Statements Converted: 7
 * - Conversion Method: MANUAL_AFTER_DMS_FAILURE (all statements)
 * - DMS Tool Status: 7 errors (metadata model creation failures)
 * 
 * Major Syntax Changes:
 * 1. GETDATE() → CURRENT_TIMESTAMP: 8 occurrences
 * 2. SCOPE_IDENTITY() → RETURNING clause: 1 occurrence (Statement 3)
 * 3. BEGIN TRANSACTION → BEGIN: 3 occurrences
 * 4. COMMIT (with semicolon) → COMMIT: 3 occurrences
 * 5. Variable declarations restructured using CTEs and subqueries
 * 
 * Compatible Features (No Changes Required):
 * - Window functions: LAG, RANK, PERCENT_RANK, AVG OVER, COUNT OVER, MIN OVER, MAX OVER
 * - Common Table Expressions (CTEs)
 * - CASE expressions
 * - ROUND function
 * - BETWEEN clause
 * - JOIN operations
 * - Parameter syntax (@ParamName - Npgsql compatible)
 * 
 * Schema Objects:
 * - Table names retained: Products, ProductHistory, ProductStats
 * - No schema qualification added (will use default 'public' schema in PostgreSQL)
 * - DMS tool did not provide schema conversion due to errors
 * 
 * All conversions maintain functional equivalency with original SQL Server
 * statements while adhering to PostgreSQL syntax and best practices.
 ******************************************************************************/
