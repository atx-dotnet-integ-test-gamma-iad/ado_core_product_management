-- ================================================================================
-- CONVERTED SQL STATEMENTS - PostgreSQL Syntax
-- Purpose: PostgreSQL versions of MS SQL Server statements
-- Conversion Date: Migration Step 2
-- Total Statements: 7
-- ================================================================================

-- ================================================================================
-- STATEMENT 1: GetAllProductsAsync
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Original Source: ProductRepository.cs - GetAllProductsAsync()
-- Changes Applied:
--   - Table names converted to lowercase (products)
--   - Column names converted to lowercase (productid, name, description, price, stockquantity, createddate, modifieddate)
--   - Window functions (AVG, COUNT OVER) are compatible with PostgreSQL
--   - ROUND function compatible with PostgreSQL
-- ================================================================================
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

-- ================================================================================
-- STATEMENT 2: GetProductByIdAsync
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Original Source: ProductRepository.cs - GetProductByIdAsync(int productId)
-- Changes Applied:
--   - Table names converted to lowercase (products)
--   - Column names converted to lowercase (productid, name, description, price, stockquantity, createddate, modifieddate)
--   - Parameter @ProductId remains unchanged (case-insensitive in PostgreSQL)
--   - LAG window function compatible with PostgreSQL
--   - ROUND function compatible with PostgreSQL
-- ================================================================================
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

-- ================================================================================
-- STATEMENT 3: InsertProductAsync
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Original Source: ProductRepository.cs - InsertProductAsync(Product product)
-- Changes Applied:
--   - DECLARE converted to PostgreSQL variable declaration style
--   - BEGIN TRANSACTION converted to BEGIN
--   - Table names converted to lowercase (products, producthistory, productstats)
--   - Column names converted to lowercase
--   - SCOPE_IDENTITY() replaced with RETURNING clause for PostgreSQL
--   - GETDATE() replaced with CURRENT_TIMESTAMP
--   - Transaction structure modified for PostgreSQL compatibility
--   - Multiple statements combined with DO block and temporary variable
-- ================================================================================
DO $$
DECLARE 
    v_newproductid INT;
BEGIN
    -- Insert the new product and get the ID
    INSERT INTO products (name, description, price, stockquantity)
    VALUES (@Name, @Description, @Price, @StockQuantity)
    RETURNING productid INTO v_newproductid;
    
    -- Log the insertion
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (v_newproductid, 'INSERT', NULL, @Price, NULL, @StockQuantity, CURRENT_TIMESTAMP);
    
    -- Update product statistics
    UPDATE productstats
    SET 
        totalproducts = totalproducts + 1,
        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
        lastupdated = CURRENT_TIMESTAMP
    WHERE statid = 1;
    
    -- Return the new product ID
    PERFORM v_newproductid;
END $$;

-- Note: For ADO.NET, this needs to be restructured to return the ID properly
-- Alternative approach using simple INSERT...RETURNING:
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- ================================================================================
-- STATEMENT 4: UpdateProductAsync
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Original Source: ProductRepository.cs - UpdateProductAsync(Product product)
-- Changes Applied:
--   - BEGIN TRANSACTION converted to BEGIN
--   - DECLARE statements converted to PostgreSQL syntax
--   - Table names converted to lowercase (products, producthistory, productstats)
--   - Column names converted to lowercase
--   - GETDATE() replaced with CURRENT_TIMESTAMP
--   - Transaction structure modified for PostgreSQL with DO block
-- ================================================================================
DO $$
DECLARE 
    v_oldprice DECIMAL(18,2);
    v_oldstock INT;
BEGIN
    -- Store old values for history
    SELECT price, stockquantity INTO v_oldprice, v_oldstock
    FROM products
    WHERE productid = @ProductId;
    
    -- Update the product
    UPDATE products
    SET 
        name = @Name,
        description = @Description,
        price = @Price,
        stockquantity = @StockQuantity,
        modifieddate = CURRENT_TIMESTAMP
    WHERE productid = @ProductId;
    
    -- Log the changes
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'UPDATE', v_oldprice, @Price, v_oldstock, @StockQuantity, CURRENT_TIMESTAMP);
    
    -- Update product statistics
    UPDATE productstats
    SET 
        averageprice = (averageprice * totalproducts - v_oldprice + @Price) / totalproducts,
        lastupdated = CURRENT_TIMESTAMP
    WHERE statid = 1;
END $$;

-- ================================================================================
-- STATEMENT 5: DeleteProductAsync
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Original Source: ProductRepository.cs - DeleteProductAsync(int productId)
-- Changes Applied:
--   - BEGIN TRANSACTION converted to BEGIN
--   - DECLARE statements converted to PostgreSQL syntax
--   - Table names converted to lowercase (products, producthistory, productstats)
--   - Column names converted to lowercase
--   - GETDATE() replaced with CURRENT_TIMESTAMP
--   - Transaction structure modified for PostgreSQL with DO block
-- ================================================================================
DO $$
DECLARE 
    v_oldprice DECIMAL(18,2);
    v_oldstock INT;
BEGIN
    -- Store product info for history
    SELECT price, stockquantity INTO v_oldprice, v_oldstock
    FROM products
    WHERE productid = @ProductId;
    
    -- Log the deletion
    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
    VALUES (@ProductId, 'DELETE', v_oldprice, NULL, v_oldstock, NULL, CURRENT_TIMESTAMP);
    
    -- Delete the product
    DELETE FROM products 
    WHERE productid = @ProductId;
    
    -- Update product statistics
    UPDATE productstats
    SET 
        totalproducts = totalproducts - 1,
        averageprice = CASE 
            WHEN totalproducts > 1 
            THEN (averageprice * totalproducts - v_oldprice) / (totalproducts - 1)
            ELSE 0
        END,
        lastupdated = CURRENT_TIMESTAMP
    WHERE statid = 1;
END $$;

-- ================================================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Original Source: ProductRepository.cs - GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Changes Applied:
--   - Table names converted to lowercase (products)
--   - Column names converted to lowercase (productid, name, description, price, stockquantity, createddate, modifieddate)
--   - RANK() and PERCENT_RANK() window functions compatible with PostgreSQL
--   - Parameters @MinPrice and @MaxPrice remain unchanged
-- ================================================================================
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

-- ================================================================================
-- STATEMENT 7: GetLowStockProductsAsync
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- Original Source: ProductRepository.cs - GetLowStockProductsAsync(int threshold)
-- Changes Applied:
--   - Table names converted to lowercase (products)
--   - Column names converted to lowercase (productid, name, description, price, stockquantity, createddate, modifieddate)
--   - AVG, MIN, MAX window functions compatible with PostgreSQL
--   - ROUND function compatible with PostgreSQL
--   - Parameter @Threshold remains unchanged
-- ================================================================================
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

-- ================================================================================
-- END OF CONVERTED STATEMENTS
-- ================================================================================
