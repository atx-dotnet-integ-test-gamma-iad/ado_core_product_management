-- ============================================================
-- EXTRACTED SQL STATEMENTS FROM ProductRepository.cs
-- Source: sourceCode/DataAccess/ProductRepository.cs
-- Total Statements: 7
-- ============================================================

-- ============================================================
-- STATEMENT 1: GetAllProductsAsync
-- Location: ProductRepository.cs, lines ~43-67
-- Method: GetAllProductsAsync()
-- Parameters: None
-- Description: Complex SELECT with CTE (ProductStats), window functions
--              (AVG OVER, COUNT OVER), INNER JOIN, CASE expressions, ROUND
-- ============================================================

                WITH ProductStats AS (
                    SELECT 
                        ProductId,
                        AVG(Price) OVER() as AvgPrice,
                        COUNT(*) OVER() as TotalProducts
                    FROM Products
                )
                SELECT 
                    p.ProductId,
                    p.Name,
                    p.Description,
                    p.Price,
                    p.StockQuantity,
                    p.CreatedDate,
                    p.ModifiedDate,
                    CASE 
                        WHEN p.Price > ps.AvgPrice THEN 'Above Average'
                        WHEN p.Price < ps.AvgPrice THEN 'Below Average'
                        ELSE 'Average'
                    END as PriceCategory,
                    ROUND((p.Price / ps.AvgPrice) * 100, 2) as PricePercentageOfAverage
                FROM Products p
                INNER JOIN ProductStats ps ON p.ProductId = ps.ProductId
                ORDER BY 
                    CASE 
                        WHEN p.Price > ps.AvgPrice THEN 1
                        ELSE 2
                    END,
                    p.Name;

-- ============================================================
-- STATEMENT 2: GetProductByIdAsync
-- Location: ProductRepository.cs, lines ~79-101
-- Method: GetProductByIdAsync(int productId)
-- Parameters: @ProductId
-- Description: SELECT with CTE (ProductHistory), window functions
--              (LAG OVER), LEFT JOIN, CASE with NULL handling
-- ============================================================

                WITH ProductHistory AS (
                    SELECT 
                        ProductId,
                        LAG(Price) OVER (ORDER BY ModifiedDate) as PreviousPrice,
                        LAG(StockQuantity) OVER (ORDER BY ModifiedDate) as PreviousStock
                    FROM Products
                    WHERE ProductId = @ProductId
                )
                SELECT 
                    p.ProductId,
                    p.Name,
                    p.Description,
                    p.Price,
                    p.StockQuantity,
                    p.CreatedDate,
                    p.ModifiedDate,
                    ph.PreviousPrice,
                    ph.PreviousStock,
                    CASE 
                        WHEN ph.PreviousPrice IS NOT NULL THEN 
                            ROUND(((p.Price - ph.PreviousPrice) / ph.PreviousPrice) * 100, 2)
                        ELSE NULL
                    END as PriceChangePercentage
                FROM Products p
                LEFT JOIN ProductHistory ph ON p.ProductId = ph.ProductId
                WHERE p.ProductId = @ProductId;

-- ============================================================
-- STATEMENT 3: InsertProductAsync
-- Location: ProductRepository.cs, lines ~115-134
-- Method: InsertProductAsync(Product product)
-- Parameters: @Name, @Description, @Price, @StockQuantity
-- Description: Transaction block with DECLARE, INSERT, SCOPE_IDENTITY(),
--              INSERT INTO ProductHistory, UPDATE ProductStats, GETDATE()
-- ============================================================

                DECLARE @NewProductId INT;
                
                BEGIN TRANSACTION;
                    -- Insert the new product
                    INSERT INTO Products (Name, Description, Price, StockQuantity)
                    VALUES (@Name, @Description, @Price, @StockQuantity);
                    
                    SET @NewProductId = SCOPE_IDENTITY();
                    
                    -- Log the insertion
                    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
                    VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, GETDATE());
                    
                    -- Update product statistics
                    UPDATE ProductStats
                    SET 
                        TotalProducts = TotalProducts + 1,
                        AveragePrice = (AveragePrice * TotalProducts + @Price) / (TotalProducts + 1),
                        LastUpdated = GETDATE()
                    WHERE StatId = 1;
                COMMIT;
                
                SELECT @NewProductId;

