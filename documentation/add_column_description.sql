/*
Descripción:
Agrega descripción documental a una columna usando MS_Description.

Uso:
- Documentación técnica
- Gobierno de datos
- Mantenimiento de sistemas

Notas:
- Compatible con herramientas de modelado/documentación

Referencia:
https://learn.microsoft.com/sql/relational-databases/system-stored-procedures/sp-addextendedproperty-transact-sql
*/

EXEC sys.sp_addextendedproperty
    @name = N'MS_Description',
    @value = N'Identificador único del cliente',
    @level0type = N'SCHEMA',
    @level0name = 'dbo',
    @level1type = N'TABLE',
    @level1name = 'Customers',
    @level2type = N'COLUMN',
    @level2name = 'CustomerId';