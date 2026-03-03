-- =============================================================
-- EXTRACTED SQL STATEMENTS CATALOG
-- Source File: sourceCode/DataAccess/ProductRepository.cs
-- Total Statements: 7
-- Date: 2026-03-03
-- =============================================================

-- =============================================================
-- Statement 1: GetAllProductsAsync()
-- Source: ProductRepository.cs, method GetAllProductsAsync()
-- Parameters: None
-- Description: Complex SELECT with CTE (productstats), window functions
--   (AVG OVER, COUNT OVER), CASE expressions, and ORDER BY
-- =============================================================

WITH productstats AS (SELECT productid, AVG(price) OVER () AS avgprice, COUNT(*) OVER () AS totalproducts FROM dbo.products) SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate, CASE WHEN p.price > ps.avgprice THEN 'Above Average' WHEN p.price < ps.avgprice THEN 'Below Average' ELSE 'Average' END AS pricecategory, ROUND((p.price / ps.avgprice) * 100, 2) AS pricepercentageofaverage FROM dbo.products AS p INNER JOIN productstats AS ps ON p.productid = ps.productid ORDER BY CASE WHEN p.price > ps.avgprice THEN 1 ELSE 2 END, p.name;

-- =============================================================
-- Statement 2: GetProductByIdAsync(int productId)
-- Source: ProductRepository.cs, method GetProductByIdAsync()
-- Parameters: @ProductId (int)
-- Description: SELECT with CTE (producthistory), LAG window function,
--   LEFT OUTER JOIN, CASE with arithmetic, parameterized
-- =============================================================

WITH producthistory AS (SELECT productid, lag(price) OVER (ORDER BY modifieddate) AS previousprice, lag(stockquantity) OVER (ORDER BY modifieddate) AS previousstock FROM dbo.products WHERE productid = @ProductId) SELECT p.productid, p.name, p.description, p.price, p.stockquantity, p.createddate, p.modifieddate, ph.previousprice, ph.previousstock, CASE WHEN ph.previousprice IS NOT NULL THEN ROUND(((p.price - ph.previousprice) / ph.previousprice) * 100, 2) ELSE NULL END AS pricechangepercentage FROM dbo.products AS p LEFT OUTER JOIN producthistory AS ph ON p.productid = ph.productid WHERE p.productid = @ProductId;

-- =============================================================
-- Statement 3: InsertProductAsync(Product product)
-- Source: ProductRepository.cs, method InsertProductAsync()
-- Parameters: @Name (string), @Description (string), @Price (decimal), @StockQuantity (int)
-- Description: T-SQL transaction block with DECLARE, INSERT with SCOPE_IDENTITY(),
--   INSERT INTO producthistory, UPDATE productstats
-- =============================================================

BEGIN TRANSACTION; DECLARE @NewProductId INT; INSERT INTO dbo.Products (Name, Description, Price, StockQuantity) VALUES (@Name, @Description, @Price, @StockQuantity); SET @NewProductId = SCOPE_IDENTITY(); INSERT INTO dbo.ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate) VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE()); UPDATE dbo.ProductStats SET TotalProducts = TotalProducts + 1, AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1), LastUpdated = GETDATE() WHERE StatId = 1; COMMIT TRANSACTION; SELECT @NewProductId;

-- =============================================================
-- Statement 4: UpdateProductAsync(Product product)
-- Source: ProductRepository.cs, method UpdateProductAsync()
-- Parameters: @ProductId (int), @Name (string), @Description (string),
--   @Price (decimal), @StockQuantity (int)
-- Description: T-SQL DECLARE, SELECT INTO variables, UPDATE products,
--   INSERT INTO producthistory, UPDATE productstats
-- =============================================================

DECLARE @OldPrice DECIMAL(18,2); DECLARE @OldStock INT; SELECT @OldPrice = Price, @OldStock = StockQuantity FROM dbo.Products WHERE ProductId = @ProductId; UPDATE dbo.Products SET Name = @Name, Description = @Description, Price = @Price, StockQuantity = @StockQuantity, ModifiedDate = GETDATE() WHERE ProductId = @ProductId; INSERT INTO dbo.ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate) VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE()); UPDATE dbo.ProductStats SET AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts, LastUpdated = GETDATE() WHERE StatId = 1;

-- =============================================================
-- Statement 5: DeleteProductAsync(int productId)
-- Source: ProductRepository.cs, method DeleteProductAsync()
-- Parameters: @ProductId (int)
-- Description: T-SQL DECLARE, SELECT INTO variables, INSERT INTO producthistory,
--   DELETE FROM products, UPDATE productstats with CASE
-- =============================================================

DECLARE @OldPrice DECIMAL(18,2); DECLARE @OldStock INT; SELECT @OldPrice = Price, @OldStock = StockQuantity FROM dbo.Products WHERE ProductId = @ProductId; INSERT INTO dbo.ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate) VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE()); DELETE FROM dbo.Products WHERE ProductId = @ProductId; UPDATE dbo.ProductStats SET TotalProducts = TotalProducts - 1, AveragePrice = CASE WHEN TotalProducts > 1 THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1) ELSE 0 END, LastUpdated = GETDATE() WHERE StatId = 1;

-- =============================================================
-- Statement 6: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Source: ProductRepository.cs, method GetProductsByPriceRangeAsync()
-- Parameters: @MinPrice (decimal), @MaxPrice (decimal)
-- Description: SELECT with CTE (rankedproducts), RANK and PERCENT_RANK window functions,
--   BETWEEN clause, CASE expressions
-- =============================================================

WITH rankedproducts AS (SELECT p.*, RANK() OVER (ORDER BY p.price) AS pricerank, percent_rank() OVER (ORDER BY p.price) AS pricepercentile FROM dbo.products AS p WHERE p.price BETWEEN @MinPrice AND @MaxPrice) SELECT rp.*, CASE WHEN rp.pricepercentile <= 0.25 THEN 'Budget' WHEN rp.pricepercentile <= 0.75 THEN 'Mid-Range' ELSE 'Premium' END AS pricesegment FROM rankedproducts AS rp ORDER BY rp.pricerank;

-- =============================================================
-- Statement 7: GetLowStockProductsAsync(int threshold)
-- Source: ProductRepository.cs, method GetLowStockProductsAsync()
-- Parameters: @Threshold (int)
-- Description: SELECT with CTE (stockanalysis), AVG/MIN/MAX window functions,
--   CASE expressions, WHERE filter
-- =============================================================

WITH stockanalysis AS (SELECT p.*, AVG(stockquantity) OVER () AS avgstock, MIN(stockquantity) OVER () AS minstock, MAX(stockquantity) OVER () AS maxstock FROM dbo.products AS p) SELECT sa.*, CASE WHEN stockquantity <= @Threshold THEN 'Critical' WHEN stockquantity <= avgstock * 0.5 THEN 'Low' ELSE 'Adequate' END AS stockstatus, ROUND((stockquantity / avgstock) * 100, 2) AS stockpercentageofaverage FROM stockanalysis AS sa WHERE stockquantity <= @Threshold ORDER BY stockquantity;
