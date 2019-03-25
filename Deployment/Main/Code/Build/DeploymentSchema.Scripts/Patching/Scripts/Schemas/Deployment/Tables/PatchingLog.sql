go
if not exists (select 1 from sys.tables t inner join sys.schemas sc on t.schema_id = sc.schema_id 
			where t.name = 'log' and sc.name = 'patching')
begin

	create table [patching].[log]
	(
		[Id] INT identity(1,1) NOT NULL PRIMARY KEY, 
		[TflDefectOrCubicInc] varchar(20) NOT NULL, 
		[ScriptName] varchar(50) NOT NULL, 
		[ScriptVersion] varchar(5) NOT NULL,
		[DateTimeStart] DATETIME NOT NULL, 
		[DateTimeEnd] DATETIME NULL, 
		[RanBy] VARCHAR(50) NULL,
		[Result] bit NULL,
		[Message] varchar(8000) NULL
	)


end
go

