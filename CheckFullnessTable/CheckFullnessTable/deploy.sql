/*
	Скрипт подготовки базы 
*/

/* Указываем базу для развертывания */
USE TOOLS 
GO
DECLARE @DEBUG BIT = 0;		/* Только отобразить текст */
DECLARE @REBILD BIT = 1;	/* пересоздавать объекты */
DECLARE @sql NVARCHAR(MAX);
DECLARE @SHCHEMA VARCHAR(5) = 'cft';
DECLARE @TABLE_VERIFICATION VARCHAR(100) = 'tVerification';		/* Хранит данные по таблицам к проверке */
DECLARE @VIEW_VERIFICATION VARCHAR(100) = 'vVerification';		/* Отображает сравнение проверок */
DECLARE @PRC_SET_VERIFY VARCHAR(100) = 'prcSetVerefyObject';	/* Добавление новой таблицы и подсчет строк в таблице */
DECLARE @PRC_AUTO_VERIFY VARCHAR(100) = 'prcAutoVerifyTable';	/* Проверка источников на наполнность */
DECLARE @IS_CREATE BIT = 0;

IF @DEBUG = 1
	PRINT '[Info] Срипт запущен в режиме debug, создание объектов не происходит.'
ELSE
	PRINT '[Info] Срипт запущен в режиме deploy'

/* Проверка существования схемы */
IF NOT EXISTS(SELECT * FROM sys.schemas WHERE name = @SHCHEMA)
	BEGIN		
	SET @sql = 'CREATE SCHEMA ' + @SHCHEMA;
		IF @DEBUG = 1
			PRINT @sql
		ELSE
			BEGIN
				EXEC sp_executesql @sql;
				PRINT '[Success] Создана схема: ' + @SHCHEMA;
			END				
	END
	ELSE
		PRINT '[Info] Схема [' + @SHCHEMA + '] уже существует'

/* Таблица для хранения источников к проверке */
IF EXISTS(
			SELECT * FROM sys.tables t
			JOIN sys.schemas s
				ON t.schema_id = s.schema_id
			WHERE t.name = @TABLE_VERIFICATION
				AND s.name = @SHCHEMA
	)
	BEGIN
		SET @sql = CONCAT('DROP TABLE',SPACE(1),DB_NAME(),'.',@SHCHEMA,'.',@TABLE_VERIFICATION);
		IF @DEBUG = 1
			PRINT @sql
		ELSE
			IF @REBILD = 1 OR @IS_CREATE = 1
				BEGIN
					EXEC sp_executesql @sql;
					SET @IS_CREATE = 1;
					PRINT '[Success] Объект был удален: ' + CONCAT(DB_NAME(),'.',@SHCHEMA,'.',@TABLE_VERIFICATION);
				END			
	END
ELSE
	SET @IS_CREATE = 1;

SET @sql = '
CREATE TABLE ' + CONCAT(DB_NAME(),'.',@SHCHEMA,'.',@TABLE_VERIFICATION,CHAR(10)) +
'(
	 loadDtm	DATETIME2(0) DEFAULT SYSDATETIME() NOT NULL
	,fullName	VARCHAR(200)	NOT NULL
	,countRows	INT				NULL
	,diffPerc	DECIMAL(8,3)	NOT NULL
)'
	IF @DEBUG = 1			
		PRINT @sql
	ELSE
		IF @REBILD = 1
				BEGIN
					EXEC sp_executesql @sql;
					SET @IS_CREATE = 0;
					PRINT '[Success] Создан объект:' + CONCAT(DB_NAME(),'.',@SHCHEMA,'.',@TABLE_VERIFICATION)
				END
			ELSE
				PRINT '[Info] Объект уже существует: ' + CONCAT(DB_NAME(),'.',@SHCHEMA,'.',@TABLE_VERIFICATION);

