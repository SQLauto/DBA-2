if not exists (select 1 from sys.procedures p inner join sys.schemas sc on p.schema_id = sc.schema_id
				where sc.name = 'deployment'and p.name = 'PatchingValidationEmpty')
begin
	exec ('create proc  deployment.PatchingValidationEmpty as begin select 1 end;')
end
go
alter procedure deployment.PatchingValidationEmpty
as
begin
	delete from deployment.PatchingPreValidationError
	DBCC CHECKIDENT ('deployment.PatchingPreValidationError', reseed, 0)
	
	delete from deployment.PatchingPostValidationError
	DBCC CHECKIDENT ('deployment.PatchingPostValidationError', reseed, 0)
end

go
