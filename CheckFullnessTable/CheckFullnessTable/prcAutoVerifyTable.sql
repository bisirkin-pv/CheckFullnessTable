USE TOOLS
GO

CREATE PROCEDURE cft.prcAutoVerifyTable
AS
BEGIN
	/* перед вставкой нужно удалить старые записи */
	DELETE tver
	FROM TOOLS.cft.tVerification tver
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
			FROM TOOLS.cft.tVerification
		)t
		WHERE t.loadDtm = t.minLoadDtm
	)t
		ON tver.fullName = t.fullName
		AND tver.loadDtm = t.loadDtm
	WHERE exists(
		SELECT fullName FROM (
			SELECT 
				 fullName
				,COUNT(*) cnt 
			FROM TOOLS.cft.tVerification
			GROUP BY fullName
		) tex
		WHERE tex.cnt > 1
		AND tver.fullName = tex.fullName
	)

	/* Insert new data */
	DECLARE cur CURSOR FOR
		SELECT 
			 fullname
			,MIN(diffPerc)
		FROM TOOLS.cft.tVerification
		GROUP BY fullName

	OPEN cur
	DECLARE @fullName VARCHAR(200)
			,@diffPerc DECIMAL(8,3)

	FETCH NEXT FROM cur INTO @fullName, @diffPerc

	WHILE(@@FETCH_STATUS = 0)
		BEGIN
			EXEC TOOLS.cft.prcSetVerefyObject @fullName, @diffPerc
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
			,@subject VARCHAR(500) = 'Sample fullness check of sources'
			,@title VARCHAR(500) = 'Checking the fullness of the sources revealed differences'

	/* Set the list of recipients */
	SET @recipients = 'admin@admin.ru'

	SET @startHTML = N'<html><head></head><body><h3>' +
		@title + '</h3>'
	SET @tableHtML = N'<table border="1" class="task"' +
		N'<thead><tr><th>Table name</th><th>Last count rows</th><th>Now count rows</th><th>Time checkout</th></thead></tbody>' +
		CAST(	
				(
				SELECT	td = ver.fullName, '',
							td = ver.lastCountRows, '',
							td = ver.nowCountRows, '',
							td = ver.nowLoadDtm, '',
							td = ROUND(ver.nowPerc,3)
				FROM TOOLS.cft.vVerification ver
				WHERE ver.nowPerc<ver.diffPerc
					OR ver.nowCountRows = 0
				ORDER BY ver.fullName ASC
				FOR XML PATH('tr'), TYPE
				) AS NVARCHAR(MAX)
			) +
		N'</tbody></table><br/>'
	SET @endHTML = N'<p>This letter is generated automatically, you do not need to answer it.</p></body></html>'
	SET @bodyHTML = CONCAT(@startHTML,@tableHtML,@endHTML)
	IF EXISTS(
		SELECT TOP 1 1 
		FROM TOOLS.cft.vVerification ver
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
				,@body_format = 'HTML'
		*/
		END
END