/* Создание представления для отображения результатов проверки */
IF EXISTS(
			SELECT * FROM sys.views t
			JOIN sys.schemas s
				ON t.schema_id = s.schema_id
			WHERE t.name = @VIEW_VERIFICATION
				AND s.name = @SHCHEMA
	)
	BEGIN
		SET @sql = CONCAT('DROP VIEW',SPACE(1),@SHCHEMA,'.',@VIEW_VERIFICATION);
		IF @DEBUG = 1
			PRINT @sql
		ELSE
			IF @REBILD = 1
				BEGIN
					EXEC sp_executesql @sql;
					SET @IS_CREATE = 1;
					PRINT '[Success] Объект был удален: ' + CONCAT(DB_NAME(),'.',@SHCHEMA,'.',@VIEW_VERIFICATION);
				END			
	END
ELSE
	SET @IS_CREATE = 1;

	SET @sql =
'CREATE VIEW ' + CONCAT(@SHCHEMA,'.',@VIEW_VERIFICATION,CHAR(10),'AS',CHAR(10)) + 
'SELECT
	 tlast.fullName
	,tlast.countRows	AS lastCountRows
	,tlast.loadDtm		AS lastLoadDtm
	,tnow.countRows		AS nowCountRows
	,tnow.loadDtm		AS nowLoadDtm
	,tnow.diffPerc		AS diffPerc
	,CASE WHEN tlast.countRows = 0
		THEN CASE WHEN tnow.countRows <> 0 
				THEN 2.000
				ELSE 0.000
			END
		ELSE CAST(1.000 * tnow.countRows / tlast.countRows AS DECIMAL(18,4))
	END nowPerc
