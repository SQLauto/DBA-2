
GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO


declare @schemaExists bit 
exec #SchemaExists 'capture', @schemaExists out

if (@schemaExists = 0)
begin
	EXEC('CREATE SCHEMA [capture]')
end

declare @tableExists bit 
exec #TableExists 'capture', 'SQLServerLogsData', @tableExists out

if (@tableExists = 0)
begin	
	CREATE TABLE [capture].[SQLServerLogsData]
	(
		[id] [int] IDENTITY(1,1) NOT NULL,
		[inserted_at] [datetime] NOT NULL DEFAULT (getdate()),
		[servername] [varchar](256) NOT NULL,
		[message] [varchar](4000) NULL,
		[ProcessInfo] [varchar](100) NULL,
		[capturedate] [datetime] NULL
	) 
end

exec #TableExists 'capture', 'SQLServerLogsWindow', @tableExists out

if (@tableExists = 0)
begin	
	CREATE TABLE [capture].[SQLServerLogsWindow]
	(
		[id] [int] IDENTITY(1,1) NOT NULL,
		[eventname] [varchar](50) NOT NULL,
		[currenttable] [varchar](100) NOT NULL,
		[datetimecovered] [datetime] NOT NULL
	) 
end

