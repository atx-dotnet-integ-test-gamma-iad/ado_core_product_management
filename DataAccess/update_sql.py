import re

# Read the file
with open('ProductRepository.cs', 'r') as f:
    content = f.read()

# These are simple string replacements for basic PostgreSQL compatibility
replacements = [
    ('SET @NewProductId = SCOPE_IDENTITY();', '-- PostgreSQL uses RETURNING instead'),
    ('DECLARE @NewProductId INT;', '-- Transaction handling moved to C# level'),
    ('DECLARE @OldPrice DECIMAL(18,2);', '-- Old values retrieved separately'),
    ('DECLARE @OldStock INT;', ''),
    ('SELECT @OldPrice = Price, @OldStock = StockQuantity', 'SELECT Price, StockQuantity'),
]

for old, new in replacements:
    content = content.replace(old, new)

# Write back
with open('ProductRepository.cs', 'w') as f:
    f.write(content)

print("ProductRepository.cs updated")
