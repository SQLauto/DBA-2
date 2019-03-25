go
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
go




declare @table1Exists bit = 0
declare @table2Exists bit = 0

exec #TableExists 'capture', 'QueryExecutionWindow', @table1Exists out
exec #TableExists 'capture', 'QueryExecutionStats', @table2Exists out

IF (@table1Exists = 1 and @table2Exists = 1)
BEGIN 
	insert into deployment.PatchingPostValidationError(IsValid, ValidationMessage) Values(1, 'Tables QueryExecutionWindow and QueryExecutionStats have been created sucessfully.')
END
ELSE
BEGIN
	insert into deployment.PatchingPostValidationError(IsValid, ValidationMessage) Values(0, 'Tables QueryExecutionWindow were not created and should have been.')
END





