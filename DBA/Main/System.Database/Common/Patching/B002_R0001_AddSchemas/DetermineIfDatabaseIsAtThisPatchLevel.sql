
GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

declare @schemaExists bit = 0
exec #SchemaExists 'maint', @schemaExists out


insert into deployment.PatchingLevelDeterminationResult (IsAtPatchLevelWhichWasTested) values(@schemaExists)




