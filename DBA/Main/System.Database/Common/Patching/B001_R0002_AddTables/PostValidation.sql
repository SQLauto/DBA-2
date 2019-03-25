
GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

declare @validationMessage varchar(max)
declare @exists bit
declare @isValid bit

exec #TableExists 'dbo', 'UptimeHistory', @exists out
set @validationMessage = 'dbo.UptimeHistory is expected to exist and it does not.'
insert into deployment.PatchingPostValidationError(ValidationMessage, IsValid) values (@validationMessage, @exists)
