/*
Description:
    Evaluates stored procedures and functions against a configurable set of
    best-practice rules. Each rule carries a weight and a penalty factor that
    reduce the routine's score when a violation is detected.
    The final score is classified into four quality tiers: Good, Fair, Poor,
    and No Evidence.

Usage:
    - Technical code reviews
    - SQL quality audits
    - Bad-practice identification across a database
    - Portfolio / onboarding baseline for new team members

Configuration:
    @TypeRule  : Edit category weights to reflect your team's priorities.
    @Rules     : Add, remove, or adjust rules and penalty factors as needed.
    Both table variables are fully self-contained -- no external dependencies.

Output columns:
    routine_catalog  : Database where the routine lives.
    routine_type     : PROCEDURE or FUNCTION.
    routine_schema   : Schema owner.
    routine_name     : Object name.
    id               : Internal row identifier.
    rating           : Final score (0.00 - 100.00). Starts at 100 and loses
                       points per violated rule.
    status           : Quality tier derived from rating.
                           Good  = 75 - 100
                           Fair  = 50 - 74
                           Poor  = 25 - 49
                           No Evidence = < 25
    rules_violated   : Semicolon-separated list of rule codes that fired.
    created          : Routine creation date.
    last_altered     : Date of the last DDL change.

Notes:
    - Designed for SQL Server 2017+.
    - Requires at least db_datareader on INFORMATION_SCHEMA.
    - The minimum score is clamped to 0.00; it will never go negative.
    - The @searchAuthor filter is ready to use; just uncomment and set.

Reference:
    https://learn.microsoft.com/sql/relational-databases/system-information-schema-views/routines-transact-sql
    https://learn.microsoft.com/sql/t-sql/statements/set-nocount-transact-sql

Author : Sergio Nevarez
Version: 1.1.0
Created: 2025-01-01
Updated: 2025-05-11   Fix off-by-one in both WHILE loops; clamp rating >= 0;
                       apply routine-type filter in UPDATE; remove orphan debug
                       SELECT; clean up commented-out dead code; add TRY/CATCH.
*/

-- ============================================================
-- SECTION 1: Rule catalog
-- ============================================================

-- ---- 1.1  Category / weight table ----
-- Weight represents the maximum percentage a category can discount
-- from the final score. Adjust to reflect your team priorities.
DECLARE @TypeRule TABLE
(
    id          INT            NOT NULL,
    description VARCHAR(50)    NOT NULL,
    weight      DECIMAL(8, 2)  NOT NULL,
    active      BIT            NOT NULL DEFAULT (1)
);

INSERT INTO @TypeRule (id, description, weight)
VALUES
    (0, 'Uncategorized', 10.0),
    (1, 'Syntax',        30.0),
    (2, 'Structure',     30.0),
    (3, 'Logic',         20.0),
    (4, 'Documentation', 10.0);


-- ---- 1.2  Rule definitions ----
-- reverse = 0 : penalise if the keyword IS found      (flag bad practice)
-- reverse = 1 : penalise if the keyword IS NOT found  (flag missing good practice)
-- factor       : multiplied by the parent category weight to calculate the deduction
-- routine      : comma-separated list of routine types this rule applies to
DECLARE @Rules TABLE
(
    id          INT IDENTITY(1, 1),
    code        VARCHAR(50)   NOT NULL,
    rule        VARCHAR(50)   NOT NULL,
    reverse     BIT           NOT NULL DEFAULT (0),
    id_type     INT           NOT NULL,
    factor      DECIMAL(8, 2) NOT NULL DEFAULT (0),
    active      BIT           NOT NULL DEFAULT (1),
    routine     VARCHAR(150)  NOT NULL
);

