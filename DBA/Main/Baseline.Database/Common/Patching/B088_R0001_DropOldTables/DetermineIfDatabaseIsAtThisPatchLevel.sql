GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

declare @tableExists bit = 0
exec #tableExists 'dbo', 'WaitStats',  @tableExists out
if (@tableExists = 0)
begin
	insert into deployment.PatchingLevelDeterminationResult (IsAtPatchLevelWhichWasTested) values(0)
end
else
begin
	insert into deployment.PatchingLevelDeterminationResult (IsAtPatchLevelWhichWasTested) values(0)
end
GO
