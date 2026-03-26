-- ============================================================================
-- Converted SQL Statements Catalog
-- Source: DataAccess/ProductRepository.cs
-- Total Statements: 7
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA (all 7)
-- DMS Failure Reason: Metadata model creation did not complete after 15 attempts
-- ============================================================================

-- ============================================================================
-- Statement 1: GetAllProductsAsync
-- Original (MS SQL):
-- ============================================================================
-- WITH ProductStats AS (
--     SELECT ProductId, AVG(Price) OVER() as AvgPrice, COUNT(*) OVER() as TotalProducts
--     FROM Products
-- )
-- SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate,
--     CASE WHEN p.Price > ps.AvgPrice THEN 'Above Average'
--          WHEN p.Price < ps.AvgPrice THEN 'Below Average' ELSE 'Average' END as PriceCategory,
--     ROUND((p.Price / ps.AvgPrice) * 100, 2) as PricePercentageOfAverage
-- FROM Products p INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId
-- ORDER BY CASE WHEN p.Price > ps.AvgPrice THEN 1 ELSE 2 END, p.Name
--
-- Converted (PostgreSQL):
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
-- Statement 2: GetProductByIdAsync
-- Original (MS SQL):
-- ============================================================================
-- WITH ProductHistory AS (
--     SELECT ProductId, LAG(Price) OVER (ORDER BY ModifiedDate) as PreviousPrice,
--            LAG(StockQuantity) OVER (ORDER BY ModifiedDate) as PreviousStock
--     FROM Products WHERE ProductId = @ProductId
-- )
-- SELECT p.ProductId, p.Name, p.Description, p.Price, p.StockQuantity, p.CreatedDate, p.ModifiedDate,
--     ph.PreviousPrice, ph.PreviousStock,
--     CASE WHEN ph.PreviousPrice IS NOT NULL THEN ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100, 2)
--          ELSE NULL END as PriceChangePercentage
-- FROM Products p LEFT JOIN ProductHistory ph ON p.ProductId = ph.ProductId
-- WHERE p.ProductId = @ProductId
--
-- Converted (PostgreSQL):
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
-- Statement 3: InsertProductAsync
-- Original (MS SQL):
-- ============================================================================
-- DECLARE @NewProductId INT;
-- BEGIN TRANSACTION;
--     INSERT INTO Products (Name, Description, Price, StockQuantity)
--     VALUES (@Name, @Description, @Price, @StockQuantity);
--     SET @NewProductId = SCOPE_IDENTITY();
--     INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
--     VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());
--     UPDATE ProductStats SET TotalProducts = TotalProducts + 1,
--         AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
--         LastUpdated = GETDATE() WHERE StatId = 1;
-- COMMIT;
-- SELECT @NewProductId;
--
-- Converted (PostgreSQL):
-- Key changes: SCOPE_IDENTITY() -> RETURNING, GETDATE() -> NOW(), BEGIN TRANSACTION -> BEGIN
-- ============================================================================

                DO $$
                DECLARE newproductid INT;
                BEGIN
                    -- Insert the new product
                    INSERT INTO products (name, description, price, stockquantity)
                    VALUES (@Name, @Description, @Price, @StockQuantity)
                    RETURNING productid INTO newproductid;
                    
                    -- Log the insertion
                    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    VALUES (newproductid, 'INSERT', NULL, @Price, NULL, @StockQuantity, NOW());
                    
                    -- Update product statistics
                    UPDATE productstats
                    SET 
                        totalproducts = totalproducts + 1,
                        averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
                        lastupdated = NOW()
                    WHERE statid = 1;
                END $$;
                
                SELECT currval(pg_get_serial_sequence('products', 'productid'));

