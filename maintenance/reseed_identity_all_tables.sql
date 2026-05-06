/*
Descripción:
Reinicia los valores identity de todas las tablas.

Uso:
- Reset de ambientes (QA / testing)
- Limpieza de datos

Notas:
- Solo aplica a tablas con identity
- Puede afectar integridad si hay relaciones

Referencia:
https://learn.microsoft.com/sql/t-sql/database-console-commands/dbcc-checkident
*/

EXEC sp_MSforeachtable
'
IF OBJECTPROPERTY(object_id(''?''), ''TableHasIdentity'') = 1
    DBCC CHECKIDENT (''?'', RESEED, 0)
';