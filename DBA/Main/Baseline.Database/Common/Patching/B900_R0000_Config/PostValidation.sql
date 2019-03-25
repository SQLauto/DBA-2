go
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
go
declare @count int = 0

select @count=count(*) from  capture.Config 
if @count = 13
begin
	insert into deployment.PatchingPostValidationError(IsValid, ValidationMessage) Values(1, 'This is valid')
end
else
begin
	insert into deployment.PatchingPostValidationError(IsValid, ValidationMessage) Values(0, 'Config has an incorrect row count ')
end