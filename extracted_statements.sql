/*******************************************************************************
 * SQL STATEMENT EXTRACTION CATALOG
 * Microsoft SQL Server to PostgreSQL Migration
 * Source File: ProductRepository.cs
 * Total Statements Extracted: 7
 * Extraction Date: 2025
 * 
 * CRITICAL: ALL statements in this catalog MUST be processed through the
 * DMS MCP tool (dms-mcp____statement_conversion_tool) for conversion.
 * No exceptions.
 ******************************************************************************/

/*******************************************************************************
 * STATEMENT 1: GetAllProductsAsync
 * Source Location: ProductRepository.cs, Lines 38-69
 * Statement Type: Complex CTE with Window Functions
 * Complexity: HIGH
 * 
 * Description:
 *   - Uses CTE (ProductStats) with window functions
 *   - AVG() OVER() and COUNT() OVER() window functions
 *   - INNER JOIN with CTE
 *   - CASE expressions for categorization
 *   - Complex ORDER BY with CASE expression
 *   - ROUND() function for percentage calculation
 * 
 * Parameters: None
 * 
 * Tables Referenced:
 *   - Products (main table)
 *   - ProductStats (CTE)
 * 
 * Schema Objects:
 *   - Products.ProductId
 *   - Products.Name
 *   - Products.Description
 *   - Products.Price
 *   - Products.StockQuantity
 *   - Products.CreatedDate
 *   - Products.ModifiedDate
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
    p.Name

/*******************************************************************************
 * STATEMENT 2: GetProductByIdAsync
 * Source Location: ProductRepository.cs, Lines 87-112
 * Statement Type: CTE with LAG Window Function and Parameterized Query
 * Complexity: MEDIUM-HIGH
 * 
 * Description:
 *   - Uses CTE (ProductHistory) with LAG() window function
 *   - LAG() OVER (ORDER BY ModifiedDate) for historical comparison
 *   - LEFT JOIN with CTE
 *   - CASE expression for NULL handling and percentage calculation
 *   - ROUND() function for percentage
 *   - Parameterized query with @ProductId
 * 
 * Parameters:
 *   - @ProductId (INT) - Product identifier
 * 
 * Tables Referenced:
 *   - Products (main table)
 *   - ProductHistory (CTE)
 * 
 * Schema Objects:
 *   - Products.ProductId
 *   - Products.Name
 *   - Products.Description
 *   - Products.Price
 *   - Products.StockQuantity
 *   - Products.CreatedDate
 *   - Products.ModifiedDate
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
WHERE p.ProductId = @ProductId

/*******************************************************************************
 * STATEMENT 3: InsertProductAsync
 * Source Location: ProductRepository.cs, Lines 130-152
 * Statement Type: Multi-Statement Transaction Block with SCOPE_IDENTITY
 * Complexity: HIGH
 * 
 * Description:
 *   - Multi-statement transaction block (BEGIN TRANSACTION ... COMMIT)
 *   - DECLARE variable (@NewProductId)
 *   - INSERT INTO Products with parameterized values
 *   - SCOPE_IDENTITY() to retrieve last inserted ID (SQL Server specific)
 *   - INSERT INTO ProductHistory for audit logging
 *   - UPDATE ProductStats with aggregate calculations
 *   - GETDATE() function calls (SQL Server specific)
 *   - Final SELECT to return the new ID
 * 
 * Parameters:
 *   - @Name (VARCHAR/NVARCHAR) - Product name
 *   - @Description (VARCHAR/NVARCHAR) - Product description (nullable)
 *   - @Price (DECIMAL) - Product price
 *   - @StockQuantity (INT) - Stock quantity
 * 
 * Tables Referenced:
 *   - Products (INSERT target)
 *   - ProductHistory (INSERT for audit)
 *   - ProductStats (UPDATE for aggregates)
 * 
 * SQL Server Specific Functions:
 *   - SCOPE_IDENTITY() - Must be converted to PostgreSQL RETURNING or LASTVAL()
 *   - GETDATE() - Must be converted to NOW() or CURRENT_TIMESTAMP
 * 
 * Transaction Boundaries:
 *   - BEGIN TRANSACTION
 *   - COMMIT
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
 * STATEMENT 4: UpdateProductAsync
 * Source Location: ProductRepository.cs, Lines 165-193
 * Statement Type: Multi-Statement Transaction Block with Local Variables
 * Complexity: HIGH
 * 
 * Description:
 *   - Multi-statement transaction block (BEGIN TRANSACTION ... COMMIT)
 *   - DECLARE variables (@OldPrice, @OldStock) for storing previous values
 *   - SELECT INTO variables to capture old values
 *   - UPDATE Products with parameterized values
 *   - INSERT INTO ProductHistory for audit logging
 *   - UPDATE ProductStats with aggregate recalculation
 *   - GETDATE() function calls (SQL Server specific)
 * 
 * Parameters:
 *   - @ProductId (INT) - Product identifier
 *   - @Name (VARCHAR/NVARCHAR) - Product name
 *   - @Description (VARCHAR/NVARCHAR) - Product description (nullable)
 *   - @Price (DECIMAL) - Product price
 *   - @StockQuantity (INT) - Stock quantity
 * 
 * Tables Referenced:
 *   - Products (SELECT and UPDATE target)
 *   - ProductHistory (INSERT for audit)
 *   - ProductStats (UPDATE for aggregates)
 * 
 * SQL Server Specific Functions:
 *   - GETDATE() - Must be converted to NOW() or CURRENT_TIMESTAMP
 * 
 * Transaction Boundaries:
 *   - BEGIN TRANSACTION
 *   - COMMIT
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
 * STATEMENT 5: DeleteProductAsync
 * Source Location: ProductRepository.cs, Lines 206-237
 * Statement Type: Multi-Statement Transaction Block with Conditional Logic
 * Complexity: HIGH
 * 
 * Description:
 *   - Multi-statement transaction block (BEGIN TRANSACTION ... COMMIT)
 *   - DECLARE variables (@OldPrice, @OldStock) for storing values before deletion
 *   - SELECT INTO variables to capture values
 *   - INSERT INTO ProductHistory for audit logging before deletion
 *   - DELETE FROM Products
 *   - UPDATE ProductStats with aggregate recalculation including CASE expression
 *   - GETDATE() function calls (SQL Server specific)
 * 
 * Parameters:
 *   - @ProductId (INT) - Product identifier to delete
 * 
 * Tables Referenced:
 *   - Products (SELECT and DELETE target)
 *   - ProductHistory (INSERT for audit)
 *   - ProductStats (UPDATE for aggregates)
 * 
 * SQL Server Specific Functions:
 *   - GETDATE() - Must be converted to NOW() or CURRENT_TIMESTAMP
 * 
 * Transaction Boundaries:
 *   - BEGIN TRANSACTION
 *   - COMMIT
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
 * Source Location: ProductRepository.cs, Lines 255-281
 * Statement Type: CTE with RANK and PERCENT_RANK Window Functions
 * Complexity: MEDIUM-HIGH
 * 
 * Description:
 *   - Uses CTE (RankedProducts) with multiple window functions
 *   - RANK() OVER (ORDER BY Price) for ranking
 *   - PERCENT_RANK() OVER (ORDER BY Price) for percentile calculation
 *   - CASE expression for price segment categorization based on percentiles
 *   - Parameterized WHERE clause with BETWEEN
 *   - ORDER BY using window function result
 * 
 * Parameters:
 *   - @MinPrice (DECIMAL) - Minimum price threshold
 *   - @MaxPrice (DECIMAL) - Maximum price threshold
 * 
 * Tables Referenced:
 *   - Products (filtered by price range)
 *   - RankedProducts (CTE)
 * 
 * Schema Objects:
 *   - Products.* (all columns)
 *   - Derived columns: PriceRank, PricePercentile, PriceSegment
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
ORDER BY rp.PriceRank

/*******************************************************************************
 * STATEMENT 7: GetLowStockProductsAsync
 * Source Location: ProductRepository.cs, Lines 299-325
 * Statement Type: CTE with Multiple Window Aggregate Functions
 * Complexity: MEDIUM-HIGH
 * 
 * Description:
 *   - Uses CTE (StockAnalysis) with multiple window aggregate functions
 *   - AVG() OVER() for average stock calculation
 *   - MIN() OVER() for minimum stock calculation
 *   - MAX() OVER() for maximum stock calculation
 *   - CASE expression for stock status categorization
 *   - ROUND() function for percentage calculation
 *   - Parameterized WHERE clause filtering by threshold
 *   - ORDER BY stock quantity
 * 
 * Parameters:
 *   - @Threshold (INT) - Stock quantity threshold for filtering
 * 
 * Tables Referenced:
 *   - Products (filtered by stock quantity)
 *   - StockAnalysis (CTE)
 * 
 * Schema Objects:
 *   - Products.* (all columns)
 *   - Derived columns: AvgStock, MinStock, MaxStock, StockStatus, StockPercentageOfAverage
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
ORDER BY StockQuantity

/*******************************************************************************
 * END OF EXTRACTION CATALOG
 * 
 * Summary:
 * - Total Statements Extracted: 7
 * - CTE Statements: 5 (Statements 1, 2, 6, 7 use CTEs)
 * - Transaction Blocks: 3 (Statements 3, 4, 5)
 * - Window Functions: 6 statements use window functions
 * - Parameterized Queries: 6 (all except Statement 1)
 * - SQL Server Specific Functions: SCOPE_IDENTITY, GETDATE
 * 
 * Next Steps:
 * 1. Pass each statement through DMS MCP tool (dms-mcp____statement_conversion_tool)
 * 2. Capture converted PostgreSQL statements
 * 3. Document any conversion failures
 * 4. Validate equivalency using sql-equivalency___validate_sql_equivalence
 ******************************************************************************/
