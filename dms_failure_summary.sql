-- ============================================================
-- DMS MCP Tool Failure Summary
-- All 7 SQL statements were attempted through the DMS MCP tool
-- All 7 failed with timeout errors
-- Manual conversion applied with lowercase schema naming
-- ============================================================

-- Statement 1 (GetAllProductsAsync):
--   DMS Attempt: 2026-03-23T14:39:10 - ERROR: Metadata model conversion failed (timeout after 15 attempts)
--   DMS Attempt 2: 2026-03-23T14:42:00 - ERROR: Command execution timed out after 300 seconds
--   Manual conversion applied: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

-- Statement 2 (GetProductByIdAsync):
--   DMS Attempt: 2026-03-23T14:55:11 - ERROR: Metadata model creation failed (timeout after 15 attempts)
--   Manual conversion applied: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

-- Statement 3 (InsertProductAsync):
--   DMS Attempt: 2026-03-23T14:57:58 - ERROR: Metadata model creation failed (timeout after 15 attempts)
--   Manual conversion applied: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
--   Key conversions: SCOPE_IDENTITY() -> lastval(), GETDATE() -> NOW(), BEGIN TRANSACTION -> BEGIN

-- Statement 4 (UpdateProductAsync):
--   DMS Attempt: 2026-03-23T15:00:43 - ERROR: Metadata model creation failed (timeout after 15 attempts)
--   Manual conversion applied: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
--   Key conversions: DECLARE variables eliminated (use subqueries), GETDATE() -> NOW()

-- Statement 5 (DeleteProductAsync):
--   DMS Attempt: 2026-03-23T15:03:25 - ERROR: Metadata model conversion failed (timeout after 15 attempts)
--   Manual conversion applied: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
--   Key conversions: DECLARE variables eliminated (use subqueries), GETDATE() -> NOW()

-- Statement 6 (GetProductsByPriceRangeAsync):
--   DMS Attempt: 2026-03-23T15:07:45 - ERROR: Metadata model creation failed (timeout after 15 attempts)
--   Manual conversion applied: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA

-- Statement 7 (GetLowStockProductsAsync):
--   DMS Attempt: 2026-03-23T15:10:30 - ERROR: Metadata model creation failed (timeout after 15 attempts)
--   Manual conversion applied: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
--   Key conversions: Added CAST for integer division in ROUND function
