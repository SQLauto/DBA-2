
GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO


declare @schemaExists bit 
exec #SchemaExists 'assurance', @schemaExists out

if (@schemaExists = 0)
begin
	EXEC('CREATE SCHEMA [assurance]')
end

declare @tableExists bit 

exec #TableExists 'assurance', 'execution', @tableExists out

if (@tableExists = 0)
begin	
	CREATE TABLE [assurance].[execution] 
	( 
		[id] [int] IDENTITY(1,1) PRIMARY KEY CLUSTERED NOT NULL,
		[started] [datetime] NOT NULL DEFAULT (getdate()), 
		[finished] [datetime] NULL, 
		[iserror] [bit] default 0 
	)

end

exec #TableExists 'assurance', 'reports', @tableExists out

if (@tableExists = 0)
begin	
	CREATE TABLE [assurance].[reports]
	( 
		[id] [int] IDENTITY(1,1) PRIMARY KEY CLUSTERED NOT NULL, 
		[filename] [varchar](100) NOT NULL, 
		[query] [varchar](max) NULL, 
		[created] [datetime] NOt NULL DEFAULT (getdate()), 
		[isenabled] [bit] NOt NULL DEFAULT 1 
	)
end

exec #TableExists 'assurance', 'results', @tableExists out

if (@tableExists = 0)
begin	
	CREATE TABLE [assurance].[results] 
	( 
		[report_id] [int] NOT NULL, 
		[execution_id] [int] NOT NULL, 
		[iserror] [bit] default 0, 
		[errormessage] [varchar](1000), 
		[created] [datetime] NOT NULL,
		CONSTRAINT FK_reportid FOREIGN KEY (report_id) REFERENCES [assurance].[reports](id),
		CONSTRAINT FK_executionid FOREIGN KEY (execution_id) REFERENCES [assurance].[execution](id),
		CONSTRAINT PK_results PRIMARY KEY ([report_id],[execution_id])		
	)
end