GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

exec #AssertTableExists 'dbo', 'CommandLog';

go