
GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

exec #AssertTableExists 'assurance', 'execution';
exec #AssertTableExists 'assurance', 'reports';
exec #AssertTableExists 'assurance', 'results';