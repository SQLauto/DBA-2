GO

declare @isValid bit = 0

if not exists (select 1 from sys.tables t inner join sys.schemas sc on t.schema_id = sc.schema_id where sc.name = 'dbo')
begin
	set @isValid = 1	
end	

insert into deployment.PatchingLevelDeterminationResult (IsAtPatchLevelWhichWasTested) values(1)