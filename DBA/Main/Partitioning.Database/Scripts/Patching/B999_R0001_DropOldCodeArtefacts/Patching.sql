
GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO
-- Drop Old Procedures
DECLARE @procedureExists BIT;
EXEC #StoredProcedureExists @schemaName = 'internal', @procedureName = 'CreateMultiFileFilegroup', @procedureExists = @procedureExists OUTPUT; 
IF @procedureExists = 1
	DROP PROCEDURE internal.CreateMultiFileFilegroup;

EXEC #StoredProcedureExists @schemaName = 'internal', @procedureName = 'CreateFilegroup', @procedureExists = @procedureExists OUTPUT; 
IF @procedureExists = 1
	DROP PROCEDURE internal.CreateFilegroup

EXEC #StoredProcedureExists @schemaName = 'internal', @procedureName = 'AddPartitions', @procedureExists = @procedureExists OUTPUT; 
IF @procedureExists = 1
	DROP PROCEDURE internal.AddPartitions

EXEC #StoredProcedureExists @schemaName = 'admin', @procedureName = 'MaintenanceTableArchiving', @procedureExists = @procedureExists OUTPUT; 
IF @procedureExists = 1
	DROP PROCEDURE admin.MaintenanceTableArchiving

EXEC #StoredProcedureExists @schemaName = 'admin', @procedureName = 'MaintenanceTableCreate', @procedureExists = @procedureExists OUTPUT; 
IF @procedureExists = 1
	DROP PROCEDURE admin.MaintenanceTableCreate

EXEC #StoredProcedureExists @schemaName = 'admin', @procedureName = 'MaintenanceSetArchiveFileGRoupsReadOnly', @procedureExists = @procedureExists OUTPUT; 
IF @procedureExists = 1
	DROP PROCEDURE admin.MaintenanceSetArchiveFileGRoupsReadOnly
	
EXEC #StoredProcedureExists @schemaName = 'admin', @procedureName = 'MaintenanceRemoveOldFiles', @procedureExists = @procedureExists OUTPUT; 
IF @procedureExists = 1
	DROP PROCEDURE admin.MaintenanceRemoveOldFiles

GO






