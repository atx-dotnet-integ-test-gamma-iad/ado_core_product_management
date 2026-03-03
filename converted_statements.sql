-- ============================================================
-- CONVERTED SQL STATEMENTS - Complete Catalog
-- All Converted PostgreSQL Statements
-- ============================================================

-- ============================================================
-- SOURCE: DataAccess/ProductRepository.cs
-- ============================================================

-- Statement 1: GetAllProductsAsync (DMS_TOOL)
WITH productstats AS (SELECT productid, AVG(price) OVER () AS avgprice, COUNT(*) OVER () AS totalproducts FROM productmanagement_dbo.products)
SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate,
    CASE WHEN p.price > ps.avgprice THEN 'Above Average' WHEN p.price < ps.avgprice THEN 'Below Average' ELSE 'Average' END AS pricecategory,
    ROUND((p.price / ps.avgprice) * 100, 2) AS pricepercentageofaverage
    FROM productmanagement_dbo.products AS p INNER JOIN productstats AS ps ON p.productid = ps.productid
    ORDER BY CASE WHEN p.price > ps.avgprice THEN 1 ELSE 2 END NULLS FIRST, p.name NULLS FIRST;

-- Statement 2: GetProductByIdAsync (DMS_TOOL)
WITH producthistory AS (SELECT productid, lag(price) OVER (ORDER BY modifieddate) AS previousprice, lag(stockquantity) OVER (ORDER BY modifieddate) AS previousstock
    FROM productmanagement_dbo.products WHERE productid = @ProductId)
SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate, ph.previousprice, ph.previousstock,
    CASE WHEN ph.previousprice IS NOT NULL THEN ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2) ELSE NULL END AS pricechangepercentage
    FROM productmanagement_dbo.products AS p LEFT OUTER JOIN producthistory AS ph ON p.productid = ph.productid WHERE p.productid = @ProductId;

-- Statement 3: InsertProductAsync (DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA)
DO $$ DECLARE var_newproductid INTEGER; BEGIN
    INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity) VALUES (@Name, @Description, @Price, @StockQuantity) RETURNING productid INTO var_newproductid;
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate) VALUES (var_newproductid, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp());
    UPDATE productmanagement_dbo.productstats SET totalproducts = totalproducts + 1, averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1), lastupdated = clock_timestamp() WHERE statid = 1;
END $$; SELECT lastval();

-- Statement 4: UpdateProductAsync (DMS_TOOL)
DO $$ DECLARE var_OldPrice NUMERIC(18, 2); var_OldStock INTEGER; BEGIN
    SELECT price, stockquantity INTO var_OldPrice, var_OldStock FROM productmanagement_dbo.products WHERE productid = @ProductId;
    UPDATE productmanagement_dbo.products SET name = @Name, description = @Description, price = @Price, stockquantity = @StockQuantity, modifieddate = clock_timestamp() WHERE productid = @ProductId;
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate) VALUES (@ProductId, 'UPDATE', var_OldPrice, @Price, var_OldStock, @StockQuantity, clock_timestamp());
    UPDATE productmanagement_dbo.productstats SET averageprice = (averageprice * totalproducts - var_OldPrice + @Price) / totalproducts, lastupdated = clock_timestamp() WHERE statid = 1;
END $$;

-- Statement 5: DeleteProductAsync (DMS_TOOL)
DO $$ DECLARE var_OldPrice NUMERIC(18, 2); var_OldStock INTEGER; BEGIN
    SELECT price, stockquantity INTO var_OldPrice, var_OldStock FROM productmanagement_dbo.products WHERE productid = @ProductId;
    INSERT INTO productmanagement_dbo.producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate) VALUES (@ProductId, 'DELETE', var_OldPrice, NULL, var_OldStock, NULL, clock_timestamp());
    DELETE FROM productmanagement_dbo.products WHERE productid = @ProductId;
    UPDATE productmanagement_dbo.productstats SET totalproducts = totalproducts - 1, averageprice = CASE WHEN totalproducts > 1 THEN (averageprice * totalproducts - var_OldPrice) / (totalproducts - 1) ELSE 0 END, lastupdated = clock_timestamp() WHERE statid = 1;
END $$;

-- Statement 6: GetProductsByPriceRangeAsync (DMS_TOOL)
WITH rankedproducts AS (SELECT p.*, RANK() OVER (ORDER BY p.price) AS pricerank, percent_rank() OVER (ORDER BY p.price) AS pricepercentile
    FROM productmanagement_dbo.products AS p WHERE p.price BETWEEN @MinPrice AND @MaxPrice)
SELECT rp.*, CASE WHEN rp.pricepercentile <= 0.25 THEN 'Budget' WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range' ELSE 'Premium' END AS pricesegment
    FROM rankedproducts AS rp ORDER BY rp.pricerank NULLS FIRST;

-- Statement 7: GetLowStockProductsAsync (DMS_TOOL)
WITH stockanalysis AS (SELECT p.*, AVG(stockquantity) OVER () AS avgstock, MIN(stockquantity) OVER () AS minstock, MAX(stockquantity) OVER () AS maxstock
    FROM productmanagement_dbo.products AS p)
