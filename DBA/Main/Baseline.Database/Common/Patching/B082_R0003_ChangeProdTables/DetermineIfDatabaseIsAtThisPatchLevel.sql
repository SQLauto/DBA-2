
GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

declare @isAtLevel bit = 0
declare @tableExists bit = 0
exec #TableExists 'dbo', 'FileInfo',  @tableExists out
 
if (@tableExists = 0)
BEGIN
	SET @isAtLevel = 0
END 
 
insert into deployment.PatchingLevelDeterminationResult (IsAtPatchLevelWhichWasTested) values(@isAtLevel)




