-- ============================================================================
-- CONVERTED SQL STATEMENTS CATALOG (PostgreSQL)
-- Source: DataAccess/ProductRepository.cs
-- Total Statements: 7
-- Conversion Method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- DMS schema_mapping_tool was used to obtain target schema/column names
-- DMS statement_conversion_tool failed for all statements with timeout errors
-- ============================================================================

-- ============================================================================
-- Statement 1: GetAllProductsAsync (CONVERTED)
-- Conversion: Table/column names lowercased per DMS schema mapping
-- DMS Failure: Metadata model conversion did not complete after 15 attempts
-- Changes: Products->products, ProductId->productid, Name->name, etc.
--          CTE name ProductStats renamed to productstats_cte to avoid 
--          collision with productstats table
-- ============================================================================

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

-- ============================================================================
-- Statement 2: GetProductByIdAsync (CONVERTED)
-- Conversion: Table/column names lowercased per DMS schema mapping
-- DMS Failure: Metadata model creation failed - Incorrect format of selection rules
-- Changes: Products->products, ProductId->productid, etc.
--          CTE name ProductHistory renamed to producthistory_cte to avoid 
--          collision with producthistory table
-- ============================================================================

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

-- ============================================================================
-- Statement 3: InsertProductAsync (CONVERTED)
-- Conversion: Table/column names lowercased per DMS schema mapping
-- DMS Failure: Metadata model conversion did not complete after 15 attempts
-- Changes: SCOPE_IDENTITY() -> RETURNING productid (via INSERT...RETURNING)
--          GETDATE() -> clock_timestamp() (per DMS schema mapping)
--          BEGIN TRANSACTION/COMMIT -> removed (handled by C# transaction)
--          DECLARE @NewProductId -> removed (RETURNING handles this)
--          Multi-statement restructured for Npgsql compatibility:
--          - INSERT with RETURNING gives back the new ID
--          - Subsequent INSERT and UPDATE use Npgsql parameters for the new ID
--          Note: This is split into 3 separate SQL commands in C# code
-- ============================================================================

-- Part 1: Insert product and get the new ID
                INSERT INTO products (name, description, price, stockquantity)
                VALUES (@Name, @Description, @Price, @StockQuantity)
                RETURNING productid;

-- Part 2: Log the insertion (executed after retrieving @NewProductId)
                INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                VALUES (@NewProductId, 'INSERT', NULL, @Price, NULL, @StockQuantity, clock_timestamp());

-- Part 3: Update product statistics
                UPDATE productstats
                SET 
                    totalproducts = totalproducts + 1,
                    averageprice = (averageprice * totalproducts + @Price) / (totalproducts + 1),
                    lastupdated = clock_timestamp()
                WHERE statid = 1;

-- ============================================================================
-- Statement 4: UpdateProductAsync (CONVERTED)
-- Conversion: Table/column names lowercased per DMS schema mapping
-- DMS Failure: Metadata model conversion did not complete after 15 attempts
-- Changes: DECLARE variables -> CTE with old values approach
--          GETDATE() -> clock_timestamp() (per DMS schema mapping)
--          BEGIN TRANSACTION/COMMIT -> removed (handled by C# transaction)
--          Restructured to use WITH clause to capture old values
-- ============================================================================

-- Part 1: Get old values (returned to C# to use as parameters)
                SELECT price as oldprice, stockquantity as oldstock
                FROM products
                WHERE productid = @ProductId;

-- Part 2: Update the product
                UPDATE products
                SET 
                    name = @Name,
                    description = @Description,
                    price = @Price,
                    stockquantity = @StockQuantity,
                    modifieddate = clock_timestamp()
                WHERE productid = @ProductId;

-- Part 3: Log the changes
                INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                VALUES (@ProductId, 'UPDATE', @OldPrice, @Price, @OldStock, @StockQuantity, clock_timestamp());

-- Part 4: Update product statistics
                UPDATE productstats
                SET 
                    averageprice = (averageprice * totalproducts - @OldPrice + @Price) / totalproducts,
                    lastupdated = clock_timestamp()
                WHERE statid = 1;

-- ============================================================================
-- Statement 5: DeleteProductAsync (CONVERTED)
-- Conversion: Table/column names lowercased per DMS schema mapping
-- DMS Failure: Metadata model conversion did not complete after 15 attempts
-- Changes: DECLARE variables -> separate SELECT then use params
--          GETDATE() -> clock_timestamp() (per DMS schema mapping)
--          BEGIN TRANSACTION/COMMIT -> removed (handled by C# transaction)
--          CASE expression preserved (compatible with PostgreSQL)
-- ============================================================================

-- Part 1: Get old values (returned to C# to use as parameters)
                SELECT price as oldprice, stockquantity as oldstock
                FROM products
                WHERE productid = @ProductId;

-- Part 2: Log the deletion
                INSERT INTO producthistory (productid, action, oldprice, newprice, oldstock, newstock, actiondate)
                VALUES (@ProductId, 'DELETE', @OldPrice, NULL, @OldStock, NULL, clock_timestamp());

-- Part 3: Delete the product
                DELETE FROM products 
                WHERE productid = @ProductId;

-- Part 4: Update product statistics
                UPDATE productstats
                SET 
                    totalproducts = totalproducts - 1,
                    averageprice = CASE 
                        WHEN totalproducts > 1 
                        THEN (averageprice * totalproducts - @OldPrice) / (totalproducts - 1)
                        ELSE 0
                    END,
                    lastupdated = clock_timestamp()
                WHERE statid = 1;

-- ============================================================================
-- Statement 6: GetProductsByPriceRangeAsync (CONVERTED)
-- Conversion: Table/column names lowercased per DMS schema mapping
-- DMS Failure: Metadata model conversion did not complete after 15 attempts
-- Changes: Products->products, Price->price, etc.
--          RANK/PERCENT_RANK/BETWEEN all compatible with PostgreSQL
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
-- Statement 7: GetLowStockProductsAsync (CONVERTED)
-- Conversion: Table/column names lowercased per DMS schema mapping
-- DMS Failure: Metadata model conversion did not complete after 15 attempts
-- Changes: Products->products, StockQuantity->stockquantity, etc.
--          Added ::NUMERIC cast for integer division in ROUND
--          (PostgreSQL integer division returns integer, need cast for decimal result)
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
                    ROUND((stockquantity::NUMERIC / avgstock) * 100, 2) as stockpercentageofaverage
                FROM stockanalysis sa
                WHERE stockquantity <= @Threshold
                ORDER BY stockquantity;

-- ============================================================================
-- END OF CONVERTED STATEMENTS CATALOG
-- ============================================================================
