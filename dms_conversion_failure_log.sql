-- ============================================================
-- DMS CONVERSION FAILURE SUMMARY
-- ============================================================
-- DMS Tool: dms-mcp___statement_conversion_tool
-- Migration Project: arn:aws:dms:us-east-1:812756961751:migration-project:NXKVMFZHAZFJFF6HU2YPUQHSI4
-- Error: Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}
-- Attempts: 3 (with varying poll_interval and max_poll_attempts)
-- 
-- DMS Schema Mapping Tool (dms-mcp___schema_mapping_tool) SUCCEEDED and provided:
--   Products -> productmanagement_dbo.products (all columns lowercase)
--   ProductHistory -> productmanagement_dbo.producthistory (all columns lowercase)
--   ProductStats -> productmanagement_dbo.productstats (all columns lowercase)
--
-- All 7 statements were attempted through DMS statement_conversion_tool.
-- All 7 statements failed with the same metadata model creation error.
-- Manual conversion applied using DMS schema mappings with lowercase naming.
-- Conversion method: DMS_FAILURE_MANUAL_CONVERSION_WITH_LOWERCASE_SCHEMA
-- ============================================================

-- Statement 1 (GetAllProductsAsync):
-- DMS Output: {"status": "error", "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"}
-- Manual Conversion: Applied lowercase schema mapping, CTE renamed to avoid conflict with table name

-- Statement 2 (GetProductByIdAsync):
-- DMS Output: {"status": "error", "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"}
-- Manual Conversion: Applied lowercase schema mapping, CTE renamed to avoid conflict with table name

-- Statement 3 (InsertProductAsync):
-- DMS Output: {"status": "error", "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"}
-- Manual Conversion: SCOPE_IDENTITY() -> currval(pg_get_serial_sequence(...)), GETDATE() -> NOW(), BEGIN TRANSACTION -> BEGIN

-- Statement 4 (UpdateProductAsync):
-- DMS Output: {"status": "error", "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"}
-- Manual Conversion: DECLARE variables eliminated by reordering operations, GETDATE() -> NOW(), BEGIN TRANSACTION -> BEGIN

-- Statement 5 (DeleteProductAsync):
-- DMS Output: {"status": "error", "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"}
-- Manual Conversion: DECLARE variables eliminated by reordering operations, GETDATE() -> NOW(), BEGIN TRANSACTION -> BEGIN

-- Statement 6 (GetProductsByPriceRangeAsync):
-- DMS Output: {"status": "error", "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"}
-- Manual Conversion: Applied lowercase schema mapping, RANK/PERCENT_RANK compatible

-- Statement 7 (GetLowStockProductsAsync):
-- DMS Output: {"status": "error", "error": "Metadata model creation failed: {'error': 'Unknown metadata model creation status: RECEIVED'}"}
-- Manual Conversion: Applied lowercase schema mapping, CAST added for integer division in ROUND
