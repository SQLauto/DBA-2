
GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

SELECT 'B999_R0001_Permissions'
GO


IF NOT EXISTS (select * from sys.server_principals where [name] = N'$(PaymentAssuranceServiceAccount)' and ([type] = 'U'))
BEGIN
	CREATE LOGIN [$(PaymentAssuranceServiceAccount)] FROM WINDOWS WITH DEFAULT_DATABASE = [$(DatabaseName)]
END

USE $(DatabaseName)

IF NOT EXISTS (select * from sys.database_principals where ([name] = N'$(PaymentAssuranceServiceAccount)') and ([type] = 'U'))
BEGIN
	CREATE USER [$(PaymentAssuranceServiceAccount)] FOR LOGIN [$(PaymentAssuranceServiceAccount)]
END

EXEC sp_addrolemember N'db_owner', N'$(PaymentAssuranceServiceAccount)';


EXEC [deployment].[SetScriptAsRun] 'B999_R0001_Permissions'
GO