FROM (
	SELECT 
		 loadDtm
		,fullName
		,countRows
	FROM (
		/* Данные за вчера */
		SELECT
			 loadDtm
			,fullName
			,countRows
			,MIN(loadDtm) OVER(PARTITION BY fullName) AS minLoadDtm
		FROM ' +
		CONCAT(DB_NAME(),'.',@SHCHEMA,'.',@TABLE_VERIFICATION,CHAR(10)) +
	') t
	WHERE t.loadDtm = t.minLoadDtm
) AS tlast
JOIN ' +
CONCAT(DB_NAME(),'.',@SHCHEMA,'.',@TABLE_VERIFICATION,SPACE(1),'tnow',CHAR(10)) +
	'ON tlast.fullName = tnow.fullName
	AND tlast.loadDtm <> tnow.loadDtm;'

	IF @DEBUG = 1			
		PRINT @sql
	ELSE
		IF @REBILD = 1 OR @IS_CREATE = 1
				BEGIN
					EXEC sp_executesql @sql;
					SET @IS_CREATE = 0;
					PRINT '[Success] Создан объект:' + CONCAT(DB_NAME(),'.',@SHCHEMA,'.',@VIEW_VERIFICATION)
				END
			ELSE
				PRINT '[Info] Объект уже существует: ' + CONCAT(DB_NAME(),'.',@SHCHEMA,'.',@VIEW_VERIFICATION);

/* Создание процедуры для внесения объектов для проверки */
IF EXISTS(
			SELECT * FROM sys.procedures t
			JOIN sys.schemas s
				ON t.schema_id = s.schema_id
			WHERE t.name = @PRC_SET_VERIFY
				AND s.name = @SHCHEMA
	)
	BEGIN
		SET @sql = CONCAT('DROP PROCEDURE',SPACE(1),@SHCHEMA,'.',@PRC_SET_VERIFY);
		IF @DEBUG = 1
			PRINT @sql
		ELSE
			IF @REBILD = 1
				BEGIN
					EXEC sp_executesql @sql;
					SET @IS_CREATE = 1;
					PRINT '[Success] Объект был удален: ' + CONCAT(DB_NAME(),'.',@SHCHEMA,'.',@PRC_SET_VERIFY);
				END			
	END
ELSE
	SET @IS_CREATE = 1;

SET @sql ='
CREATE PROCEDURE' + CONCAT(SPACE(1),@SHCHEMA,'.',@PRC_SET_VERIFY) +
'(
	 @FULL_NAME VARCHAR(200)
	,@DIFF_PERC DECIMAL(8,3) = 0.75
	,@DEBUG BIT = 0
)
AS
BEGIN
	SET NOCOUNT ON;
	 DECLARE @sql NVARCHAR(MAX);
	 BEGIN TRY
		SET @sql = CONCAT(''INSERT INTO ' + CONCAT(DB_NAME(),'.',@SHCHEMA,'.',@TABLE_VERIFICATION) + '(fullName,countRows,diffPerc)'',CHAR(10));
		SET @sql = @sql + 
			''SELECT '''''' + REPLACE(REPLACE(@FULL_NAME,''['',''''),'']'','''') +'''''' AS fullName, (SELECT COUNT(*) FROM '' + 
			@FULL_NAME +
			'') countRow, ''+
			CAST(@DIFF_PERC AS NVARCHAR(12)) + 
			'' AS diffPerc''
		IF @DEBUG = 1
			PRINT @sql
		ELSE
			BEGIN
				EXEC sp_executesql @sql;
				PRINT ''[Success] Добавлен объект к проверке: '' + @FULL_NAME;
			END
	 END TRY
	 BEGIN CATCH		
		PRINT CONCAT(''[Error] возникла ошибка в ходе выполнения:'',CHAR(10),ERROR_NUMBER(),CHAR(10),ERROR_LINE(),CHAR(10),ERROR_MESSAGE());
		IF @DEBUG = 0
			THROW;
	 END CATCH
END'
	IF @DEBUG = 1			
		PRINT @sql
	ELSE
		IF @REBILD = 1 OR @IS_CREATE = 1
				BEGIN
					EXEC sp_executesql @sql;
					SET @IS_CREATE = 0;
					PRINT '[Success] Создан объект:' + CONCAT(DB_NAME(),'.',@SHCHEMA,'.',@PRC_SET_VERIFY)
				END
			ELSE
				PRINT '[Info] Объект уже существует: ' + CONCAT(DB_NAME(),'.',@SHCHEMA,'.',@PRC_SET_VERIFY);

/* Создание процедуры для выполнения проверок */
IF EXISTS(
			SELECT * FROM sys.procedures t
			JOIN sys.schemas s
				ON t.schema_id = s.schema_id
			WHERE t.name = @PRC_AUTO_VERIFY
				AND s.name = @SHCHEMA
	)
	BEGIN
		SET @sql = CONCAT('DROP PROCEDURE',SPACE(1),@SHCHEMA,'.',@PRC_AUTO_VERIFY);
		IF @DEBUG = 1
			PRINT @sql
		ELSE
			IF @REBILD = 1
				BEGIN
					EXEC sp_executesql @sql;
					SET @IS_CREATE = 1;
					PRINT '[Success] Объект был удален: ' + CONCAT(DB_NAME(),'.',@SHCHEMA,'.',@PRC_AUTO_VERIFY);
				END			
	END
ELSE
	SET @IS_CREATE = 1;

SET @sql = '
CREATE PROCEDURE ' + CONCAT(@SHCHEMA,'.',@PRC_AUTO_VERIFY,CHAR(10),'AS',CHAR(10)) +
'BEGIN
	/* перед вставкой нужно удалить старые записи */
	DELETE tver
	FROM ' + CONCAT(DB_NAME(),'.',@SHCHEMA,'.',@TABLE_VERIFICATION) +' tver
	JOIN (
		SELECT
			 fullName
			,countRows
			,loadDtm
		FROM (
			SELECT 
				 fullName
				,countRows
				,loadDtm
				,MIN(loadDtm) OVER (PARTITION BY fullname) minLoadDtm
			FROM ' + CONCAT(DB_NAME(),'.',@SHCHEMA,'.',@TABLE_VERIFICATION) +
'		)t
		WHERE t.loadDtm = t.minLoadDtm
	)t
		ON tver.fullName = t.fullName
		AND tver.loadDtm = t.loadDtm
	WHERE exists(
		SELECT fullName FROM (
			SELECT 
				 fullName
				,COUNT(*) cnt 
			FROM ' + CONCAT(DB_NAME(),'.',@SHCHEMA,'.',@TABLE_VERIFICATION) +
'			GROUP BY fullName
		) tex
		WHERE tex.cnt > 1
		AND tver.fullName = tex.fullName
	)

	/* Insert new data */
	DECLARE cur CURSOR FOR
		SELECT 
			 fullname
			,MIN(diffPerc)
		FROM ' + CONCAT(DB_NAME(),'.',@SHCHEMA,'.',@TABLE_VERIFICATION) +
'		GROUP BY fullName

	OPEN cur
	DECLARE @fullName VARCHAR(200)
			,@diffPerc DECIMAL(8,3)

	FETCH NEXT FROM cur INTO @fullName, @diffPerc

	WHILE(@@FETCH_STATUS = 0)
		BEGIN
			EXEC ' + CONCAT(DB_NAME(),'.',@SHCHEMA,'.',@PRC_SET_VERIFY) + ' @fullName, @diffPerc
			FETCH NEXT FROM cur INTO @fullName, @diffPerc
		END

	CLOSE cur
	DEALLOCATE cur

	/* Sending a letter if there are errors  */
	DECLARE @tableHtML NVARCHAR(MAX)
			,@startHTML VARCHAR(2000)
			,@endHTML VARCHAR(1000)
			,@bodyHTML VARCHAR(MAX)
			,@recipients VARCHAR(1000)
			,@subject VARCHAR(500) = ''Sample fullness check of sources''
			,@title VARCHAR(500) = ''Checking the fullness of the sources revealed differences''

	/* Set the list of recipients */
	SET @recipients = ''admin@admin.ru''

	SET @startHTML = N''<html><head></head><body><h3>'' +
		@title + ''</h3>''
	SET @tableHtML = N''<table border="1" class="task"'' +
		N''<thead><tr><th>Table name</th><th>Last count rows</th><th>Now count rows</th><th>Time checkout</th></thead></tbody>'' +
		CAST(	
				(
				SELECT	td = ver.fullName, '''',
							td = ver.lastCountRows, '''',
							td = ver.nowCountRows, '''',
							td = ver.nowLoadDtm, '''',
							td = ROUND(ver.nowPerc,3)
				FROM ' + CONCAT(DB_NAME(),'.',@SHCHEMA,'.',@VIEW_VERIFICATION) + ' ver
				WHERE ver.nowPerc<ver.diffPerc
					OR ver.nowCountRows = 0
				ORDER BY ver.fullName ASC
				FOR XML PATH(''tr''), TYPE
				) AS NVARCHAR(MAX)
			) +
		N''</tbody></table><br/>''
	SET @endHTML = N''<p>This letter is generated automatically, you do not need to answer it.</p></body></html>''
	SET @bodyHTML = CONCAT(@startHTML,@tableHtML,@endHTML)
	IF EXISTS(
		SELECT TOP 1 1 
		FROM ' + CONCAT(DB_NAME(),'.',@SHCHEMA,'.',@VIEW_VERIFICATION) + ' ver
		WHERE  ver.nowPerc<ver.diffPerc
					OR ver.nowCountRows = 0
		)
		BEGIN
		PRINT @bodyHTML;
		/*
			EXEc msdb.dbo.sp_send_dbmail
				 @recipients = @recipients
				,@body = @bodyHTML
				,@subject = @subject
				,@body_format = ''HTML''
		*/
		END
END'
	IF @DEBUG = 1			
		PRINT @sql
	ELSE
		IF @REBILD = 1 OR @IS_CREATE = 1
				BEGIN
					EXEC sp_executesql @sql;
					SET @IS_CREATE = 0;
					PRINT '[Success] Создан объект:' + CONCAT(DB_NAME(),'.',@SHCHEMA,'.',@PRC_AUTO_VERIFY)
				END
			ELSE
				PRINT '[Info] Объект уже существует: ' + CONCAT(DB_NAME(),'.',@SHCHEMA,'.',@PRC_AUTO_VERIFY);