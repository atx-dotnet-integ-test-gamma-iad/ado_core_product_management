-- ============================================================================
-- CONVERTED SQL STATEMENTS CATALOG (PostgreSQL)
-- Source: DataAccess/ProductRepository.cs
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: AccessDeniedException - dms:StartMetadataModelCreation not authorized
-- Total Statements: 7
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync (Line ~42-70)
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: All schema objects converted to lowercase
-- ============================================================================
                WITH productstats AS (
                    SELECT 
                        productid,
                        AVG(price) OVER() as avgprice,
                        COUNT(*) OVER() as totalproducts
                    FROM products
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
                    ROUND((p.price / ps.avgprice) * 100, 2) as pricepercentageofaverage
                FROM products p
                INNER JOIN productstats ps ON p.productid = ps.productid
                ORDER BY 
                    CASE 
                        WHEN p.price > ps.avgprice THEN 1
                        ELSE 2
                    END,
                    p.name;

-- ============================================================================
-- STATEMENT 2: GetProductByIdAsync (Line ~77-100)
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: All schema objects converted to lowercase
-- ============================================================================
                WITH producthistory AS (
                    SELECT 
                        productid,
                        LAG(price) OVER (ORDER BY modifieddate) as previousprice,
                        LAG(stockquantity) OVER (ORDER BY modifieddate) as previousstock
                    FROM products
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
                FROM products p
                LEFT JOIN producthistory ph ON p.productid = ph.productid
                WHERE p.productid = @ProductId;

-- ============================================================================
-- STATEMENT 3: InsertProductAsync (Line ~115-136)
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: SCOPE_IDENTITY() -> RETURNING, GETDATE() -> NOW(), DECLARE/SET -> DO block with RETURNING,
--          All schema objects converted to lowercase
-- ============================================================================
                INSERT INTO products (name, description, price, stockquantity)
                VALUES (@Name, @Description, @Price, @StockQuantity)
                RETURNING productid;

-- NOTE: The transaction block with SCOPE_IDENTITY() pattern is restructured for PostgreSQL.
-- The INSERT with RETURNING provides the new ID directly.
-- The ProductHistory insert and ProductStats update are handled as separate statements 
-- in the C# code since PostgreSQL does not support multi-statement batches with DECLARE in a single command string the same way.
-- For the C# integration, we split into individual statements executed within a transaction.

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync (Line ~151-178)
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: GETDATE() -> NOW(), DECLARE/SET variable pattern -> separate SELECT,
--          All schema objects converted to lowercase
-- ============================================================================
-- PostgreSQL version uses separate statements within a C# transaction:
-- Statement 4a: Get old values
                SELECT price, stockquantity
                FROM products
                WHERE productid = @ProductId;

-- Statement 4b: Update the product
                UPDATE products
                SET 
                    name = @Name,
                    description = @Description,
                    price = @Price,
                    stockquantity = @StockQuantity,
                    modifieddate = NOW()
                WHERE productid = @ProductId;

-- Statement 4c: Log the changes
                INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());

-- Statement 4d: Update product statistics
                UPDATE productstats
                SET 
                    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
                    lastupdated = NOW()
                WHERE statid = 1;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync (Line ~192-219)
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: GETDATE() -> NOW(), DECLARE/SET variable pattern -> separate SELECT,
--          All schema objects converted to lowercase
-- ============================================================================
-- PostgreSQL version uses separate statements within a C# transaction:
-- Statement 5a: Get old values
                SELECT price, stockquantity
                FROM products
                WHERE productid = @ProductId;

-- Statement 5b: Log the deletion
                INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());

-- Statement 5c: Delete the product
                DELETE FROM products 
                WHERE productid = @ProductId;

-- Statement 5d: Update product statistics
                UPDATE productstats
                SET 
                    totalproducts = totalproducts - 1,
                    averageprice = CASE 
                        WHEN totalproducts > 1 
                        THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
                        ELSE 0
                    END,
                    lastupdated = NOW()
                WHERE statid = 1;

-- ============================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (Line ~230-250)
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: All schema objects converted to lowercase
-- ============================================================================
                WITH rankedproducts AS (
                    SELECT 
                        p.*,
                        RANK() OVER (ORDER BY p.price) as pricerank,
                        PERCENT_RANK() OVER (ORDER BY p.price) as pricepercentile
                    FROM products p
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
-- STATEMENT 7: GetLowStockProductsAsync (Line ~264-284)
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: All schema objects converted to lowercase, CAST for integer division
-- ============================================================================
                WITH stockanalysis AS (
                    SELECT 
                        p.*,
                        AVG(stockquantity) OVER() as avgstock,
                        MIN(stockquantity) OVER() as minstock,
                        MAX(stockquantity) OVER() as maxstock
                    FROM products p
                )
                SELECT 
                    sa.*,
                    CASE 
                        WHEN stockquantity <= @Threshold THEN 'Critical'
                        WHEN stockquantity <= avgstock * 0.5 THEN 'Low'
                        ELSE 'Adequate'
                    END as stockstatus,
                    ROUND((CAST(stockquantity AS DECIMAL) / avgstock) * 100, 2) as stockpercentageofaverage
                FROM stockanalysis sa
                WHERE stockquantity <= @Threshold
                ORDER BY stockquantity;
