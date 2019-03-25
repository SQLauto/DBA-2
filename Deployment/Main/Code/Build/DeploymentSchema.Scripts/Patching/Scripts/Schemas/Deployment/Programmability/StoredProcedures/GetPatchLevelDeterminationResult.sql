if not exists (select 1 from sys.procedures p inner join sys.schemas sc on p.schema_id = sc.schema_id
				where sc.name = 'deployment'and p.name = 'GetPatchingLevelDeterminationResult')
begin
	exec ('create proc  deployment.GetPatchingLevelDeterminationResult as begin select 1 end;')
end
go
alter procedure deployment.GetPatchingLevelDeterminationResult
	@isValid bit output,
	@errorMessage varchar(max) output,
	@isAtPatchLevelWhichWasTested bit output
as
begin

	set @isValid = 1
	set @isAtPatchLevelWhichWasTested = 0
	declare @count int = (select count(*) from deployment.PatchingLevelDeterminationResult)
	set @errorMessage = ''
	
	if (@count != 1)
	begin
		set @isValid = 0
		set @errorMessage = 'The count of records in deployment.PatchingLevelDeterminationResult must be One and it was: ' + cast(@count as varchar(10))
	end
	else
	begin
		set @isAtPatchLevelWhichWasTested = (select IsAtPatchLevelWhichWasTested from deployment.PatchingLevelDeterminationResult)
	end
	
end
go