/*
Descripción:
Busca texto dentro de procedimientos almacenados.

Uso:
- Impact analysis
- Refactorización
- Búsqueda de lógica específica

Notas:
- Puede ser costoso en bases grandes

Referencia:
https://learn.microsoft.com/sql/relational-databases/system-information-schema-views
*/

DECLARE @search NVARCHAR(100) = 'Customer';

SELECT
    ROUTINE_SCHEMA,
    ROUTINE_NAME,
    ROUTINE_TYPE,
    ROUTINE_DEFINITION
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_DEFINITION LIKE '%' + @search + '%'
ORDER BY ROUTINE_SCHEMA, ROUTINE_NAME;