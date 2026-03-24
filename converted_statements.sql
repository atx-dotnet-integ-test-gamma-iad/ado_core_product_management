-- ============================================================================
-- CONVERTED SQL STATEMENTS CATALOG
-- Source: DataAccess/ProductRepository.cs
-- Conversion Date: 2026-03-24
-- Total Statements: 7
-- DMS Tool Status: ALL 7 STATEMENTS FAILED - Metadata model creation/conversion timeout
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA (all 7)
-- Schema Mapping (from DMS Schema Mapping Tool):
--   dbo.Products -> productmanagement_dbo.products
--   dbo.ProductHistory -> productmanagement_dbo.producthistory
--   dbo.ProductStats -> productmanagement_dbo.productstats
--   All column names -> lowercase
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync
-- Source: DataAccess/ProductRepository.cs, Method: GetAllProductsAsync()
-- conversion_method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model conversion failed: Metadata model conversion did not complete after 15 attempts
-- ============================================================================

-- ORIGINAL MS SQL:
-- WITH productstats_cte AS (
--     SELECT 
--         ProductId,
--         AVG(Price) OVER() as AvgPrice,
--         COUNT(*) OVER() as TotalProducts
--     FROM [dbo].[Products]
-- )
-- SELECT 
--     p.ProductId,
--     p.Name,
--     p.Description,
--     p.Price,
--     p.StockQuantity,
--     p.CreatedDate,
--     p.ModifiedDate,
--     CASE 
--         WHEN p.Price > ps.AvgPrice THEN 'Above Average'
--         WHEN p.Price < ps.AvgPrice THEN 'Below Average'
--         ELSE 'Average'
--     END as PriceCategory,
--     ROUND(CAST(p.Price AS NUMERIC) / ps.AvgPrice * 100, 2) as PricePercentageOfAverage
-- FROM [dbo].[Products] p
-- INNER JOIN productstats_cte ps ON p.ProductId = ps.ProductId
-- ORDER BY 
--     CASE 
--         WHEN p.Price > ps.AvgPrice THEN 1
--         ELSE 2
--     END,
--     p.Name

-- CONVERTED POSTGRESQL:
WITH productstats_cte AS (
    SELECT 
        productid,
        AVG(price) OVER() as avgprice,
        COUNT(*) OVER() as totalproducts
    FROM productmanagement_dbo.products
)
SELECT 
    p.productid,
    p.name,
    p.description,
    p.price,
    p.stockquantity,
    p.createddate,
    p.modifieddate,
    CASE 
        WHEN p.price > ps.avgprice THEN 'Above Average'
        WHEN p.price < ps.avgprice THEN 'Below Average'
        ELSE 'Average'
    END as pricecategory,
    ROUND(CAST(p.price AS NUMERIC) / ps.avgprice * 100, 2) as pricepercentageofaverage
FROM productmanagement_dbo.products p
INNER JOIN productstats_cte ps ON p.productid = ps.productid
ORDER BY 
    CASE 
        WHEN p.price > ps.avgprice THEN 1
        ELSE 2
    END,
    p.name;

-- ============================================================================
-- STATEMENT 2: GetProductByIdAsync
-- Source: DataAccess/ProductRepository.cs, Method: GetProductByIdAsync(int productId)
-- conversion_method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model conversion failed: Metadata model conversion did not complete after 15 attempts
-- ============================================================================

-- ORIGINAL MS SQL:
-- WITH producthistory_cte AS (
--     SELECT 
--         ProductId,
--         LAG(Price) OVER (ORDER BY ModifiedDate) as PreviousPrice,
--         LAG(StockQuantity) OVER (ORDER BY ModifiedDate) as PreviousStock
--     FROM [dbo].[Products]
--     WHERE ProductId = @ProductId
-- )
-- SELECT 
--     p.ProductId,
--     p.Name,
--     p.Description,
--     p.Price,
--     p.StockQuantity,
--     p.CreatedDate,
--     p.ModifiedDate,
--     ph.PreviousPrice,
--     ph.PreviousStock,
--     CASE 
--         WHEN ph.PreviousPrice IS NOT NULL THEN 
--             ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100, 2)
--         ELSE NULL
--     END as PriceChangePercentage
-- FROM [dbo].[Products] p
-- LEFT JOIN producthistory_cte ph ON p.ProductId = ph.ProductId
-- WHERE p.ProductId = @ProductId

