/*==============================================================================
    Changes By Author

    Purpose:
        Analyze XML v2 Change history by Author.

    Compatibility:
        SQL Server 2012+

==============================================================================*/

SET NOCOUNT ON;

/*==============================================================================
    Procedure Inventory
==============================================================================*/

IF OBJECT_ID('tempdb..#Procedures') IS NOT NULL
    DROP TABLE #Procedures;

CREATE TABLE #Procedures
(
    ObjectId INT PRIMARY KEY,
    SchemaName SYSNAME,
    ProcedureName SYSNAME,
    DefinitionText NVARCHAR(MAX)
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
FROM sys.procedures P
INNER JOIN sys.schemas S
    ON S.schema_id = P.schema_id
LEFT JOIN sys.sql_modules M
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
    XmlDefinition XML
);

INSERT INTO #Documentation
(
    ObjectId,
    SchemaName,
    ProcedureName,
    XmlDefinition
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
FROM #Procedures P
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
    XmlDefinition
FROM #Documentation
WHERE
    XmlDefinition IS NOT NULL
    AND XmlDefinition.value(
            '(/Documentation/@Version)[1]',
            'varchar(10)'
        ) = '2.0';


/*==============================================================================
    Change Detail
==============================================================================*/

IF OBJECT_ID('tempdb..#ChangeDetail') IS NOT NULL
    DROP TABLE #ChangeDetail;

CREATE TABLE #ChangeDetail
(
    ObjectId INT,

    SchemaName SYSNAME,
    ProcedureName SYSNAME,

    FullProcedureName VARCHAR(300),

    AuthorName VARCHAR(200),

    ChangeDate DATE,

    ChangeType VARCHAR(50),

    Ticket VARCHAR(100),

    ChangeDescription VARCHAR(MAX)
);

INSERT INTO #ChangeDetail
(
    ObjectId,
    SchemaName,
    ProcedureName,
    FullProcedureName,

    AuthorName,
    ChangeDate,
    ChangeType,
    Ticket,
    ChangeDescription
)
SELECT
    X.ObjectId,

    X.SchemaName,
    X.ProcedureName,

    QUOTENAME(X.SchemaName)
    + '.'
    + QUOTENAME(X.ProcedureName),

    C.N.value('@Author','varchar(200)'),

    CAST
    (
        C.N.value('@Date','varchar(20)')
        AS DATE
    ),

    C.N.value('@Type','varchar(50)'),

    NULLIF
    (
        C.N.value('@Ticket','varchar(100)'),
        ''
    ),

    LTRIM(RTRIM(C.N.value('.','varchar(max)')))

FROM #XmlV2 X
CROSS APPLY X.XmlDefinition.nodes('/Documentation/Log/Change') C(N);


/*==============================================================================
    Detail Result
==============================================================================*/

SELECT
    AuthorName,

    FullProcedureName,

    ChangeType,

    ChangeDate,

    Ticket,

    ChangeDescription

FROM #ChangeDetail
ORDER BY
    ChangeDate DESC,
    AuthorName;


/*==============================================================================
    Summary Result
==============================================================================*/

SELECT
    AuthorName,

    COUNT(*) AS TotalChanges,

    COUNT(DISTINCT ObjectId) AS AffectedProcedures,

    MIN(ChangeDate) AS FirstChangeDate,

    MAX(ChangeDate) AS LastChangeDate

FROM #ChangeDetail
GROUP BY
    AuthorName
ORDER BY
    TotalChanges DESC,
    AuthorName;