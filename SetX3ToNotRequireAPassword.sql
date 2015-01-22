DECLARE @rowcnt INT
BEGIN TRAN
UPDATE DEMO.ADOVAL
SET VALEUR_0 = 1
WHERE 
	PARAM_0 = 'PASSWD' 
	AND CMP_0 = ''
	AND FCY_0 = ''
	
SET @rowcnt = @@ROWCOUNT

IF @rowcnt > 1
BEGIN
	PRINT 'We updated too many rows, rolling back this transaction. No changes  have been made.'
	ROLLBACK
END
ELSE
BEGIN
	PRINT 'Password for this folder is no longer required'
	COMMIT TRAN
END


SELECT * 
FROM DEMO.ADOVAL
WHERE PARAM_0 = 'PASSWD'
