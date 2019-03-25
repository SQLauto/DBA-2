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
SET @sql= @sql+'AND  TABLE_NAME = @tablename)) '
SET @sql= @sql+'BEGIN '
    SET @sql= @sql+'CREATE TABLE ['+@schemaname+'].['+@tablename+'] '+CHAR(10)
	SET @sql= @sql+'( '	+CHAR(10)
	SET @sql= @sql+'	[id] [int] IDENTITY(1,1) PRIMARY KEY CLUSTERED NOT NULL, '+CHAR(10)
	SET @sql= @sql+'	[filename] [varchar](100) NOT NULL, '+CHAR(10)
	SET @sql= @sql+'	[query] [varchar](max) NULL, '+CHAR(10)
	SET @sql= @sql+'	[created] [datetime] NOt NULL DEFAULT (getdate()), '+CHAR(10)
	SET @sql= @sql+'	[isenabled] [bit] NOt NULL DEFAULT 1 '+CHAR(10)
	SET @sql= @sql+'); '
SET @sql= @sql+'END '+CHAR(10)
SET @sql= @sql+'ELSE '+CHAR(10)
SET @sql= @sql+'BEGIN '+CHAR(10)
	SET @sql= @sql+'PRINT ''TABLE ALREADY EXIST'' '+CHAR(10)
SET @sql= @sql+'END '+CHAR(10)

exec sp_executesql @sql, N'@schemaname VARCHAR(50),@tablename varchar(100)', @schemaname,@tablename