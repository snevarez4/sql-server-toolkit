/*==============================================================================
    XML V2 Validation Toolkit

    Purpose:
        Validate XML v2 documentation compliance.

    Compatibility:
        SQL Server 2012+

    Iteration:
        1.0

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
==============================================================================*/

SET NOCOUNT ON;

/*==============================================================================
    Configuration
==============================================================================*/

DECLARE @DocumentationStartTag VARCHAR(50) = '<Documentation';
DECLARE @DocumentationEndTag   VARCHAR(50) = '</Documentation>';

/*==============================================================================
    Procedure Inventory
==============================================================================*/

IF OBJECT_ID('tempdb..#Procedures') IS NOT NULL
    DROP TABLE #Procedures;

CREATE TABLE #Procedures
(
    ObjectId        INT         NOT NULL,
    SchemaName      SYSNAME     NOT NULL,
    ProcedureName   SYSNAME     NOT NULL,
    DefinitionText  NVARCHAR(MAX) NULL
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
    ObjectId                    INT,
    SchemaName                  SYSNAME,
    ProcedureName               SYSNAME,

    XmlStartPosition            INT,
    XmlEndPosition              INT,

    XmlText                     NVARCHAR(MAX),

    HasDocumentation            BIT,
    HasMultipleDocumentation    BIT,
    IsEncrypted                 BIT
);

INSERT INTO #Documentation
(
    ObjectId,
    SchemaName,
    ProcedureName,
    XmlStartPosition,
    XmlEndPosition,
    XmlText,
    HasDocumentation,
    HasMultipleDocumentation,
    IsEncrypted
)
SELECT
    P.ObjectId,
    P.SchemaName,
    P.ProcedureName,

    XmlStartPosition =
        CHARINDEX(@DocumentationStartTag, P.DefinitionText),

    XmlEndPosition =
        CASE
            WHEN CHARINDEX(@DocumentationEndTag, P.DefinitionText) > 0
            THEN CHARINDEX(@DocumentationEndTag, P.DefinitionText)
                 + LEN(@DocumentationEndTag) - 1
            ELSE 0
        END,

    XmlText =
        NULL,

    HasDocumentation =
        CASE
            WHEN CHARINDEX(@DocumentationStartTag, P.DefinitionText) > 0
            THEN 1
            ELSE 0
        END,

    HasMultipleDocumentation =
        0,

    IsEncrypted =
        CASE
            WHEN P.DefinitionText IS NULL
            THEN 1
            ELSE 0
        END
FROM #Procedures AS P;


/*==============================================================================
    Populate XML Text
==============================================================================*/

UPDATE D
SET XmlText =
    SUBSTRING
    (
        P.DefinitionText,
        D.XmlStartPosition,
        D.XmlEndPosition - D.XmlStartPosition + 1
    )
FROM #Documentation AS D
INNER JOIN #Procedures AS P
    ON P.ObjectId = D.ObjectId
WHERE
    D.XmlStartPosition > 0
    AND D.XmlEndPosition > D.XmlStartPosition;


/*==============================================================================
    Detect Multiple Documentation Nodes
==============================================================================*/

UPDATE D
SET HasMultipleDocumentation =
    CASE
        WHEN CHARINDEX
             (
                 @DocumentationStartTag,
                 P.DefinitionText,
                 D.XmlEndPosition + 1
             ) > 0
        THEN 1
        ELSE 0
    END
FROM #Documentation AS D
INNER JOIN #Procedures AS P
    ON P.ObjectId = D.ObjectId
WHERE
    D.HasDocumentation = 1
    AND P.DefinitionText IS NOT NULL;


/*==============================================================================
    Parsed XML
==============================================================================*/

IF OBJECT_ID('tempdb..#ParsedXml') IS NOT NULL
    DROP TABLE #ParsedXml;

CREATE TABLE #ParsedXml
(
    ObjectId INT PRIMARY KEY,
    XmlDefinition XML
);

/*==============================================================================
    Validation Results
==============================================================================*/

IF OBJECT_ID('tempdb..#ValidationResults') IS NOT NULL
    DROP TABLE #ValidationResults;

CREATE TABLE #ValidationResults
(
    SchemaName         SYSNAME,
    ProcedureName      SYSNAME,

    Severity           VARCHAR(10),

    ValidationCode     VARCHAR(10),

    ValidationMessage  VARCHAR(200)
);

/*==============================================================================
    V050 - Encrypted Procedure
==============================================================================*/

