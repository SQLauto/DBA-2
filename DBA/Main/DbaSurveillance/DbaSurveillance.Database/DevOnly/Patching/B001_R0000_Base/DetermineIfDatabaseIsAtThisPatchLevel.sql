GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

--this base patching folder exists to provide a starting point for subsequent patches.
-- applied to Deptford branch but our starting point is essentially Camden...
insert into deployment.PatchingLevelDeterminationResult (IsAtPatchLevelWhichWasTested) values(1)