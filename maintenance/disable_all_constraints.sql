/*
Descripción:
Deshabilita todas las constraints de todas las tablas.

Uso:
- Cargas masivas de datos
- Migraciones controladas

Notas:
- Ejecutar con precaución en producción
- Requiere reactivación posterior

Referencia:
https://learn.microsoft.com/sql/t-sql/statements/alter-table
*/

EXEC sp_MSforeachtable 
    'ALTER TABLE ? NOCHECK CONSTRAINT ALL';