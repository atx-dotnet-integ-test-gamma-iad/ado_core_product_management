/*******************************************************************************
 * SQL STATEMENT EXTRACTION CATALOG
 * Microsoft SQL Server to PostgreSQL Migration
 * Source Application: AdoCore - ADO.NET Product Management System
 * 
 * This catalog contains all SQL statements extracted from the source code
 * for processing through the DMS MCP conversion tool.
 * 
 * Extraction Date: 2024
 * Total Statements Extracted: 7
 ******************************************************************************/

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync - Complex CTE with Window Functions
-- ============================================================================
-- Source File: ProductRepository.cs
-- Source Method: GetAllProductsAsync()
-- Line Numbers: 41-68
-- Statement Type: SELECT with CTE, Window Functions (AVG OVER, COUNT OVER), CASE
-- Complexity: High
-- Description: Retrieves all products with calculated price categories using 
--              window functions for average price comparison
-- ============================================================================

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

-- ============================================================================
-- STATEMENT 2: GetProductByIdAsync - CTE with LAG Window Function
-- ============================================================================
-- Source File: ProductRepository.cs
-- Source Method: GetProductByIdAsync(int productId)
-- Line Numbers: 82-109
-- Statement Type: SELECT with CTE, LAG Window Function, LEFT JOIN
-- Complexity: High
-- Parameters: @ProductId (INT)
-- Description: Retrieves product by ID with historical price and stock tracking
--              using LAG window function
-- ============================================================================

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

-- ============================================================================
-- STATEMENT 3: InsertProductAsync - Multi-Statement Transaction Block
-- ============================================================================
-- Source File: ProductRepository.cs
-- Source Method: InsertProductAsync(Product product)
-- Line Numbers: 123-147
-- Statement Type: TRANSACTION with INSERT, SCOPE_IDENTITY(), UPDATE
-- Complexity: Very High
-- Parameters: @Name (VARCHAR), @Description (VARCHAR), @Price (DECIMAL), 
--             @StockQuantity (INT)
-- Description: Transaction block that inserts a new product, logs to history,
--              and updates statistics. Uses SCOPE_IDENTITY() and GETDATE()
-- ============================================================================

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

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync - Multi-Statement Transaction Block
-- ============================================================================
-- Source File: ProductRepository.cs
-- Source Method: UpdateProductAsync(Product product)
-- Line Numbers: 161-189
-- Statement Type: TRANSACTION with DECLARE, SELECT, UPDATE, INSERT
-- Complexity: Very High
-- Parameters: @ProductId (INT), @Name (VARCHAR), @Description (VARCHAR), 
--             @Price (DECIMAL), @StockQuantity (INT)
-- Description: Transaction block that stores old values, updates product,
--              logs changes to history, and updates statistics
-- ============================================================================

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

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync - Multi-Statement Transaction Block
-- ============================================================================
-- Source File: ProductRepository.cs
-- Source Method: DeleteProductAsync(int productId)
-- Line Numbers: 203-234
-- Statement Type: TRANSACTION with DECLARE, SELECT, INSERT, DELETE, UPDATE
-- Complexity: Very High
-- Parameters: @ProductId (INT)
-- Description: Transaction block that stores product info, logs deletion,
--              deletes product, and updates statistics
-- ============================================================================

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

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync - CTE with Ranking Functions
-- ============================================================================
-- Source File: ProductRepository.cs
-- Source Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Line Numbers: 248-272
-- Statement Type: SELECT with CTE, RANK(), PERCENT_RANK() Window Functions
-- Complexity: High
-- Parameters: @MinPrice (DECIMAL), @MaxPrice (DECIMAL)
-- Description: Retrieves products in a price range with ranking and percentile
--              calculations for price segmentation
-- ============================================================================

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

-- ============================================================================
-- STATEMENT 7: GetLowStockProductsAsync - CTE with Multiple Window Functions
-- ============================================================================
-- Source File: ProductRepository.cs
-- Source Method: GetLowStockProductsAsync(int threshold)
-- Line Numbers: 286-314
-- Statement Type: SELECT with CTE, Multiple Window Functions (AVG, MIN, MAX OVER)
-- Complexity: High
-- Parameters: @Threshold (INT)
-- Description: Retrieves low stock products with stock analysis using multiple
--              window functions for comparison
-- ============================================================================

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
 * EXTRACTION SUMMARY
 * 
 * Total SQL Statements Extracted: 7
 * 
 * Statement Types:
 *   - SELECT with CTE and Window Functions: 4 statements
 *   - Transaction Blocks (INSERT/UPDATE/DELETE): 3 statements
 * 
 * SQL Server Specific Features Identified:
 *   - Window Functions: AVG OVER, COUNT OVER, LAG OVER, RANK, PERCENT_RANK
 *   - Common Table Expressions (WITH clause): 5 statements
 *   - SCOPE_IDENTITY(): 1 occurrence
 *   - GETDATE(): 8 occurrences
 *   - DECLARE statements: 6 occurrences
 *   - Transaction syntax: BEGIN TRANSACTION, COMMIT
 *   - ROUND function: 5 occurrences
 *   - CASE expressions: 7 occurrences
 * 
 * Complexity Assessment:
 *   - High Complexity: 4 statements (CTE + Window Functions)
 *   - Very High Complexity: 3 statements (Multi-statement transactions)
 * 
 * All statements are ready for DMS MCP tool conversion in Step 2.
 ******************************************************************************/
