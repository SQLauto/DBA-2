DECLARE @sql nvarchar(1000)
DECLARE @sqlschema nvarchar(100)
declare @schemaname varchar(100)=!DBVARIABLE_schemaname!
declare @tablename varchar(100)=!DBVARIABLE_tablename!

IF NOT EXISTS ( SELECT  schema_name FROM information_schema.schemata WHERE schema_name = @schemaname ) 
BEGIN
SET @sqlschema='CREATE SCHEMA ' + @schemaname
EXEC sp_executesql @sqlschema
END

SET @sql= 'IF (NOT EXISTS (SELECT * '
SET @sql= @sql+'FROM INFORMATION_SCHEMA.TABLES '
SET @sql= @sql+'WHERE TABLE_SCHEMA = @schemaname '
SET @sql= @sql+'AND  TABLE_NAME = @tablename)) '+CHAR(10)
SET @sql= @sql+'BEGIN '+CHAR(10)
    SET @sql= @sql+'CREATE TABLE ['+@schemaname+'].['+@tablename+'] '+CHAR(10)
	SET @sql= @sql+'( '	+CHAR(10)
	SET @sql= @sql+'	[report_id] [int] NOT NULL, '+CHAR(10)
	SET @sql= @sql+'	[execution_id] [int] NOT NULL, '+CHAR(10)
	SET @sql= @sql+'	[iserror] [bit] default 0, '+CHAR(10)
	SET @sql= @sql+'	[errormessage] [varchar](1000), '+CHAR(10)
	SET @sql= @sql+'	[created] [datetime] NOT NULL, '+CHAR(10)
	SET @sql= @sql+'	CONSTRAINT FK_reportid FOREIGN KEY (report_id) REFERENCES [assurance].[reports](id), '+CHAR(10)
    SET @sql= @sql+'	CONSTRAINT FK_executionid FOREIGN KEY (execution_id) REFERENCES [assurance].[execution](id), '+CHAR(10)
	SET @sql= @sql+'	CONSTRAINT PK_results PRIMARY KEY ([report_id],[execution_id]) '+CHAR(10)
	SET @sql= @sql+'); '
SET @sql= @sql+'END '+CHAR(10)
SET @sql= @sql+'ELSE '+CHAR(10)
SET @sql= @sql+'BEGIN '+CHAR(10)
	SET @sql= @sql+'PRINT ''TABLE ALREADY EXIST'' '+CHAR(10)
SET @sql= @sql+'END '+CHAR(10)

exec sp_executesql @sql, N'@schemaname VARCHAR(50),@tablename varchar(100)', @schemaname,@tablename