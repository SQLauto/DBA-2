go
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
go

declare @tableExists bit = 0
exec #TableExists 'capture', 'DiskUsageData', @tableExists out

insert into deployment.PatchingPostValidationError(IsValid, ValidationMessage) Values(@tableExists, 'Table [capture].[DiskUsageData] was not created and should have been.')