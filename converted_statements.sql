-- =============================================================================
-- CONVERTED SQL STATEMENTS - PostgreSQL equivalents
-- Source: sourceCode/DataAccess/ProductRepository.cs
-- Total Statements: 7
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Metadata model creation/conversion timed out after multiple attempts
-- Schema Mapping Source: DMS schema_mapping_tool (successful)
-- Schema Mapping Applied:
--   dbo.Products -> products (columns: productid, name, description, price, stockquantity, createddate, modifieddate)
--   dbo.ProductHistory -> producthistory (columns: historyid, productid, action, oldprice, newprice, oldstock, newstock, actiondate)
--   dbo.ProductStats -> productstats (columns: statid, totalproducts, averageprice, lastupdated)
--   GETDATE() -> clock_timestamp()
--   SCOPE_IDENTITY() -> RETURNING clause
-- =============================================================================

-- =============================================================================
-- Statement 1: GetAllProductsAsync() - Converted to PostgreSQL
-- Source Method: GetAllProductsAsync()
-- =============================================================================

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
                    p.name

-- =============================================================================
-- Statement 2: GetProductByIdAsync() - Converted to PostgreSQL
-- Source Method: GetProductByIdAsync(int productId)
-- =============================================================================

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
                WHERE p.productid = @ProductId

-- =============================================================================
-- Statement 3: InsertProductAsync() - Converted to PostgreSQL
-- Source Method: InsertProductAsync(Product product)
-- Note: SCOPE_IDENTITY() replaced with RETURNING clause
--       GETDATE() replaced with clock_timestamp()
--       Transaction block restructured for PostgreSQL compatibility
--       DECLARE/@variable pattern replaced with DO block
-- =============================================================================

                DO $$
                DECLARE var_newproductid INTEGER;
                BEGIN
                    -- Insert the new product and capture the ID
                    INSERT INTO products (name, description, price, stockquantity)
                    VALUES (@Name, @Description, @Price, @StockQuantity)
                    RETURNING productid INTO var_newproductid;
                    
                    -- Log the insertion
                    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    VALUES (var_newproductid, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp());
                    
                    -- Update product statistics
                    UPDATE productstats
                    SET 
                        totalproducts = totalproducts + 1,
                        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
                        lastupdated = clock_timestamp()
                    WHERE statid = 1;
                END $$;

-- =============================================================================
-- Statement 4: UpdateProductAsync() - Converted to PostgreSQL
-- Source Method: UpdateProductAsync(Product product)
-- Note: DECLARE/@variable pattern replaced with DO block
--       GETDATE() replaced with clock_timestamp()
-- =============================================================================

                DO $$
                DECLARE var_oldprice NUMERIC(18,2);
                DECLARE var_oldstock INTEGER;
                BEGIN
                    -- Store old values for history
                    SELECT price, stockquantity INTO var_oldprice, var_oldstock
                    FROM products
                    WHERE productid = @ProductId;
                    
                    -- Update the product
                    UPDATE products
                    SET 
                        name = @Name,
                        description = @Description,
                        price = @Price,
                        stockquantity = @StockQuantity,
                        modifieddate = clock_timestamp()
                    WHERE productid = @ProductId;
                    
                    -- Log the changes
                    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    VALUES (@ProductId, 'UPDATE', var_oldprice, @Price, var_oldstock, @StockQuantity, clock_timestamp());
                    
                    -- Update product statistics
                    UPDATE productstats
                    SET 
                        averageprice = (averageprice * totalproducts - var_oldprice + @Price) / totalproducts,
                        lastupdated = clock_timestamp()
                    WHERE statid = 1;
                END $$;

-- =============================================================================
-- Statement 5: DeleteProductAsync() - Converted to PostgreSQL
-- Source Method: DeleteProductAsync(int productId)
-- Note: DECLARE/@variable pattern replaced with DO block
--       GETDATE() replaced with clock_timestamp()
-- =============================================================================

                DO $$
                DECLARE var_oldprice NUMERIC(18,2);
                DECLARE var_oldstock INTEGER;
                BEGIN
                    -- Store product info for history
                    SELECT price, stockquantity INTO var_oldprice, var_oldstock
                    FROM products
                    WHERE productid = @ProductId;
                    
                    -- Log the deletion
                    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    VALUES (@ProductId, 'DELETE', var_oldprice, NULL, var_oldstock, NULL, clock_timestamp());
                    
                    -- Delete the product
                    DELETE FROM products 
                    WHERE productid = @ProductId;
                    
                    -- Update product statistics
                    UPDATE productstats
                    SET 
                        totalproducts = totalproducts - 1,
                        averageprice = CASE 
                            WHEN totalproducts > 1 
                            THEN (averageprice * totalproducts - var_oldprice) / (totalproducts - 1)
                            ELSE 0
                        END,
                        lastupdated = clock_timestamp()
                    WHERE statid = 1;
                END $$;

-- =============================================================================
-- Statement 6: GetProductsByPriceRangeAsync() - Converted to PostgreSQL
-- Source Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- =============================================================================

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
                ORDER BY rp.pricerank

-- =============================================================================
-- Statement 7: GetLowStockProductsAsync() - Converted to PostgreSQL
-- Source Method: GetLowStockProductsAsync(int threshold)
-- =============================================================================

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
                    ROUND((CAST(stockquantity AS NUMERIC) / avgstock) * 100, 2) as stockpercentageofaverage
                FROM stockanalysis sa
                WHERE stockquantity <= @Threshold
                ORDER BY stockquantity
