-- =====================================================
-- Extracted SQL Statements from ProductRepository.cs
-- Source Database: SQL Server 2019, Database: ProductManagement, Schema: dbo
-- Target Database: PostgreSQL, Schema: productmanagement_dbo
-- =====================================================

-- =====================================================
-- Statement 1: GetAllProductsAsync (Lines 44-60)
-- Method: GetAllProductsAsync()
-- Type: SELECT with CTE and window functions
-- =====================================================
WITH ProductStats AS (
    SELECT ProductId, AVG(Price) OVER () AS AvgPrice, COUNT(*) OVER () AS TotalProducts
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

-- =====================================================
-- Statement 2: GetProductByIdAsync (Lines 75-90)
-- Method: GetProductByIdAsync(int productId)
-- Type: SELECT with CTE and LAG window function
-- =====================================================
WITH ProductHistory AS (
    SELECT ProductId, LAG(Price) OVER (ORDER BY ModifiedDate) AS PreviousPrice, LAG(StockQuantity) OVER (ORDER BY ModifiedDate) AS PreviousStock
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

-- =====================================================
-- Statement 3: InsertProductAsync (Lines 104-121)
-- Method: InsertProductAsync(Product product)
-- Type: Transaction block with INSERT and UPDATE
-- =====================================================
BEGIN
    DECLARE @NewProductId INT;

    INSERT INTO dbo.Products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity);

    SET @NewProductId = SCOPE_IDENTITY();

    INSERT INTO dbo.ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());

    UPDATE dbo.ProductStats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = GETDATE()
    WHERE StatId = 1;

    SELECT @NewProductId;
END;

-- =====================================================
-- Statement 4: UpdateProductAsync (Lines 136-152)
-- Method: UpdateProductAsync(Product product)
-- Type: Transaction block with SELECT INTO, UPDATE, INSERT
-- =====================================================
BEGIN
    DECLARE @OldPrice DECIMAL(18, 2);
    DECLARE @OldStock INT;

    SELECT @OldPrice = Price, @OldStock = StockQuantity
    FROM dbo.Products
    WHERE ProductId = @ProductId;

    UPDATE dbo.Products
    SET Name = @Name, Description = @Description, Price = @Price, StockQuantity = @StockQuantity, ModifiedDate = GETDATE()
    WHERE ProductId = @ProductId;

    INSERT INTO dbo.ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());

    UPDATE dbo.ProductStats
    SET AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts, LastUpdated = GETDATE()
    WHERE StatId = 1;
END;

-- =====================================================
-- Statement 5: DeleteProductAsync (Lines 167-186)
-- Method: DeleteProductAsync(int productId)
-- Type: Transaction block with SELECT INTO, INSERT, DELETE, UPDATE
-- =====================================================
BEGIN
    DECLARE @OldPrice DECIMAL(18, 2);
    DECLARE @OldStock INT;

    SELECT @OldPrice = Price, @OldStock = StockQuantity
    FROM dbo.Products
    WHERE ProductId = @ProductId;

    INSERT INTO dbo.ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());

    DELETE FROM dbo.Products
    WHERE ProductId = @ProductId;

    UPDATE dbo.ProductStats
    SET TotalProducts = TotalProducts - 1,
        AveragePrice = CASE
            WHEN TotalProducts > 1 THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1)
            ELSE 0
        END,
        LastUpdated = GETDATE()
    WHERE StatId = 1;
END;

-- =====================================================
-- Statement 6: GetProductsByPriceRangeAsync (Lines 200-213)
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Type: SELECT with CTE and RANK/PERCENT_RANK window functions
-- =====================================================
WITH RankedProducts AS (
    SELECT p.*, RANK() OVER (ORDER BY p.Price) AS PriceRank, PERCENT_RANK() OVER (ORDER BY p.Price) AS PricePercentile
    FROM dbo.Products AS p
    WHERE p.Price BETWEEN @MinPrice AND @MaxPrice
)
SELECT
    rp.*,
    CASE
        WHEN rp.PricePercentile <= 0.25 THEN 'Budget'
        WHEN rp.PricePercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END AS PriceSegment
FROM RankedProducts AS rp
ORDER BY rp.PriceRank;

-- =====================================================
-- Statement 7: GetLowStockProductsAsync (Lines 228-241)
-- Method: GetLowStockProductsAsync(int threshold)
-- Type: SELECT with CTE and AVG/MIN/MAX window functions
-- =====================================================
WITH StockAnalysis AS (
    SELECT p.*, AVG(StockQuantity) OVER () AS AvgStock, MIN(StockQuantity) OVER () AS MinStock, MAX(StockQuantity) OVER () AS MaxStock
    FROM dbo.Products AS p
)
SELECT
    sa.*,
    CASE
        WHEN StockQuantity <= @Threshold THEN 'Critical'
        WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END AS StockStatus,
    ROUND((StockQuantity / AvgStock) * 100, 2) AS StockPercentageOfAverage
FROM StockAnalysis AS sa
WHERE StockQuantity <= @Threshold
ORDER BY StockQuantity;
