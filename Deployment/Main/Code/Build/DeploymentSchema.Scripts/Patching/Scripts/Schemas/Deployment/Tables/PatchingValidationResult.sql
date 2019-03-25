go
if not exists (select 1 from sys.tables t inner join sys.schemas sc on t.schema_id = sc.schema_id 
			where t.name = 'PatchingValidationResult' and sc.name = 'deployment')
begin
	create table deployment.PatchingValidationResult
	(
		IsValid bit default(0) not null,
		CreatedAt datetimeoffset default(sysdatetimeoffset())
	)

end	
GO