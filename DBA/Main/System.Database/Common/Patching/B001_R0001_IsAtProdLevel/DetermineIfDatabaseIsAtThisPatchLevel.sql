GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

declare @isValid bit = 0;
exec #TableExists 'dbo', 'CommandLog', @isValid out;


insert into deployment.PatchingLevelDeterminationResult (IsAtPatchLevelWhichWasTested) values(@isValid);
