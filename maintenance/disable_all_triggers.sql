/*
Descripción:
Deshabilita todos los triggers de todas las tablas.

Uso:
- Migraciones masivas
- Cargas ETL
- Troubleshooting

Notas:
- Ejecutar con precaución
- Recordar reactivar posteriormente

Referencia:
https://learn.microsoft.com/sql/t-sql/statements/disable-trigger-transact-sql
*/

EXEC sp_MSforeachtable
    'ALTER TABLE ? DISABLE TRIGGER ALL';