/*
	Diccionario de Datos
	http://dblearner.com/el-diccionario-de-datos/
*/

CREATE TABLE ##TablasColumnas (
	   Esquema VARCHAR(50)
	,Tabla VARCHAR(50)
	,Columna VARCHAR(50)
	,Tipo VARCHAR(50)
	,Tamano VARCHAR(50)
	,Nulo VARCHAR(50)
	,Llave VARCHAR(50)
	,Relacionada VARCHAR(150)
	,Descripcion VARCHAR(150)
);

DECLARE @empty NVarChar(1) SET @empty = '';
DECLARE @dash NVarChar(1) SET @dash = '_';
DECLARE @pk NVarChar(2) SET @pk = 'PK';
DECLARE @fk NVarChar(2) SET @fk = 'FK';
DECLARE @uq NVarChar(2) SET @uq = 'IX';

INSERT INTO ##TablasColumnas ( Esquema, Tabla, Columna, Tipo, Tamano, Nulo, Llave, Relacionada, Descripcion)
	SELECT 
	  SCHEMA_NAME(o.schema_id) AS Esquema,
	  O.Name AS Tabla,
	  C.Name AS Columna,
	  T.Name AS Tipo,
	  CASE
		WHEN T.Name = 'decimal' Then  CAST(C.[Precision] AS varchar(20)) + ',' + CAST(C.scale AS varchar(20))
		ELSE CAST(C.max_length AS varchar(20))
	  END AS [Tamano],

	  CASE
		WHEN C.Is_Nullable = 0 Then 'No'
		WHEN C.Is_Nullable = 1 Then 'Si'
	  END [Nulo],
  
		'' AS [Llave],
		'' AS [Relacionada],

	 CAST(P2.value AS varchar(150))  AS [Descripcion]
	FROM
	 sys.tables O
	  INNER JOIN sys.Columns C
		ON O.object_id = C.object_id
	  INNER JOIN sys.Types T
		ON C.system_type_id = T.system_type_id
		AND C.system_type_id = T.user_type_id
	  LEFT JOIN sys.extended_properties P1
		ON C.object_id = P1.major_id
		AND P1.minor_id = 0
		LEFT JOIN sys.extended_properties P2
			ON C.object_id = P2.major_id
			AND C.Column_id = P2.minor_id
			AND P2.Class = 1
	WHERE O.Name  <> 'sysdiagrams'
	ORDER BY
		SCHEMA_NAME(o.schema_id),
		O.Name,
		C.Column_id;

-- PRIMARY KEY
;WITH CTE_PRIMARY_KEY AS
(
	SELECT
		K.TABLE_SCHEMA,  
		K.TABLE_NAME ,
		K.COLUMN_NAME ,
		K.CONSTRAINT_NAME
	FROM    INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS C
			JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE AS K ON C.TABLE_NAME COLLATE Modern_Spanish_CI_AS  = K.TABLE_NAME COLLATE Modern_Spanish_CI_AS
															 AND C.CONSTRAINT_CATALOG COLLATE Modern_Spanish_CI_AS = K.CONSTRAINT_CATALOG COLLATE Modern_Spanish_CI_AS
															 AND C.CONSTRAINT_SCHEMA COLLATE Modern_Spanish_CI_AS = K.CONSTRAINT_SCHEMA COLLATE Modern_Spanish_CI_AS
															 AND C.CONSTRAINT_NAME COLLATE Modern_Spanish_CI_AS = K.CONSTRAINT_NAME COLLATE Modern_Spanish_CI_AS
	WHERE   C.CONSTRAINT_TYPE = 'PRIMARY KEY'
)UPDATE T
	SET
		T.Llave = SUBSTRING(K.CONSTRAINT_NAME,1,2)
	FROM ##TablasColumnas AS T
		INNER JOIN CTE_PRIMARY_KEY AS K ON  T.Esquema COLLATE Modern_Spanish_CI_AS = K.TABLE_SCHEMA COLLATE Modern_Spanish_CI_AS
			AND T.Tabla COLLATE Modern_Spanish_CI_AS = K.TABLE_NAME COLLATE Modern_Spanish_CI_AS
			AND T.Columna COLLATE Modern_Spanish_CI_AS = K.COLUMN_NAME COLLATE Modern_Spanish_CI_AS


