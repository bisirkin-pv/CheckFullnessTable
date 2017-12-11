USE TOOLS
GO

CREATE PROCEDURE cft.prcSetVerefyObject
(
	 @FULL_NAME VARCHAR(200)
	,@DIFF_PERC DECIMAL(8,3) = 0.75
	,@DEBUG BIT = 0
)
AS
BEGIN
	SET NOCOUNT ON;
	/* DECLARE @FULL_NAME VARCHAR(200) = 'pubs.[dbo].[authors]'
	 ,@DIFF_PERC DECIMAL(8,3) = 0.75
	 ,@DEBUG BIT = 1
	 --*/
	 DECLARE @sql NVARCHAR(MAX);
	 BEGIN TRY
		SET @sql = CONCAT('INSERT INTO TOOLS.cft.tVerification(fullName,countRows,diffPerc)',CHAR(10));
		SET @sql = @sql + 
			'SELECT ''' + REPLACE(REPLACE(@FULL_NAME,'[',''),']','') +''' AS fullName, (SELECT COUNT(*) FROM ' + 
			@FULL_NAME +
			') countRow, '+
			CAST(@DIFF_PERC AS NVARCHAR(12)) + 
			' AS diffPerc'
		IF @DEBUG = 1
			PRINT @sql
		ELSE
			BEGIN
				EXEC sp_executesql @sql;
				PRINT '[Success] Добавлен объект к проверке: ' + @FULL_NAME;
			END
	 END TRY
	 BEGIN CATCH		
		PRINT CONCAT('[Error] возникла ошибка в ходе выполнения:',CHAR(10),ERROR_NUMBER(),CHAR(10),ERROR_LINE(),CHAR(10),ERROR_MESSAGE());
		IF @DEBUG = 0
			THROW;
	 END CATCH
END


