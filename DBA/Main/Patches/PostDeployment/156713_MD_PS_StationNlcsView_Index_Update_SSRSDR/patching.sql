/*
Description
 This patch is will create non clustered index IX_RevisionId_CoverAll on table [dbo].[StationNlcsView].
 Note: This is a new index, so rollack is not required.	
*/

declare @ReadOnlyStatus  nvarchar(250); 

set  @ReadOnlyStatus = CONVERT(varchar(250),DATABASEPROPERTYEX('MasterData_ProjectionStore', 'Updateability'));

IF (@ReadOnlyStatus = 'READ_ONLY') 
begin
	USE [master]
	ALTER DATABASE [MasterData_ProjectionStore] SET SINGLE_USER WITH ROLLBACK IMMEDIATE 
	ALTER DATABASE [MasterData_ProjectionStore] SET  READ_WRITE WITH NO_WAIT
end

USE [MasterData_ProjectionStore]

IF EXISTS (SELECT * FROM sys.indexes WHERE object_id = OBJECT_ID(N'[dbo].[StationNlcsView]') AND name = N'IX_RevisionId_CoverAll')
begin
	DROP INDEX [IX_RevisionId_CoverAll] ON [dbo].[StationNlcsView]
end

CREATE NONCLUSTERED INDEX [IX_RevisionId_CoverAll] ON [dbo].[StationNlcsView]
(
	[RevisionId] ASC
)
INCLUDE ( 	[StationName],
	[PaidAreaName],
	[ServedBy],
	[NationalLocationCode],
	[IndexId],
	[Created],
	[Updated],
	[Id],
	[StationId],
	[DeviceType],
	[LastModifiedBy],
	[PaidAreaDisplayName],
	[isDesignatedPoint],
	[SelfServiceRefundDisabled],
	[ServiceDisruptionRefundDisabled]
	) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]


IF (@ReadOnlyStatus = 'READ_ONLY') 
begin
	USE [master]
	ALTER DATABASE [MasterData_ProjectionStore] SET MULTI_USER
	ALTER DATABASE [MasterData_ProjectionStore] SET  READ_ONLY WITH NO_WAIT
	
end

GO