GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

DECLARE @procedureExists BIT;
EXEC #StoredProcedureExists @schemaName = 'admin', @procedureName = 'MaintenanceTableCreate', @procedureExists = @procedureExists OUTPUT; 
DECLARE @doesNotExist BIT;
IF @procedureExists = 1
BEGIN
	SET @doesNotExist = 0
END
ELSE
BEGIN
	SET @doesNotExist = 1
END

INSERT INTO deployment.PatchingPostValidationError (ValidationMessage, IsValid) VALUES ('Procedure ''admin.MaintenanceTableCreate'' does exist and should have been dropped', @doesNotExist);

GO
