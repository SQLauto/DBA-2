
GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

declare @pkExists bit = 0
declare @primaryKeyName varchar(128)
exec #GetPrimaryKeyName 'capture', 'WaitStats', @primaryKeyName out
if (@primaryKeyName is not null)
begin
	set @pkExists = 1
end


insert into deployment.PatchingLevelDeterminationResult (IsAtPatchLevelWhichWasTested) values(@pkExists)




