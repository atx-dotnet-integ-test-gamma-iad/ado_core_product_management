-- ============================================================================
-- CONVERTED SQL STATEMENTS (MS SQL Server -> PostgreSQL)
-- All statements were attempted through DMS MCP tool first.
-- DMS FAILED for all 7 statements with: "Metadata model creation failed: 
--   {'error': 'Unknown metadata model creation status: RECEIVED'}"
-- Manual conversion applied with lowercase schema object names per migration rules.
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- ============================================================================

-- ============================================================================
-- STATEMENT 1: GetAllProductsAsync (CONVERTED)
-- Source: sourceCode/DataAccess/ProductRepository.cs -> GetAllProductsAsync()
-- Changes: Schema objects lowercased (Products->products, ProductId->productid, etc.)
--          ROUND cast for proper decimal division in PostgreSQL
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
-- STATEMENT 2: GetProductByIdAsync (CONVERTED)
-- Source: sourceCode/DataAccess/ProductRepository.cs -> GetProductByIdAsync()
-- Changes: Schema objects lowercased, @ProductId -> @ProductId (Npgsql compatible)
--          ROUND cast for proper decimal division in PostgreSQL
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
-- STATEMENT 3: InsertProductAsync (CONVERTED)
-- Source: sourceCode/DataAccess/ProductRepository.cs -> InsertProductAsync()
-- Changes: Removed DECLARE/SCOPE_IDENTITY(), used INSERT...RETURNING
--          GETDATE() -> NOW(), schema objects lowercased
--          Restructured to avoid T-SQL variables - uses multiple statements
--          with RETURNING clause to get the new product ID
-- ============================================================================
                INSERT INTO products (name, description, price, stockquantity)
                VALUES (@Name, @Description, @Price, @StockQuantity)
                RETURNING productid;

-- ============================================================================
-- STATEMENT 3b: InsertProductAsync - ProductHistory insert (CONVERTED)
-- This is executed separately after getting the new product ID
-- ============================================================================
                INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- ============================================================================
-- STATEMENT 3c: InsertProductAsync - ProductStats update (CONVERTED)
-- ============================================================================
                UPDATE productstats
                SET 
                    totalproducts = totalproducts + 1,
                    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
                    lastupdated = NOW()
                WHERE statid = 1;

-- ============================================================================
-- STATEMENT 4: UpdateProductAsync (CONVERTED)
-- Source: sourceCode/DataAccess/ProductRepository.cs -> UpdateProductAsync()
-- Changes: Removed DECLARE, GETDATE() -> NOW(), schema objects lowercased
--          Restructured to separate queries executed in ADO.NET transaction
-- ============================================================================
-- 4a: Get old values
                SELECT price, stockquantity
                FROM products
                WHERE productid = @ProductId;

-- 4b: Update the product
                UPDATE products
                SET 
                    name = @Name,
                    description = @Description,
                    price = @Price,
                    stockquantity = @StockQuantity,
                    modifieddate = NOW()
                WHERE productid = @ProductId;

-- 4c: Log the changes
                INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());

-- 4d: Update product statistics
                UPDATE productstats
                SET 
                    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
                    lastupdated = NOW()
                WHERE statid = 1;

-- ============================================================================
-- STATEMENT 5: DeleteProductAsync (CONVERTED)
-- Source: sourceCode/DataAccess/ProductRepository.cs -> DeleteProductAsync()
-- Changes: Removed DECLARE, GETDATE() -> NOW(), schema objects lowercased
--          Restructured to separate queries executed in ADO.NET transaction
-- ============================================================================
-- 5a: Get old values
                SELECT price, stockquantity
                FROM products
                WHERE productid = @ProductId;

-- 5b: Log the deletion
                INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());

-- 5c: Delete the product
                DELETE FROM products 
                WHERE productid = @ProductId;

-- 5d: Update product statistics
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
-- STATEMENT 6: GetProductsByPriceRangeAsync (CONVERTED)
-- Source: sourceCode/DataAccess/ProductRepository.cs -> GetProductsByPriceRangeAsync()
-- Changes: Schema objects lowercased
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
-- STATEMENT 7: GetLowStockProductsAsync (CONVERTED)
-- Source: sourceCode/DataAccess/ProductRepository.cs -> GetLowStockProductsAsync()
-- Changes: Schema objects lowercased, ROUND cast for integer division
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
