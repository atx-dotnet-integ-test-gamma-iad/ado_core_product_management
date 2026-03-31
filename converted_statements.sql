-- ============================================================
-- Converted PostgreSQL Statements from ProductRepository.cs
-- Source: sourceCode/DataAccess/ProductRepository.cs
-- Conversion Date: 2026-03-31
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS Failure Reason: Metadata model conversion/creation timeout after max poll attempts
-- Schema Mapping Source: DMS schema_mapping_tool (successful)
-- Target Schema: productmanagement_dbo (lowercase per DMS schema mapping)
-- Total Statements: 7
-- ============================================================

-- ============================================================
-- Statement 1: GetAllProductsAsync (converted)
-- Conversions: Table/column names to lowercase per DMS schema mapping
-- ROUND and CAST added for integer division safety
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
-- Conversions: Table/column names to lowercase, CTE renamed to avoid conflict
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
-- Conversions: SCOPE_IDENTITY() -> RETURNING + data-modifying CTEs
--              GETDATE() -> clock_timestamp()
--              BEGIN TRANSACTION/COMMIT removed (handled by Npgsql in C#)
--              Table/column names to lowercase
-- ============================================================
                WITH new_product AS (
                    INSERT INTO products (name, description, price, stockquantity)
                    VALUES (@Name, @Description, @Price, @StockQuantity)
                    RETURNING productid
                ),
                history_insert AS (
                    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    SELECT productid, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp()
                    FROM new_product
                ),
                stats_update AS (
                    UPDATE productstats
                    SET 
                        totalproducts = totalproducts + 1,
                        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
                        lastupdated = clock_timestamp()
                    WHERE statid = 1
                )
                SELECT productid FROM new_product;

-- ============================================================
-- Statement 4: UpdateProductAsync (converted)
-- Conversions: DECLARE/@vars -> CTEs with subqueries
--              GETDATE() -> clock_timestamp()
--              BEGIN TRANSACTION/COMMIT removed (handled by Npgsql in C#)
--              Table/column names to lowercase
-- ============================================================
                WITH old_values AS (
                    SELECT price as oldprice, stockquantity as oldstock
                    FROM products
                    WHERE productid = @ProductId
                ),
                update_product AS (
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
                insert_history AS (
                    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    SELECT @ProductId, 'UPDATE', ov.oldprice, @Price, ov.oldstock, @StockQuantity, clock_timestamp()
                    FROM old_values ov
                )
                UPDATE productstats
                SET 
                    averageprice = (averageprice * totalproducts - (SELECT oldprice FROM old_values) + @Price) / totalproducts,
                    lastupdated = clock_timestamp()
                WHERE statid = 1;

-- ============================================================
-- Statement 5: DeleteProductAsync (converted)
-- Conversions: DECLARE/@vars -> CTEs with subqueries
--              GETDATE() -> clock_timestamp()
--              BEGIN TRANSACTION/COMMIT removed (handled by Npgsql in C#)
--              Table/column names to lowercase
-- ============================================================
                WITH old_values AS (
                    SELECT price as oldprice, stockquantity as oldstock
                    FROM products
                    WHERE productid = @ProductId
                ),
                insert_history AS (
                    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    SELECT @ProductId, 'DELETE', ov.oldprice, NULL, ov.oldstock, NULL, clock_timestamp()
                    FROM old_values ov
                ),
                delete_product AS (
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

-- ============================================================
-- Statement 6: GetProductsByPriceRangeAsync (converted)
-- Conversions: Table/column names to lowercase
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
-- Conversions: Table/column names to lowercase
--              Added CAST for integer division safety in ROUND
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
                    ROUND((CAST(stockquantity AS NUMERIC) / avgstock) * 100, 2) as stockpercentageofaverage
                FROM stockanalysis sa
                WHERE stockquantity <= @Threshold
                ORDER BY stockquantity;

-- ============================================================
-- SETUP SCRIPT STATEMENTS - CONVERTED (Scripts/01_InitialSetup.sql)
-- ============================================================

-- Statement 8: Create Products Table (Simple) - converted
CREATE TABLE IF NOT EXISTS products(productid INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY, name VARCHAR(100) NOT NULL, description VARCHAR(500), price NUMERIC(18, 2) NOT NULL, stockquantity INTEGER NOT NULL, createddate TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(), modifieddate TIMESTAMP WITHOUT TIME ZONE);

-- Statement 9: sp_GetAllProducts body - converted
SELECT productid, name, description, price, stockquantity, createddate, modifieddate FROM products ORDER BY name;

-- Statement 10: sp_GetProductById body - converted
SELECT productid, name, description, price, stockquantity, createddate, modifieddate FROM products WHERE productid = @ProductId;

-- Statement 11: sp_InsertProduct body - converted
INSERT INTO products (name, description, price, stockquantity) VALUES (@Name, @Description, @Price, @StockQuantity) RETURNING productid;

-- Statement 12: sp_UpdateProduct body - converted
UPDATE products SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = clock_timestamp() WHERE productid = @ProductId;

-- Statement 13: sp_DeleteProduct body - converted
DELETE FROM products WHERE productid = @ProductId;

-- ============================================================
-- SETUP SCRIPT STATEMENTS - CONVERTED (Database/Scripts/01_InitialSetup.sql)
-- ============================================================

-- Statement 14: Create Categories Table - converted
CREATE TABLE categories(categoryid INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY, name VARCHAR(50) NOT NULL, description VARCHAR(200), parentcategoryid INTEGER, createddate TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp());

-- Statement 15: Create Suppliers Table - converted
CREATE TABLE suppliers(supplierid INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY, name VARCHAR(100) NOT NULL, contactname VARCHAR(100), email VARCHAR(100), phone VARCHAR(20), address VARCHAR(200), country VARCHAR(50), isactive BOOLEAN NOT NULL DEFAULT TRUE, createddate TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp());

-- Statement 16: Create Products Table (Extended) - converted
CREATE TABLE products(productid INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY, name VARCHAR(100) NOT NULL, description VARCHAR(500), price NUMERIC(18, 2) NOT NULL, stockquantity INTEGER NOT NULL, categoryid INTEGER, supplierid INTEGER, sku VARCHAR(50), weight NUMERIC(10, 2), dimensions VARCHAR(50), isdiscontinued BOOLEAN NOT NULL DEFAULT FALSE, reorderlevel INTEGER NOT NULL DEFAULT 10, createddate TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(), modifieddate TIMESTAMP WITHOUT TIME ZONE);

-- Statement 17: Create ProductHistory Table - converted
CREATE TABLE producthistory(historyid INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY, productid INTEGER NOT NULL, action VARCHAR(10) NOT NULL, oldprice NUMERIC(18, 2), newprice NUMERIC(18, 2), oldstock INTEGER, newstock INTEGER, actiondate TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(), modifiedby VARCHAR(100));

-- Statement 18: Create ProductStats Table - converted
CREATE TABLE productstats(statid INTEGER PRIMARY KEY DEFAULT 1, totalproducts INTEGER NOT NULL DEFAULT 0, averageprice NUMERIC(18, 2) NOT NULL DEFAULT 0, totalstockvalue NUMERIC(18, 2) NOT NULL DEFAULT 0, lowstockcount INTEGER NOT NULL DEFAULT 0, discontinuedcount INTEGER NOT NULL DEFAULT 0, lastupdated TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp());

-- Statement 19: Insert Sample Categories - converted
INSERT INTO categories (name, description, parentcategoryid) VALUES ('Electronics', 'Electronic devices and accessories', NULL);

-- Statement 20: Update Initial Statistics - converted
UPDATE productstats SET totalproducts = (SELECT COUNT(*) FROM products), averageprice = (SELECT AVG(price) FROM products), totalstockvalue = (SELECT SUM(price * stockquantity) FROM products), lowstockcount = (SELECT COUNT(*) FROM products WHERE stockquantity <= reorderlevel), discontinuedcount = (SELECT COUNT(*) FROM products WHERE isdiscontinued = TRUE), lastupdated = clock_timestamp() WHERE statid = 1;