-- FOREIGN KEY
;WITH CTE_FOREIGN_KEY AS
(
	SELECT
		K.TABLE_SCHEMA,  
		K.TABLE_NAME ,
		K.COLUMN_NAME ,
		K.CONSTRAINT_NAME
	FROM    INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS C
			JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE AS K ON C.TABLE_NAME = K.TABLE_NAME
															 AND C.CONSTRAINT_CATALOG = K.CONSTRAINT_CATALOG
															 AND C.CONSTRAINT_SCHEMA = K.CONSTRAINT_SCHEMA
															 AND C.CONSTRAINT_NAME = K.CONSTRAINT_NAME
	WHERE   C.CONSTRAINT_TYPE = 'FOREIGN KEY'
)UPDATE T
	SET
		T.Llave = T.Llave + ',' + SUBSTRING(K.CONSTRAINT_NAME,1,2)
		,T.Relacionada  = 
		REPLACE(
		REPLACE(
			REPLACE(K.CONSTRAINT_NAME COLLATE Modern_Spanish_CI_AS , T.Tabla,@empty)
			,@fk,@empty)
			,@dash,@empty)
	FROM ##TablasColumnas AS T
		INNER JOIN CTE_FOREIGN_KEY AS K ON  T.Esquema COLLATE Modern_Spanish_CI_AS = K.TABLE_SCHEMA COLLATE Modern_Spanish_CI_AS
			AND T.Tabla COLLATE Modern_Spanish_CI_AS = K.TABLE_NAME COLLATE Modern_Spanish_CI_AS
			AND T.Columna COLLATE Modern_Spanish_CI_AS = K.COLUMN_NAME COLLATE Modern_Spanish_CI_AS

---- UNIQUE
--;WITH CTE_FOREIGN_KEY AS
--(
--	SELECT
--		K.TABLE_SCHEMA,  
--		K.TABLE_NAME ,
--		K.COLUMN_NAME ,
--		K.CONSTRAINT_NAME
--	FROM    INFORMATION_SCHEMA.TABLE_CONSTRAINTS AS C
--			JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE AS K ON C.TABLE_NAME = K.TABLE_NAME
--															 AND C.CONSTRAINT_CATALOG = K.CONSTRAINT_CATALOG
--															 AND C.CONSTRAINT_SCHEMA = K.CONSTRAINT_SCHEMA
--															 AND C.CONSTRAINT_NAME = K.CONSTRAINT_NAME
--	WHERE   C.CONSTRAINT_TYPE = 'UNIQUE'
--)UPDATE T
--	SET
--		T.Llave = T.Llave + ',' + SUBSTRING(K.CONSTRAINT_NAME,1,2)
--		,T.Relacionada = T.Relacionada + ',' +
--		REPLACE(
--		REPLACE(
--			REPLACE(K.CONSTRAINT_NAME, T.Tabla,@empty)
--			,@uq,@empty)
--			,@dash,@empty)
--	FROM ##TablasColumnas AS T
--		INNER JOIN CTE_FOREIGN_KEY AS K ON  T.Esquema = K.TABLE_SCHEMA
--			AND T.Tabla = K.TABLE_NAME
--			AND T.Columna = K.COLUMN_NAME;

	SELECT  
		Esquema
		,Tabla 
		,Columna AS  Nombre
		,Tipo AS 'Tipo de dato'
		,Tamano AS 'Tamaño'
		,Nulo AS 'Nulo?'
		,Llave AS 'Llave (PK, FK)'
		,Relacionada AS 'Tabla Relacionada'
		,Descripcion AS 'Descripción'
	FROM ##TablasColumnas 
		--Where 
		--Esquema = 'global'
		--and Columna in ( 'Nombre','Descripcion')
		Order by Esquema ,Tabla;

DROP TABLE ##TablasColumnas;
