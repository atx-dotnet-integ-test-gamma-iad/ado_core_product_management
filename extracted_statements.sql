-- =====================================================
-- Extracted SQL Statements from ProductRepository.cs
-- Source: DataAccess/ProductRepository.cs
-- Total Statements: 15
-- =====================================================

-- =====================================================
-- Statement 1: GetAllProductsAsync - Complex SELECT with CTE
-- Method: GetAllProductsAsync()
-- Transaction: No
-- Parameters: None
-- =====================================================
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

-- =====================================================
-- Statement 2: GetProductByIdAsync - SELECT with CTE, window functions
-- Method: GetProductByIdAsync(int productId)
-- Transaction: No
-- Parameters: @ProductId
-- =====================================================
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

-- =====================================================
-- Statement 3: InsertProductAsync - INSERT with RETURNING
-- Method: InsertProductAsync(Product product)
-- Transaction: Yes (statement 1 of 3)
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- =====================================================
INSERT INTO products (name, description, price, stockquantity)
VALUES (@Name, @Description, @Price, @StockQuantity)
RETURNING productid;

-- =====================================================
-- Statement 4: InsertProductAsync - INSERT into history log
-- Method: InsertProductAsync(Product product)
-- Transaction: Yes (statement 2 of 3)
-- Parameters: @ProductId, @Price, @StockQuantity
-- =====================================================
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());

-- =====================================================
-- Statement 5: InsertProductAsync - UPDATE stats
-- Method: InsertProductAsync(Product product)
-- Transaction: Yes (statement 3 of 3)
-- Parameters: @Price
-- =====================================================
UPDATE productstats
SET 
    totalproducts = totalproducts + 1,
    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
    lastupdated = NOW()
WHERE statid = 1;

-- =====================================================
-- Statement 6: UpdateProductAsync - SELECT old values
-- Method: UpdateProductAsync(Product product)
-- Transaction: Yes (statement 1 of 4)
-- Parameters: @ProductId
-- =====================================================
SELECT price, stockquantity FROM products WHERE productid = @ProductId;

-- =====================================================
-- Statement 7: UpdateProductAsync - UPDATE product
-- Method: UpdateProductAsync(Product product)
-- Transaction: Yes (statement 2 of 4)
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- =====================================================
UPDATE products
SET 
    name = @Name,
    description = @Description,
    price = @Price,
    stockquantity = @StockQuantity,
    modifieddate = NOW()
WHERE productid = @ProductId;

-- =====================================================
-- Statement 8: UpdateProductAsync - INSERT into history log
-- Method: UpdateProductAsync(Product product)
-- Transaction: Yes (statement 3 of 4)
-- Parameters: @ProductId, @OldPrice, @Price, @OldStock, @StockQuantity
-- =====================================================
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, NOW());

-- =====================================================
-- Statement 9: UpdateProductAsync - UPDATE stats
-- Method: UpdateProductAsync(Product product)
-- Transaction: Yes (statement 4 of 4)
-- Parameters: @OldPrice, @Price
-- =====================================================
UPDATE productstats
SET 
    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
    lastupdated = NOW()
WHERE statid = 1;

-- =====================================================
-- Statement 10: DeleteProductAsync - SELECT old values
-- Method: DeleteProductAsync(int productId)
-- Transaction: Yes (statement 1 of 4)
-- Parameters: @ProductId
-- =====================================================
SELECT price, stockquantity FROM products WHERE productid = @ProductId;

-- =====================================================
-- Statement 11: DeleteProductAsync - INSERT into history log
-- Method: DeleteProductAsync(int productId)
-- Transaction: Yes (statement 2 of 4)
-- Parameters: @ProductId, @OldPrice, @OldStock
-- =====================================================
INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, NOW());

-- =====================================================
-- Statement 12: DeleteProductAsync - DELETE product
-- Method: DeleteProductAsync(int productId)
-- Transaction: Yes (statement 3 of 4)
-- Parameters: @ProductId
-- =====================================================
DELETE FROM products 
WHERE productid = @ProductId;

-- =====================================================
-- Statement 13: DeleteProductAsync - UPDATE stats with CASE
-- Method: DeleteProductAsync(int productId)
-- Transaction: Yes (statement 4 of 4)
-- Parameters: @OldPrice
-- =====================================================
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

-- =====================================================
-- Statement 14: GetProductsByPriceRangeAsync - SELECT with RANK, PERCENT_RANK
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Transaction: No
-- Parameters: @MinPrice, @MaxPrice
-- =====================================================
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

-- =====================================================
-- Statement 15: GetLowStockProductsAsync - SELECT with AVG/MIN/MAX OVER
-- Method: GetLowStockProductsAsync(int threshold)
-- Transaction: No
-- Parameters: @Threshold
-- =====================================================
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
