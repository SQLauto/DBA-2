SET QUOTED_IDENTIFIER ON;
GO
:error $(errorLogPath)\ErrorPatching.txt

--Print 'Deploy deployment helpers schema'
GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO


declare @tableExists bit = 0
exec #TableExists 'dbo', '$(TableName)', @tableExists out
if (@tableExists = 0)
begin
	create table dbo.TableOne
	(
		Id SMALLINT PRIMARY KEY,
		Name varchar(30) NOT NULL,
		Description varchar(50) NULL
	)
end

go