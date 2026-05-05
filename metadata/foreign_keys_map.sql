/*
Descripción:
Lista todas las relaciones de llaves foráneas en la base de datos.

Uso:
- Entender relaciones entre tablas
- Impact analysis antes de cambios

Notas:
- Incluye tabla origen y destino
- Útil para documentación

Referencia:
https://learn.microsoft.com/sql/relational-databases/system-catalog-views
*/

SELECT
    fk.name AS foreign_key_name,
    SCHEMA_NAME(tp.schema_id) AS parent_schema,
    tp.name AS parent_table,
    cp.name AS parent_column,
    SCHEMA_NAME(tr.schema_id) AS referenced_schema,
    tr.name AS referenced_table,
    cr.name AS referenced_column
FROM sys.foreign_keys fk
INNER JOIN sys.foreign_key_columns fkc 
    ON fk.object_id = fkc.constraint_object_id
INNER JOIN sys.tables tp 
    ON fkc.parent_object_id = tp.object_id
INNER JOIN sys.columns cp 
    ON fkc.parent_object_id = cp.object_id 
    AND fkc.parent_column_id = cp.column_id
INNER JOIN sys.tables tr 
    ON fkc.referenced_object_id = tr.object_id
INNER JOIN sys.columns cr 
    ON fkc.referenced_object_id = cr.object_id 
    AND fkc.referenced_column_id = cr.column_id
ORDER BY parent_table;