GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO


insert into deployment.PatchingLevelDeterminationResult (IsAtPatchLevelWhichWasTested) values(0)

