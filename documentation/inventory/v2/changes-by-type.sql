/*==============================================================================
    Changes By Type

    Purpose:
        Analyze XML V2 Change history by Change Type.

    Compatibility:
        SQL Server 2012+

==============================================================================*/

SET NOCOUNT ON;

/*==============================================================================
    Valid Change Types
==============================================================================*/

DECLARE @ValidTypes TABLE
(
    ChangeType VARCHAR(10) PRIMARY KEY
);

INSERT INTO @ValidTypes
(
    ChangeType
)
VALUES
('US'),
('BUG'),
('FIX'),
('REF'),
('DOC'),
('PERF'),
('SEC');


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
    AND XmlDefinition.value
    (
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

    ChangeType VARCHAR(20),

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

    NULLIF
    (
        LTRIM(RTRIM(C.N.value('@Author','varchar(200)'))),
        ''
    ),

    TRY_CONVERT
    (
        DATE,
        C.N.value('@Date','varchar(20)')
    ),

    NULLIF
    (
        LTRIM(RTRIM(C.N.value('@Type','varchar(20)'))),
        ''
    ),

    NULLIF
    (
        LTRIM(RTRIM(C.N.value('@Ticket','varchar(100)'))),
        ''
    ),

    LTRIM(RTRIM(C.N.value('.','varchar(max)')))

FROM #XmlV2 X
CROSS APPLY X.XmlDefinition.nodes('/Documentation/Log/Change') C(N);


/*==============================================================================
    Dataset 1
    Change Detail
==============================================================================*/

SELECT
    ChangeType,

    AuthorName,

    FullProcedureName,

    ChangeDate,

    Ticket,

    ChangeDescription

FROM #ChangeDetail
ORDER BY
    ChangeDate DESC,
    ChangeType,
    AuthorName;


/*==============================================================================
    Dataset 2
    Change Type Summary
==============================================================================*/

SELECT
    D.ChangeType,

    COUNT(*) AS TotalChanges,

    COUNT(DISTINCT D.ObjectId) AS ProceduresAffected,

    COUNT(DISTINCT D.AuthorName) AS AuthorsInvolved,

    MIN(D.ChangeDate) AS FirstChangeDate,

    MAX(D.ChangeDate) AS LastChangeDate,

    CAST
    (
        COUNT(*) * 100.0
        /
        SUM(COUNT(*)) OVER()
    AS DECIMAL(6,2)
    ) AS PercentOfTotal

FROM #ChangeDetail D
INNER JOIN @ValidTypes V
    ON V.ChangeType COLLATE Modern_Spanish_CI_AS = D.ChangeType COLLATE Modern_Spanish_CI_AS
GROUP BY
    D.ChangeType

ORDER BY
    TotalChanges DESC,
    D.ChangeType;


/*==============================================================================
    Dataset 3
    Invalid Types
==============================================================================*/

SELECT
    ISNULL(D.ChangeType, 'NULL') AS ChangeType,

    COUNT(*) AS TotalOccurrences

FROM #ChangeDetail D
    LEFT JOIN @ValidTypes V
        ON V.ChangeType COLLATE Modern_Spanish_CI_AS = D.ChangeType COLLATE Modern_Spanish_CI_AS
WHERE
    V.ChangeType IS NULL

GROUP BY
    D.ChangeType

ORDER BY
    TotalOccurrences DESC;