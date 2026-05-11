/*
Descripción:
Obtiene parámetros de procedimientos almacenados.

Uso:
- Documentación
- Integraciones
- Impact analysis

Notas:
- Incluye tipo y orden de parámetros

Referencia:
https://learn.microsoft.com/sql/relational-databases/system-catalog-views
*/

SELECT
    sp.name AS procedure_name,
    p.parameter_id,
    p.name AS parameter_name,
    t.name AS data_type,
    p.max_length,
    p.precision,
    p.scale
FROM sys.procedures sp
INNER JOIN sys.parameters p 
    ON sp.object_id = p.object_id
INNER JOIN sys.types t 
    ON p.user_type_id = t.user_type_id
ORDER BY sp.name, p.parameter_id;