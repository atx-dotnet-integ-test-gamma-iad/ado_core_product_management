-- ============================================================================
-- EXTRACTED SQL STATEMENTS CATALOG
-- Source: DataAccess/ProductRepository.cs
-- Purpose: Catalog of all original MS SQL Server statements for DMS conversion
-- Total Statements: 15
-- ============================================================================

-- ============================================================================
-- Statement 1: GetAllProductsAsync - Complex CTE with window functions
-- Method: GetAllProductsAsync()
-- Variable: sql (const string)
-- Location: ~Line 41
-- ============================================================================
WITH ProductStats AS (
    SELECT
        ProductId,
        AVG(Price) OVER () AS AvgPrice,
        COUNT(*) OVER () AS TotalProducts
    FROM dbo.Products
)
SELECT
    p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate,
    CASE
        WHEN p.Price > ps.AvgPrice THEN 'Above Average'
        WHEN p.Price < ps.AvgPrice THEN 'Below Average'
        ELSE 'Average'
    END AS PriceCategory,
    ROUND((p.Price / ps.AvgPrice) * 100, 2) AS PricePercentageOfAverage
FROM dbo.Products AS p
INNER JOIN ProductStats AS ps ON p.ProductId = ps.ProductId
ORDER BY
    CASE
        WHEN p.Price > ps.AvgPrice THEN 1
        ELSE 2
    END, p.Name;

-- ============================================================================
-- Statement 2: GetProductByIdAsync - CTE with LAG window function
-- Method: GetProductByIdAsync(int productId)
-- Variable: sql (const string)
-- Location: ~Line 72
-- ============================================================================
WITH ProductHistory AS (
    SELECT
        ProductId,
        LAG(Price) OVER (ORDER BY ModifiedDate) AS PreviousPrice,
        LAG(StockQuantity) OVER (ORDER BY ModifiedDate) AS PreviousStock
    FROM dbo.Products
    WHERE ProductId = @ProductId
)
SELECT
    p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate,
    ph.PreviousPrice, ph.PreviousStock,
    CASE
        WHEN ph.PreviousPrice IS NOT NULL THEN ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100, 2)
        ELSE NULL
    END AS PriceChangePercentage
FROM dbo.Products AS p
LEFT OUTER JOIN ProductHistory AS ph ON p.ProductId = ph.ProductId
WHERE p.ProductId = @ProductId;

-- ============================================================================
-- Statement 3: InsertProductAsync - INSERT product with SCOPE_IDENTITY
-- Method: InsertProductAsync(Product product)
-- Variable: sqlInsertProduct (const string)
-- Location: ~Line 104
-- ============================================================================
INSERT INTO dbo.Products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity);
SELECT SCOPE_IDENTITY();

-- ============================================================================
-- Statement 4: InsertProductAsync - INSERT into ProductHistory for INSERT action
-- Method: InsertProductAsync(Product product)
-- Variable: sqlLogHistory (const string)
-- Location: ~Line 117
-- ============================================================================
INSERT INTO dbo.ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());

-- ============================================================================
-- Statement 5: InsertProductAsync - UPDATE ProductStats (increment TotalProducts)
-- Method: InsertProductAsync(Product product)
-- Variable: sqlUpdateStats (const string)
-- Location: ~Line 127
-- ============================================================================
UPDATE dbo.ProductStats
SET
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = GETDATE()
WHERE StatId = 1;

-- ============================================================================
-- Statement 6: UpdateProductAsync - SELECT old values from Products
-- Method: UpdateProductAsync(Product product)
-- Variable: sqlGetOldValues (const string)
-- Location: ~Line 150
-- ============================================================================
SELECT Price, StockQuantity
FROM dbo.Products
WHERE ProductId = @ProductId;

-- ============================================================================
-- Statement 7: UpdateProductAsync - UPDATE product SET with ModifiedDate
-- Method: UpdateProductAsync(Product product)
-- Variable: sqlUpdateProduct (const string)
-- Location: ~Line 162
-- ============================================================================
UPDATE dbo.Products
SET
    Name = @Name,
    Description = @Description,
    Price = @Price,
    StockQuantity = @StockQuantity,
    ModifiedDate = GETDATE()
