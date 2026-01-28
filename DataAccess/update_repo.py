#!/usr/bin/env python3
# Script to update ProductRepository.cs with PostgreSQL syntax

with open('ProductRepository.cs', 'r') as f:
    lines = f.readlines()

# Find and replace T-SQL transaction blocks
new_lines = []
i = 0
while i < len(lines):
    line = lines[i]
    
    # Skip GETDATE replacement (already done)
    
    # Replace BEGIN TRANSACTION with transaction handling comment
    if 'BEGIN TRANSACTION;' in line and 'const string sql' in ''.join(lines[max(0,i-5):i]):
        # Mark SQL Server transaction blocks to be removed - they'll be handled at C# level
        new_lines.append(line.replace('BEGIN TRANSACTION;', '-- Transaction managed by C# code'))
    elif 'COMMIT;' in line and '@"' in ''.join(lines[max(0,i-30):i]):
        new_lines.append(line.replace('COMMIT;', '-- Commit managed by C# code'))
    elif 'DECLARE @NewProductId INT;' in line:
        # Skip T-SQL variable declarations in InsertProductAsync
        i += 1
        continue
    elif 'SET @NewProductId = SCOPE_IDENTITY();' in line:
        # Skip SCOPE_IDENTITY line - will be handled by RETURNING
        i += 1
        continue
    elif 'SELECT @NewProductId;' in line:
        # Skip SELECT statement
        i += 1
        continue
    elif 'DECLARE @OldPrice DECIMAL(18,2);' in line or 'DECLARE @OldStock INT;' in line:
        # Skip T-SQL variable declarations
        i += 1
        continue
    elif 'SELECT @OldPrice = Price, @OldStock = StockQuantity' in line:
        # Mark to be handled in C# code
        new_lines.append(line.replace('SELECT @OldPrice = Price, @OldStock = StockQuantity', '-- Variables handled in C# code'))
    else:
        new_lines.append(line)
    
    i += 1

# Write updated content
with open('ProductRepository.cs', 'w') as f:
    f.writelines(new_lines)

print("Updated ProductRepository.cs with PostgreSQL syntax")
print("- GETDATE() -> NOW() (already done)")
print("- Removed T-SQL variable declarations")
print("- Removed SCOPE_IDENTITY() and transaction keywords")
