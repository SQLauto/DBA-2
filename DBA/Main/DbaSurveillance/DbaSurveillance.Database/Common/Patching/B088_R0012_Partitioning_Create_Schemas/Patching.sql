
GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

SELECT 'B072_R0012_Partitioning_Create_Schemas'
GO

DECLARE @exists BIT = 0



PRINT 'Creating schema: admin'
SET @exists = 1
EXEC #SchemaExists 'admin', @exists OUT
IF (@exists = 0)
BEGIN
	EXEC('CREATE SCHEMA [admin]')
END


PRINT 'Creating schema: internal'
SET @exists = 1
EXEC #SchemaExists 'internal', @exists OUT
IF (@exists = 0)
BEGIN
	EXEC('CREATE SCHEMA [internal]')
END


PRINT 'Creating schema: archive'
SET @exists = 1
EXEC #SchemaExists 'archive', @exists OUT
IF (@exists = 0)
BEGIN
	EXEC('CREATE SCHEMA [archive]')
END



EXEC [deployment].[SetScriptAsRun] 'B072_R0012_Partitioning_Create_Schemas'
GO
