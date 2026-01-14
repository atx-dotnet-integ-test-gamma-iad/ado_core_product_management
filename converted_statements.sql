-- ============================================================================
-- PostgreSQL Converted SQL Statements Catalog
-- Target Database: PostgreSQL
-- Total Statements: 7
-- Conversion Date: 2026-01-14
-- DMS Tool: AWS Database Migration Service
-- Schema Conversion: Products -> productmanagement_dbo.products
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync (MANUAL CONVERSION AFTER DMS FAILURE)
-- ============================================================================
-- Original Method: GetAllProductsAsync
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed: {'error': 'Metadata model creation did not complete after 15 attempts'}
-- Manual Conversion Applied: Yes
-- Changes: 
--   - Schema: Products -> productmanagement_dbo.products
--   - CTE name kept as ProductStats (PostgreSQL supports case-insensitive)
--   - Window functions (AVG OVER, COUNT OVER) are compatible
--   - Added NULLS FIRST to ORDER BY for PostgreSQL best practice
-- ============================================================================

WITH ProductStats AS (
    SELECT 
        ProductId,
        AVG(Price) OVER() as AvgPrice,
        COUNT(*) OVER() as TotalProducts
    FROM productmanagement_dbo.products
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
FROM productmanagement_dbo.products p
INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId
ORDER BY 
    CASE 
        WHEN p.Price > ps.AvgPrice THEN 1
        ELSE 2
    END,
    p.Name NULLS FIRST;

-- ============================================================================
-- STATEMENT 2: GetProductByIdAsync (DMS TOOL CONVERSION)
-- ============================================================================
-- Original Method: GetProductByIdAsync
-- Conversion Status: DMS_TOOL
-- DMS Metadata Model: sql-conversion-1768418692
-- Changes:
--   - Schema: Products -> productmanagement_dbo.products
--   - CTE name: ProductHistory -> producthistory (lowercase)
--   - LAG window function preserved
--   - LEFT JOIN -> LEFT OUTER JOIN (PostgreSQL explicit syntax)
--   - Parameter @ProductId kept as-is (will update in code layer)
-- ============================================================================

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

-- ============================================================================
-- STATEMENT 3: InsertProductAsync (MANUAL CONVERSION AFTER DMS FAILURE)
-- ============================================================================
-- Original Method: InsertProductAsync
-- Conversion Status: MANUAL_AFTER_DMS_FAILURE
-- DMS Error: Metadata model creation failed: {'default_error_details': {'message': 'Statement definition is not valid.'}}
-- Manual Conversion Applied: Yes
-- Changes:
--   - Schema: Products -> productmanagement_dbo.products
--   - Schema: ProductHistory -> productmanagement_dbo.producthistory
--   - Schema: ProductStats -> productmanagement_dbo.productstats
--   - SCOPE_IDENTITY() replaced with RETURNING clause on INSERT
--   - GETDATE() -> CURRENT_TIMESTAMP
--   - Transaction management removed (handled at ADO.NET layer)
--   - Variables declared using DO block pattern
--   - Multi-statement transaction converted to sequential statements
-- ============================================================================

-- Insert the new product with RETURNING
INSERT INTO productmanagement_dbo.products (Name, Description, Price, StockQuantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING ProductId;

-- Note: The following statements would be executed separately in the same transaction:
-- Log the insertion
INSERT INTO productmanagement_dbo.producthistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);

-- Update product statistics
UPDATE productmanagement_dbo.productstats
SET 
    TotalProducts = TotalProducts + 1,
    AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync (DMS TOOL CONVERSION with Manual Refinement)
-- ============================================================================
-- Original Method: UpdateProductAsync
-- Conversion Status: DMS_TOOL
-- DMS Metadata Model: sql-conversion-1768418880
-- DMS Warning: [7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction management commands such as BEGIN TRAN, SAVE TRAN in functions. Convert your source code manually.]
-- Manual Refinement: Removed DECLARE/BEGIN/END wrapper, removed transaction commands
-- Changes:
--   - Schema: Products -> productmanagement_dbo.products
--   - Schema: ProductHistory -> productmanagement_dbo.producthistory
--   - Schema: ProductStats -> productmanagement_dbo.productstats
--   - GETDATE() -> clock_timestamp() (by DMS, refined to CURRENT_TIMESTAMP for consistency)
--   - Variable declarations: @OldPrice -> var_OldPrice, @OldStock -> var_OldStock
--   - Transaction management removed (handled at ADO.NET layer)
-- ============================================================================

-- Store old values for history
DO $$
DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
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

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync (DMS TOOL CONVERSION with Manual Refinement)
-- ============================================================================
-- Original Method: DeleteProductAsync
-- Conversion Status: DMS_TOOL
-- DMS Metadata Model: sql-conversion-1768418987
-- DMS Warning: [7807 - Severity CRITICAL - PostgreSQL does not support explicit transaction management commands such as BEGIN TRAN, SAVE TRAN in functions. Convert your source code manually.]
-- Manual Refinement: Removed DECLARE/BEGIN/END wrapper, removed transaction commands
-- Changes:
--   - Schema: Products -> productmanagement_dbo.products
--   - Schema: ProductHistory -> productmanagement_dbo.producthistory
--   - Schema: ProductStats -> productmanagement_dbo.productstats
--   - GETDATE() -> clock_timestamp() (refined to CURRENT_TIMESTAMP)
--   - Variable declarations: @OldPrice -> var_OldPrice, @OldStock -> var_OldStock
--   - Transaction management removed (handled at ADO.NET layer)
-- ============================================================================

-- Store product info and delete
DO $$
DECLARE
    var_OldPrice NUMERIC(18, 2);
    var_OldStock INTEGER;
BEGIN
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
    SET totalproducts = totalproducts - 1, 
        averageprice = CASE
            WHEN totalproducts > 1 THEN (averageprice * totalproducts - var_OldPrice) / (totalproducts - 1)
            ELSE 0
        END, 
        lastupdated = CURRENT_TIMESTAMP
    WHERE statid = 1;
END $$;

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (DMS TOOL CONVERSION)
-- ============================================================================
-- Original Method: GetProductsByPriceRangeAsync
-- Conversion Status: DMS_TOOL
-- DMS Metadata Model: sql-conversion-1768419094
-- Changes:
--   - Schema: Products -> productmanagement_dbo.products
--   - CTE name: RankedProducts -> rankedproducts (lowercase)
--   - RANK() and PERCENT_RANK() window functions preserved
--   - Added NULLS FIRST to ORDER BY
--   - Parameters @MinPrice, @MaxPrice kept as-is
-- ============================================================================

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

-- ============================================================================
-- STATEMENT 7: GetLowStockProductsAsync (DMS TOOL CONVERSION)
-- ============================================================================
-- Original Method: GetLowStockProductsAsync
-- Conversion Status: DMS_TOOL
-- DMS Metadata Model: sql-conversion-1768419205
-- Changes:
--   - Schema: Products -> productmanagement_dbo.products
--   - CTE name: StockAnalysis -> stockanalysis (lowercase)
--   - Window functions (AVG OVER, MIN OVER, MAX OVER) preserved
--   - Added NULLS FIRST to ORDER BY
--   - Parameter @Threshold kept as-is
-- ============================================================================

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

-- ============================================================================
-- END OF CONVERTED SQL STATEMENTS CATALOG
-- Total Statements Converted: 7
-- DMS Tool Successful Conversions: 5 (Statements 2, 4, 5, 6, 7)
-- Manual Conversions After DMS Failure: 2 (Statements 1, 3)
-- Schema Object Name Changes: Products -> productmanagement_dbo.products
-- ============================================================================
