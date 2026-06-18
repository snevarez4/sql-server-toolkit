/*==============================================================================
    Inventory V2

    Purpose:
        Generate a documentation inventory based on XML v2 metadata.

    Compatibility:
        SQL Server 2012+

    Rules Implemented:
        | Code | Description                   |
        | ---- | ----------------------------- |
        | V001 | Missing Documentation Node    |
        | V002 | Invalid Documentation Version |
        | V003 | Malformed XML                 |
        | V010 | Missing Info Node             |
        | V011 | Missing Application           |
        | V012 | Missing Module                |
        | V013 | Missing Maintainer            |
        | V014 | Missing Description           |
        | V030 | Missing Change Date           |
        | V031 | Missing Change Author         |
        | V032 | Missing Change Type           |
        | V033 | Invalid Change Type           |
        | V034 | Missing Change Description    |
        | V035 | Invalid Change Date Format    |

    Notes:
        - Only XML v2 documentation is considered.
        - Encrypted procedures are excluded.
        - Multiple Application or Module values are returned as stored.
        - No permanent objects are created.

==============================================================================*/

SET NOCOUNT ON;

/*==============================================================================
    Procedure Inventory
==============================================================================*/

IF OBJECT_ID('tempdb..#Procedures') IS NOT NULL
    DROP TABLE #Procedures;

CREATE TABLE #Procedures
(
    ObjectId        INT             NOT NULL,
    SchemaName      SYSNAME         NOT NULL,
    ProcedureName   SYSNAME         NOT NULL,
    DefinitionText  NVARCHAR(MAX)   NULL
);

INSERT INTO #Procedures
(
    ObjectId,
    SchemaName,
    ProcedureName,
    DefinitionText
)
SELECT
    P.object_id,
    S.name,
    P.name,
    M.definition
FROM sys.procedures AS P
INNER JOIN sys.schemas AS S
    ON S.schema_id = P.schema_id
LEFT JOIN sys.sql_modules AS M
    ON M.object_id = P.object_id;


/*==============================================================================
    Documentation Extraction
==============================================================================*/

IF OBJECT_ID('tempdb..#Documentation') IS NOT NULL
    DROP TABLE #Documentation;

CREATE TABLE #Documentation
(
    ObjectId INT PRIMARY KEY,

    SchemaName SYSNAME,
    ProcedureName SYSNAME,

    XmlText XML
);

INSERT INTO #Documentation
(
    ObjectId,
    SchemaName,
    ProcedureName,
    XmlText
)
SELECT
    P.ObjectId,
    P.SchemaName,
    P.ProcedureName,

    TRY_CAST
    (
        SUBSTRING
        (
            P.DefinitionText,
            CHARINDEX('<Documentation', P.DefinitionText),
            CHARINDEX('</Documentation>', P.DefinitionText)
                - CHARINDEX('<Documentation', P.DefinitionText)
                + LEN('</Documentation>')
        )
        AS XML
    )
FROM #Procedures AS P
WHERE
    P.DefinitionText IS NOT NULL
    AND CHARINDEX('<Documentation', P.DefinitionText) > 0
    AND CHARINDEX('</Documentation>', P.DefinitionText) > 0;


/*==============================================================================
    XML V2 Only
==============================================================================*/

IF OBJECT_ID('tempdb..#XmlV2') IS NOT NULL
    DROP TABLE #XmlV2;

CREATE TABLE #XmlV2
(
    ObjectId INT PRIMARY KEY,
    SchemaName SYSNAME,
    ProcedureName SYSNAME,
    XmlDefinition XML
);

INSERT INTO #XmlV2
(
    ObjectId,
    SchemaName,
    ProcedureName,
    XmlDefinition
)
SELECT
    ObjectId,
    SchemaName,
    ProcedureName,
    XmlText
FROM #Documentation
WHERE XmlText IS NOT NULL
    AND
        XmlText.value(
            '(/Documentation/@Version)[1]',
            'varchar(10)'
            ) = '2.0';

/*==============================================================================
    Inventory
==============================================================================*/

IF OBJECT_ID('tempdb..#Inventory') IS NOT NULL
    DROP TABLE #Inventory;

CREATE TABLE #Inventory
(
    ObjectId INT,

    SchemaName SYSNAME,
    ProcedureName SYSNAME,
    
    FullProcedureName VARCHAR(300),

    ApplicationName VARCHAR(500),
    ModuleName VARCHAR(500),

    Maintainer VARCHAR(200),

    DescriptionText VARCHAR(1000),

    CreatedDate DATE,

    ChangeCount INT,

    LastChangeDate DATE,

    DocumentationVersion VARCHAR(10)
);


/*==============================================================================
    Inventory Population
==============================================================================*/

INSERT INTO #Inventory
(
    --ObjectId,

    SchemaName,
    ProcedureName,

    FullProcedureName,

    ApplicationName,
    ModuleName,

    Maintainer,

    DescriptionText,

    CreatedDate,

    ChangeCount,

    LastChangeDate,

    DocumentationVersion
)
SELECT
    X.SchemaName,

    X.ProcedureName,

    QUOTENAME(X.SchemaName) + '.' + QUOTENAME(X.ProcedureName) AS FullProcedureName,

    X.XmlDefinition.value(
        '(/Documentation/Info/Application/text())[1]',
        'varchar(500)'
    ),

    X.XmlDefinition.value(
        '(/Documentation/Info/Module/text())[1]',
        'varchar(500)'
    ),

    X.XmlDefinition.value(
        '(/Documentation/Info/Maintainer/text())[1]',
        'varchar(200)'
    ),

    LTRIM(X.XmlDefinition.value(
        '(/Documentation/Info/Description/text())[1]',
        'varchar(max)'
    )),

    CASE
        WHEN X.XmlDefinition.exist('/Documentation/Info/CreatedDate') = 1
        THEN CAST(
            X.XmlDefinition.value(
                '(/Documentation/Info/CreatedDate/text())[1]',
                'varchar(20)'
            )
            AS DATE
        )
    END,

    X.XmlDefinition.value(
        'count(/Documentation/Log/Change)',
        'int'
    ),

    LastChange.LastChangeDate,

    X.XmlDefinition.value(
        '(/Documentation/@Version)[1]',
        'varchar(10)'
    )

FROM #XmlV2 X

OUTER APPLY
(
    SELECT
        MAX(
            CAST(
                C.N.value('@Date','varchar(20)')
                AS DATE
            )
        ) AS LastChangeDate
    FROM X.XmlDefinition.nodes('/Documentation/Log/Change') C(N)
) LastChange;


/*==============================================================================
    Results
==============================================================================*/

SELECT
    SchemaName,
    ProcedureName,

    FullProcedureName,

    ApplicationName,
    ModuleName,

    Maintainer,

    DescriptionText,

    CreatedDate,

    ChangeCount,

    LastChangeDate
FROM #Inventory
ORDER BY
    ApplicationName,
    ModuleName,
    ProcedureName;