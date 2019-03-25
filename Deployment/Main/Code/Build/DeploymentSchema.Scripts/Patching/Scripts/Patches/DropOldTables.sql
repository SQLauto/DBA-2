if exists (select 1 from sys.tables t inner join sys.schemas sc on t.schema_id = sc.schema_id 
			where t.name = 'PatchingValidationResult' and sc.name = 'deployment')
begin
	exec('drop table deployment.PatchingValidationResult');
	
end	
GO

if exists (select 1 from sys.tables t inner join sys.schemas sc on t.schema_id = sc.schema_id 
			where t.name = 'PatchingValidationError' and sc.name = 'deployment')
begin
	exec('drop table deployment.PatchingValidationError');
	
end	
GO
