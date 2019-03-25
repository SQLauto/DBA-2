
--Print 'Deploy deployment helpers schema'
GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

declare @tableExists bit = 0
exec #TableExists 'capture', 'DiskUsageData', @tableExists out

insert into deployment.PatchingLevelDeterminationResult (IsAtPatchLevelWhichWasTested) values(@tableExists)

