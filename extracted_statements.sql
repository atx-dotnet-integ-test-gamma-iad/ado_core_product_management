-- ============================================================================
-- EXTRACTED SQL STATEMENTS CATALOG
-- Source: DataAccess/ProductRepository.cs
-- Total Statements: 15
-- Original MS SQL Server Statements (before migration)
-- Generated for DMS conversion and equivalency validation
-- ============================================================================

-- =============================================================================
-- Statement 1: GetAllProductsAsync - sql
-- Source Method: GetAllProductsAsync()
-- Variable Name: sql
-- Type: Complex SELECT with CTE, window functions, INNER JOIN, CASE, ROUND, ORDER BY
-- =============================================================================
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

-- =============================================================================
-- Statement 2: GetProductByIdAsync - sql
-- Source Method: GetProductByIdAsync(int productId)
-- Variable Name: sql
-- Type: Complex SELECT with CTE, LAG window function, LEFT JOIN, CASE, parameterized
-- =============================================================================
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

-- =============================================================================
-- Statement 3: InsertProductAsync - insertSql
-- Source Method: InsertProductAsync(Product product)
-- Variable Name: insertSql
-- Type: INSERT with SCOPE_IDENTITY()
-- =============================================================================
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity);
SELECT SCOPE_IDENTITY() AS ProductId;

-- =============================================================================
-- Statement 4: InsertProductAsync - historySql
-- Source Method: InsertProductAsync(Product product)
-- Variable Name: historySql
-- Type: INSERT for logging insertion
-- =============================================================================
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());

-- =============================================================================
-- Statement 5: InsertProductAsync - statsSql
-- Source Method: InsertProductAsync(Product product)
-- Variable Name: statsSql
-- Type: UPDATE ProductStats for statistics after insert
-- =============================================================================
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = GETDATE()
WHERE StatId = 1;

-- =============================================================================
-- Statement 6: UpdateProductAsync - selectSql
-- Source Method: UpdateProductAsync(Product product)
-- Variable Name: selectSql
-- Type: SELECT old values before update
-- =============================================================================
SELECT Price, StockQuantity FROM Products WHERE ProductId = @ProductId;

-- =============================================================================
-- Statement 7: UpdateProductAsync - updateSql
-- Source Method: UpdateProductAsync(Product product)
-- Variable Name: updateSql
-- Type: UPDATE Products with multiple columns
-- =============================================================================
UPDATE Products
SET 
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = GETDATE()
WHERE ProductId = @ProductId;

-- =============================================================================
-- Statement 8: UpdateProductAsync - historySql
-- Source Method: UpdateProductAsync(Product product)
-- Variable Name: historySql
-- Type: INSERT into ProductHistory for logging update
-- =============================================================================
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());

-- =============================================================================
-- Statement 9: UpdateProductAsync - statsSql
-- Source Method: UpdateProductAsync(Product product)
-- Variable Name: statsSql
-- Type: UPDATE ProductStats for statistics after update
-- =============================================================================
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = GETDATE()
WHERE StatId = 1;

-- =============================================================================
-- Statement 10: DeleteProductAsync - selectSql
-- Source Method: DeleteProductAsync(int productId)
-- Variable Name: selectSql
-- Type: SELECT old values before delete (same SQL as Statement 6)
-- =============================================================================
SELECT Price, StockQuantity FROM Products WHERE ProductId = @ProductId;

-- =============================================================================
-- Statement 11: DeleteProductAsync - historySql
-- Source Method: DeleteProductAsync(int productId)
-- Variable Name: historySql
-- Type: INSERT into ProductHistory for logging deletion
-- =============================================================================
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());

-- =============================================================================
-- Statement 12: DeleteProductAsync - deleteSql
-- Source Method: DeleteProductAsync(int productId)
-- Variable Name: deleteSql
-- Type: DELETE FROM Products
-- =============================================================================
DELETE FROM Products WHERE ProductId = @ProductId;

-- =============================================================================
-- Statement 13: DeleteProductAsync - statsSql
-- Source Method: DeleteProductAsync(int productId)
-- Variable Name: statsSql
-- Type: UPDATE ProductStats with CASE for handling last product
-- =============================================================================
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

-- =============================================================================
-- Statement 14: GetProductsByPriceRangeAsync - sql
-- Source Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Variable Name: sql
-- Type: Complex SELECT with CTE, RANK, PERCENT_RANK, BETWEEN, CASE, ORDER BY
-- =============================================================================
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

-- =============================================================================
-- Statement 15: GetLowStockProductsAsync - sql
-- Source Method: GetLowStockProductsAsync(int threshold)
-- Variable Name: sql
-- Type: Complex SELECT with CTE, AVG/MIN/MAX window functions, CASE, CAST, ROUND
-- =============================================================================
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
    ROUND((CAST(StockQuantity AS DECIMAL) / AvgStock) * 100, 2) as StockPercentageOfAverage
FROM StockAnalysis sa
WHERE StockQuantity <= @Threshold
ORDER BY StockQuantity;