WHERE ProductId = @ProductId;

-- ============================================================================
-- Statement 8: UpdateProductAsync - INSERT into ProductHistory for UPDATE action
-- Method: UpdateProductAsync(Product product)
-- Variable: sqlLogHistory (const string)
-- Location: ~Line 178
-- ============================================================================
INSERT INTO dbo.ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());

-- ============================================================================
-- Statement 9: UpdateProductAsync - UPDATE ProductStats (recalculate AveragePrice)
-- Method: UpdateProductAsync(Product product)
-- Variable: sqlUpdateStats (const string)
-- Location: ~Line 191
-- ============================================================================
UPDATE dbo.ProductStats
SET
    AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
    LastUpdated = GETDATE()
WHERE StatId = 1;

-- ============================================================================
-- Statement 10: DeleteProductAsync - SELECT old values from Products
-- Method: DeleteProductAsync(int productId)
-- Variable: sqlGetOldValues (const string)
-- Location: ~Line 213
-- ============================================================================
SELECT Price, StockQuantity
FROM dbo.Products
WHERE ProductId = @ProductId;

-- ============================================================================
-- Statement 11: DeleteProductAsync - INSERT into ProductHistory for DELETE action
-- Method: DeleteProductAsync(int productId)
-- Variable: sqlLogHistory (const string)
-- Location: ~Line 225
-- ============================================================================
INSERT INTO dbo.ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());

-- ============================================================================
-- Statement 12: DeleteProductAsync - DELETE FROM Products
-- Method: DeleteProductAsync(int productId)
-- Variable: sqlDeleteProduct (const string)
-- Location: ~Line 235
-- ============================================================================
DELETE FROM dbo.Products
WHERE ProductId = @ProductId;

-- ============================================================================
-- Statement 13: DeleteProductAsync - UPDATE ProductStats (decrement TotalProducts with CASE)
-- Method: DeleteProductAsync(int productId)
-- Variable: sqlUpdateStats (const string)
-- Location: ~Line 244
-- ============================================================================
UPDATE dbo.ProductStats
SET
    TotalProducts = TotalProducts - 1,
    AveragePrice = CASE
        WHEN TotalProducts > 1
        THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1)
        ELSE 0
    END,
    LastUpdated = GETDATE()
WHERE StatId = 1;

-- ============================================================================
-- Statement 14: GetProductsByPriceRangeAsync - CTE with RANK/PERCENT_RANK
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Variable: sql (const string)
-- Location: ~Line 261
-- ============================================================================
WITH RankedProducts AS (
    SELECT
        p.*,
        RANK() OVER (ORDER BY p.Price) AS PriceRank,
        PERCENT_RANK() OVER (ORDER BY p.Price) AS PricePercentile
    FROM dbo.Products p
    WHERE p.Price BETWEEN @MinPrice AND @MaxPrice
)
SELECT
    rp.*,
    CASE
        WHEN rp.PricePercentile <= 0.25 THEN 'Budget'
        WHEN rp.PricePercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END AS PriceSegment
FROM RankedProducts rp
ORDER BY rp.PriceRank;

-- ============================================================================
-- Statement 15: GetLowStockProductsAsync - CTE with AVG/MIN/MAX window functions
-- Method: GetLowStockProductsAsync(int threshold)
-- Variable: sql (const string)
-- Location: ~Line 295
-- ============================================================================
WITH StockAnalysis AS (
    SELECT
        p.*,
        AVG(StockQuantity) OVER() AS AvgStock,
        MIN(StockQuantity) OVER() AS MinStock,
        MAX(StockQuantity) OVER() AS MaxStock
    FROM dbo.Products p
)
SELECT
    sa.*,
    CASE
        WHEN StockQuantity <= @Threshold THEN 'Critical'
        WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END AS StockStatus,
    ROUND((StockQuantity / AvgStock) * 100, 2) AS StockPercentageOfAverage
FROM StockAnalysis sa
WHERE StockQuantity <= @Threshold
ORDER BY StockQuantity;
