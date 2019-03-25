
GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

select 'Partitioning_SQLAgentJob'
go
:r $(scriptPath)\..\Schema\Job\Partitioning_SQLAgentJob.sql

go


