/*
===============================================================================
CONVERTED SQL STATEMENTS CATALOG
PostgreSQL Target Syntax
Conversion Date: 2024-11-26
Conversion Method: Manual (After DMS Tool Failures)
Total Statements: 7
===============================================================================
*/

/*
===============================================================================
STATEMENT ID: 1
METHOD: GetAllProductsAsync
TYPE: SELECT (Complex CTE with Window Functions)
CONVERSION METHOD: MANUAL_AFTER_DMS_FAILURE
PARAMETERS: None
===============================================================================
*/
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

/*
===============================================================================
STATEMENT ID: 2
METHOD: GetProductByIdAsync
TYPE: SELECT (CTE with LAG Window Function)
CONVERSION METHOD: MANUAL_AFTER_DMS_FAILURE
PARAMETERS: $1 = ProductId (INT)
PARAMETER CHANGES: @ProductId → $1
===============================================================================
*/
WITH ProductHistory AS (
    SELECT 
        ProductId,
        LAG(Price) OVER (ORDER BY ModifiedDate) as PreviousPrice,
        LAG(StockQuantity) OVER (ORDER BY ModifiedDate) as PreviousStock
    FROM Products
    WHERE ProductId = $1
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
WHERE p.ProductId = $1;

/*
===============================================================================
STATEMENT ID: 3
METHOD: InsertProductAsync
TYPE: INSERT with RETURNING (Single Statement for ADO.NET)
CONVERSION METHOD: MANUAL_AFTER_DMS_FAILURE
PARAMETERS: $1 = Name, $2 = Description, $3 = Price, $4 = StockQuantity
PARAMETER CHANGES: @Name → $1, @Description → $2, @Price → $3, @StockQuantity → $4
MAJOR CHANGES: SCOPE_IDENTITY() → RETURNING clause, Transaction split into multiple commands
NOTE: Subsequent operations (history insert, stats update) will be handled as separate commands in C# transaction
===============================================================================
*/
INSERT INTO Products (Name, Description, Price, StockQuantity)
VALUES ($1, $2, $3, $4)
RETURNING ProductId;

-- Subsequent statement for history (to be executed after getting ProductId)
-- INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
-- VALUES ($1, 'INSERT', NULL, $2, NULL, $3, CURRENT_TIMESTAMP);

-- Subsequent statement for statistics (to be executed in same transaction)
-- UPDATE ProductStats
-- SET 
--     TotalProducts = TotalProducts + 1,
--     AveragePrice = (AveragePrice * TotalProducts + $2) / (TotalProducts + 1),
--     LastUpdated = CURRENT_TIMESTAMP
-- WHERE StatId = 1;

/*
===============================================================================
STATEMENT ID: 4 - Part 1
METHOD: UpdateProductAsync - Get Old Values
TYPE: SELECT
CONVERSION METHOD: MANUAL_AFTER_DMS_FAILURE
PARAMETERS: $1 = ProductId
NOTE: This is the first statement in the transaction to retrieve old values
===============================================================================
*/
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = $1;

/*
===============================================================================
STATEMENT ID: 4 - Part 2
METHOD: UpdateProductAsync - Update Product
TYPE: UPDATE
CONVERSION METHOD: MANUAL_AFTER_DMS_FAILURE
PARAMETERS: $1 = ProductId, $2 = Name, $3 = Description, $4 = Price, $5 = StockQuantity
PARAMETER CHANGES: GETDATE() → CURRENT_TIMESTAMP
===============================================================================
*/
UPDATE Products
SET 
    Name = $2,
    Description = $3,
    Price = $4,
    StockQuantity = $5,
    ModifiedDate = CURRENT_TIMESTAMP
WHERE ProductId = $1;

/*
===============================================================================
STATEMENT ID: 4 - Part 3
METHOD: UpdateProductAsync - Log History
TYPE: INSERT
CONVERSION METHOD: MANUAL_AFTER_DMS_FAILURE
PARAMETERS: $1 = ProductId, $2 = OldPrice (from C# code), $3 = Price, 
            $4 = OldStock (from C# code), $5 = StockQuantity
PARAMETER CHANGES: GETDATE() → CURRENT_TIMESTAMP
===============================================================================
*/
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES ($1, 'UPDATE', $2, $3, $4, $5, CURRENT_TIMESTAMP);

/*
===============================================================================
STATEMENT ID: 4 - Part 4
METHOD: UpdateProductAsync - Update Statistics
TYPE: UPDATE
CONVERSION METHOD: MANUAL_AFTER_DMS_FAILURE
PARAMETERS: $1 = OldPrice (from C# code), $2 = Price
PARAMETER CHANGES: GETDATE() → CURRENT_TIMESTAMP
===============================================================================
*/
UPDATE ProductStats
SET 
    AveragePrice = (AveragePrice * TotalProducts - $1 + $2) / TotalProducts,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

/*
===============================================================================
STATEMENT ID: 5 - Part 1
METHOD: DeleteProductAsync - Get Product Info
TYPE: SELECT
CONVERSION METHOD: MANUAL_AFTER_DMS_FAILURE
PARAMETERS: $1 = ProductId
NOTE: This is the first statement in the transaction to retrieve values for history
===============================================================================
*/
SELECT Price, StockQuantity
FROM Products
WHERE ProductId = $1;

/*
===============================================================================
STATEMENT ID: 5 - Part 2
METHOD: DeleteProductAsync - Log History
TYPE: INSERT
CONVERSION METHOD: MANUAL_AFTER_DMS_FAILURE
PARAMETERS: $1 = ProductId, $2 = OldPrice (from C# code), $3 = OldStock (from C# code)
PARAMETER CHANGES: GETDATE() → CURRENT_TIMESTAMP
===============================================================================
*/
INSERT INTO ProductHistory (ProductId, Action, OldPrice, NewPrice, OldStock, NewStock, ActionDate)
VALUES ($1, 'DELETE', $2, NULL, $3, NULL, CURRENT_TIMESTAMP);

/*
===============================================================================
STATEMENT ID: 5 - Part 3
METHOD: DeleteProductAsync - Delete Product
TYPE: DELETE
CONVERSION METHOD: MANUAL_AFTER_DMS_FAILURE
PARAMETERS: $1 = ProductId
===============================================================================
*/
DELETE FROM Products 
WHERE ProductId = $1;

/*
===============================================================================
STATEMENT ID: 5 - Part 4
METHOD: DeleteProductAsync - Update Statistics
TYPE: UPDATE
CONVERSION METHOD: MANUAL_AFTER_DMS_FAILURE
PARAMETERS: $1 = OldPrice (from C# code)
PARAMETER CHANGES: GETDATE() → CURRENT_TIMESTAMP
===============================================================================
*/
UPDATE ProductStats
SET 
    TotalProducts = TotalProducts - 1,
    AveragePrice = CASE 
        WHEN TotalProducts > 1 
        THEN (AveragePrice * TotalProducts - $1) / (TotalProducts - 1)
        ELSE 0
    END,
    LastUpdated = CURRENT_TIMESTAMP
WHERE StatId = 1;

/*
===============================================================================
STATEMENT ID: 6
METHOD: GetProductsByPriceRangeAsync
TYPE: SELECT (CTE with RANK and PERCENT_RANK Window Functions)
CONVERSION METHOD: MANUAL_AFTER_DMS_FAILURE
PARAMETERS: $1 = MinPrice, $2 = MaxPrice
PARAMETER CHANGES: @MinPrice → $1, @MaxPrice → $2
===============================================================================
*/
WITH RankedProducts AS (
    SELECT 
        p.*,
        RANK() OVER (ORDER BY p.Price) as PriceRank,
        PERCENT_RANK() OVER (ORDER BY p.Price) as PricePercentile
    FROM Products p
    WHERE p.Price BETWEEN $1 AND $2
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

/*
===============================================================================
STATEMENT ID: 7
METHOD: GetLowStockProductsAsync
TYPE: SELECT (CTE with Multiple Window Functions)
CONVERSION METHOD: MANUAL_AFTER_DMS_FAILURE
PARAMETERS: $1 = Threshold
PARAMETER CHANGES: @Threshold → $1
===============================================================================
*/
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
        WHEN StockQuantity <= $1 THEN 'Critical'
        WHEN StockQuantity <= AvgStock * 0.5 THEN 'Low'
        ELSE 'Adequate'
    END as StockStatus,
    ROUND((StockQuantity / AvgStock) * 100, 2) as StockPercentageOfAverage
FROM StockAnalysis sa
WHERE StockQuantity <= $1
ORDER BY StockQuantity;

/*
===============================================================================
CONVERSION SUMMARY
===============================================================================
Total Statements: 7 (expanded to 14 individual SQL commands for ADO.NET execution)
Conversion Method: All MANUAL_AFTER_DMS_FAILURE

Key Changes Applied:
1. Parameter Syntax: @param → $1, $2, $3, etc. (PostgreSQL positional parameters)
2. GETDATE() → CURRENT_TIMESTAMP
3. SCOPE_IDENTITY() → RETURNING clause
4. Transaction blocks split into multiple statements for ADO.NET execution
5. Variables (DECLARE) → Handled in C# code between statements
6. BEGIN TRANSACTION/COMMIT → Managed by NpgsqlTransaction in C#

Statements Requiring Code Changes:
- Statement 3 (InsertProductAsync): Use RETURNING, handle subsequent operations
- Statement 4 (UpdateProductAsync): Split into 4 commands with transaction
- Statement 5 (DeleteProductAsync): Split into 4 commands with transaction

Schema Changes: None (DMS did not provide alternative schema names)

PostgreSQL Compatibility:
- CTEs: Fully compatible
- Window Functions: Fully compatible
- CASE expressions: Fully compatible
- ROUND function: Fully compatible
- All standard SQL features used are supported by PostgreSQL

===============================================================================
*/
