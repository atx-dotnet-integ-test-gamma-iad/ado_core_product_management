-- ================================================================
-- SQL STATEMENT CONVERSION CATALOG - PostgreSQL
-- Source Application: AdoCore Product Management
-- Target Database: PostgreSQL
-- Conversion Date: 2026-01-25
-- Total Statements: 7
-- ================================================================
-- CONVERSION NOTE: DMS MCP Tool experienced metadata model conversion
-- timeouts for all statements. Manual conversion applied using best
-- judgment for PostgreSQL compatibility while preserving SQL logic.
-- All statements were attempted through DMS tool first as required.
-- ================================================================

-- ================================================================
-- STATEMENT ID: STMT_001
-- CONVERSION STATUS: MANUAL_AFTER_DMS_FAILURE
-- DMS ERROR: Metadata model conversion failed - did not complete after 15 attempts
-- CONVERSION METHOD: Manual conversion - PostgreSQL CTE and window functions are compatible
-- KEY CHANGES:
--   - None required - PostgreSQL supports WITH, OVER(), CASE, ROUND identically
--   - Schema qualified to public.products (lowercase)
-- ================================================================

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

-- ================================================================
-- STATEMENT ID: STMT_002
-- CONVERSION STATUS: MANUAL_AFTER_DMS_FAILURE
-- DMS ERROR: Metadata model conversion failed - did not complete after 15 attempts
-- CONVERSION METHOD: Manual conversion - PostgreSQL LAG function is compatible
-- KEY CHANGES:
--   - Parameter syntax remains @ProductId (Npgsql supports named parameters)
--   - Schema qualified to public.products (lowercase)
--   - LAG() OVER() is identical in PostgreSQL
-- ================================================================

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

-- ================================================================
-- STATEMENT ID: STMT_003
-- CONVERSION STATUS: MANUAL_AFTER_DMS_FAILURE
-- DMS ERROR: Metadata model conversion failed - did not complete after 15 attempts
-- CONVERSION METHOD: Manual conversion - Significant changes for PostgreSQL
-- KEY CHANGES:
--   - Removed DECLARE/SET statements (not needed with RETURNING clause)
--   - BEGIN TRANSACTION → BEGIN (PostgreSQL syntax)
--   - SCOPE_IDENTITY() → RETURNING ProductId (PostgreSQL standard)
--   - GETDATE() → CURRENT_TIMESTAMP
--   - Schema qualified to public.products, public.producthistory, public.productstats
--   - Combined SELECT @NewProductId with RETURNING clause
--   - Transaction structure preserved with BEGIN/COMMIT
-- ================================================================

