
GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

declare @columnExists bit 
declare @tableExists bit = 1
declare @newTableExists bit
declare @primaryKeyName varchar(128)
exec #TableExists 'dbo', 'DatabaseFiles',  @tableExists out
if (@tableExists = 0)
BEGIN

	DROP TABLE [dbo].[DatabaseFiles]

END 

exec #TableExists 'capture', 'DatabaseFiles',  @newTableExists out

if (@newTableExists = 0)
BEGIN
	CREATE TABLE [capture].[DatabaseFiles] 
(
	[ID] [int] NOT NULL IDENTITY(1, 1),
	[ServerName] [varchar](500) NULL,
	[DatabaseName] [varchar](500) NULL,
	[LogicalFileName] [varchar](500) NULL,
	[Database_ID] [int] NULL,
	[File_ID] [int] NULL,
	[PhysicalName] [varchar] (1000) NULL,
	[fileType] [smallint] NULL,
	[file_guid] [uniqueidentifier] NULL,
	[createdDate] [datetime] NULL CONSTRAINT [DF__DatabaseF__creat__07E124C1] DEFAULT (getdate()),
	[endDate] [datetime] NULL

) ON [PRIMARY]
END









GO