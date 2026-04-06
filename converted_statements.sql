-- =============================================
-- CONVERTED SQL STATEMENTS FOR PostgreSQL (Npgsql-compatible)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Error: Metadata model creation/conversion did not complete after multiple attempts
-- These statements are designed to be executed via Npgsql ADO.NET from C#
-- =============================================

-- Statement 1: GetAllProductsAsync (PostgreSQL)
-- Changes: All identifiers lowercase, syntax compatible with PostgreSQL
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

-- =============================================

-- Statement 2: GetProductByIdAsync (PostgreSQL)
-- Changes: All identifiers lowercase
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

-- =============================================

-- Statement 3: InsertProductAsync (PostgreSQL)
-- Changes: SCOPE_IDENTITY() -> RETURNING; GETDATE() -> NOW(); 
-- Transaction managed at C# level via NpgsqlTransaction
-- Multi-statement batch for Npgsql
                INSERT INTO products (name, description, price, stockquantity)
                VALUES (@Name, @Description, @Price, @StockQuantity);

                INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                VALUES (lastval(), 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

                UPDATE productstats
                SET 
                    totalproducts = totalproducts + 1,
                    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
                    lastupdated = NOW()
                WHERE statid = 1;

                SELECT lastval();

-- =============================================

-- Statement 4: UpdateProductAsync (PostgreSQL)
-- Changes: DECLARE/SET variable pattern replaced with subqueries;
-- GETDATE() -> NOW(); Transaction managed at C# level
                UPDATE products
                SET 
                    name = @Name,
                    description = @Description,
                    price = @Price,
                    stockquantity = @StockQuantity,
                    modifieddate = NOW()
                WHERE productid = @ProductId;

                INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                SELECT @ProductId, 'UPDATE', 
                    (SELECT price FROM products WHERE productid = @ProductId),
                    @Price,
                    (SELECT stockquantity FROM products WHERE productid = @ProductId),
                    @StockQuantity, NOW();

                UPDATE productstats
                SET 
                    averageprice = (averageprice * totalproducts - (SELECT price FROM products WHERE productid = @ProductId) + @Price) / totalproducts,
                    lastupdated = NOW()
                WHERE statid = 1;

-- =============================================

-- Statement 5: DeleteProductAsync (PostgreSQL)
-- Changes: DECLARE/SET variable pattern replaced with subqueries;
-- GETDATE() -> NOW(); Transaction managed at C# level
                INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                SELECT @ProductId, 'DELETE', price, NULL, stockquantity, NULL, NOW()
                FROM products WHERE productid = @ProductId;

                DELETE FROM products 
                WHERE productid = @ProductId;

                UPDATE productstats
                SET 
                    totalproducts = totalproducts - 1,
                    averageprice = CASE 
                        WHEN totalproducts > 1 
                        THEN (averageprice * totalproducts - (SELECT oldprice FROM producthistory WHERE productid = @ProductId AND action = 'DELETE' ORDER BY actiondate DESC LIMIT 1)) / (totalproducts - 1)
                        ELSE 0
                    END,
                    lastupdated = NOW()
                WHERE statid = 1;

-- =============================================

-- Statement 6: GetProductsByPriceRangeAsync (PostgreSQL)
-- Changes: All identifiers lowercase
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

-- =============================================

-- Statement 7: GetLowStockProductsAsync (PostgreSQL)
-- Changes: All identifiers lowercase; CAST for proper decimal division
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
                    ROUND(CAST(stockquantity AS NUMERIC) / CAST(avgstock AS NUMERIC) * 100, 2) as stockpercentageofaverage
                FROM stockanalysis sa
                WHERE stockquantity <= @Threshold
                ORDER BY stockquantity;
