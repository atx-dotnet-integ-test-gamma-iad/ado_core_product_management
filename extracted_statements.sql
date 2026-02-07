/*******************************************************************************
 * EXTRACTED SQL STATEMENTS FROM ADO.NET APPLICATION
 * SQL Server to PostgreSQL Migration - Statement Extraction Catalog
 * 
 * This file contains all SQL statements extracted from the codebase with
 * complete metadata for DMS tool conversion and validation.
 * 
 * Total Statements: 7
 * Source File: sourceCode/DataAccess/ProductRepository.cs
 * Schema Context: dbo (SQL Server) / public (PostgreSQL target)
 * 
 * Extraction Date: 2026-02-07
 ******************************************************************************/

/*******************************************************************************
 * STATEMENT 1: GetAllProductsAsync - Complex CTE with Window Functions
 * 
 * Location: ProductRepository.cs, lines 42-73
 * Method: GetAllProductsAsync()
 * Parameters: None
 * Returns: List<Product>
 * 
 * Features:
 * - Common Table Expression (CTE) with window functions
 * - AVG() OVER() - Average price across all products
 * - COUNT(*) OVER() - Total product count
 * - CASE expressions for categorization
 * - INNER JOIN with CTE
 * - Complex ORDER BY with CASE expressions
 * 
 * Tables: Products
 * 
 * Description: Retrieves all products with price analysis using window functions
 * to calculate average price and categorize products as Above/Below/Average price.
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
 * Location: ProductRepository.cs, lines 85-118
 * Method: GetProductByIdAsync(int productId)
 * Parameters: @ProductId (INT)
 * Returns: Product or null
 * 
 * Features:
 * - Common Table Expression (CTE)
 * - LAG() window function for historical data
 * - LEFT JOIN with CTE
 * - Calculated percentage change
 * - CASE expression for NULL handling
 * 
 * Tables: Products
 * 
 * Description: Retrieves a specific product with price history analysis using
 * LAG window function to get previous price and stock values.
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
 * Location: ProductRepository.cs, lines 130-157
 * Method: InsertProductAsync(Product product)
 * Parameters: @Name (NVARCHAR), @Description (NVARCHAR), @Price (DECIMAL), 
 *             @StockQuantity (INT)
 * Returns: New ProductId (INT)
 * 
 * Features:
 * - BEGIN TRANSACTION / COMMIT block
 * - DECLARE @variable syntax for T-SQL variables
 * - SCOPE_IDENTITY() to get inserted ID
 * - GETDATE() for current timestamp (2 occurrences)
 * - Multiple INSERT statements
 * - UPDATE statement with calculations
 * - Final SELECT to return new ID
 * 
 * Tables: Products, ProductHistory, ProductStats
 * 
 * Description: Inserts a new product and logs the action in history table while
 * updating aggregate statistics. Returns the new product ID.
 ******************************************************************************/
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

/*******************************************************************************
 * STATEMENT 4: UpdateProductAsync - Multi-Statement Transaction with Variables
 * 
 * Location: ProductRepository.cs, lines 175-210
 * Method: UpdateProductAsync(Product product)
 * Parameters: @ProductId (INT), @Name (NVARCHAR), @Description (NVARCHAR), 
 *             @Price (DECIMAL), @StockQuantity (INT)
 * Returns: None (ExecuteNonQuery)
 * 
 * Features:
 * - BEGIN TRANSACTION / COMMIT block
 * - DECLARE @variable syntax (2 variables)
 * - SELECT to store old values into variables
 * - UPDATE statement with multiple columns
 * - GETDATE() for current timestamp (3 occurrences)
 * - INSERT for history logging
 * - UPDATE with calculations using variables
 * 
 * Tables: Products, ProductHistory, ProductStats
 * 
 * Description: Updates product information with transaction safety, logging
 * changes to history table and updating aggregate statistics.
 ******************************************************************************/
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

/*******************************************************************************
 * STATEMENT 5: DeleteProductAsync - Multi-Statement Transaction with Conditional Logic
 * 
 * Location: ProductRepository.cs, lines 227-262
 * Method: DeleteProductAsync(int productId)
 * Parameters: @ProductId (INT)
 * Returns: None (ExecuteNonQuery)
 * 
 * Features:
 * - BEGIN TRANSACTION / COMMIT block
 * - DECLARE @variable syntax (2 variables)
 * - SELECT to store old values into variables
 * - INSERT for history logging
 * - DELETE statement
 * - UPDATE with CASE expression for conditional calculation
 * - GETDATE() for current timestamp (2 occurrences)
 * 
 * Tables: Products, ProductHistory, ProductStats
 * 
 * Description: Deletes a product with transaction safety, logging the deletion
 * to history table and updating aggregate statistics with conditional logic.
 ******************************************************************************/
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

/*******************************************************************************
 * STATEMENT 6: GetProductsByPriceRangeAsync - CTE with RANK and PERCENT_RANK
 * 
 * Location: ProductRepository.cs, lines 271-291
 * Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
 * Parameters: @MinPrice (DECIMAL), @MaxPrice (DECIMAL)
 * Returns: List<Product>
 * 
 * Features:
 * - Common Table Expression (CTE)
 * - RANK() window function
 * - PERCENT_RANK() window function
 * - BETWEEN clause for range filtering
 * - CASE expression for segmentation
 * - ORDER BY with window function result
 * 
 * Tables: Products
 * 
 * Description: Retrieves products within a price range with ranking analysis
 * using RANK and PERCENT_RANK window functions for price segmentation.
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
 * Location: ProductRepository.cs, lines 303-323
 * Method: GetLowStockProductsAsync(int threshold)
 * Parameters: @Threshold (INT)
 * Returns: List<Product>
 * 
 * Features:
 * - Common Table Expression (CTE)
 * - AVG() OVER() window function
 * - MIN() OVER() window function
 * - MAX() OVER() window function
 * - CASE expression for status categorization
 * - WHERE clause filtering
 * - ORDER BY with column reference
 * 
 * Tables: Products
 * 
 * Description: Retrieves products with stock below threshold using window
 * functions to calculate stock statistics and categorize stock status.
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
 * END OF EXTRACTED STATEMENTS
 * 
 * Summary:
 * - Total Statements Extracted: 7
 * - Statements with Window Functions: 5 (Statements 1, 2, 6, 7)
 * - Statements with CTEs: 5 (Statements 1, 2, 6, 7)
 * - Transaction Blocks: 3 (Statements 3, 4, 5)
 * - T-SQL Specific Features:
 *   * SCOPE_IDENTITY() - 1 occurrence (Statement 3)
 *   * GETDATE() - 8 occurrences (Statements 3, 4, 5)
 *   * BEGIN TRANSACTION/COMMIT - 3 occurrences (Statements 3, 4, 5)
 *   * DECLARE @variable - 3 occurrences (Statements 3, 4, 5)
 *   * LAG() window function - 1 occurrence (Statement 2)
 *   * RANK() window function - 1 occurrence (Statement 6)
 *   * PERCENT_RANK() window function - 1 occurrence (Statement 6)
 * 
 * All statements are ready for DMS MCP tool conversion to PostgreSQL syntax.
 ******************************************************************************/
