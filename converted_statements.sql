-- ================================================================
-- CONVERTED SQL STATEMENTS CATALOG (PostgreSQL)
-- Source: DataAccess/ProductRepository.cs
-- Database: ProductManagement (SQL Server to PostgreSQL Migration)
-- Total Statements: 7
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Metadata model creation failed - service timeout after multiple attempts
-- ================================================================

-- ================================================================
-- STATEMENT 1: GetAllProductsAsync (PostgreSQL)
-- Original Method: GetAllProductsAsync()
-- Conversion: Lowercase schema names, ROUND cast for integer division
-- ================================================================
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

-- ================================================================
-- STATEMENT 2: GetProductByIdAsync (PostgreSQL)
-- Original Method: GetProductByIdAsync(int productId)
-- Conversion: Lowercase schema names, LAG window function (same in PG)
-- ================================================================
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

-- ================================================================
-- STATEMENT 3: InsertProductAsync (PostgreSQL)
-- Original Method: InsertProductAsync(Product product)
-- Conversion: SCOPE_IDENTITY() replaced with lastval(), GETDATE() replaced with NOW(),
--             Removed DECLARE/SET, restructured for PostgreSQL
-- ================================================================
                    -- Insert the new product
                    INSERT INTO products (name, description, price, stockquantity)
                    VALUES (@Name, @Description, @Price, @StockQuantity);
                    
                    -- Log the insertion
                    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    VALUES (lastval(), 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());
                    
                    -- Update product statistics
                    UPDATE productstats
                    SET 
                        totalproducts = totalproducts + 1,
                        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
                        lastupdated = NOW()
                    WHERE statid = 1;
                
                    SELECT lastval();

-- ================================================================
-- STATEMENT 4: UpdateProductAsync (PostgreSQL)
-- Original Method: UpdateProductAsync(Product product)
-- Conversion: DECLARE variables replaced with inline subqueries,
--             GETDATE() replaced with NOW(), lowercase schema names
-- Note: Reordered operations to capture old values via subqueries before update
-- ================================================================
                    -- Log the changes (capture old values before update)
                    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    SELECT @ProductId, 'UPDATE', price, @Price, stockquantity, @StockQuantity, NOW()
                    FROM products WHERE productid = @ProductId;
                    
                    -- Update product statistics (capture old price before update)
                    UPDATE productstats
                    SET 
                        averageprice = (averageprice * totalproducts - (SELECT price FROM products WHERE productid = @ProductId) + @Price) / totalproducts,
                        lastupdated = NOW()
                    WHERE statid = 1;

                    -- Update the product
                    UPDATE products
                    SET 
                        name = @Name,
                        description = @Description,
                        price = @Price,
                        stockquantity = @StockQuantity,
                        modifieddate = NOW()
                    WHERE productid = @ProductId;

-- ================================================================
-- STATEMENT 5: DeleteProductAsync (PostgreSQL)
-- Original Method: DeleteProductAsync(int productId)
-- Conversion: DECLARE variables replaced with inline subqueries,
--             GETDATE() replaced with NOW(), lowercase schema names
-- Note: Reordered - log and stats update happen before delete to capture old values
-- ================================================================
                    -- Log the deletion (must be before DELETE to capture old values)
                    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    SELECT productid, 'DELETE', price, NULL, stockquantity, NULL, NOW()
                    FROM products WHERE productid = @ProductId;
                    
                    -- Update product statistics (must be before DELETE to capture old values)
                    UPDATE productstats
                    SET 
                        totalproducts = totalproducts - 1,
                        averageprice = CASE 
                            WHEN totalproducts > 1 
                            THEN (averageprice * totalproducts - (SELECT price FROM products WHERE productid = @ProductId)) / (totalproducts - 1)
                            ELSE 0
                        END,
                        lastupdated = NOW()
                    WHERE statid = 1;
                    
                    -- Delete the product
                    DELETE FROM products 
                    WHERE productid = @ProductId;

-- ================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync (PostgreSQL)
-- Original Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Conversion: Lowercase schema names, window functions same in PG
-- ================================================================
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

-- ================================================================
-- STATEMENT 7: GetLowStockProductsAsync (PostgreSQL)
-- Original Method: GetLowStockProductsAsync(int threshold)
-- Conversion: Lowercase schema names, ROUND with CAST for integer division
-- ================================================================
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
