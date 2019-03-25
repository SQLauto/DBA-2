
GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

declare @tableExists bit = 0
exec #tableExists 'dim', 'Instances',  @tableExists out
if (@tableExists = 0)
begin
	insert into deployment.PatchingLevelDeterminationResult (IsAtPatchLevelWhichWasTested) values(@tableExists)
end






