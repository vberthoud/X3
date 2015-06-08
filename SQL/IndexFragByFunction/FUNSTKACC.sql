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
		'COMPANY'
	)
	

exec dbo.uspGetDiscreteIndexFrag 
	@ObjectIDs, @FragPercent = 0, 
	@PageCount = 0, 
	@Rebuild = 0, 
	@Reorganize = 0, 
	@RebuildHeap = 0, 
	@MaxDop = 64
