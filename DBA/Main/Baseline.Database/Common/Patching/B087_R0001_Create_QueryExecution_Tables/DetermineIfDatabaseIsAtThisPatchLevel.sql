
--Print 'Deploy deployment helpers schema'
GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

declare @table1Exists bit = 0
declare @table2Exists bit = 0

exec #TableExists 'capture', 'QueryExecutionWindow', @table1Exists out
exec #TableExists 'capture', 'QueryExecutionStats', @table2Exists out

IF (@table1Exists = 1 and @table2Exists = 1)
BEGIN 
	insert into deployment.PatchingLevelDeterminationResult (IsAtPatchLevelWhichWasTested) values(1)
END
ELSE
BEGIN
	insert into deployment.PatchingLevelDeterminationResult (IsAtPatchLevelWhichWasTested) values(0)
END