INSERT INTO #ValidationResults
(
    SchemaName,
    ProcedureName,
    Severity,
    ValidationCode,
    ValidationMessage
)
SELECT
    SchemaName,
    ProcedureName,
    'WARNING',
    'V050',
    'Encrypted Procedure'
FROM #Documentation
WHERE IsEncrypted = 1;


/*==============================================================================
    V001 - Missing Documentation Node
==============================================================================*/

INSERT INTO #ValidationResults
(
    SchemaName,
    ProcedureName,
    Severity,
    ValidationCode,
    ValidationMessage
)
SELECT
    SchemaName,
    ProcedureName,
    'ERROR',
    'V001',
    'Missing Documentation Node'
FROM #Documentation
WHERE
    IsEncrypted = 0
    AND HasDocumentation = 0;


/*==============================================================================
    XML Parse Validation
==============================================================================*/

DECLARE
    @ObjectId INT,
    @XmlText NVARCHAR(MAX);

DECLARE XmlCursor CURSOR LOCAL FAST_FORWARD
FOR
SELECT
    ObjectId,
    XmlText
FROM #Documentation
WHERE
    HasDocumentation = 1
    AND IsEncrypted = 0;

OPEN XmlCursor;

FETCH NEXT FROM XmlCursor
INTO @ObjectId, @XmlText;

WHILE @@FETCH_STATUS = 0
BEGIN

    BEGIN TRY

        INSERT INTO #ParsedXml
        (
            ObjectId,
            XmlDefinition
        )
        VALUES
        (
            @ObjectId,
            CAST(@XmlText AS XML)
        );

    END TRY
    BEGIN CATCH

        INSERT INTO #ValidationResults
        (
            SchemaName,
            ProcedureName,
            Severity,
            ValidationCode,
            ValidationMessage
        )
        SELECT
            SchemaName,
            ProcedureName,
            'ERROR',
            'V003',
            'Malformed XML'
        FROM #Documentation
        WHERE ObjectId = @ObjectId;

    END CATCH;

    FETCH NEXT FROM XmlCursor
    INTO @ObjectId, @XmlText;

END

CLOSE XmlCursor;
DEALLOCATE XmlCursor;

/*==============================================================================
    V002 - Invalid Documentation Version
==============================================================================*/

INSERT INTO #ValidationResults
(
    SchemaName,
    ProcedureName,
    Severity,
    ValidationCode,
    ValidationMessage
)
SELECT
    D.SchemaName,
    D.ProcedureName,
    'ERROR',
    'V002',
    'Invalid Documentation Version'
FROM #ParsedXml AS X
INNER JOIN #Documentation AS D
    ON D.ObjectId = X.ObjectId
WHERE
    X.XmlDefinition.value
    (
        '(/Documentation/@Version)[1]',
        'varchar(10)'
    ) <> '2.0';


/*==============================================================================
    V040 - Multiple Documentation Nodes
==============================================================================*/

INSERT INTO #ValidationResults
(
    SchemaName,
    ProcedureName,
    Severity,
    ValidationCode,
    ValidationMessage
)
SELECT
    SchemaName,
    ProcedureName,
    'WARNING',
    'V040',
    'Multiple Documentation Nodes'
FROM #Documentation
WHERE HasMultipleDocumentation = 1;

/*==============================================================================
    V010 - Missing Info Node
==============================================================================*/

INSERT INTO #ValidationResults
(
    SchemaName,
    ProcedureName,
    Severity,
    ValidationCode,
    ValidationMessage
)
SELECT
    D.SchemaName,
    D.ProcedureName,
    'ERROR',
    'V010',
    'Missing Info Node'
FROM #ParsedXml AS X
INNER JOIN #Documentation AS D
    ON D.ObjectId = X.ObjectId
WHERE
    X.XmlDefinition.exist('/Documentation/Info') = 0;

/*==============================================================================
    V011 - Missing Application
==============================================================================*/

INSERT INTO #ValidationResults
(
    SchemaName,
    ProcedureName,
    Severity,
    ValidationCode,
    ValidationMessage
)
SELECT
    D.SchemaName,
    D.ProcedureName,
    'ERROR',
    'V011',
    'Missing Application'
FROM #ParsedXml AS X
INNER JOIN #Documentation AS D
    ON D.ObjectId = X.ObjectId
WHERE
    X.XmlDefinition.exist('/Documentation/Info/Application') = 0;

