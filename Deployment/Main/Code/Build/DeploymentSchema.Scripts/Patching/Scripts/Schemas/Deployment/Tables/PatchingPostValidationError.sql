go

if not exists (select 1 from sys.tables t inner join sys.schemas sc on t.schema_id = sc.schema_id 
			where t.name = 'PatchingPostValidationError' and sc.name = 'deployment')
begin
	create table deployment.PatchingPostValidationError
	(
		Id bigint identity(1,1) not null,
		ValidationMessage varchar(max) not null, 
		IsValid bit default(0) not null,
		CreatedAt datetimeoffset default(sysdatetimeoffset())
	)
	
end	
GO

