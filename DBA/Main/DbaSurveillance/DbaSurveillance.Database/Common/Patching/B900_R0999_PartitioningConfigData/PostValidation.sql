GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

declare @validationMessage varchar(max)
declare @tableExists bit = 0
declare @expectedRows int = 8
if exists(select 1 from [admin].[PartitionConfig] where name='WhoIsActive') 
begin
	insert into deployment.PatchingPostValidationError (ValidationMessage, IsValid) values ('Is Valid', 1)	
end
else
begin
	insert into deployment.PatchingPostValidationError (ValidationMessage, IsValid) values ('Expected entries in admin.partitionconfig', 0)
end
if (SELECT COUNT(Name) FROM admin.PartitionConfig) = @expectedRows
begin
	insert into deployment.PatchingPostValidationError (ValidationMessage, IsValid) values ('Is Valid', 1)	
end
else
begin
	insert into deployment.PatchingPostValidationError (ValidationMessage, IsValid) values ('Expected '+CAST(@expectedRows AS VARCHAR)+' records in admin.partitionconfig', 0)
end