
GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

declare @tableExists bit = 0
exec #TableExists 'dbo', 'PerfMonData', @tableExists out
if (@tableExists = 1)
begin
	drop table dbo.PerfMonData
end
go


	

declare @tableExists bit = 0
exec #TableExists 'dbo', 'FileInfo', @tableExists out
if (@tableExists = 1)
begin	
	drop table dbo.FileInfo
end

go


go
