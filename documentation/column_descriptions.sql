/*
Descripción:
Obtiene las descripciones de tablas y columnas usando MS_Description.

Uso:
- Auditoría de documentación
- Validar cobertura documental

Notas:
- Requiere extended properties configuradas

Referencia:
https://learn.microsoft.com/sql/relational-databases/system-catalog-views
*/

SELECT
    s.name AS schema_name,
    t.name AS table_name,
    c.name AS column_name,
    ep.value AS column_description
FROM sys.tables t
INNER JOIN sys.schemas s 
    ON t.schema_id = s.schema_id
INNER JOIN sys.columns c 
    ON t.object_id = c.object_id
LEFT JOIN sys.extended_properties ep 
    ON ep.major_id = c.object_id
    AND ep.minor_id = c.column_id
    AND ep.name = 'MS_Description'
ORDER BY s.name, t.name, c.column_id;