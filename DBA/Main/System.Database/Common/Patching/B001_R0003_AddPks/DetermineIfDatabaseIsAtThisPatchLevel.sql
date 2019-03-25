
GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

declare @primaryKeyExists varchar(128)
declare @pkExists bit = 0
exec #GetPrimaryKeyName 'dbo', 'UptimeHistory', @primaryKeyExists out

if(@primaryKeyExists is not null)
begin
	set @pkExists = 1;
end

insert into deployment.PatchingLevelDeterminationResult (IsAtPatchLevelWhichWasTested) values(@pkExists)




