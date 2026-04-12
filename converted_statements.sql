-- ============================================================================
-- Converted SQL Statements (MS SQL Server -> PostgreSQL)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Metadata model creation failed: Unknown metadata model creation status: RECEIVED
-- Schema mappings obtained from DMS schema_mapping_tool:
--   Products -> products, ProductHistory -> producthistory, ProductStats -> productstats
--   All column names -> lowercase
--   GETDATE() -> clock_timestamp()
--   SCOPE_IDENTITY() -> RETURNING clause / lastval()
--   DECLARE @var -> DO $$ DECLARE v_var ... END $$
-- Total Statements: 7
-- ============================================================================

-- ============================================================================
-- Statement 1: GetAllProductsAsync (Converted)
-- Original: CTE with AVG/COUNT window functions, CASE, ROUND
-- Changes: All identifiers lowercased per DMS schema mapping
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
-- Statement 2: GetProductByIdAsync (Converted)
-- Original: CTE with LAG window function, CASE, ROUND
-- Changes: All identifiers lowercased per DMS schema mapping
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
-- Statement 3: InsertProductAsync (Converted)
-- Original: DECLARE, SCOPE_IDENTITY, BEGIN TRANSACTION, INSERT, UPDATE, GETDATE
-- Changes: SCOPE_IDENTITY -> RETURNING + lastval(), GETDATE -> clock_timestamp(),
--          DECLARE @var -> DO block with v_var, all identifiers lowercased
-- NOTE: For ADO.NET integration, this is restructured to work with ExecuteScalar
-- ============================================================================
                INSERT INTO products (name, description, price, stockquantity)
                VALUES (@Name, @Description, @Price, @StockQuantity);

                INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                VALUES (lastval(), 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp());

                UPDATE productstats
                SET 
                    totalproducts = totalproducts + 1,
                    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
                    lastupdated = clock_timestamp()
                WHERE statid = 1;
                
                SELECT lastval();

-- ============================================================================
-- Statement 4: UpdateProductAsync (Converted)
-- Original: BEGIN TRANSACTION, DECLARE, SELECT INTO vars, UPDATE, INSERT, GETDATE
-- Changes: DECLARE @var -> DO block with v_var, GETDATE -> clock_timestamp(),
--          all identifiers lowercased
-- NOTE: For ADO.NET integration, restructured as DO block
-- ============================================================================
                DO $$
                DECLARE
                    v_oldprice NUMERIC(18,2);
                    v_oldstock INTEGER;
                BEGIN
                    SELECT price, stockquantity INTO v_oldprice, v_oldstock
                    FROM products
                    WHERE productid = @ProductId;
                    
                    UPDATE products
                    SET 
                        name = @Name,
                        description = @Description,
                        price = @Price,
                        stockquantity = @StockQuantity,
                        modifieddate = clock_timestamp()
                    WHERE productid = @ProductId;
                    
                    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    VALUES (@ProductId, 'UPDATE', v_oldprice, @Price, v_oldstock, @StockQuantity, clock_timestamp());
                    
                    UPDATE productstats
                    SET 
                        averageprice = (averageprice * totalproducts - v_oldprice + @Price) / totalproducts,
                        lastupdated = clock_timestamp()
                    WHERE statid = 1;
                END $$;

-- ============================================================================
-- Statement 5: DeleteProductAsync (Converted)
-- Original: BEGIN TRANSACTION, DECLARE, SELECT INTO vars, INSERT, DELETE, UPDATE, CASE, GETDATE
-- Changes: DECLARE @var -> DO block with v_var, GETDATE -> clock_timestamp(),
--          all identifiers lowercased
-- NOTE: For ADO.NET integration, restructured as DO block
-- ============================================================================
                DO $$
                DECLARE
                    v_oldprice NUMERIC(18,2);
                    v_oldstock INTEGER;
                BEGIN
                    SELECT price, stockquantity INTO v_oldprice, v_oldstock
                    FROM products
                    WHERE productid = @ProductId;
                    
                    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    VALUES (@ProductId, 'DELETE', v_oldprice, NULL, v_oldstock, NULL, clock_timestamp());
                    
                    DELETE FROM products 
                    WHERE productid = @ProductId;
                    
                    UPDATE productstats
                    SET 
                        totalproducts = totalproducts - 1,
                        averageprice = CASE 
                            WHEN totalproducts > 1 
                            THEN (averageprice * totalproducts - v_oldprice) / (totalproducts - 1)
                            ELSE 0
                        END,
                        lastupdated = clock_timestamp()
                    WHERE statid = 1;
                END $$;

-- ============================================================================
-- Statement 6: GetProductsByPriceRangeAsync (Converted)
-- Original: CTE with RANK, PERCENT_RANK, BETWEEN, CASE
-- Changes: All identifiers lowercased per DMS schema mapping
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
-- Statement 7: GetLowStockProductsAsync (Converted)
-- Original: CTE with AVG/MIN/MAX window functions, CASE, ROUND
-- Changes: All identifiers lowercased per DMS schema mapping,
--          Added ::numeric cast for integer division in ROUND
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
                    ROUND((stockquantity::numeric / avgstock) * 100, 2) as stockpercentageofaverage
                FROM stockanalysis sa
                WHERE stockquantity <= @Threshold
                ORDER BY stockquantity;
