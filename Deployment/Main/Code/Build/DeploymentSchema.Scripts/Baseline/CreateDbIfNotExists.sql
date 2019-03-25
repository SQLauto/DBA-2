
go
use master;

go

declare @dbname varchar(128) = '$(databasename)';


if not exists (select 1 from sys.databases where name = @dbname)
begin
	declare @sql varchar(max) = 'create database '  + @dbname;
	exec(@sql);
end

go