/*==============================================================================
    V012 - Missing Module
==============================================================================*/

INSERT INTO #ValidationResults
(
    SchemaName,
    ProcedureName,
    Severity,
    ValidationCode,
    ValidationMessage
)
SELECT
    D.SchemaName,
    D.ProcedureName,
    'ERROR',
    'V012',
    'Missing Module'
FROM #ParsedXml AS X
INNER JOIN #Documentation AS D
    ON D.ObjectId = X.ObjectId
WHERE
    X.XmlDefinition.exist('/Documentation/Info/Module') = 0;

/*==============================================================================
    V013 - Missing Maintainer
==============================================================================*/

INSERT INTO #ValidationResults
(
    SchemaName,
    ProcedureName,
    Severity,
    ValidationCode,
    ValidationMessage
)
SELECT
    D.SchemaName,
    D.ProcedureName,
    'ERROR',
    'V013',
    'Missing Maintainer'
FROM #ParsedXml AS X
INNER JOIN #Documentation AS D
    ON D.ObjectId = X.ObjectId
WHERE
    X.XmlDefinition.exist('/Documentation/Info/Maintainer') = 0;

/*==============================================================================
    V014 - Missing Description
==============================================================================*/

INSERT INTO #ValidationResults
(
    SchemaName,
    ProcedureName,
    Severity,
    ValidationCode,
    ValidationMessage
)
SELECT
    D.SchemaName,
    D.ProcedureName,
    'ERROR',
    'V014',
    'Missing Description'
FROM #ParsedXml AS X
INNER JOIN #Documentation AS D
    ON D.ObjectId = X.ObjectId
WHERE
    X.XmlDefinition.exist('/Documentation/Info/Description') = 0;

/*==============================================================================
    V015 - Missing CreatedDate
==============================================================================*/

INSERT INTO #ValidationResults
(
    SchemaName,
    ProcedureName,
    Severity,
    ValidationCode,
    ValidationMessage
)
SELECT
    D.SchemaName,
    D.ProcedureName,
    'WARNING',
    'V015',
    'Missing CreatedDate'
FROM #ParsedXml AS X
INNER JOIN #Documentation AS D
    ON D.ObjectId = X.ObjectId
WHERE
    X.XmlDefinition.exist('/Documentation/Info/CreatedDate') = 0;

/*==============================================================================
    V020 - Missing Log Node
==============================================================================*/

INSERT INTO #ValidationResults
(
    SchemaName,
    ProcedureName,
    Severity,
    ValidationCode,
    ValidationMessage
)
SELECT
    D.SchemaName,
    D.ProcedureName,
    'WARNING',
    'V020',
    'Missing Log Node'
FROM #ParsedXml AS X
INNER JOIN #Documentation AS D
    ON D.ObjectId = X.ObjectId
WHERE
    X.XmlDefinition.exist('/Documentation/Log') = 0;

/*==============================================================================
    V021 - Missing Change Node
==============================================================================*/

INSERT INTO #ValidationResults
(
    SchemaName,
    ProcedureName,
    Severity,
    ValidationCode,
    ValidationMessage
)
SELECT
    D.SchemaName,
    D.ProcedureName,
    'WARNING',
    'V021',
    'Missing Change Node'
FROM #ParsedXml AS X
INNER JOIN #Documentation AS D
    ON D.ObjectId = X.ObjectId
WHERE
    X.XmlDefinition.exist('/Documentation/Log') = 1
    AND X.XmlDefinition.exist('/Documentation/Log/Change') = 0;

/*==============================================================================
    Change Nodes
==============================================================================*/

DECLARE @ValidChangeTypes TABLE
(
    ChangeType VARCHAR(20) PRIMARY KEY
);

INSERT INTO @ValidChangeTypes
    VALUES ('US'),
            ('BUG'),
            ('HOTFIX'),
            ('PERF'),
            ('SEC'),
            ('REFACTOR'),
            ('DOC'),
            ('CONFIG');

IF OBJECT_ID('tempdb..#Changes') IS NOT NULL
    DROP TABLE #Changes;

CREATE TABLE #Changes
(
    ObjectId INT,

    ChangeDate VARCHAR(20),
    ChangeAuthor VARCHAR(100),
    ChangeType VARCHAR(20),

    ChangeDescription NVARCHAR(MAX)
);

