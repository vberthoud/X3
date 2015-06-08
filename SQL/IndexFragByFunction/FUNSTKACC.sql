DECLARE  @ObjectIDs AS dbo.ObjectIDs ;

INSERT INTO @ObjectIDs(ObjectId, SchemaName, TableName)
SELECT t.object_id, s.name, t.name
FROM sys.tables t
	INNER JOIN sys.schemas s
		ON t.schema_id = s.schema_id
WHERE 
	s.name = 'DEMO' 
	AND t.name IN
	(
		'ITMCOST',
		'STOJOU', 
		'STOJOUVAL', 
		'STJTMP', 
		'STOACCPAR', 
		'PARSTOACC', 
		'ITMFACILIT', 
		'ITMMVT', 
		'TABCOSTMET', 
		'TABCUR', 
		'PERIOD', 
		'FACILITY', 
		'COMPANY', 
		'PRECEIPT', 
		'PRECEIPTD',
		'PRECEIPTD',
		'PINVOICE',
		'PINVOICED',
		'PINVOICEV',
		'PRETURN',
		'PRETURND',
		'SCOITM', 
		'SDELIVERY', 
		'SDELIVERYD', 
		'SINVOICE', 
		'SINVOICED', 
		'SRETURN', 
		'SRETURND', 
		'SMVTH', 
		'SMVTD', 
		'BPCUSTOMER', 
		'CUNLISDET', 
		'SCHGH', 
		'SCHGD', 
		'HDKTASK', 
		'SERREQUEST', 
		'MFGMATTRK', 
		'MFGOPE', 
		'GAUTACE'
	)
	

exec dbo.uspGetDiscreteIndexFrag 
	@ObjectIDs, @FragPercent = 0, 
	@PageCount = 0, 
	@Rebuild = 0, 
	@Reorganize = 0, 
	@RebuildHeap = 0, 
	@MaxDop = 64
