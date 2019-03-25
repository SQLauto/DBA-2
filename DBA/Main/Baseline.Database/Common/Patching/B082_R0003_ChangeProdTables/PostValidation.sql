
GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

declare @tableExists bit 
exec #TableExists 'dbo', 'FileInfo',  @tableExists out
if (@tableExists = 1)
BEGIN
	insert into deployment.PatchingPostValidationError (ValidationMessage, IsValid) values ('dbo.FileInfo should not exist', 0);
END
ELSE
BEGIN
	insert into deployment.PatchingPostValidationError (ValidationMessage, IsValid) values ('dbo.FileInfo correctly dropped', 1);
END


go

