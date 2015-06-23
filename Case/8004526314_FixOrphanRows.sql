BEGIN TRAN

IF OBJECT_ID('dbo.ZDeleteLog', 'U') IS NULL
BEGIN
	CREATE TABLE dbo.ZDeleteLog 
	(
		ID				INT	IDENTITY(1,1),
		TableName		SYSNAME,
		RowID			INT,
		KeyValue		VARCHAR(MAX),
		DeleteDate		DATETIME
	)
END

BEGIN TRY

	-- Delete records inside CPTANALIN that don't exist for SOH
	DECLARE @cptMask VARCHAR(MAX), @rowcount INT
	SET @cptMask = 'SO%'

	INSERT INTO dbo.ZDeleteLog (TableName, RowID, KeyValue, DeleteDate)
	SELECT 
		'CPTANALIN', 
		cpt.ROWID, 
		ABRFIC_0 + '-' + 
			CONVERT(VARCHAR(MAX),VCRTYP_0) + '-' + 
			VCRNUM_0 + '-' + 
			CONVERT(VARCHAR(MAX),VCRLIN_0) + '-' + 
			CONVERT(VARCHAR(MAX),VCRSEQ_0) + '-' + 
			CPLCLE_0 + '-' + 
			CONVERT(VARCHAR(MAX),ANALIG_0),
		GETDATE()
	FROM NATRAINV6.CPTANALIN cpt
		LEFT JOIN NATRAINV6.SORDER soh
			ON cpt.VCRNUM_0 = soh.SOHNUM_0
	WHERE soh.SOHNUM_0 IS NULL AND cpt.VCRNUM_0 LIKE @cptMask 


	DELETE NATRAINV6.CPTANALIN 
	FROM NATRAINV6.CPTANALIN AS cpt
		LEFT JOIN NATRAINV6.SORDER soh
			ON cpt.VCRNUM_0 = soh.SOHNUM_0
	WHERE soh.SOHNUM_0 IS NULL AND cpt.VCRNUM_0 LIKE @cptMask 

	SET @rowcount = @@ROWCOUNT
	PRINT CONVERT(VARCHAR(MAX), @rowcount) + ' rows deleted from NATRAINV6.CPTANALIN'
	SET @rowcount = 0


	-- Delete records inside SORDERP that don't exist within SORDER
	INSERT INTO dbo.ZDeleteLog(TableName,RowID,KeyValue, DeleteDate)
	SELECT 
		'SORDERP', 
		sop.ROWID, 
		sop.SOHNUM_0 + '-' + 
			CONVERT(VARCHAR(MAX),sop.SOPLIN_0)+ '-' + 
			CONVERT(VARCHAR(MAX),sop.SOPSEQ_0),
		GETDATE()
	FROM NATRAINV6.SORDERP sop
		LEFT JOIN NATRAINV6.SORDER soh
			ON sop.SOHNUM_0 = soh.SOHNUM_0
	WHERE soh.SOHNUM_0 IS NULL

	DELETE NATRAINV6.SORDERP
	FROM NATRAINV6.SORDERP sop
		LEFT JOIN NATRAINV6.SORDER soh
			ON sop.SOHNUM_0 = soh.SOHNUM_0
	WHERE soh.SOHNUM_0 IS NULL

	SET @rowcount = @@ROWCOUNT
	PRINT CONVERT(VARCHAR(MAX), @rowcount) + ' rows deleted from NATRAINV6.SORDERP'
	SET @rowcount = 0

	-- Delete records inside SORDERQ that don't exist within SORDER
	INSERT INTO dbo.ZDeleteLog(TableName,RowID,KeyValue, DeleteDate)
	SELECT 
		'SORDERQ', 
		soq.ROWID, 
		soq.SOHNUM_0 + '-' + 
			CONVERT(VARCHAR(MAX),soq.SOPLIN_0)+ '-' + 
			CONVERT(VARCHAR(MAX),soq.SOQSEQ_0),
		GETDATE()
	FROM NATRAINV6.SORDERQ soq
		LEFT JOIN NATRAINV6.SORDER soh
			ON soq.SOHNUM_0 = soh.SOHNUM_0
	WHERE soh.SOHNUM_0 IS NULL

	DELETE NATRAINV6.SORDERQ
	FROM NATRAINV6.SORDERQ soq
		LEFT JOIN NATRAINV6.SORDER soh
			ON soq.SOHNUM_0 = soh.SOHNUM_0
	WHERE soh.SOHNUM_0 IS NULL

	SET @rowcount = @@ROWCOUNT
	PRINT CONVERT(VARCHAR(MAX), @rowcount) + ' rows deleted from NATRAINV6.SORDERQ'
	SET @rowcount = 0


	-- Delete records that exist in SORDERC that don't exist within SORDERC
	INSERT INTO dbo.ZDeleteLog(TableName,RowID,KeyValue, DeleteDate)
	SELECT 
		'SORDERQ', 
		soc.ROWID, 
		soc.SOHNUM_0 + '-' + 
			CONVERT(VARCHAR(MAX),soc.SOPLIN_0),
		GETDATE()
	FROM NATRAINV6.SORDERC soc
		LEFT JOIN NATRAINV6.SORDER soh
			ON soc.SOHNUM_0 = soh.SOHNUM_0
	WHERE soh.SOHNUM_0 IS NULL

	DELETE NATRAINV6.SORDERC
	FROM NATRAINV6.SORDERC soc
		LEFT JOIN NATRAINV6.SORDER soh
			ON soc.SOHNUM_0 = soh.SOHNUM_0
	WHERE soh.SOHNUM_0 IS NULL
	
	SET @rowcount = @@ROWCOUNT
	PRINT CONVERT(VARCHAR(MAX), @rowcount) + ' rows deleted from NATRAINV6.SORDERC'
	SET @rowcount = 0

	-- Check log of records that were deleted
	SELECT * FROM dbo.ZDeleteLog

END TRY

BEGIN CATCH
	SELECT	ERROR_NUMBER()		AS ErrorNumber,
			ERROR_SEVERITY()	AS ErrorSeverity,
			ERROR_STATE()		AS ErrorState,
			ERROR_PROCEDURE()	AS ErrorProcedure,
			ERROR_LINE()		AS ErrorLine,
			ERROR_MESSAGE()		AS ErrorMessage

	IF @@TRANCOUNT > 0
	BEGIN
		ROLLBACK TRANSACTION
	END
END CATCH



-- Finally commit 
IF @@TRANCOUNT > 0
BEGIN
	COMMIT TRAN
END
