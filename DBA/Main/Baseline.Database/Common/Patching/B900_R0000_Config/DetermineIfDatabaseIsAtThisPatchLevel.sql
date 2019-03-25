
GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

--never at this level as we always want the redeploy artefacts to run
insert into deployment.PatchingLevelDeterminationResult (IsAtPatchLevelWhichWasTested) values(0)

