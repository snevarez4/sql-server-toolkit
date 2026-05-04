/*
Descripción:
Busca una columna en todas las tablas de la base de datos.

Uso:
- Impact analysis
- Refactorización
- Troubleshooting

Notas:
- Solo tablas de usuario (no system tables)

Referencia:
https://learn.microsoft.com/sql/relational-databases/system-catalog-views
*/

DECLARE @column_name NVARCHAR(100) = 'Id';

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ty.name AS data_type
FROM sys.columns c
INNER JOIN sys.tables t ON c.object_id = t.object_id
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN sys.types ty ON c.user_type_id = ty.user_type_id
WHERE c.name = @column_name
ORDER BY schema_name, table_name;