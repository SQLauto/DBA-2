
GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

select 'RedeployCodeArtifacts'
go
--Run script
:r $(scriptPath)\B999_R0000_RedeployCodeArtifacts\RedeployCodeArtifacts.sql
-- need this space here - sql cmd mystery
EXEC [deployment].[SetScriptAsRun] 'RedeployCodeArtifacts'

GO


