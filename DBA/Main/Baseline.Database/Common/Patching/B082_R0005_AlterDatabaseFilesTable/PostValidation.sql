
GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

exec #AssertTableExists 'capture', 'DatabaseFiles'