-- CONVERTED POSTGRESQL:
WITH producthistory_cte AS (
    SELECT 
        productid,
        LAG(price) OVER (ORDER BY modifieddate) as previousprice,
        LAG(stockquantity) OVER (ORDER BY modifieddate) as previousstock
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId
)
SELECT 
    p.productid,
    p.name,
    p.description,
    p.price,
    p.stockquantity,
    p.createddate,
    p.modifieddate,
    ph.previousprice,
    ph.previousstock,
    CASE 
        WHEN ph.previousprice IS NOT NULL THEN 
            ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2)
        ELSE NULL
    END as pricechangepercentage
FROM productmanagement_dbo.products p
LEFT JOIN producthistory_cte ph ON p.productid = ph.productid
WHERE p.productid = @ProductId;

-- ============================================================================
-- STATEMENT 3: InsertProductAsync
-- Source: DataAccess/ProductRepository.cs, Method: InsertProductAsync(Product product)
-- conversion_method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: Metadata model creation did not complete after 15 attempts
-- ============================================================================

-- ORIGINAL MS SQL:
-- BEGIN TRANSACTION;
--     INSERT INTO [dbo].[Products] (Name, Description, Price, StockQuantity)
--     VALUES (@Name, @Description, @Price, @StockQuantity);
--     
--     INSERT INTO [dbo].[ProductHistory] (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
--     VALUES (SCOPE_IDENTITY(), 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());
--     
--     UPDATE [dbo].[ProductStats]
--     SET 
--         TotalProducts = TotalProducts + 1,
--         AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
--         LastUpdated = GETDATE()
--     WHERE StatId = 1;
-- COMMIT TRANSACTION;
-- 
-- SELECT SCOPE_IDENTITY();

-- CONVERTED POSTGRESQL:
BEGIN;
    INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity);
    
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (lastval(), 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp());
    
    UPDATE productmanagement_dbo.productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = clock_timestamp()
    WHERE statid = 1;
COMMIT;

SELECT lastval();

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync
-- Source: DataAccess/ProductRepository.cs, Method: UpdateProductAsync(Product product)
-- conversion_method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: Metadata model creation did not complete after 15 attempts
-- ============================================================================

