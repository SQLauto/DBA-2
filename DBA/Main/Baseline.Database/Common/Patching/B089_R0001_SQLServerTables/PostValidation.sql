GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

DECLARE @exists BIT = 1;

EXEC #TableExists 'capture','SQLServerLogsData', @exists out;
INSERT INTO deployment.PatchingPostValidationError (ValidationMessage, IsValid) VALUES ('capture.SQLServerLogsData should exist', @exists);



GO
