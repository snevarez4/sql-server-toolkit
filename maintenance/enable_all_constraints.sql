/*
Descripción:
Habilita todas las constraints de todas las tablas.

Uso:
- Restaurar integridad después de cargas masivas
- Procesos ETL controlados

Notas:
- Ejecutar después de disable_all_constraints.sql

Referencia:
https://learn.microsoft.com/sql/t-sql/statements/alter-table
*/

EXEC sp_MSforeachtable
    'ALTER TABLE ? WITH CHECK CHECK CONSTRAINT ALL';