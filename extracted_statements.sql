-- ============================================================================
-- EXTRACTED SQL STATEMENTS CATALOG
-- Source: DataAccess/ProductRepository.cs
-- Purpose: Comprehensive catalog of all SQL statements for DMS conversion
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetAllProductsAsync
-- Line Number: ~44-71
-- Statement Type: SELECT with CTE and Window Functions
-- Parameters: None
-- ============================================================================
WITH ProductStats AS (
    SELECT 
        ProductId,
        AVG(Price) OVER() as AvgPrice,
        COUNT(*) OVER() as TotalProducts
    FROM public.products
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
FROM public.products p
INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId
ORDER BY 
    CASE 
        WHEN p.Price > ps.AvgPrice THEN 1
        ELSE 2
    END,
    p.Name;

-- ============================================================================
-- STATEMENT 2: GetProductByIdAsync
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductByIdAsync
-- Line Number: ~86-113
-- Statement Type: SELECT with CTE, Window Functions (LAG), and Parameters
-- Parameters: @ProductId (int)
-- ============================================================================
WITH ProductHistory AS (
    SELECT 
        ProductId,
        LAG(Price) OVER (ORDER BY ModifiedDate) as PreviousPrice,
        LAG(StockQuantity) OVER (ORDER BY ModifiedDate) as PreviousStock
    FROM public.products
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
FROM public.products p
LEFT JOIN ProductHistory ph ON p.ProductId = ph.ProductId
WHERE p.ProductId = @ProductId;

-- ============================================================================
-- STATEMENT 3: InsertProductAsync
-- Source File: DataAccess/ProductRepository.cs
-- Method: InsertProductAsync
-- Line Number: ~123-148
-- Statement Type: Transaction with INSERT, SCOPE_IDENTITY(), and NOW()
-- Parameters: @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
-- SQL Server Specific: DECLARE, BEGIN/COMMIT, SCOPE_IDENTITY(), NOW()
-- ============================================================================
DECLARE @NewProductId INT;

BEGIN;
    -- Insert the new product
    INSERT INTO public.products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity);
    
    SET @NewProductId = SCOPE_IDENTITY();
    
    -- Log the insertion
    INSERT INTO public.producthistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());
    
    -- Update product statistics
    UPDATE public.productstats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = NOW()
    WHERE StatId = 1;
COMMIT;

SELECT @NewProductId;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync
-- Source File: DataAccess/ProductRepository.cs
-- Method: UpdateProductAsync
-- Line Number: ~160-189
-- Statement Type: Transaction with UPDATE, DECLARE, and NOW()
-- Parameters: @ProductId (int), @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
-- SQL Server Specific: DECLARE, BEGIN/COMMIT, NOW()
-- ============================================================================
BEGIN;
    -- Store old values for history
    DECLARE @OldPrice DECIMAL(18,2);
    DECLARE @OldStock INT;
    
    SELECT @OldPrice = Price, @OldStock = StockQuantity
    FROM public.products
    WHERE ProductId = @ProductId;
    
    -- Update the product
    UPDATE public.products
    SET 
        Name = @Name,
        Description = @Description,
        Price = @Price,
        StockQuantity = @StockQuantity,
        ModifiedDate = NOW()
    WHERE ProductId = @ProductId;
    
    -- Log the changes
    INSERT INTO public.producthistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());
    
    -- Update product statistics
    UPDATE public.productstats
    SET 
        AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
        LastUpdated = NOW()
    WHERE StatId = 1;
COMMIT;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync
-- Source File: DataAccess/ProductRepository.cs
-- Method: DeleteProductAsync
-- Line Number: ~201-228
-- Statement Type: Transaction with DELETE, DECLARE, and NOW()
-- Parameters: @ProductId (int)
-- SQL Server Specific: DECLARE, BEGIN/COMMIT, NOW()
-- ============================================================================
BEGIN;
    -- Store product info for history
    DECLARE @OldPrice DECIMAL(18,2);
    DECLARE @OldStock INT;
    
    SELECT @OldPrice = Price, @OldStock = StockQuantity
    FROM public.products
    WHERE ProductId = @ProductId;
    
    -- Log the deletion
    INSERT INTO public.producthistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());
    
    -- Delete the product
    DELETE FROM public.products 
    WHERE ProductId = @ProductId;
    
    -- Update product statistics
    UPDATE public.productstats
    SET 
        TotalProducts = TotalProducts - 1,
        AveragePrice = CASE 
            WHEN TotalProducts > 1 
            THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1)
            ELSE 0
        END,
        LastUpdated = NOW()
    WHERE StatId = 1;
COMMIT;

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetProductsByPriceRangeAsync
-- Line Number: ~240-261
-- Statement Type: SELECT with CTE, Window Functions (RANK, PERCENT_RANK), and Parameters
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
-- ============================================================================
WITH RankedProducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.Price) as PriceRank,
        PERCENT_RANK() OVER (ORDER BY p.Price) as PricePercentile
    FROM public.products p
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
-- STATEMENT 7: GetLowStockProductsAsync
-- Source File: DataAccess/ProductRepository.cs
-- Method: GetLowStockProductsAsync
-- Line Number: ~273-294
-- Statement Type: SELECT with CTE, Window Functions (AVG, MIN, MAX), and Parameters
-- Parameters: @Threshold (int)
-- ============================================================================
WITH StockAnalysis AS (
    SELECT 
        p.*,
        AVG(StockQuantity) OVER() as AvgStock,
        MIN(StockQuantity) OVER() as MinStock,
        MAX(StockQuantity) OVER() as MaxStock
    FROM public.products p
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

-- ============================================================================
-- END OF EXTRACTED STATEMENTS CATALOG
-- Total Statements: 7
-- SQL Server Specific Features Identified:
--   - DECLARE variables (statements 3, 4, 5)
--   - BEGIN/COMMIT transactions (statements 3, 4, 5)
--   - SCOPE_IDENTITY() (statement 3)
--   - NOW() function (statements 3, 4, 5)
--   - @parameter syntax (statements 2, 3, 4, 5, 6, 7)
-- ============================================================================
