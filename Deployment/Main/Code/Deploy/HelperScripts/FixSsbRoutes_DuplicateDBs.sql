USE PARE;
GO

DECLARE @BrokerInstance sysname;
DECLARE @sql nvarchar(max);

SELECT 
	@BrokerInstance = service_broker_guid 
FROM sys.databases 
WHERE name = 'PCS';

DECLARE RouteCursor CURSOR 
	FORWARD_ONLY
	FOR SELECT 'ALTER ROUTE [' + name + '] WITH BROKER_INSTANCE = ''' + @BrokerInstance + ''';' FROM sys.routes WHERE name like 'http://tfl.gov.uk/%';

OPEN RouteCursor

FETCH NEXT FROM RouteCursor INTO @sql

WHILE @@FETCH_STATUS = 0
BEGIN
	PRINT @sql;
	EXEC sp_executesql @sql;
	FETCH NEXT FROM RouteCursor INTO @sql
END

GO


USE PCS;
GO

DECLARE @BrokerInstance sysname;
DECLARE @sql nvarchar(max);

SELECT 
	@BrokerInstance = service_broker_guid 
FROM sys.databases 
WHERE name = 'PARE';

DECLARE RouteCursor CURSOR 
	FORWARD_ONLY
	FOR SELECT 'ALTER ROUTE [' + name + '] WITH BROKER_INSTANCE = ''' + @BrokerInstance + ''';' FROM sys.routes WHERE name like 'http://tfl.gov.uk/%';

OPEN RouteCursor

FETCH NEXT FROM RouteCursor INTO @sql

WHILE @@FETCH_STATUS = 0
BEGIN
	PRINT @sql;
	EXEC sp_executesql @sql;
	FETCH NEXT FROM RouteCursor INTO @sql
END

GO