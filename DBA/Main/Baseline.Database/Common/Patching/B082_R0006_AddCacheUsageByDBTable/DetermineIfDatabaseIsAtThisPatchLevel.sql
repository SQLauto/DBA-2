
GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO


declare @tableExists bit = 0 
declare @primaryKeyName varchar(128)
exec #TableExists 'capture', 'CacheUsagebyDBData',  @tableExists out

insert into deployment.PatchingLevelDeterminationResult (IsAtPatchLevelWhichWasTested) values(@tableExists)



