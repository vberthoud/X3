/*****************************************************************************************/
--	Author:			Bob Delamater
--	Date:			02/05/2015
--	Description:	Locate stock records with a blank value within QTYSTU_0 field, or a null value
--					Note: QTYSTU_0 is assumed to not allow nulls but the check will be made anyways
--					
--					Create a table to store these records
--					This table will be useful for analyzing and finding a pattern as to root cause
--
--	How to use:		This script needs to have the schema replaced with your specific schema.
--					To do this press ctrl + m and place the name of the X3 folder 
--					(DEMO or PRODUCTION for instance) and press ok.
--					Then, ensure that the database is set correctly for your connection. 
--					Script must be run as a member of the sysadmin role (SA or equivalent)
--					If database mail is installed an email will be generated
--
--	Parameters:		1. Database Name: 
--						- This is the x3 database name, normally x3v6, or x3v7					
--					2. To Email Address:
--						- This the email address to send the results to
--					3. From Email Address
--						- This is email address you want to send on behalf of
--					4. X3 Folder Name
--						- This is the schema name where you want to store the new table. 
--						- The schema name is equal to the name of the X3 folder
--						- Example: DEMO, PRODUCTION, LIVE
--					5. Database Mail Profile Name
--						- This is usually something like ADMIN
--						- Check your Database Mail Profile setup to learn the name
--						- This query can help identify the profile name
--							SELECT name FROM msdb..sysmail_profile

/*****************************************************************************************/



/*********************************** Variable Set Up *************************************/
USE <DatabaseName, SYSNAME, x3v6>
GO
DECLARE 
	@emailList				VARCHAR(MAX), 
	@fromEmail				VARCHAR(255), 
	@BatchID				UNIQUEIDENTIFIER,			-- Uniquely identifies a batch of records at insertion time of STOCKBLANKQTY_BJD
	@execSQL				VARCHAR(MAX),				-- Used for database mail 
	@myEmailBody			VARCHAR(MAX),
	@IsTableFonctionExists	BIT,
	@IsDatabaseRoleExists	BIT,
	@DBName					SYSNAME
SET @emailList = '<To Email Address, VARCHAR(MAX), yourEmailAddressListHere@sage.com>'
SET @fromEmail = '<From Email Address, VARCHAR(MAX), yourFromEmailhere@sage.com>'
SET @BatchID = NEWID()

SET @IsTableFonctionExists = 0
SET @IsDatabaseRoleExists = 0
SET @DBName = '<DatabaseName, SYSNAME, x3v6>'

