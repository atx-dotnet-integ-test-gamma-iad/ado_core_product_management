-- ============================================================
-- CONVERTED SQL STATEMENTS (PostgreSQL) FROM ProductRepository.cs
-- Source: DataAccess/ProductRepository.cs
-- Target Database: PostgreSQL (ProductManagement)
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Metadata model conversion failed - did not complete after 15 attempts
-- Note: Transaction blocks restructured to work with Npgsql ADO.NET parameterized queries.
--       BEGIN TRANSACTION/COMMIT removed from SQL (handled in C# code via NpgsqlTransaction).
--       DECLARE/SET variables replaced with subqueries or INSERT...RETURNING.
-- ============================================================

-- ============================================================
-- Statement 1: GetAllProductsAsync (PostgreSQL)
-- Original: CTE with AVG/COUNT window functions, INNER JOIN, CASE, ROUND
-- Changes: Table/column names to lowercase
-- ============================================================
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

-- ============================================================
-- Statement 2: GetProductByIdAsync (PostgreSQL)
-- Original: CTE with LAG window function, LEFT JOIN, CASE, ROUND
-- Changes: Table/column names to lowercase, parameter @ProductId kept for Npgsql
-- ============================================================
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

-- ============================================================
-- Statement 3: InsertProductAsync (PostgreSQL)
-- Original: Transaction with DECLARE @NewProductId, SCOPE_IDENTITY(), GETDATE()
-- Changes: Split into 3 separate SQL statements executed in C# transaction:
--   3a: INSERT INTO products ... RETURNING productid (gets the new ID)
--   3b: INSERT INTO producthistory ... (logs the insertion)
--   3c: UPDATE productstats ... (updates statistics)
-- SCOPE_IDENTITY() -> INSERT...RETURNING productid
-- GETDATE() -> NOW()
-- BEGIN TRANSACTION/COMMIT -> handled in C# via NpgsqlTransaction
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
-- Statement 4: UpdateProductAsync (PostgreSQL)
-- Original: Transaction with DECLARE @OldPrice/@OldStock, SELECT INTO vars, UPDATE, INSERT, GETDATE()
-- Changes: Split into 4 separate SQL statements executed in C# transaction:
--   4a: SELECT price, stockquantity FROM products (gets old values into C# vars)
--   4b: UPDATE products ... (updates the product)
--   4c: INSERT INTO producthistory ... (logs the changes)
--   4d: UPDATE productstats ... (updates statistics)
-- GETDATE() -> NOW()
-- BEGIN TRANSACTION/COMMIT -> handled in C# via NpgsqlTransaction
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
-- Statement 5: DeleteProductAsync (PostgreSQL)
-- Original: Transaction with DECLARE @OldPrice/@OldStock, SELECT INTO vars, INSERT, DELETE, UPDATE, CASE, GETDATE()
-- Changes: Split into 4 separate SQL statements executed in C# transaction:
--   5a: SELECT price, stockquantity FROM products (gets old values into C# vars)
--   5b: INSERT INTO producthistory ... (logs the deletion)
--   5c: DELETE FROM products ... (deletes the product)
--   5d: UPDATE productstats ... (updates statistics)
-- GETDATE() -> NOW()
-- BEGIN TRANSACTION/COMMIT -> handled in C# via NpgsqlTransaction
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
-- Statement 6: GetProductsByPriceRangeAsync (PostgreSQL)
-- Original: CTE with RANK, PERCENT_RANK, BETWEEN, CASE
-- Changes: Table/column names to lowercase
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
-- Statement 7: GetLowStockProductsAsync (PostgreSQL)
-- Original: CTE with AVG/MIN/MAX window functions, CASE, ROUND
-- Changes: Table/column names to lowercase, cast for integer division in ROUND
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
                    ROUND((stockquantity::numeric / avgstock) * 100, 2) as stockpercentageofaverage
                FROM stockanalysis sa
                WHERE stockquantity <= @Threshold
                ORDER BY stockquantity;
