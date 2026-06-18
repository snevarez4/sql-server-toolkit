/*==============================================================================
    Dashboard Summary

    Purpose:
        Executive summary for XML V2 documentation.

    Provides:
        - Inventory Metrics
        - Change Metrics
        - Top Authors
        - Top Change Types
        - Most Active Procedures
        - Documentation Health

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
    DefinitionText NVARCHAR(MAX),
    XmlDefinition XML
);

INSERT INTO #Documentation
(
    ObjectId,
    SchemaName,
    ProcedureName,
    DefinitionText,
    XmlDefinition
)
SELECT
    P.ObjectId,
    P.SchemaName,
    P.ProcedureName,
    P.DefinitionText,

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
WHERE P.DefinitionText IS NOT NULL;


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

    NULLIF(
        LTRIM(RTRIM(C.N.value('@Author','varchar(200)')))
    , ''),

    TRY_CONVERT(
        DATE,
        C.N.value('@Date','varchar(20)')
    ),

    NULLIF(
        LTRIM(RTRIM(C.N.value('@Type','varchar(20)')))
    , ''),

    NULLIF(
        LTRIM(RTRIM(C.N.value('@Ticket','varchar(100)')))
    , ''),

    LTRIM(RTRIM(C.N.value('.','varchar(max)')))

FROM #XmlV2 X
CROSS APPLY X.XmlDefinition.nodes('/Documentation/Log/Change') C(N);


/*==============================================================================
    Dataset 1
    Inventory Summary
==============================================================================*/

SELECT
    'Total Procedures' AS Metric,
    COUNT(*) AS MetricValue
FROM #Procedures

UNION ALL

SELECT
    'XML V2 Procedures',
    COUNT(*)
FROM #XmlV2

UNION ALL

SELECT
    'XML V1 Procedures',
    COUNT(*)
FROM #Documentation
WHERE XmlDefinition IS NOT NULL
AND ISNULL(
        XmlDefinition.value(
            '(/Documentation/@Version)[1]',
            'varchar(10)'
        ),
        ''
    ) <> '2.0'

UNION ALL

SELECT
    'Undocumented Procedures',
    COUNT(*)
FROM #Procedures
WHERE DefinitionText NOT LIKE '%<Documentation%';


/*==============================================================================
    Dataset 2
    Change Summary
==============================================================================*/

SELECT
    COUNT(*) AS TotalChanges,
    COUNT(DISTINCT AuthorName) AS Authors,
    COUNT(DISTINCT ObjectId) AS ProceduresChanged,
    MIN(ChangeDate) AS FirstChangeDate,
    MAX(ChangeDate) AS LastChangeDate
FROM #ChangeDetail;


/*==============================================================================
    Dataset 3
    Top Authors
==============================================================================*/

SELECT TOP (10)
    AuthorName,
    COUNT(*) AS TotalChanges
FROM #ChangeDetail
GROUP BY AuthorName
ORDER BY COUNT(*) DESC;


/*==============================================================================
    Dataset 4
    Top Change Types
==============================================================================*/

SELECT TOP (10)
    ChangeType,
    COUNT(*) AS TotalChanges
FROM #ChangeDetail
GROUP BY ChangeType
ORDER BY COUNT(*) DESC;


/*==============================================================================
    Dataset 5
    Most Active Procedures
==============================================================================*/

SELECT TOP (10)
    FullProcedureName,
    COUNT(*) AS TotalChanges
FROM #ChangeDetail
GROUP BY FullProcedureName
ORDER BY COUNT(*) DESC;


/*==============================================================================
    Dataset 6
    Documentation Health
==============================================================================*/

;WITH ValidationResults AS
(
    SELECT
        'V001' AS ValidationCode
    FROM #Procedures P
    WHERE P.DefinitionText NOT LIKE '%<Documentation%'

    UNION ALL

    SELECT
        'V002'
    FROM #Documentation D
    WHERE D.XmlDefinition IS NOT NULL
    AND D.XmlDefinition.value(
            '(/Documentation/@Version)[1]',
            'varchar(10)'
        ) <> '2.0'

    UNION ALL

    SELECT
        'V010'
    FROM #XmlV2 X
    WHERE ISNULL(
        X.XmlDefinition.value(
            '(/Documentation/Info/Application/text())[1]',
            'varchar(200)'
        ),
        ''
    ) = ''

    UNION ALL

    SELECT
        'V020'
    FROM #XmlV2 X
    WHERE ISNULL(
        X.XmlDefinition.value(
            '(/Documentation/Info/Module/text())[1]',
            'varchar(200)'
        ),
        ''
    ) = ''

    UNION ALL

    SELECT
        'V030'
    FROM #XmlV2 X
    WHERE ISNULL(
        X.XmlDefinition.value(
            '(/Documentation/Info/Maintainer/text())[1]',
            'varchar(200)'
        ),
        ''
    ) = ''

    UNION ALL

    SELECT
        'V050'
    FROM #ChangeDetail C
    LEFT JOIN @ValidTypes V
        ON V.ChangeType COLLATE Modern_Spanish_CI_AS = C.ChangeType COLLATE Modern_Spanish_CI_AS 
    WHERE V.ChangeType IS NULL
)
SELECT
    ValidationCode,

    COUNT(*) AS Total,

    CAST
    (
        COUNT(*) * 100.0 /
        NULLIF(
            (
                SELECT COUNT(*)
                FROM #XmlV2
            ),
            0
        )
    AS DECIMAL(6,2)
    ) AS PercentOfProcedures

FROM ValidationResults
GROUP BY ValidationCode
ORDER BY ValidationCode;