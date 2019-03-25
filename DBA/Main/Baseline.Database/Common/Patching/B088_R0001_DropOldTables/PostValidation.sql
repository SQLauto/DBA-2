GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

DECLARE @exists BIT = 1;

EXEC #TableExists 'dbo','WaitStats', @exists out;
INSERT INTO deployment.PatchingPostValidationError (ValidationMessage, IsValid) VALUES ('dbo.WaitStats should not exist', 1 - @exists);



GO