SET @execSQL = 'SELECT * FROM <DatabaseName, SYSNAME, x3v6>.<X3 Folder Name, SYSNAME, DEMO>.STOCKBLANKQTY_BJD WHERE BatchID = ''' + CONVERT(VARCHAR(40), @BatchID) + ''''


/******************************* Sanity Checks / Go - No Go	******************************/
-- If not SA user cancel
IF (SELECT IS_SRVROLEMEMBER('sysadmin')) <> 1
BEGIN
	PRINT 'This script must be run as a sysadmin. Please change the user connection to sa or equivalent'
	RETURN
END

-- Is this an X3 database?
IF EXISTS
(
	SELECT t.name 
	FROM sys.tables t 
		INNER JOIN sys.schemas s 
			ON t.schema_id = s.schema_id 
			AND s.name = 'X3' 
			AND t.name ='AFONCTION'
)
	BEGIN
		SET @IsTableFonctionExists = 1
	END

IF EXISTS(SELECT * FROM sys.database_principals WHERE name = 'X3_ADX_SYS')
BEGIN
	SET @IsDatabaseRoleExists = 1
END


IF (@IsDatabaseRoleExists = 0 OR @IsTableFonctionExists = 0 OR (LOWER(DB_NAME()) <> LOWER(@DBName)))
BEGIN
	PRINT 'Please run this against your Sage ERP X3 database. Script terminated.'
	RETURN
END

/******************************* Create Table or Populate Table ******************************/
IF OBJECT_ID('<X3 Folder Name, SYSNAME, DEMO>.STOCKBLANKQTY_BJD', 'U') IS NULL
	BEGIN
		PRINT 'Creating <X3 Folder Name, SYSNAME, DEMO>.STOCKBLANKQTY_BJD Table'
		
		SELECT * 
		INTO <X3 Folder Name, SYSNAME, DEMO>.STOCKBLANKQTY_BJD
		FROM <X3 Folder Name, SYSNAME, DEMO>.STOCK 
		WHERE 1=2
		
		ALTER TABLE <X3 Folder Name, SYSNAME, DEMO>.STOCKBLANKQTY_BJD ADD DiagCreateDate DATETIME
		ALTER TABLE <X3 Folder Name, SYSNAME, DEMO>.STOCKBLANKQTY_BJD ADD BatchID	UNIQUEIDENTIFIER
	END
ELSE
	BEGIN
		PRINT 'STOCKBLANKQTY_BJD Already created'
		INSERT INTO <X3 Folder Name, SYSNAME, DEMO>.STOCKBLANKQTY_BJD
		SELECT		
				STOFCY_0, STOCOU_0, OWNER_0, 
				ITMREF_0, LOT_0, SLO_0, 
				BPSLOT_0, PALNUM_0, CTRNUM_0, 
				STA_0, LOC_0, LOCTYP_0, 
				LOCCAT_0, WRH_0, SERNUM_0, 
				RCPDAT_0, PCU_0, PCUSTUCOE_0, 
				QTYPCU_0, QTYSTU_0, QTYSTUACT_0, 
				PCUORI_0, QTYPCUORI_0, QTYSTUORI_0, 
				QLYCTLDEM_0, CUMALLQTY_0, CUMALLQTA_0, 
				CUMWIPQTY_0, CUMWIPQTA_0, EDTFLG_0, 
				LASRCPDAT_0, LASISSDAT_0, LASCUNDAT_0, 
				CUNLOKFLG_0, CUNLISNUM_0, EXPNUM_0, 
				CREDAT_0, CREUSR_0, UPDDAT_0, 
				UPDUSR_0, GETDATE(), @BatchID
		FROM	<X3 Folder Name, SYSNAME, DEMO>.STOCK WITH(NOLOCK)
		WHERE   QTYSTU_0 IS NULL
				OR(RTRIM(LTRIM(QTYSTU_0)) = '')
		ORDER BY STOFCY_0, LOC_0, ITMREF_0, STA_0
	END



/******************************* Is Database Mail Installed and Configured? ******************************/
-- Is database mail enabled?
IF NOT EXISTS
(
	SELECT name, value_in_use
	FROM sys.configurations
	WHERE LOWER(name) LIKE 'database mail xps' AND value_in_use = 1
)
BEGIN
	PRINT 'Database Mail is not configured. Please configure database mail first, this procedure has been terminated. ' + CHAR(10)
	+ 'See these instructions: http://msdn.microsoft.com/en-us/library/hh245116(v=sql.110).aspx'

	RETURN
END


/******************************* Send an email alerting blank quantity exists ******************************/
IF EXISTS(SELECT 1 FROM <X3 Folder Name, SYSNAME, DEMO>.STOCKBLANKQTY_BJD WHERE BatchID = @BatchID)
	BEGIN

		SET @myEmailBody = 'The STOCKBLANKQTY_BJD table has been loaded with data. Please run the following query to get these results:'  
		+ CHAR(13) + 'SELECT * FROM <DatabaseName, SYSNAME, x3v6>.<X3 Folder Name, SYSNAME, DEMO>.STOCKBLANKQTY_BJD WHERE BatchID = ''' + CONVERT(VARCHAR(40), @BatchID) + ''''
		USE msdb
		PRINT 'Sending results via DB Mail'
		EXEC msdb.dbo.sp_send_dbmail 
			@profile_name = '<Database Mail Profile Name, SYSNAME, Admin>',
			@query = @execSQL,
			@query_result_width = 32767,
			@attach_query_result_as_file = 1,
			@recipients = @emailList, 
			@body = @myEmailBody,
			@body_format = 'HTML',
			@subject = 'Sage: Blank Quantity Values Within STOCK Table',
			@from_address = @fromEmail

	END
ELSE
	BEGIN
		PRINT 'No new stock records with a blank value in QTYSTU_0. No database mail has been sent and no new records within STOCKBLANKQTY_BJD.'
	END	

