EXEC #CreateDummyStoredProcedureIfNotExists 'perf', 'PareDatabaseRestoreConfigurationPostRestore'
GO

ALTER PROCEDURE [perf].[PareDatabaseRestoreConfigurationPostRestore]
	@performNightlyRestore bit,
	@upgradeDatabase bit
as
begin
	
	begin transaction 

		begin try
		declare @databaseOfInterest varchar(128) = 'Pare'

		declare @buildShouldUpgradeDatabase bit
		declare @isPerformNightlyRestoreEnabled bit
		declare @lastUpdatedBy varchar(512)
		declare @lastUpdatedAt datetimeoffset


		select
			@buildShouldUpgradeDatabase = drc.BuildShouldUpgradeDatabase,
			@isPerformNightlyRestoreEnabled = drc.IsPerformNightlyRestoreEnabled,
			@lastUpdatedAt = drc.LastUpdatedAt,
			@lastUpdatedBy = drc.LastUpdatedBy
		from
			perf.DatabaseRestoreConfiguration drc
		where
			DatabaseName = @databaseOfInterest

		declare @now datetimeoffset = sysdatetimeoffset()
		declare @user nvarchar(255) = suser_sname()

		insert into perf.DatabaseRestoreConfigurationHistory (DatabaseName, IsPerformNightlyRestoreEnabled, BuildShouldUpgradeDatabase,
					OriginalValueForIsPerformNightlyRestoreEnabled, OriginalValueForBuildShouldUpgradeDatabase,
					OriginalValueForLastUpdatedBy, OriginalValueForLastUpdatedAt, 
					UpdatedBy, UpdatedAt) 
		values
		(
			@databaseOfInterest, @performNightlyRestore, @upgradeDatabase, @isPerformNightlyRestoreEnabled, @buildShouldUpgradeDatabase,
			@lastUpdatedBy, @lastUpdatedAt, @user, @now
		)

		update perf.DatabaseRestoreConfiguration
		set
			IsPerformNightlyRestoreEnabled = @performNightlyRestore,
			BuildShouldUpgradeDatabase = @upgradeDatabase,
			LastUpdatedBy = @user,
			LastUpdatedAt = @now
		where
			DatabaseName = @databaseOfInterest

		commit transaction

		select
			drc.DatabaseName,
			drc.BuildShouldUpgradeDatabase,
			drc.IsPerformNightlyRestoreEnabled
		from
			perf.DatabaseRestoreConfiguration drc
		where
			DatabaseName = @databaseOfInterest
	end try
	begin catch
		rollback transaction
		throw
	end catch

end


GO
