declare @sql varchar(max) = 'create database ' + $(databasename)
exec(@sql)