-- ORIGINAL MS SQL:
-- BEGIN TRANSACTION;
--     INSERT INTO [dbo].[ProductHistory] (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
--     SELECT @ProductId, 'UPDATE', p.Price, @Price, p.StockQuantity, @StockQuantity, GETDATE()
--     FROM [dbo].[Products] p
--     WHERE p.ProductId = @ProductId;
--
--     UPDATE [dbo].[Products]
--     SET 
--         Name = @Name,
--         Description = @Description,
--         Price = @Price,
--         StockQuantity = @StockQuantity,
--         ModifiedDate = GETDATE()
--     WHERE ProductId = @ProductId;
--     
--     UPDATE [dbo].[ProductStats]
--     SET 
--         AveragePrice = (AveragePrice * TotalProducts - (SELECT TOP 1 OldPrice FROM [dbo].[ProductHistory] WHERE ProductId = @ProductId AND Action = 'UPDATE' ORDER BY ActionDate DESC) + @Price) / TotalProducts,
--         LastUpdated = GETDATE()
--     WHERE StatId = 1;
-- COMMIT TRANSACTION;

-- CONVERTED POSTGRESQL:
BEGIN;
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT @ProductId, 'UPDATE', p.price, @Price, p.stockquantity, @StockQuantity, clock_timestamp()
    FROM productmanagement_dbo.products p
    WHERE p.productid = @ProductId;

    UPDATE productmanagement_dbo.products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = clock_timestamp()
    WHERE productid = @ProductId;
    
    UPDATE productmanagement_dbo.productstats
    SET 
        averageprice = (averageprice * totalproducts - (SELECT oldprice FROM productmanagement_dbo.producthistory WHERE productid = @ProductId AND action = 'UPDATE' ORDER BY actiondate DESC LIMIT 1) + @Price) / totalproducts,
        lastupdated = clock_timestamp()
    WHERE statid = 1;
COMMIT;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync
-- Source: DataAccess/ProductRepository.cs, Method: DeleteProductAsync(int productId)
-- conversion_method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: Metadata model creation did not complete after 15 attempts
-- ============================================================================

-- ORIGINAL MS SQL:
-- BEGIN TRANSACTION;
--     INSERT INTO [dbo].[ProductHistory] (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
--     SELECT ProductId, 'DELETE', Price, NULL, StockQuantity, NULL, GETDATE()
--     FROM [dbo].[Products]
--     WHERE ProductId = @ProductId;
--     
--     DELETE FROM [dbo].[Products] 
--     WHERE ProductId = @ProductId;
--     
--     UPDATE [dbo].[ProductStats]
--     SET 
--         TotalProducts = TotalProducts - 1,
--         AveragePrice = CASE 
--             WHEN TotalProducts > 1 
--             THEN (AveragePrice * TotalProducts - (SELECT TOP 1 ISNULL(OldPrice, 0) FROM [dbo].[ProductHistory] WHERE ProductId = @ProductId AND Action = 'DELETE' ORDER BY ActionDate DESC)) / (TotalProducts - 1)
--             ELSE 0
--         END,
--         LastUpdated = GETDATE()
--     WHERE StatId = 1;
-- COMMIT TRANSACTION;

-- CONVERTED POSTGRESQL:
BEGIN;
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    SELECT productid, 'DELETE', price, NULL, stockquantity, NULL, clock_timestamp()
    FROM productmanagement_dbo.products
    WHERE productid = @ProductId;
    
    DELETE FROM productmanagement_dbo.products 
    WHERE productid = @ProductId;
    
    UPDATE productmanagement_dbo.productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - (SELECT COALESCE(oldprice, 0) FROM productmanagement_dbo.producthistory WHERE productid = @ProductId AND action = 'DELETE' ORDER BY actiondate DESC LIMIT 1)) / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = clock_timestamp()
    WHERE statid = 1;
COMMIT;

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- Source: DataAccess/ProductRepository.cs, Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- conversion_method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: Metadata model creation did not complete after 15 attempts
-- ============================================================================

-- ORIGINAL MS SQL:
-- WITH rankedproducts AS (
--     SELECT 
--         p.*,
--         RANK() OVER (ORDER BY p.Price) as PriceRank,
--         PERCENT_RANK() OVER (ORDER BY p.Price) as PricePercentile
--     FROM [dbo].[Products] p
--     WHERE p.Price BETWEEN @MinPrice AND @MaxPrice
-- )
-- SELECT 
--     rp.*,
--     CASE 
--         WHEN rp.PricePercentile <= 0.25 THEN 'Budget'
--         WHEN rp.PricePercentile <= 0.75 THEN 'Mid-Range'
--         ELSE 'Premium'
--     END as PriceSegment
-- FROM rankedproducts rp
-- ORDER BY rp.PriceRank

-- CONVERTED POSTGRESQL:
WITH rankedproducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.price) as pricerank,
        PERCENT_RANK() OVER (ORDER BY p.price) as pricepercentile
    FROM productmanagement_dbo.products p
    WHERE p.price BETWEEN @MinPrice AND @MaxPrice
)
SELECT 
    rp.*,
    CASE 
        WHEN rp.pricepercentile <= 0.25 THEN 'Budget'
        WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range'
        ELSE 'Premium'
    END as pricesegment
FROM rankedproducts rp
ORDER BY rp.pricerank;

-- ============================================================================
-- STATEMENT 7: GetLowStockProductsAsync
-- Source: DataAccess/ProductRepository.cs, Method: GetLowStockProductsAsync(int threshold)
-- conversion_method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: Metadata model creation did not complete after 15 attempts
-- ============================================================================

-- ORIGINAL MS SQL:
-- WITH stockanalysis AS (
--     SELECT 
--         p.*,
--         AVG(StockQuantity) OVER() as AvgStock,
--         MIN(StockQuantity) OVER() as MinStock,
--         MAX(StockQuantity) OVER() as MaxStock
--     FROM [dbo].[Products] p
-- )
-- SELECT 
--     sa.*,
--     CASE 
--         WHEN StockQuantity <= @Threshold THEN 'Critical'
--         WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low'
--         ELSE 'Adequate'
--     END as StockStatus,
--     ROUND(CAST(StockQuantity AS NUMERIC) / AvgStock * 100, 2) as StockPercentageOfAverage
-- FROM stockanalysis sa
-- WHERE StockQuantity <= @Threshold
-- ORDER BY StockQuantity

-- CONVERTED POSTGRESQL:
WITH stockanalysis AS (
    SELECT 
        p.*,
        AVG(stockquantity) OVER() as avgstock,
        MIN(stockquantity) OVER() as minstock,
        MAX(stockquantity) OVER() as maxstock
    FROM productmanagement_dbo.products p
)
SELECT 
    sa.*,
    CASE 
        WHEN stockquantity <= @Threshold THEN 'Critical'
        WHEN stockquantity <= avgstock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as stockstatus,
    ROUND(CAST(stockquantity AS NUMERIC) / avgstock * 100, 2) as stockpercentageofaverage
FROM stockanalysis sa
WHERE stockquantity <= @Threshold
ORDER BY stockquantity;
