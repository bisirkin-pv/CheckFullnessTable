/*
	скрипт для удаления
*/

/* Указываем базу */
USE TOOLS 
GO
DECLARE @DEBUG BIT = 0;
DECLARE @sql NVARCHAR(MAX);
DECLARE @SHCHEMA VARCHAR(5) = 'cft';
DECLARE @TABLE_VERIFICATION VARCHAR(100) = 'tVerification';
DECLARE @VIEW_VERIFICATION VARCHAR(100) = 'vVerification';
DECLARE @PRC_SET_VERIFY VARCHAR(100) = 'prcSetVerefyObject';
DECLARE @PRC_AUTO_VERIFY VARCHAR(100) = 'prcAutoVerifyTable';

IF @DEBUG = 1
	PRINT '[Info] Скрипт запущен в режиме debug, удаление объектов не происходит.'
ELSE
	PRINT '[Info] Скрипт запущен в режиме deploy'
IF EXISTS(
			SELECT * FROM sys.tables t
			JOIN sys.schemas s
				ON t.schema_id = s.schema_id
			WHERE t.name = @TABLE_VERIFICATION
				AND s.name = @SHCHEMA
	)
	BEGIN
		SET @sql = CONCAT('DROP TABLE',SPACE(1),'.',@SHCHEMA,'.',@TABLE_VERIFICATION);
		IF @DEBUG = 1
			PRINT @sql
		ELSE
			BEGIN
				EXEC sp_executesql @sql;
				PRINT '[Success] Объект был удален: ' + CONCAT(DB_NAME(),'.',@SHCHEMA,'.',@TABLE_VERIFICATION);
			END			
	END
	ELSE 
		PRINT '[Info] Объект не найден: ' + CONCAT(DB_NAME(),'.',@SHCHEMA,'.',@TABLE_VERIFICATION);

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
			BEGIN
				EXEC sp_executesql @sql;
				PRINT '[Success] Объект был удален: ' + CONCAT(DB_NAME(),'.',@SHCHEMA,'.',@VIEW_VERIFICATION);
			END			
	END
	ELSE 
		PRINT '[Info] Объект не найден: ' + CONCAT(DB_NAME(),'.',@SHCHEMA,'.',@VIEW_VERIFICATION);

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
			BEGIN
				EXEC sp_executesql @sql;
				PRINT '[Success] Объект был удален: ' + CONCAT(DB_NAME(),'.',@SHCHEMA,'.',@PRC_SET_VERIFY);
			END			
	END
	ELSE 
		PRINT '[Info] Объект не найден: ' + CONCAT(DB_NAME(),'.',@SHCHEMA,'.',@PRC_SET_VERIFY);

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
			BEGIN
				EXEC sp_executesql @sql;
				PRINT '[Success] Объект был удален: ' + CONCAT(DB_NAME(),'.',@SHCHEMA,'.',@PRC_AUTO_VERIFY);
			END			
	END
	ELSE 
		PRINT '[Info] Объект не найден: ' + CONCAT(DB_NAME(),'.',@SHCHEMA,'.',@PRC_AUTO_VERIFY);