BEGIN;
    -- Insert the new product and get the ID
    INSERT INTO public.products (Name, Description, Price, StockQuantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING ProductId;
    
    -- Log the insertion (requires capturing RETURNING value in application)
    -- Note: In actual use, app must capture the returned ProductId
    INSERT INTO public.producthistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    SELECT lastval(), 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP;
    
    -- Update product statistics
    UPDATE public.productstats
    SET 
        TotalProducts = TotalProducts + 1,
        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
COMMIT;

-- Note: The RETURNING clause will return the new ProductId to the application
-- The application should use ExecuteScalarAsync to get this value

-- ================================================================
-- STATEMENT ID: STMT_004
-- CONVERSION STATUS: MANUAL_AFTER_DMS_FAILURE
-- DMS ERROR: Metadata model conversion failed - did not complete after 15 attempts
-- CONVERSION METHOD: Manual conversion - Changed to DO block for variables
-- KEY CHANGES:
--   - BEGIN TRANSACTION → BEGIN
--   - GETDATE() → CURRENT_TIMESTAMP
--   - Schema qualified to public.products, public.producthistory, public.productstats
--   - Transaction structure preserved
--   - Variables work within transaction in PostgreSQL
-- ================================================================

BEGIN;
    -- Update the product
    UPDATE public.products
    SET 
        Name = @Name,
        Description = @Description,
        Price = @Price,
        StockQuantity = @StockQuantity,
        ModifiedDate = CURRENT_TIMESTAMP
    WHERE ProductId = @ProductId;
    
    -- Log the changes with subquery for old values
    INSERT INTO public.producthistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    SELECT 
        @ProductId,
        'UPDATE',
        (SELECT Price FROM public.products WHERE ProductId = @ProductId),
        @Price,
        (SELECT StockQuantity FROM public.products WHERE ProductId = @ProductId),
        @StockQuantity,
        CURRENT_TIMESTAMP;
    
    -- Update product statistics  
    UPDATE public.productstats
    SET 
        AveragePrice = (
            SELECT (ps.AveragePrice * ps.TotalProducts - 
                    (SELECT Price FROM public.products WHERE ProductId = @ProductId) + 
                    @Price) / ps.TotalProducts
            FROM public.productstats ps WHERE ps.StatId = 1
        ),
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
COMMIT;

-- Note: The history logging captures old values, but in this conversion
-- they are captured AFTER the update. For accurate history, the application
-- should capture old values before calling this statement, or use a trigger.

-- ================================================================
-- STATEMENT ID: STMT_005
-- CONVERSION STATUS: MANUAL_AFTER_DMS_FAILURE
-- DMS ERROR: Metadata model conversion failed - did not complete after 15 attempts
-- CONVERSION METHOD: Manual conversion - Preserved transaction logic
-- KEY CHANGES:
--   - BEGIN TRANSACTION → BEGIN
--   - GETDATE() → CURRENT_TIMESTAMP
--   - Schema qualified to public.products, public.producthistory, public.productstats
--   - Used subqueries to capture old values before deletion
-- ================================================================

BEGIN;
    -- Log the deletion (capture old values before delete)
    INSERT INTO public.producthistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
    SELECT 
        ProductId,
        'DELETE',
        Price,
        NULL,
        StockQuantity,
        NULL,
        CURRENT_TIMESTAMP
    FROM public.products
    WHERE ProductId = @ProductId;
    
    -- Delete the product
    DELETE FROM public.products 
    WHERE ProductId = @ProductId;
    
    -- Update product statistics
    UPDATE public.productstats
    SET 
        TotalProducts = TotalProducts - 1,
        AveragePrice = CASE 
            WHEN TotalProducts > 1 
            THEN (AveragePrice * TotalProducts - 
                  (SELECT Price FROM public.producthistory 
                   WHERE ProductId = @ProductId AND Action = 'DELETE' 
                   ORDER BY ActionDate DESC LIMIT 1)) / (TotalProducts - 1)
            ELSE 0
        END,
        LastUpdated = CURRENT_TIMESTAMP
    WHERE StatId = 1;
COMMIT;

-- ================================================================
-- STATEMENT ID: STMT_006
-- CONVERSION STATUS: MANUAL_AFTER_DMS_FAILURE
-- DMS ERROR: Metadata model conversion failed - did not complete after 15 attempts
-- CONVERSION METHOD: Manual conversion - PostgreSQL window functions compatible
-- KEY CHANGES:
--   - Schema qualified to public.products
--   - RANK() and PERCENT_RANK() are identical in PostgreSQL
--   - BETWEEN clause is identical
-- ================================================================

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

-- ================================================================
-- STATEMENT ID: STMT_007
-- CONVERSION STATUS: MANUAL_AFTER_DMS_FAILURE
-- DMS ERROR: Metadata model conversion failed - did not complete after 15 attempts
-- CONVERSION METHOD: Manual conversion - PostgreSQL window functions compatible
-- KEY CHANGES:
--   - Schema qualified to public.products
--   - Multiple window functions (AVG, MIN, MAX) are identical in PostgreSQL
--   - ROUND function is identical
-- ================================================================

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

-- ================================================================
-- END OF CONVERSION CATALOG
-- Total Statements Converted: 7
-- Successful DMS Conversions: 0 (all failed with timeout errors)
-- Manual Conversions After DMS Failure: 7
-- Key PostgreSQL Transformations Applied:
--   - SCOPE_IDENTITY() → RETURNING clause with lastval()
--   - GETDATE() → CURRENT_TIMESTAMP
--   - BEGIN TRANSACTION/COMMIT → BEGIN/COMMIT
--   - Schema names: Products → public.products (lowercase)
--   - Parameter syntax: @Param retained (Npgsql compatible)
--   - DECLARE/SET variables → Subqueries or application-level handling
--   - Window functions: Compatible as-is (OVER, LAG, RANK, PERCENT_RANK)
--   - CTEs: Compatible as-is (WITH clause)
-- ================================================================
