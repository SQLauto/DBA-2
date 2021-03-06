EXEC #CreateDummyStoredProcedureIfNotExists 'capture', 'DiskUsage'
GO
ALTER procedure [capture].[DiskUsage]
AS
BEGIN 
SET XACT_ABORT, NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
INSERT INTO [capture].[DiskUsageData]( [Volume], [SizeInGb], [FreeInGb], [FreePercentage], [CaptureDate])
SELECT distinct(volume_mount_point) [Volume], 
  total_bytes/1048576/1024.0 as [SizeInGb], 
  available_bytes/1048576/1024.0 as [FreeInGb],
  (select ((available_bytes/1048576* 1.0)/(total_bytes/1048576* 1.0) *100)) as [FreePercentage],
  GETDATE() [CaptureDate]
FROM sys.master_files AS f CROSS APPLY 
  sys.dm_os_volume_stats(f.database_id, f.file_id)
group by volume_mount_point, total_bytes/1048576, 
  available_bytes/1048576 order by 1
END
GO