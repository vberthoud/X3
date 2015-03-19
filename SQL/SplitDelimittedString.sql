/*  
SET STATISTICS IO ON;
SET STATISTICS TIME ON;
SET NOCOUNT ON;

SELECT [Value] FROM [dbo].[split_delimited_string]
   ('1||2||3||4||5||6||7||8||9||10||11||12||13||14||15||16||17||18||19||20','||') 
      WHERE Value IN (1,2,3,4,5,6,7,8,9,20) 
SELECT [Value] FROM [dbo].[split_delimited_string]
   ('1;2;3;4;5;6;7;8;9;10;11;12;13;14;15;16;17;18;19;20',';')  
SELECT [Value] FROM [dbo].[split_delimited_string]
   ('1[][]2[][]3[][]4[][]5[][]6[][]7[][]8[][]9[][]10[][]11[][]12[][]13[][]14[][]15[][]16[][]17[][]18[][]19[][]20','[][]')  

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
SET NOCOUNT OFF;
*/  
CREATE FUNCTION [split_delimited_string]  
(  
 @str NVARCHAR(MAX),   
 @sep NVARCHAR(MAX)  
)  
RETURNS @value TABLE (Value NVARCHAR(MAX))  
AS  
BEGIN  
 
 DECLARE @xml XML = (SELECT CONVERT(XML,'<r>' + REPLACE(@str,@sep,'</r><r>') + '</r>'))
 
 INSERT INTO @value(Value)
 SELECT t.value('.','NVARCHAR(MAX)')
 FROM @xml.nodes('/r') AS x(t)
   
 RETURN;  
END