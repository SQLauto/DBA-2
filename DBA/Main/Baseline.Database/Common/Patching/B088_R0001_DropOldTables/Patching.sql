GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

DECLARE @exists BIT = 0;



BEGIN TRY
		
	set @exists = 0     exec #tableExists 'dbo', 'BlockedProcessReport',  @exists out     if @exists = 1     DROP TABLE [dbo].[BlockedProcessReport]
	set @exists = 0     exec #tableExists 'dbo', 'CacheUsageData',  @exists out     if @exists = 1     DROP TABLE [dbo].[CacheUsageData]
	set @exists = 0     exec #tableExists 'dbo', 'CacheUsageResults',  @exists out     if @exists = 1     DROP TABLE [dbo].[CacheUsageResults]
	set @exists = 0     exec #tableExists 'dbo', 'CaptureConfig',  @exists out     if @exists = 1     DROP TABLE [dbo].[CaptureConfig]
	set @exists = 0     exec #tableExists 'dbo', 'CaptureConfigFreqSubDayType',  @exists out     if @exists = 1     DROP TABLE [dbo].[CaptureConfigFreqSubDayType]
	set @exists = 0     exec #tableExists 'dbo', 'CaptureConfigFreqType',  @exists out     if @exists = 1     DROP TABLE [dbo].[CaptureConfigFreqType]
	set @exists = 0     exec #tableExists 'dbo', 'CaptureCpuData',  @exists out     if @exists = 1     DROP TABLE [dbo].[CaptureCpuData]
	set @exists = 0     exec #tableExists 'dbo', 'CaptureCpuResults',  @exists out     if @exists = 1     DROP TABLE [dbo].[CaptureCpuResults]
	set @exists = 0     exec #tableExists 'dbo', 'CaptureProcData',  @exists out     if @exists = 1     DROP TABLE [dbo].[CaptureProcData]
	set @exists = 0     exec #tableExists 'dbo', 'CaptureProcResults',  @exists out     if @exists = 1     DROP TABLE [dbo].[CaptureProcResults]
	set @exists = 0     exec #tableExists 'dbo', 'ConfigData',  @exists out     if @exists = 1     DROP TABLE [dbo].[ConfigData]
	set @exists = 0     exec #tableExists 'dbo', 'CpuUtilisation',  @exists out     if @exists = 1     DROP TABLE [dbo].[CpuUtilisation]
	set @exists = 0     exec #tableExists 'dbo', 'CurrentPartitionState',  @exists out     if @exists = 1     DROP TABLE [dbo].[CurrentPartitionState]
	set @exists = 0     exec #tableExists 'dbo', 'currentrank',  @exists out     if @exists = 1     DROP TABLE [dbo].[currentrank]
	set @exists = 0     exec #tableExists 'dbo', 'DatabaseFiles',  @exists out     if @exists = 1     DROP TABLE [dbo].[DatabaseFiles]
	set @exists = 0     exec #tableExists 'dbo', 'DeploymentHistory',  @exists out     if @exists = 1     DROP TABLE [dbo].[DeploymentHistory]
	set @exists = 0     exec #tableExists 'dbo', 'MonitoredInstances',  @exists out     if @exists = 1     DROP TABLE [dbo].[MonitoredInstances]
	set @exists = 0     exec #tableExists 'dbo', 'OS_WAIT_STATS',  @exists out     if @exists = 1     DROP TABLE [dbo].[OS_WAIT_STATS]
	set @exists = 0     exec #tableExists 'dbo', 'PerfAlertThreshold',  @exists out     if @exists = 1     DROP TABLE [dbo].[PerfAlertThreshold]
	set @exists = 0     exec #tableExists 'dbo', 'PerfAlertThresholdType',  @exists out     if @exists = 1     DROP TABLE [dbo].[PerfAlertThresholdType]
	set @exists = 0     exec #tableExists 'dbo', 'PerfData',  @exists out     if @exists = 1     DROP TABLE [dbo].[PerfData]
	set @exists = 0     exec #tableExists 'dbo', 'PerfmonAlertThresholds',  @exists out     if @exists = 1     DROP TABLE [dbo].[PerfmonAlertThresholds]
	set @exists = 0     exec #tableExists 'dbo', 'PerfmonAlertThresholds_bkup',  @exists out     if @exists = 1     DROP TABLE [dbo].[PerfmonAlertThresholds_bkup]
	set @exists = 0     exec #tableExists 'dbo', 'PerfmonCounterData',  @exists out     if @exists = 1     DROP TABLE [dbo].[PerfmonCounterData]
	set @exists = 0     exec #tableExists 'dbo', 'PerformAlertThreasholds',  @exists out     if @exists = 1     DROP TABLE [dbo].[PerformAlertThreasholds]
	set @exists = 0     exec #tableExists 'dbo', 'PerformAlertThreasholdsTab',  @exists out     if @exists = 1     DROP TABLE [dbo].[PerformAlertThreasholdsTab]
	set @exists = 0     exec #tableExists 'dbo', 'PerfServer',  @exists out     if @exists = 1     DROP TABLE [dbo].[PerfServer]
	set @exists = 0     exec #tableExists 'dbo', 'ProcPerfCacheCollection',  @exists out     if @exists = 1     DROP TABLE [dbo].[ProcPerfCacheCollection]
	set @exists = 0     exec #tableExists 'dbo', 'ServerConfig',  @exists out     if @exists = 1     DROP TABLE [dbo].[ServerConfig]
	set @exists = 0     exec #tableExists 'dbo', 'table_size',  @exists out     if @exists = 1     DROP TABLE [dbo].[table_size]
	set @exists = 0     exec #tableExists 'dbo', 'CaptureResults',  @exists out     if @exists = 1     DROP TABLE [dbo].[CaptureResults]
	set @exists = 0     exec #tableExists 'dbo', 'CaptureData',  @exists out     if @exists = 1     DROP TABLE [dbo].[CaptureData]
	set @exists = 0     exec #tableExists 'dbo', 'WaitStats',  @exists out     if @exists = 1     DROP TABLE [dbo].[WaitStats]
	set @exists = 0     exec #tableExists 'dbo', 'PerfCounter',  @exists out     if @exists = 1     DROP TABLE [dbo].[PerfCounter]

END TRY
BEGIN CATCH
	THROW;
END CATCH
	


EXEC [deployment].[SetScriptAsRun] 'B088_R0001_DropOldTables'
GO
