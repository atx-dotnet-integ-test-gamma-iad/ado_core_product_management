/*******************************************************************************
 * SQL STATEMENT EXTRACTION CATALOG
 * Source: Microsoft SQL Server ADO.NET Application
 * Target: PostgreSQL Migration
 * Generated: Step 1 - Extract and Catalog All SQL Statements
 ******************************************************************************/

/*******************************************************************************
 * STATEMENT 1: GetAllProductsAsync
 * Source File: DataAccess/ProductRepository.cs
 * Method: GetAllProductsAsync()
 * Lines: 37-73
 * Statement Type: SELECT with CTE and Window Functions
 * Parameters: None
 * SQL Server Specific Functions: AVG() OVER(), COUNT() OVER()
 * Tables: Products
 * Description: Retrieves all products with price category analysis using window functions
 ******************************************************************************/

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

/*******************************************************************************
 * STATEMENT 2: GetProductByIdAsync
 * Source File: DataAccess/ProductRepository.cs
 * Method: GetProductByIdAsync(int productId)
 * Lines: 79-110
 * Statement Type: SELECT with CTE and LAG Window Function
 * Parameters: @ProductId (int)
 * SQL Server Specific Functions: LAG() OVER()
 * Tables: Products
 * Description: Retrieves product by ID with historical price comparison using LAG
 ******************************************************************************/

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

/*******************************************************************************
 * STATEMENT 3: InsertProductAsync - Transaction Block
 * Source File: DataAccess/ProductRepository.cs
 * Method: InsertProductAsync(Product product)
 * Lines: 120-149
 * Statement Type: TRANSACTION with INSERT, UPDATE
 * Parameters: @Name, @Description, @Price, @StockQuantity
 * SQL Server Specific Functions: SCOPE_IDENTITY(), GETDATE()
 * Tables: Products, ProductHistory, ProductStats
 * Description: Inserts new product with history logging and statistics update
 ******************************************************************************/

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

/*******************************************************************************
 * STATEMENT 4: UpdateProductAsync - Transaction Block
 * Source File: DataAccess/ProductRepository.cs
 * Method: UpdateProductAsync(Product product)
 * Lines: 162-195
 * Statement Type: TRANSACTION with UPDATE, INSERT
 * Parameters: @ProductId, @Name, @Description, @Price, @StockQuantity
 * SQL Server Specific Functions: GETDATE()
 * Tables: Products, ProductHistory, ProductStats
 * Description: Updates product with history logging and statistics recalculation
 ******************************************************************************/

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

/*******************************************************************************
 * STATEMENT 5: DeleteProductAsync - Transaction Block
 * Source File: DataAccess/ProductRepository.cs
 * Method: DeleteProductAsync(int productId)
 * Lines: 209-240
 * Statement Type: TRANSACTION with DELETE, INSERT, UPDATE
 * Parameters: @ProductId
 * SQL Server Specific Functions: GETDATE()
 * Tables: Products, ProductHistory, ProductStats
 * Description: Deletes product with history logging and statistics update
 ******************************************************************************/

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

/*******************************************************************************
 * STATEMENT 6: GetProductsByPriceRangeAsync
 * Source File: DataAccess/ProductRepository.cs
 * Method: GetProductsByPriceRangeAsync(decimal minPrice, decimal maxPrice)
 * Lines: 256-278
 * Statement Type: SELECT with CTE and Window Functions
 * Parameters: @MinPrice, @MaxPrice
 * SQL Server Specific Functions: RANK() OVER(), PERCENT_RANK() OVER()
 * Tables: Products
 * Description: Retrieves products in price range with ranking and percentile
 ******************************************************************************/

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

/*******************************************************************************
 * STATEMENT 7: GetLowStockProductsAsync
 * Source File: DataAccess/ProductRepository.cs
 * Method: GetLowStockProductsAsync(int threshold)
 * Lines: 290-318
 * Statement Type: SELECT with CTE and Window Functions
 * Parameters: @Threshold
 * SQL Server Specific Functions: AVG() OVER(), MIN() OVER(), MAX() OVER()
 * Tables: Products
 * Description: Retrieves low stock products with stock status analysis
 ******************************************************************************/

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

/*******************************************************************************
 * SUMMARY OF EXTRACTED STATEMENTS
 ******************************************************************************/
/*
Total Statements Extracted: 7

Statement Types:
- SELECT with CTE and Window Functions: 4 statements (1, 2, 6, 7)
- Transaction Blocks (INSERT/UPDATE/DELETE): 3 statements (3, 4, 5)

SQL Server Specific Functions Found:
- SCOPE_IDENTITY() - 1 occurrence in Statement 3
- GETDATE() - 9 occurrences across Statements 3, 4, 5
- LAG() OVER() - 2 occurrences in Statement 2
- RANK() OVER() - 1 occurrence in Statement 6
- PERCENT_RANK() OVER() - 1 occurrence in Statement 6
- AVG() OVER() - 2 occurrences in Statements 1, 7
- COUNT() OVER() - 1 occurrence in Statement 1
- MIN() OVER() - 1 occurrence in Statement 7
- MAX() OVER() - 1 occurrence in Statement 7

Parameters Used:
- @ProductId - Statements 2
- @Name, @Description, @Price, @StockQuantity - Statements 3, 4
- @MinPrice, @MaxPrice - Statement 6
- @Threshold - Statement 7

Tables Referenced:
- Products - All statements
- ProductHistory - Statements 3, 4, 5
- ProductStats - Statements 3, 4, 5

All statements have been successfully extracted and cataloged for DMS conversion.
*/
