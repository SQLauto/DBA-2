go
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
go

IF NOT EXISTS (SELECT 1 FROM sys.foreign_keys WHERE object_id = OBJECT_ID(N'[dbo].[fk_PerfData_PerfServerId]') AND parent_object_id = OBJECT_ID(N'[dbo].[PerfData]'))
BEGIN
	insert into deployment.PatchingPostValidationError (ValidationMessage, IsValid) values ('fk_PerfData_PerfServerId should exists on [dbo].PerfData', 0);
end
else
begin
	INSERT INTO deployment.PatchingPostValidationError (ValidationMessage, IsValid) VALUES ('Is valid', 1);
end

go