GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

declare @validationMessage varchar(max)
declare @tableExists bit = 0
if exists(select 1 from [internal].[MountpointConfig] where Path='D:\Partitions')
begin
	insert into deployment.PatchingPostValidationError (ValidationMessage, IsValid) values ('Is Valid', 1)	
end
else
begin
	insert into deployment.PatchingPostValidationError (ValidationMessage, IsValid) values ('Expected entries in [internal].[MountpointConfig]', 0)
end