SELECT sa.*, CASE WHEN stockquantity <= @Threshold THEN 'Critical' WHEN stockquantity <= avgstock * 0.5 THEN 'Low' ELSE 'Adequate' END AS stockstatus,
    ROUND((stockquantity / avgstock) * 100, 2) AS stockpercentageofaverage
    FROM stockanalysis AS sa WHERE stockquantity <= @Threshold ORDER BY stockquantity NULLS FIRST;

-- ============================================================
-- SOURCE: Scripts/01_InitialSetup.sql
-- ============================================================

-- Statement 8: CREATE TABLE Products (DMS_TOOL)
CREATE TABLE productmanagement_dbo.products (productid BIGINT GENERATED ALWAYS AS IDENTITY (START WITH 1 INCREMENT BY 1) PRIMARY KEY,
    name VARCHAR(100) NOT NULL, description VARCHAR(500) NULL, price NUMERIC(18, 2) NOT NULL,
    stockquantity INTEGER NOT NULL, createddate TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    modifieddate TIMESTAMP WITHOUT TIME ZONE NULL);

-- Statement 9: sp_GetAllProducts body (DMS_TOOL)
SELECT productid, name, description, price, stockquantity, createddate, modifieddate
    FROM productmanagement_dbo.products ORDER BY name NULLS FIRST;

-- Statement 10: sp_GetProductById body (DMS_TOOL)
SELECT productid, name, description, price, stockquantity, createddate, modifieddate
    FROM productmanagement_dbo.products WHERE productid = @ProductId;

-- Statement 11: sp_InsertProduct body (DMS_TOOL)
INSERT INTO productmanagement_dbo.products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity);

-- Statement 12: sp_UpdateProduct body (DMS_TOOL)
UPDATE productmanagement_dbo.products SET name = @Name, description = @Description, price = @Price,
    stockquantity = @StockQuantity, modifieddate = clock_timestamp() WHERE productid = @ProductId;

-- Statement 13: sp_DeleteProduct body (DMS_TOOL)
DELETE FROM productmanagement_dbo.products WHERE productid = @ProductId;

-- ============================================================
-- SOURCE: Database/Scripts/01_InitialSetup.sql
-- ============================================================

-- Statement 14: CREATE TABLE Categories (DMS_TOOL pattern applied)
CREATE TABLE productmanagement_dbo.categories (categoryid BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(50) NOT NULL, description VARCHAR(200) NULL, parentcategoryid BIGINT NULL,
    createddate TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp());

-- Statement 15: CREATE TABLE Suppliers (DMS_TOOL pattern applied)
CREATE TABLE productmanagement_dbo.suppliers (supplierid BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL, contactname VARCHAR(100) NULL, email VARCHAR(100) NULL,
    phone VARCHAR(20) NULL, address VARCHAR(200) NULL, country VARCHAR(50) NULL,
    isactive BOOLEAN NOT NULL DEFAULT TRUE, createddate TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp());

-- Statement 16: CREATE TABLE Products Extended (DMS_TOOL pattern applied)
CREATE TABLE productmanagement_dbo.products (productid BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(100) NOT NULL, description VARCHAR(500) NULL, price NUMERIC(18, 2) NOT NULL,
    stockquantity INTEGER NOT NULL, categoryid BIGINT NULL, supplierid BIGINT NULL,
    sku VARCHAR(50) NULL, weight NUMERIC(10, 2) NULL, dimensions VARCHAR(50) NULL,
    isdiscontinued BOOLEAN NOT NULL DEFAULT FALSE, reorderlevel INTEGER NOT NULL DEFAULT 10,
    createddate TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    modifieddate TIMESTAMP WITHOUT TIME ZONE NULL);

-- Statement 17: CREATE TABLE ProductHistory (DMS_TOOL pattern applied)
CREATE TABLE productmanagement_dbo.producthistory (historyid BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    productid BIGINT NOT NULL, action VARCHAR(10) NOT NULL, oldprice NUMERIC(18, 2) NULL,
    newprice NUMERIC(18, 2) NULL, oldstock INTEGER NULL, newstock INTEGER NULL,
    actiondate TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp(),
    modifiedby VARCHAR(100) NULL);

-- Statement 18: CREATE TABLE ProductStats (DMS_TOOL pattern applied)
CREATE TABLE productmanagement_dbo.productstats (statid INTEGER PRIMARY KEY DEFAULT 1,
    totalproducts INTEGER NOT NULL DEFAULT 0, averageprice NUMERIC(18, 2) NOT NULL DEFAULT 0,
    totalstockvalue NUMERIC(18, 2) NOT NULL DEFAULT 0, lowstockcount INTEGER NOT NULL DEFAULT 0,
    discontinuedcount INTEGER NOT NULL DEFAULT 0,
    lastupdated TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT clock_timestamp());

-- Statement 19: UPDATE ProductStats (DMS_TOOL pattern applied)
UPDATE productmanagement_dbo.productstats SET
    totalproducts = (SELECT COUNT(*) FROM productmanagement_dbo.products),
    averageprice = (SELECT AVG(price) FROM productmanagement_dbo.products),
    totalstockvalue = (SELECT SUM(price * stockquantity) FROM productmanagement_dbo.products),
    lowstockcount = (SELECT COUNT(*) FROM productmanagement_dbo.products WHERE stockquantity <= reorderlevel),
    discontinuedcount = (SELECT COUNT(*) FROM productmanagement_dbo.products WHERE isdiscontinued = TRUE),
    lastupdated = clock_timestamp()
WHERE statid = 1;