-- ============================================================================
-- Statement 4: UpdateProductAsync
-- Original (MS SQL):
-- ============================================================================
-- BEGIN TRANSACTION;
--     DECLARE @OldPrice DECIMAL(18,2); DECLARE @OldStock INT;
--     SELECT @OldPrice = Price, @OldStock = StockQuantity FROM Products WHERE ProductId = @ProductId;
--     UPDATE Products SET Name = @Name, Description = @Description, Price = @Price,
--         StockQuantity = @StockQuantity, ModifiedDate = GETDATE() WHERE ProductId = @ProductId;
--     INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
--     VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());
--     UPDATE ProductStats SET AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
--         LastUpdated = GETDATE() WHERE StatId = 1;
-- COMMIT;
--
-- Converted (PostgreSQL):
-- Key changes: DECLARE -> DO $$ DECLARE, GETDATE() -> NOW(), BEGIN TRANSACTION -> BEGIN
-- ============================================================================

                DO $$
                DECLARE oldprice DECIMAL(18,2);
                DECLARE oldstock INT;
                BEGIN
                    -- Store old values for history
                    SELECT price, stockquantity INTO oldprice, oldstock
                    FROM products
                    WHERE productid = @ProductId;
                    
                    -- Update the product
                    UPDATE products
                    SET 
                        name = @Name,
                        description = @Description,
                        price = @Price,
                        stockquantity = @StockQuantity,
                        modifieddate = NOW()
                    WHERE productid = @ProductId;
                    
                    -- Log the changes
                    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    VALUES (@ProductId, 'UPDATE', oldprice, @Price, oldstock, @StockQuantity, NOW());
                    
                    -- Update product statistics
                    UPDATE productstats
                    SET 
                        averageprice = (averageprice * totalproducts - oldprice + @Price) / totalproducts,
                        lastupdated = NOW()
                    WHERE statid = 1;
                END $$;

-- ============================================================================
-- Statement 5: DeleteProductAsync
-- Original (MS SQL):
-- ============================================================================
-- BEGIN TRANSACTION;
--     DECLARE @OldPrice DECIMAL(18,2); DECLARE @OldStock INT;
--     SELECT @OldPrice = Price, @OldStock = StockQuantity FROM Products WHERE ProductId = @ProductId;
--     INSERT INTO ProductHistory (...) VALUES (..., GETDATE());
--     DELETE FROM Products WHERE ProductId = @ProductId;
--     UPDATE ProductStats SET TotalProducts = TotalProducts - 1,
--         AveragePrice = CASE WHEN TotalProducts > 1 THEN ... ELSE 0 END,
--         LastUpdated = GETDATE() WHERE StatId = 1;
-- COMMIT;
--
-- Converted (PostgreSQL):
-- ============================================================================

                DO $$
                DECLARE oldprice DECIMAL(18,2);
                DECLARE oldstock INT;
                BEGIN
                    -- Store product info for history
                    SELECT price, stockquantity INTO oldprice, oldstock
                    FROM products
                    WHERE productid = @ProductId;
                    
                    -- Log the deletion
                    INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                    VALUES (@ProductId, 'DELETE', oldprice, NULL, oldstock, NULL, NOW());
                    
                    -- Delete the product
                    DELETE FROM products 
                    WHERE productid = @ProductId;
                    
                    -- Update product statistics
                    UPDATE productstats
                    SET 
                        totalproducts = totalproducts - 1,
                        averageprice = CASE 
                            WHEN totalproducts > 1 
                            THEN (averageprice * totalproducts - oldprice) / (totalproducts - 1)
                            ELSE 0
                        END,
                        lastupdated = NOW()
                    WHERE statid = 1;
                END $$;

-- ============================================================================
-- Statement 6: GetProductsByPriceRangeAsync
-- Original (MS SQL):
-- ============================================================================
-- WITH RankedProducts AS (
--     SELECT p.*, RANK() OVER (ORDER BY p.Price) as PriceRank,
--            PERCENT_RANK() OVER (ORDER BY p.Price) as PricePercentile
--     FROM Products p WHERE p.Price BETWEEN @MinPrice AND @MaxPrice
-- )
-- SELECT rp.*, CASE WHEN rp.PricePercentile <= 0.25 THEN 'Budget' ... END as PriceSegment
-- FROM RankedProducts rp ORDER BY rp.PriceRank
--
-- Converted (PostgreSQL):
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
-- Statement 7: GetLowStockProductsAsync
-- Original (MS SQL):
-- ============================================================================
-- WITH StockAnalysis AS (
--     SELECT p.*, AVG(StockQuantity) OVER() as AvgStock, MIN(StockQuantity) OVER() as MinStock,
--            MAX(StockQuantity) OVER() as MaxStock FROM Products p
-- )
-- SELECT sa.*, CASE WHEN StockQuantity <= @Threshold THEN 'Critical' ... END as StockStatus,
--     ROUND((StockQuantity / AvgStock) * 100, 2) as StockPercentageOfAverage
-- FROM StockAnalysis sa WHERE StockQuantity <= @Threshold ORDER BY StockQuantity
--
-- Converted (PostgreSQL):
-- Key changes: Added CAST for integer division fix
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
                    ROUND((CAST(stockquantity AS DECIMAL) / avgstock) * 100, 2) as stockpercentageofaverage
                FROM stockanalysis sa
                WHERE stockquantity <= @Threshold
                ORDER BY stockquantity;

-- ============================================================================
-- END OF CONVERTED STATEMENTS CATALOG
-- ============================================================================
