-- ============================================================
-- CONVERTED SQL STATEMENTS FOR PostgreSQL
-- Converted from MS SQL Server using DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Statement Conversion Tool failed for all 7 statements (metadata model creation/conversion timeout)
-- Schema mapping obtained from DMS Schema Mapping Tool:
--   Products -> products (schema: productmanagement_dbo)
--   ProductHistory -> producthistory (schema: productmanagement_dbo)
--   ProductStats -> productstats (schema: productmanagement_dbo)
--   All column names converted to lowercase per DMS schema mapping
--
-- Note: For transactional statements (3,4,5), the original T-SQL used DECLARE variables
-- and inline transactions. In PostgreSQL with Npgsql ADO.NET, these are restructured as
-- multiple individual SQL statements executed within a C# managed transaction.
-- ============================================================

-- ============================================================
-- Statement 1: GetAllProductsAsync (converted)
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: Table/column names to lowercase per DMS schema mapping
--          CTE name changed to avoid conflict with productstats table
-- ============================================================
                WITH productstats_cte AS (
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
                INNER JOIN productstats_cte ps ON p.productid = ps.productid
                ORDER BY 
                    CASE 
                        WHEN p.price > ps.avgprice THEN 1
                        ELSE 2
                    END,
                    p.name;

-- ============================================================
-- Statement 2: GetProductByIdAsync (converted)
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: Table/column names to lowercase per DMS schema mapping
--          CTE name changed to avoid conflict with producthistory table
-- ============================================================
                WITH producthistory_cte AS (
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
                LEFT JOIN producthistory_cte ph ON p.productid = ph.productid
                WHERE p.productid = @ProductId;

-- ============================================================
-- Statement 3: InsertProductAsync (converted)
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: SCOPE_IDENTITY() -> RETURNING productid (on the INSERT)
--          GETDATE() -> NOW()
--          DECLARE/BEGIN TRANSACTION/COMMIT -> C# managed transaction with separate statements
--          Table/column names to lowercase per DMS schema mapping
-- Restructured as 3 separate statements executed within C# transaction:
-- ============================================================
-- Statement 3a: Insert product and return new ID
                INSERT INTO products (name, description, price, stockquantity)
                VALUES (@Name, @Description, @Price, @StockQuantity)
                RETURNING productid;

-- Statement 3b: Log the insertion (uses @NewProductId from C# code)
                INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- Statement 3c: Update product statistics
                UPDATE productstats
                SET 
                    totalproducts = totalproducts + 1,
                    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
                    lastupdated = NOW()
                WHERE statid = 1;

-- ============================================================
-- Statement 4: UpdateProductAsync (converted)
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: DECLARE @var / SELECT INTO @var -> SELECT ... as separate query read from C#
--          GETDATE() -> NOW()
--          DECLARE/BEGIN TRANSACTION/COMMIT -> C# managed transaction with separate statements
--          Table/column names to lowercase per DMS schema mapping
-- Restructured as 4 separate statements executed within C# transaction:
-- ============================================================
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

-- ============================================================
-- Statement 5: DeleteProductAsync (converted)
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: DECLARE @var / SELECT INTO @var -> SELECT ... as separate query read from C#
--          GETDATE() -> NOW()
--          CASE expression compatible with PostgreSQL
--          DECLARE/BEGIN TRANSACTION/COMMIT -> C# managed transaction with separate statements
--          Table/column names to lowercase per DMS schema mapping
-- Restructured as 4 separate statements executed within C# transaction:
-- ============================================================
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

-- ============================================================
-- Statement 6: GetProductsByPriceRangeAsync (converted)
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: Table/column names to lowercase per DMS schema mapping
-- ============================================================
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

-- ============================================================
-- Statement 7: GetLowStockProductsAsync (converted)
-- Conversion: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Changes: Table/column names to lowercase per DMS schema mapping
--          ROUND with cast for integer division
-- ============================================================
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
                    ROUND((stockquantity / avgstock) * 100, 2) as stockpercentageofaverage
                FROM stockanalysis sa
                WHERE stockquantity <= @Threshold
                ORDER BY stockquantity;