INSERT INTO #Changes
(
    ObjectId,
    ChangeDate,
    ChangeAuthor,
    ChangeType,
    ChangeDescription
)
SELECT
    P.ObjectId,

    X.C.value('@Date','varchar(20)'),

    X.C.value('@Author','varchar(100)'),

    X.C.value('@Type','varchar(20)'),

    LTRIM(RTRIM(X.C.value('.','nvarchar(max)')))
FROM #ParsedXml P
    CROSS APPLY P.XmlDefinition.nodes('/Documentation/Log/Change') X(C);

/*==============================================================================
    V030 - Missing Change Date
==============================================================================*/

INSERT INTO #ValidationResults
SELECT
    D.SchemaName,
    D.ProcedureName,
    'ERROR',
    'V030',
    'Missing Change Date'
FROM #Changes C
INNER JOIN #Documentation D
    ON D.ObjectId = C.ObjectId
WHERE
    ISNULL(LTRIM(RTRIM(C.ChangeDate)),'') = '';

/*==============================================================================
    V031 - Missing Change Author
==============================================================================*/

INSERT INTO #ValidationResults
SELECT
    D.SchemaName,
    D.ProcedureName,
    'ERROR',
    'V031',
    'Missing Change Author'
FROM #Changes C
INNER JOIN #Documentation D
    ON D.ObjectId = C.ObjectId
WHERE
    ISNULL(LTRIM(RTRIM(C.ChangeAuthor)),'') = '';

/*==============================================================================
    V032 - Missing Change Type
==============================================================================*/

INSERT INTO #ValidationResults
SELECT
    D.SchemaName,
    D.ProcedureName,
    'ERROR',
    'V032',
    'Missing Change Type'
FROM #Changes C
INNER JOIN #Documentation D
    ON D.ObjectId = C.ObjectId
WHERE
    ISNULL(LTRIM(RTRIM(C.ChangeType)),'') = '';

/*==============================================================================
    V033 - Invalid Change Type
==============================================================================*/

INSERT INTO #ValidationResults
SELECT
    D.SchemaName,
    D.ProcedureName,
    'ERROR',
    'V033',
    'Invalid Change Type'
FROM #Changes C
INNER JOIN #Documentation D
    ON D.ObjectId = C.ObjectId
LEFT JOIN @ValidChangeTypes T
    ON T.ChangeType COLLATE Modern_Spanish_CI_AS = C.ChangeType COLLATE Modern_Spanish_CI_AS
WHERE
    ISNULL(LTRIM(RTRIM(C.ChangeType)),'') <> ''
    AND T.ChangeType IS NULL;

/*==============================================================================
    V034 - Missing Change Description
==============================================================================*/

INSERT INTO #ValidationResults
SELECT
    D.SchemaName,
    D.ProcedureName,
    'ERROR',
    'V034',
    'Missing Change Description'
FROM #Changes C
INNER JOIN #Documentation D
    ON D.ObjectId = C.ObjectId
WHERE
    ISNULL(LTRIM(RTRIM(C.ChangeDescription)),'') = '';

/*==============================================================================
    V035 - Invalid Change Date Format
==============================================================================*/

INSERT INTO #ValidationResults
SELECT
    D.SchemaName,
    D.ProcedureName,
    'ERROR',
    'V035',
    'Invalid Change Date Format'
FROM #Changes C
INNER JOIN #Documentation D
    ON D.ObjectId = C.ObjectId
WHERE
    ISNULL(LTRIM(RTRIM(C.ChangeDate)),'') <> ''
    AND
    (
        C.ChangeDate NOT LIKE
            '[1-2][0-9][0-9][0-9]-[0-1][0-9]-[0-3][0-9]'
        OR
        ISDATE(C.ChangeDate) = 0
    );

/*==============================================================================
    PASS - Validation Successful
==============================================================================*/

INSERT INTO #ValidationResults
(
    SchemaName,
    ProcedureName,
    Severity,
    ValidationCode,
    ValidationMessage
)
SELECT
    D.SchemaName,
    D.ProcedureName,
    'INFO',
    'PASS',
    'Validation Successful'
FROM #Documentation D
WHERE NOT EXISTS
(
    SELECT 1
    FROM #ValidationResults VR
    WHERE VR.SchemaName = D.SchemaName
      AND VR.ProcedureName = D.ProcedureName
);

/*==============================================================================
    Results
==============================================================================*/

SELECT
    SchemaName,
    ProcedureName,
    Severity,
    ValidationCode,
    ValidationMessage
FROM #ValidationResults
ORDER BY
    SchemaName,
    ProcedureName,
    ValidationCode;