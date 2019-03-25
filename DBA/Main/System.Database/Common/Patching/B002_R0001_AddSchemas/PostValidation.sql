
GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

exec #AssertSchemaExists 'maint';
exec #AssertSchemaExists 'support';

go



