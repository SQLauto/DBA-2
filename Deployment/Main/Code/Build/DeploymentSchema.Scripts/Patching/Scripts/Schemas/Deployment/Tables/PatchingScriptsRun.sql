go
if not exists (select 1 from sys.tables t inner join sys.schemas sc on t.schema_id = sc.schema_id 
			where t.name = 'PatchingScriptsRun' and sc.name = 'deployment')
begin

	create table [deployment].[PatchingScriptsRun]
	(
		[Id] INT identity(1,1) NOT NULL PRIMARY KEY, 
		[Name] NVARCHAR(256) NULL, 
		[DateTimeRun] DATETIME NULL, 
		[RanBy] NVARCHAR(100) NULL
	)

	create table [deployment].[zzzPatchingScriptsRun]
	(
		[Id] INT identity(1,1) NOT NULL PRIMARY KEY, 
		[Name] NVARCHAR(256) NULL, 
		[DateTimeRun] DATETIME NULL, 
		[RanBy] NVARCHAR(100) NULL
	)
end
go

