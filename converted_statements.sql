-- ============================================================================
-- Converted SQL Statements (PostgreSQL) from DataAccess/ProductRepository.cs
-- Source: MS SQL Server → Target: PostgreSQL
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Schema Mapping Source: DMS schema_mapping_tool (productmanagement_dbo schema)
-- Total Statements: 7
-- ============================================================================

-- ============================================================================
-- Statement 1: GetAllProductsAsync() [CONVERTED]
-- Source: DataAccess/ProductRepository.cs
-- Conversion: Lowercase schema objects per DMS schema mapping
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
                    ROUND((p.price / ps.avgprice * 100)::numeric, 2) as pricepercentageofaverage
                FROM products p
                INNER JOIN productstats ps ON p.productid = ps.productid
                ORDER BY 
                    CASE 
                        WHEN p.price > ps.avgprice THEN 1
                        ELSE 2
                    END,
                    p.name;

-- ============================================================================
-- Statement 2: GetProductByIdAsync() [CONVERTED]
-- Source: DataAccess/ProductRepository.cs
-- Conversion: Lowercase schema objects, ROUND cast to numeric
-- Parameters: @ProductId (int)
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
                            ROUND(((p.price - ph.previousprice) / ph.previousprice * 100)::numeric, 2)
                        ELSE NULL
                    END as pricechangepercentage
                FROM products p
                LEFT JOIN producthistory ph ON p.productid = ph.productid
                WHERE p.productid = @ProductId;

-- ============================================================================
-- Statement 3: InsertProductAsync() [CONVERTED]
-- Source: DataAccess/ProductRepository.cs
-- Conversion: SCOPE_IDENTITY() → RETURNING, GETDATE() → clock_timestamp(),
--             Transaction block → CTE with RETURNING, lowercase schema
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- ============================================================================

                WITH new_product AS (
                    INSERT INTO products (name, description, price, stockquantity)
                    VALUES (@Name, @Description, @Price, @StockQuantity)
                    RETURNING productid
                ),
                log_insert AS (
                    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    SELECT productid, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp()
                    FROM new_product
                ),
                update_stats AS (
                    UPDATE productstats
                    SET 
                        totalproducts = totalproducts + 1,
                        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
                        lastupdated = clock_timestamp()
                    WHERE statid = 1
                )
                SELECT productid FROM new_product;

-- ============================================================================
-- Statement 4: UpdateProductAsync() [CONVERTED]
-- Source: DataAccess/ProductRepository.cs
-- Conversion: DECLARE/SET → CTE subqueries, GETDATE() → clock_timestamp(),
--             Transaction block → CTE chain, lowercase schema
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- ============================================================================

                WITH old_values AS (
                    SELECT price as oldprice, stockquantity as oldstock
                    FROM products
                    WHERE productid = @ProductId
                ),
                do_update AS (
                    UPDATE products
                    SET 
                        name = @Name,
                        description = @Description,
                        price = @Price,
                        stockquantity = @StockQuantity,
                        modifieddate = clock_timestamp()
                    WHERE productid = @ProductId
                    RETURNING productid
                ),
                log_update AS (
                    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    SELECT @ProductId, 'UPDATE', oldprice, @Price, oldstock, @StockQuantity, clock_timestamp()
                    FROM old_values
                )
                UPDATE productstats
                SET 
                    averageprice = (averageprice * totalproducts - (SELECT oldprice FROM old_values) + @Price) / totalproducts,
                    lastupdated = clock_timestamp()
                WHERE statid = 1;

-- ============================================================================
-- Statement 5: DeleteProductAsync() [CONVERTED]
-- Source: DataAccess/ProductRepository.cs
-- Conversion: DECLARE/SET → CTE subqueries, GETDATE() → clock_timestamp(),
--             Transaction block → CTE chain, lowercase schema
-- Parameters: @ProductId
-- ============================================================================

                WITH old_values AS (
                    SELECT price as oldprice, stockquantity as oldstock
                    FROM products
                    WHERE productid = @ProductId
                ),
                log_delete AS (
                    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    SELECT @ProductId, 'DELETE', oldprice, NULL, oldstock, NULL, clock_timestamp()
                    FROM old_values
                ),
                do_delete AS (
                    DELETE FROM products 
                    WHERE productid = @ProductId
                )
                UPDATE productstats
                SET 
                    totalproducts = totalproducts - 1,
                    averageprice = CASE 
                        WHEN totalproducts > 1 
                        THEN (averageprice * totalproducts - (SELECT oldprice FROM old_values)) / (totalproducts - 1)
                        ELSE 0
                    END,
                    lastupdated = clock_timestamp()
                WHERE statid = 1;

-- ============================================================================
-- Statement 6: GetProductsByPriceRangeAsync() [CONVERTED]
-- Source: DataAccess/ProductRepository.cs
-- Conversion: Lowercase schema objects
-- Parameters: @MinPrice, @MaxPrice
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
-- Statement 7: GetLowStockProductsAsync() [CONVERTED]
-- Source: DataAccess/ProductRepository.cs
-- Conversion: Lowercase schema objects, ROUND cast to numeric
-- Parameters: @Threshold
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
                    ROUND((stockquantity::numeric / avgstock * 100)::numeric, 2) as stockpercentageofaverage
                FROM stockanalysis sa
                WHERE stockquantity <= @Threshold
                ORDER BY stockquantity;

-- ============================================================================
-- END OF CONVERTED STATEMENTS
-- Total: 7 SQL statement blocks converted
-- All conversions: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- ============================================================================
