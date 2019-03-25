
GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

declare @tableExists bit = 0
exec #tableExists 'dbo', 'AlertHistory',  @tableExists out


insert into deployment.PatchingLevelDeterminationResult (IsAtPatchLevelWhichWasTested) values(@tableExists)




