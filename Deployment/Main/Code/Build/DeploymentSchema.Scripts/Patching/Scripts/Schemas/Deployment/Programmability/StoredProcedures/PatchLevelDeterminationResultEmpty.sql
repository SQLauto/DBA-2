if not exists (select 1 from sys.procedures p inner join sys.schemas sc on p.schema_id = sc.schema_id
				where sc.name = 'deployment'and p.name = 'PatchLevelDeterminationResultEmpty')
begin
	exec ('create proc  deployment.PatchLevelDeterminationResultEmpty as begin select 1 end;')
end
go
alter procedure deployment.PatchLevelDeterminationResultEmpty
as
begin
	delete from deployment.PatchingLevelDeterminationResult
end

go