INSERT INTO @Rules (code, rule, reverse, id_type, factor, routine)
VALUES
    -- Syntax rules -----------------------------------------------------------
    ('not_use_nocount',        'NOCOUNT',       1, 1, 0.20, 'PROCEDURE'),
    ('not_use_nolock',         'NOLOCK',        1, 1, 0.25, 'FUNCTION, PROCEDURE'),
    ('use_collate',            'COLLATE',       0, 1, 0.20, 'FUNCTION, PROCEDURE'),
    ('use_fn_formatmessage',   'FORMATMESSAGE', 0, 1, 0.25, 'FUNCTION, PROCEDURE'),
    ('use_print',              'PRINT',         0, 1, 0.20, 'FUNCTION, PROCEDURE'),
    ('use_fn_raiserror',       'RAISERROR',     0, 1, 0.20, 'FUNCTION, PROCEDURE'),
    ('has_asterisk_select',    '* FROM',        0, 1, 0.20, 'FUNCTION, PROCEDURE'),
    ('has_parentheses_asterisk','*)',            0, 1, 0.20, 'FUNCTION, PROCEDURE'),

    -- Structure rules ---------------------------------------------------------
    ('use_var_max',     '(MAX)',    0, 2, 0.20, 'FUNCTION, PROCEDURE'),
    ('use_fn_max',      'MAX(',     0, 2, 0.20, 'FUNCTION, PROCEDURE'),
    ('use_global_temp', '##',       0, 2, 0.20, 'FUNCTION, PROCEDURE'),
    ('use_user_types',  'READONLY', 0, 2, 0.15, 'FUNCTION, PROCEDURE'),
    ('use_openjson',    'OPENJSON', 0, 2, 0.15, 'FUNCTION, PROCEDURE'),

    -- Logic rules -------------------------------------------------------------
    ('use_transaction', 'TRANSACTION', 0, 3, 0.30, 'FUNCTION, PROCEDURE'),
    ('use_while',       'WHILE',       0, 3, 0.30, 'FUNCTION, PROCEDURE'),
    ('use_cte',         'WITH',        0, 3, 0.40, 'FUNCTION, PROCEDURE'),
    ('use_return',      'RETURN',      0, 3, 0.40, 'FUNCTION, PROCEDURE');


-- ============================================================
-- SECTION 2: Working area
-- ============================================================

IF OBJECT_ID('tempdb..#RoutineReview') IS NOT NULL
    DROP TABLE #RoutineReview;

CREATE TABLE #RoutineReview
(
    id              INT IDENTITY(1, 1),
    routine_catalog VARCHAR(100)   NOT NULL,
    routine_schema  VARCHAR(100)   NOT NULL,
    routine_name    VARCHAR(100)   NOT NULL,
    routine_type    VARCHAR(100)   NOT NULL,
    created         DATETIME       NULL,
    last_altered    DATETIME       NULL,
    rating          DECIMAL(8, 2)  NOT NULL DEFAULT (100),
    rules_violated  VARCHAR(2000)  NULL          -- expanded from 500 to 2000
);


-- ============================================================
-- SECTION 3: Load routines
-- ============================================================

-- Optional: filter by author tag embedded in the routine definition.
-- Example tag convention: <Author>snevarez</Author>
DECLARE @search_author VARCHAR(50) = NULL;
-- SET @search_author = 'snevarez';

INSERT INTO #RoutineReview
    (routine_catalog, routine_schema, routine_name, routine_type, created, last_altered)
SELECT
    ROUTINE_CATALOG,
    ROUTINE_SCHEMA,
    ROUTINE_NAME,
    ROUTINE_TYPE,
    CREATED,
    LAST_ALTERED
FROM INFORMATION_SCHEMA.ROUTINES
WHERE
    (@search_author IS NULL
        OR ROUTINE_DEFINITION LIKE '%' + @search_author + '%');


-- ============================================================
-- SECTION 4: Evaluate rules (iterative scoring engine)
-- ============================================================

