

GO
GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO


exec #AssertTableTypeExists 'maint', 'RestoreDatabaseMappings'

go

