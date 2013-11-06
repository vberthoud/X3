-- Check to see if server names are not equal
IF COALESCE(@@SERVERNAME, '') <>  COALESCE(SERVERPROPERTY('SeverName'), '')
BEGIN
	EXEC sp_dropserver @@SERVERNAME
	EXEC sp_addserver N'X3VCDBJDAN2\X3V6', local
END


PRINT 'You must restart your SQL Server in order for the changes to be in effect'