BEGIN TRY

    DECLARE
        @idx_routine    INT = 1,
        @max_routine    INT = (SELECT MAX(id) FROM #RoutineReview),

        @routine_schema VARCHAR(100),
        @routine_name   VARCHAR(100),
        @routine_type   VARCHAR(100);

    WHILE @idx_routine <= @max_routine   -- Fixed: <= to include the last row
    BEGIN
        SELECT
            @routine_schema = routine_schema,
            @routine_name   = routine_name,
            @routine_type   = routine_type
        FROM #RoutineReview
        WHERE id = @idx_routine;

        -- Inner loop: apply every active rule to the current routine
        DECLARE
            @current_rule_id INT = 1,
            @max_rule        INT = (SELECT MAX(id) FROM @Rules),

            @code    VARCHAR(50),
            @rule    VARCHAR(50),
            @reverse BIT,
            @factor  DECIMAL(8, 2),
            @weight  DECIMAL(8, 2),
            @routine VARCHAR(150);

        WHILE @current_rule_id <= @max_rule   -- Fixed: <= to include the last rule
        BEGIN
            SELECT
                @code    = R.code,
                @rule    = R.rule,
                @factor  = R.factor,
                @reverse = R.reverse,
                @weight  = TR.weight,
                @routine = R.routine
            FROM @Rules AS R
                INNER JOIN @TypeRule AS TR ON TR.id = R.id_type
            WHERE R.id     = @current_rule_id
              AND R.active  = 1;

            -- Skip rules that do not apply to this routine type
            IF CHARINDEX(@routine_type, @routine) = 0
            BEGIN
                SET @current_rule_id += 1;
                CONTINUE;
            END;

            -- Apply penalty: reverse = 0 fires when pattern IS found
            --                reverse = 1 fires when pattern IS NOT found
            IF @reverse = 0
            BEGIN
                UPDATE T
                SET
                    T.rating =
                        -- Clamp: never drop below 0
                        CASE
                            WHEN T.rating - (@weight * @factor) < 0 THEN 0.00
                            ELSE T.rating - (@weight * @factor)
                        END,
                    T.rules_violated =
                        IIF(ISNULL(T.rules_violated, '') = '',
                            @code,
                            T.rules_violated + ';' + @code)
                FROM #RoutineReview AS T
                    INNER JOIN INFORMATION_SCHEMA.ROUTINES AS R
                        ON  R.ROUTINE_SCHEMA COLLATE database_default
                                = T.routine_schema COLLATE database_default
                        AND R.ROUTINE_NAME   COLLATE database_default
                                = T.routine_name   COLLATE database_default
                        AND R.ROUTINE_TYPE   COLLATE database_default
                                = T.routine_type   COLLATE database_default
                        AND R.ROUTINE_DEFINITION LIKE '%' + @rule + '%'
                WHERE T.routine_schema = @routine_schema
                  AND T.routine_name   = @routine_name;
            END
            ELSE
            BEGIN
                UPDATE T
                SET
                    T.rating =
                        CASE
                            WHEN T.rating - (@weight * @factor) < 0 THEN 0.00
                            ELSE T.rating - (@weight * @factor)
                        END,
                    T.rules_violated =
                        IIF(ISNULL(T.rules_violated, '') = '',
                            @code,
                            T.rules_violated + ';' + @code)
                FROM #RoutineReview AS T
                    INNER JOIN INFORMATION_SCHEMA.ROUTINES AS R
                        ON  R.ROUTINE_SCHEMA COLLATE database_default
                                = T.routine_schema COLLATE database_default
                        AND R.ROUTINE_NAME   COLLATE database_default
                                = T.routine_name   COLLATE database_default
                        AND R.ROUTINE_TYPE   COLLATE database_default
                                = T.routine_type   COLLATE database_default
                        AND R.ROUTINE_DEFINITION NOT LIKE '%' + @rule + '%'
                WHERE T.routine_schema = @routine_schema
                  AND T.routine_name   = @routine_name;
            END

            SET @current_rule_id += 1;
        END -- inner WHILE

        SET @idx_routine += 1;
    END -- outer WHILE

END TRY
BEGIN CATCH
    -- Surface the error with context so the caller knows exactly what failed
    DECLARE
        @err_msg  NVARCHAR(4000) = ERROR_MESSAGE(),
        @err_line INT            = ERROR_LINE();

    RAISERROR(
        N'sql_object_health_check failed at line %d: %s',
        16, 1,
        @err_line, @err_msg
    );
END CATCH;


-- ============================================================
-- SECTION 5: Final results
-- ============================================================

-- Scoring scale
--   Good        : 75 - 100  (routine meets most best practices)
--   Fair        : 50 -  74  (room for improvement)
--   Poor        : 25 -  49  (significant issues found)
--   No Evidence :  0 -  24  (routine does not meet minimum bar)

SELECT
    routine_catalog,
    routine_type,
    routine_schema,
    routine_name,
    id,
    rating,
    CASE
        WHEN rating >= 75.00 THEN 'Good'
        WHEN rating >= 50.00 THEN 'Fair'
        WHEN rating >= 25.00 THEN 'Poor'
        ELSE                      'No Evidence'
    END                  AS status,
    rules_violated,
    created,
    last_altered
FROM #RoutineReview
ORDER BY
    routine_type,
    routine_schema,
    rating,
    routine_name;


-- ============================================================
-- SECTION 6: Cleanup
-- ============================================================

IF OBJECT_ID('tempdb..#RoutineReview') IS NOT NULL
    DROP TABLE #RoutineReview;