-- ============================================================
-- STATEMENT 4: UpdateProductAsync
-- Location: ProductRepository.cs, lines ~149-177
-- Method: UpdateProductAsync(Product product)
-- Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
-- Description: Transaction block with DECLARE variables, SELECT INTO variables,
--              UPDATE Products with GETDATE(), INSERT ProductHistory, UPDATE ProductStats
-- ============================================================

                BEGIN TRANSACTION;
                    -- Store old values for history
                    DECLARE @OldPrice DECIMAL(18,2);
                    DECLARE @OldStock INT;
                    
                    SELECT @OldPrice = Price, @OldStock = StockQuantity
                    FROM Products
                    WHERE ProductId = @ProductId;
                    
                    -- Update the product
                    UPDATE Products
                    SET 
                        Name = @Name,
                        Description = @Description,
                        Price = @Price,
                        StockQuantity = @StockQuantity,
                        ModifiedDate = GETDATE()
                    WHERE ProductId = @ProductId;
                    
                    -- Log the changes
                    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
                    VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, GETDATE());
                    
                    -- Update product statistics
                    UPDATE ProductStats
                    SET 
                        AveragePrice = (AveragePrice * TotalProducts - @OldPrice + @Price) / TotalProducts,
                        LastUpdated = GETDATE()
                    WHERE StatId = 1;
                COMMIT;

-- ============================================================
-- STATEMENT 5: DeleteProductAsync
-- Location: ProductRepository.cs, lines ~192-222
-- Method: DeleteProductAsync(int productId)
-- Parameters: @ProductId
-- Description: Transaction block with DECLARE variables, SELECT INTO variables,
--              INSERT ProductHistory, DELETE FROM Products, UPDATE ProductStats
--              with CASE expression, GETDATE()
-- ============================================================

                BEGIN TRANSACTION;
                    -- Store product info for history
                    DECLARE @OldPrice DECIMAL(18,2);
                    DECLARE @OldStock INT;
                    
                    SELECT @OldPrice = Price, @OldStock = StockQuantity
                    FROM Products
                    WHERE ProductId = @ProductId;
                    
                    -- Log the deletion
                    INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
                    VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, GETDATE());
                    
                    -- Delete the product
                    DELETE FROM Products 
                    WHERE ProductId = @ProductId;
                    
                    -- Update product statistics
                    UPDATE ProductStats
                    SET 
                        TotalProducts = TotalProducts - 1,
                        AveragePrice = CASE 
                            WHEN TotalProducts > 1 
                            THEN (AveragePrice * TotalProducts - @OldPrice) / (TotalProducts - 1)
                            ELSE 0
                        END,
                        LastUpdated = GETDATE()
                    WHERE StatId = 1;
                COMMIT;

-- ============================================================
-- STATEMENT 6: GetProductsByPriceRangeAsync
-- Location: ProductRepository.cs, lines ~233-250
-- Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
-- Parameters: @MinPrice, @MaxPrice
-- Description: SELECT with CTE (RankedProducts), window functions
--              (RANK OVER, PERCENT_RANK OVER), BETWEEN, CASE expressions
-- ============================================================

                WITH RankedProducts AS (
                    SELECT 
                        p.*,
                        RANK() OVER (ORDER BY p.Price) as PriceRank,
                        PERCENT_RANK() OVER (ORDER BY p.Price) as PricePercentile
                    FROM Products p
                    WHERE p.Price BETWEEN @MinPrice AND @MaxPrice
                )
                SELECT 
                    rp.*,
                    CASE 
                        WHEN rp.PricePercentile <= 0.25 THEN 'Budget'
                        WHEN rp.PricePercentile <= 0.75 THEN 'Mid-Range'
                        ELSE 'Premium'
                    END as PriceSegment
                FROM RankedProducts rp
                ORDER BY rp.PriceRank;

-- ============================================================
-- STATEMENT 7: GetLowStockProductsAsync
-- Location: ProductRepository.cs, lines ~266-283
-- Method: GetLowStockProductsAsync(int threshold)
-- Parameters: @Threshold
-- Description: SELECT with CTE (StockAnalysis), window functions
--              (AVG OVER, MIN OVER, MAX OVER), CASE expressions, ROUND
-- ============================================================

                WITH StockAnalysis AS (
                    SELECT 
                        p.*,
                        AVG(StockQuantity) OVER() as AvgStock,
                        MIN(StockQuantity) OVER() as MinStock,
                        MAX(StockQuantity) OVER() as MaxStock
                    FROM Products p
                )
                SELECT 
                    sa.*,
                    CASE 
                        WHEN StockQuantity <= @Threshold THEN 'Critical'
                        WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low'
                        ELSE 'Adequate'
                    END as StockStatus,
                    ROUND((StockQuantity / AvgStock) * 100, 2) as StockPercentageOfAverage
                FROM StockAnalysis sa
                WHERE StockQuantity <= @Threshold
                ORDER BY StockQuantity;

-- ============================================================
-- SCHEMA REFERENCE (from Database/Scripts/01_InitialSetup.sql)
-- Tables used: Products, ProductHistory, ProductStats, Categories, Suppliers
-- ============================================================
