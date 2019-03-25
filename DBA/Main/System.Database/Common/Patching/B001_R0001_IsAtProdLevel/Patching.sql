


GO
/****** Object:  StoredProcedure [dbo].[CheckLinkedServer]    Script Date: 27/10/2015 09:31:00 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[CheckLinkedServer]
AS
--ONLY RUN FOR SERVER WHERE FAE IS LOCATED
IF EXISTS (SELECT * FROM SYS.DATABASES WHERE NAME LIKE 'FAE%' AND @@SERVERNAME LIKE '%FPDC%')
BEGIN
	
	PRINT 'Server has FAE DB'

	--DECLARE VARIABLES
	DECLARE @CurrentLinkedServer VARCHAR(200)
	DECLARE @NewLinkedServer	 VARCHAR(200)
	DECLARE @SQL				 NVARCHAR(2000)
  

	--GET LINKED SERVER LIST
	CREATE TABLE #LinkedServers (
	ID		SMALLINT IDENTITY (1,1) NOT NULL,
	SRV_NAME	VARCHAR(50),
	SRV_PROVIDERNAME	VARCHAR(50),
	SRV_PRODUCT			VARCHAR(50),
	SRV_DATASOURCE		VARCHAR(50),
	SRV_PROVIDERSTRING	VARCHAR(50),
	SRV_LOCATION		VARCHAR(50),
	SRV_CAT				VARCHAR(50),
	PRIMARY KEY (ID))

	--GET ACTIVE ALWAYS ON LIST
	CREATE TABLE #AlwaysOnList (
	ID				SMALLINT IDENTITY (1,1) NOT NULL,
	DBName			VARCHAR(50),
	AlwaysOnName	VARCHAR(50),
	RoleDesc		VARCHAR(50),
	ServerName		VARCHAR(50),
	PRIMARY KEY (ID))

	INSERT INTO #LinkedServers
	EXEC sp_linkedservers
	 
	 SELECT * from #LinkedServers
	 WHERE 
		SRV_NAME <> @@SERVERNAME 
		AND
		SRV_NAME NOT LIKE '%ALWAYS%'	

	SELECT TOP 1 @CurrentLinkedServer = SRV_NAME 
	FROM #LinkedServers 
	WHERE 
		SRV_NAME <> @@SERVERNAME 
		AND
		SRV_NAME NOT LIKE '%ALWAYS%'	


	SET @SQL = '
		  SELECT distinct databases.name, availability_groups.name,
				 dm_hadr_availability_replica_states.role_desc,
				  nodestate.replica_server_name
		  FROM [' + @CurrentLinkedServer + '].master.sys.databases databases
		  INNER JOIN [' + @CurrentLinkedServer + '].master.sys.availability_databases_cluster availability_databases_cluster 
		  ON databases.group_database_id = availability_databases_cluster.group_database_id
		  INNER JOIN [' + @CurrentLinkedServer + '].master.sys.availability_groups availability_groups 
		  ON availability_databases_cluster.group_id = availability_groups.group_id
		  INNER JOIN [' + @CurrentLinkedServer + '].master.sys.dm_hadr_availability_replica_states dm_hadr_availability_replica_states 
		  ON availability_groups.group_id = dm_hadr_availability_replica_states.group_id 
		--	AND databases.replica_id = dm_hadr_availability_replica_states.replica_id
		  INNER JOIN [' + @CurrentLinkedServer + '].master.sys.dm_hadr_availability_replica_cluster_states nodestate 
		  ON nodestate.group_id = availability_groups.group_id 
			--AND nodestate.replica_id = dm_hadr_availability_replica_states.replica_id
		  INNER JOIN [' + @CurrentLinkedServer + '].master.sys.dm_hadr_availability_replica_cluster_nodes nodes 
		  ON nodes.replica_server_name = nodestate.replica_server_name
		  --WHERE nodestate.replica_server_name not in (''' + @CurrentLinkedServer + ''')'

	INSERT INTO #AlwaysOnList
	EXEC (@SQL)



	IF EXISTS (SELECT * FROM #AlwaysOnList WHERE RoleDesc = 'PRIMARY' AND ServerName = @CurrentLinkedServer)
	BEGIN
		PRINT 'Linked server is pointing to ' + @CurrentLinkedServer + ' which is primary.'
	END
	ELSE
	BEGIN
	
		PRINT 'Linked server is pointing to ' + @CurrentLinkedServer + ' which is the secondary. Need to rebuild'
		SELECT TOP 1 @NewLinkedServer = ServerName FROM #AlwaysOnList WHERE ServerName <> @CurrentLinkedServer
															AND RoleDesc = 'SECONDARY'
		PRINT 'Swtiching server point to ' + @NewLinkedServer + ' which is the Primary.'


		BEGIN TRY
		BEGIN TRAN
		--BUILD NEW LINKED SERVER
		SET @SQL = 'EXEC master.dbo.sp_addlinkedserver @server = N''' + @NewLinkedServer + ''', @srvproduct=N''SQL Server'''
		PRINT (@SQL)

		SET @SQL = 'EXEC master.dbo.sp_addlinkedsrvlogin @rmtsrvname=N''' + @NewLinkedServer + ''',@useself=N''True'',@locallogin=NULL,@rmtuser=NULL,@rmtpassword=NULL'
		PRINT (@SQL)

		SET @SQL = 'EXEC master.dbo.sp_serveroption @server=N''' + @NewLinkedServer + ''', @optname=N''collation compatible'', @optvalue=N''false'''
		PRINT (@SQL)

		SET @SQL = 'EXEC master.dbo.sp_serveroption @server=N''' + @NewLinkedServer + ''', @optname=N''data access'', @optvalue=N''true'''
		PRINT (@SQL)

		SET @SQL = 'EXEC master.dbo.sp_serveroption @server=N''' + @NewLinkedServer + ''', @optname=N''dist'', @optvalue=N''false'''
		PRINT (@SQL)

		SET @SQL = 'EXEC master.dbo.sp_serveroption @server=N''' + @NewLinkedServer + ''', @optname=N''pub'', @optvalue=N''false'''
		PRINT (@SQL)

		SET @SQL = 'EXEC master.dbo.sp_serveroption @server=N''' + @NewLinkedServer + ''', @optname=N''rpc'', @optvalue=N''true'''
		PRINT (@SQL)

		SET @SQL = 'EXEC master.dbo.sp_serveroption @server=N''' + @NewLinkedServer + ''', @optname=N''rpc out'', @optvalue=N''true'''
		PRINT (@SQL)

		SET @SQL = 'EXEC master.dbo.sp_serveroption @server=N''' + @NewLinkedServer + ''', @optname=N''sub'', @optvalue=N''false'''
		PRINT (@SQL)

		SET @SQL = 'EXEC master.dbo.sp_serveroption @server=N''' + @NewLinkedServer + ''', @optname=N''connect timeout'', @optvalue=N''0'''
		PRINT (@SQL)

		SET @SQL = 'EXEC master.dbo.sp_serveroption @server=N''' + @NewLinkedServer + ''', @optname=N''collation name'', @optvalue=null'''
		PRINT (@SQL)

		SET @SQL = 'EXEC master.dbo.sp_serveroption @server=N''' + @NewLinkedServer + ''', @optname=N''lazy schema validation'', @optvalue=N''false'''
		PRINT (@SQL)

		SET @SQL = 'EXEC master.dbo.sp_serveroption @server=N''' + @NewLinkedServer + ''', @optname=N''query timeout'', @optvalue=N''0'''
		PRINT (@SQL)

		SET @SQL = 'EXEC master.dbo.sp_serveroption @server=N''' + @NewLinkedServer + ''', @optname=N''use remote collation'', @optvalue=N''true'''
		PRINT (@SQL)

		SET @SQL = 'EXEC master.dbo.sp_serveroption @server=N''' + @NewLinkedServer + ''', @optname=N''remote proc transaction promotion'', @optvalue=N''true'''
		PRINT (@SQL)

		SET @SQL= 'DROP SYNONYM [internal].[PareRatingStageSyntheticTap]'
		PRINT (@SQL)

		SET @SQL ='CREATE SYNONYM [internal].[PareRatingStageSyntheticTap] FOR [N''' + @NewLinkedServer + '''].[FAE_BDTuning].[pare].[RatingStageSyntheticTap]'
		PRINT (@SQL)

		SET @SQL= 'DROP SYNONYM [internal].[PareRatingStageTap0]'
		PRINT (@SQL)

		SET @SQL ='CREATE SYNONYM [internal].[PareRatingStageTap0] FOR [N''' + @NewLinkedServer + '''].[FAE_BDTuning].[pare].[RatingStageTap0]'
		PRINT (@SQL)

		SET @SQL= 'DROP SYNONYM [internal].[PareRatingStageTap1]'
		PRINT (@SQL)

		SET @SQL ='CREATE SYNONYM [internal].[PareRatingStageTap1] FOR [N''' + @NewLinkedServer + '''].[FAE_BDTuning].[pare].[RatingStageTap1]'
		PRINT (@SQL)
		COMMIT TRAN
		END TRY
		BEGIN CATCH

			ROLLBACK TRAN
			DECLARE @ErrorMessage NVARCHAR(4000);
			DECLARE @ErrorSeverity INT;
			DECLARE @ErrorState INT;

			SELECT 
				@ErrorMessage = ERROR_MESSAGE(),
				@ErrorSeverity = ERROR_SEVERITY(),
				@ErrorState = ERROR_STATE();

			RAISERROR (@ErrorMessage, -- Message text.
					   @ErrorSeverity, -- Severity.
					   @ErrorState -- State.
					   );

		END CATCH
	END

	--CLEAN UP
	DROP TABLE #LinkedServers
	DROP TABLE #AlwaysOnList

END
ELSE
BEGIN
	PRINT 'Server does not contain FAE DB'
END




GO
/****** Object:  StoredProcedure [dbo].[CommandExecute]    Script Date: 27/10/2015 09:31:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[CommandExecute]

@Command nvarchar(max),
@CommandType nvarchar(max),
@Mode int,
@Comment nvarchar(max) = NULL,
@DatabaseName nvarchar(max) = NULL,
@SchemaName nvarchar(max) = NULL,
@ObjectName nvarchar(max) = NULL,
@ObjectType nvarchar(max) = NULL,
@IndexName nvarchar(max) = NULL,
@IndexType int = NULL,
@StatisticsName nvarchar(max) = NULL,
@PartitionNumber int = NULL,
@ExtendedInfo xml = NULL,
@LogToTable nvarchar(max),
@Execute nvarchar(max)

AS

BEGIN

  ----------------------------------------------------------------------------------------------------
  --// Source: http://ola.hallengren.com                                                          //--
  ----------------------------------------------------------------------------------------------------

  SET NOCOUNT ON

  SET LOCK_TIMEOUT 3600000

  DECLARE @StartMessage nvarchar(max)
  DECLARE @EndMessage nvarchar(max)
  DECLARE @ErrorMessage nvarchar(max)
  DECLARE @ErrorMessageOriginal nvarchar(max)

  DECLARE @StartTime datetime
  DECLARE @EndTime datetime

  DECLARE @StartTimeSec datetime
  DECLARE @EndTimeSec datetime

  DECLARE @ID int

  DECLARE @Error int
  DECLARE @ReturnCode int

  SET @Error = 0
  SET @ReturnCode = 0

  ----------------------------------------------------------------------------------------------------
  --// Check core requirements                                                                    //--
  ----------------------------------------------------------------------------------------------------

  IF @LogToTable = 'Y' AND NOT EXISTS (SELECT * FROM sys.objects objects INNER JOIN sys.schemas schemas ON objects.[schema_id] = schemas.[schema_id] WHERE objects.[type] = 'U' AND schemas.[name] = 'dbo' AND objects.[name] = 'CommandLog')
  BEGIN
    SET @ErrorMessage = 'The table CommandLog is missing. Download http://ola.hallengren.com/scripts/CommandLog.sql.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF @Error <> 0
  BEGIN
    SET @ReturnCode = @Error
    GOTO ReturnCode
  END

  ----------------------------------------------------------------------------------------------------
  --// Check input parameters                                                                     //--
  ----------------------------------------------------------------------------------------------------

  IF @Command IS NULL OR @Command = ''
  BEGIN
    SET @ErrorMessage = 'The value for the parameter @Command is not supported.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF @CommandType IS NULL OR @CommandType = '' OR LEN(@CommandType) > 60
  BEGIN
    SET @ErrorMessage = 'The value for the parameter @CommandType is not supported.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF @Mode NOT IN(1,2) OR @Mode IS NULL
  BEGIN
    SET @ErrorMessage = 'The value for the parameter @Mode is not supported.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF @LogToTable NOT IN('Y','N') OR @LogToTable IS NULL
  BEGIN
    SET @ErrorMessage = 'The value for the parameter @LogToTable is not supported.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF @Execute NOT IN('Y','N') OR @Execute IS NULL
  BEGIN
    SET @ErrorMessage = 'The value for the parameter @Execute is not supported.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF @Error <> 0
  BEGIN
    SET @ReturnCode = @Error
    GOTO ReturnCode
  END

  ----------------------------------------------------------------------------------------------------
  --// Log initial information                                                                    //--
  ----------------------------------------------------------------------------------------------------

  SET @StartTime = GETDATE()
  SET @StartTimeSec = CONVERT(datetime,CONVERT(nvarchar,@StartTime,120),120)

  SET @StartMessage = 'Date and time: ' + CONVERT(nvarchar,@StartTimeSec,120) + CHAR(13) + CHAR(10)
  SET @StartMessage = @StartMessage + 'Command: ' + @Command
  IF @Comment IS NOT NULL SET @StartMessage = @StartMessage + CHAR(13) + CHAR(10) + 'Comment: ' + @Comment
  SET @StartMessage = REPLACE(@StartMessage,'%','%%')
  RAISERROR(@StartMessage,10,1) WITH NOWAIT

  IF @LogToTable = 'Y'
  BEGIN
    INSERT INTO dbo.CommandLog (DatabaseName, SchemaName, ObjectName, ObjectType, IndexName, IndexType, StatisticsName, PartitionNumber, ExtendedInfo, CommandType, Command, StartTime)
    VALUES (@DatabaseName, @SchemaName, @ObjectName, @ObjectType, @IndexName, @IndexType, @StatisticsName, @PartitionNumber, @ExtendedInfo, @CommandType, @Command, @StartTime)
  END

  SET @ID = SCOPE_IDENTITY()

  ----------------------------------------------------------------------------------------------------
  --// Execute command                                                                            //--
  ----------------------------------------------------------------------------------------------------

  IF @Mode = 1 AND @Execute = 'Y'
  BEGIN
    EXECUTE(@Command)
    SET @Error = @@ERROR
    SET @ReturnCode = @Error
  END

  IF @Mode = 2 AND @Execute = 'Y'
  BEGIN
    BEGIN TRY
      EXECUTE(@Command)
    END TRY
    BEGIN CATCH
      SET @Error = ERROR_NUMBER()
      SET @ReturnCode = @Error
      SET @ErrorMessageOriginal = ERROR_MESSAGE()
      SET @ErrorMessage = 'Msg ' + CAST(@Error AS nvarchar) + ', ' + ISNULL(@ErrorMessageOriginal,'')
      RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    END CATCH
  END

  ----------------------------------------------------------------------------------------------------
  --// Log completing information                                                                 //--
  ----------------------------------------------------------------------------------------------------

  SET @EndTime = GETDATE()
  SET @EndTimeSec = CONVERT(datetime,CONVERT(varchar,@EndTime,120),120)

  SET @EndMessage = 'Outcome: ' + CASE WHEN @Execute = 'N' THEN 'Not Executed' WHEN @Error = 0 THEN 'Succeeded' ELSE 'Failed' END + CHAR(13) + CHAR(10)
  SET @EndMessage = @EndMessage + 'Duration: ' + CASE WHEN DATEDIFF(ss,@StartTimeSec, @EndTimeSec)/(24*3600) > 0 THEN CAST(DATEDIFF(ss,@StartTimeSec, @EndTimeSec)/(24*3600) AS nvarchar) + '.' ELSE '' END + CONVERT(nvarchar,@EndTimeSec - @StartTimeSec,108) + CHAR(13) + CHAR(10)
  SET @EndMessage = @EndMessage + 'Date and time: ' + CONVERT(nvarchar,@EndTimeSec,120) + CHAR(13) + CHAR(10) + ' '
  SET @EndMessage = REPLACE(@EndMessage,'%','%%')
  RAISERROR(@EndMessage,10,1) WITH NOWAIT

  IF @LogToTable = 'Y'
  BEGIN
    UPDATE dbo.CommandLog
    SET EndTime = @EndTime,
        ErrorNumber = CASE WHEN @Execute = 'N' THEN NULL ELSE @Error END,
        ErrorMessage = @ErrorMessageOriginal
    WHERE ID = @ID
  END

  ReturnCode:
  IF @ReturnCode <> 0
  BEGIN
    RETURN @ReturnCode
  END

  ----------------------------------------------------------------------------------------------------

END



GO
/****** Object:  StoredProcedure [dbo].[DatabaseBackup]    Script Date: 27/10/2015 09:31:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DatabaseBackup]

@Databases nvarchar(max),
@Directory nvarchar(max) = NULL,
@BackupType nvarchar(max),
@Verify nvarchar(max) = 'N',
@CleanupTime int = NULL,
@Compress nvarchar(max) = NULL,
@CopyOnly nvarchar(max) = 'N',
@ChangeBackupType nvarchar(max) = 'N',
@BackupSoftware nvarchar(max) = NULL,
@CheckSum nvarchar(max) = 'N',
@BlockSize int = NULL,
@BufferCount int = NULL,
@MaxTransferSize int = NULL,
@NumberOfFiles int = NULL,
@CompressionLevel int = NULL,
@Description nvarchar(max) = NULL,
@Threads int = NULL,
@Throttle int = NULL,
@Encrypt nvarchar(max) = 'N',
@EncryptionType nvarchar(max) = NULL,
@EncryptionKey nvarchar(max) = NULL,
@ReadWriteFileGroups nvarchar(max) = 'N',
@LogToTable nvarchar(max) = 'N',
@Execute nvarchar(max) = 'Y'

AS
 
BEGIN

  ----------------------------------------------------------------------------------------------------
  --// Source: http://ola.hallengren.com                                                          //--
  ----------------------------------------------------------------------------------------------------

  SET NOCOUNT ON

  DECLARE @StartMessage nvarchar(max)
  DECLARE @EndMessage nvarchar(max)
  DECLARE @DatabaseMessage nvarchar(max)
  DECLARE @ErrorMessage nvarchar(max)

  DECLARE @Version numeric(18,10)

  DECLARE @Cluster nvarchar(max)

  DECLARE @DefaultDirectory nvarchar(4000)

  DECLARE @CurrentRootDirectoryID int
  DECLARE @CurrentRootDirectoryPath nvarchar(4000)

  DECLARE @CurrentDBID int
  DECLARE @CurrentDatabaseID int
  DECLARE @CurrentDatabaseName nvarchar(max)
  DECLARE @CurrentBackupType nvarchar(max)
  DECLARE @CurrentFileExtension nvarchar(max)
  DECLARE @CurrentFileNumber int
  DECLARE @CurrentDifferentialBaseLSN numeric(25,0)
  DECLARE @CurrentDifferentialBaseIsSnapshot bit
  DECLARE @CurrentLogLSN numeric(25,0)
  DECLARE @CurrentLatestBackup datetime
  DECLARE @CurrentDatabaseNameFS nvarchar(max)
  DECLARE @CurrentDirectoryID int
  DECLARE @CurrentDirectoryPath nvarchar(max)
  DECLARE @CurrentFilePath nvarchar(max)
  DECLARE @CurrentDate datetime
  DECLARE @CurrentCleanupDate datetime
  DECLARE @CurrentIsDatabaseAccessible bit
  DECLARE @CurrentAvailabilityGroup nvarchar(max)
  DECLARE @CurrentAvailabilityGroupRole nvarchar(max)
  DECLARE @CurrentIsPreferredBackupReplica bit
  DECLARE @CurrentDatabaseMirroringRole nvarchar(max)
  DECLARE @CurrentLogShippingRole nvarchar(max)

  DECLARE @CurrentCommand01 nvarchar(max)
  DECLARE @CurrentCommand02 nvarchar(max)
  DECLARE @CurrentCommand03 nvarchar(max)
  DECLARE @CurrentCommand04 nvarchar(max)

  DECLARE @CurrentCommandOutput01 int
  DECLARE @CurrentCommandOutput02 int
  DECLARE @CurrentCommandOutput03 int
  DECLARE @CurrentCommandOutput04 int

  DECLARE @CurrentCommandType01 nvarchar(max)
  DECLARE @CurrentCommandType02 nvarchar(max)
  DECLARE @CurrentCommandType03 nvarchar(max)
  DECLARE @CurrentCommandType04 nvarchar(max)

  DECLARE @Directories TABLE (ID int PRIMARY KEY,
                              DirectoryPath nvarchar(max),
                              Completed bit)

  DECLARE @DirectoryInfo TABLE (FileExists bit,
                                FileIsADirectory bit,
                                ParentDirectoryExists bit)

  DECLARE @tmpDatabases TABLE (ID int IDENTITY,
                               DatabaseName nvarchar(max),
                               DatabaseNameFS nvarchar(max),
                               DatabaseType nvarchar(max),
                               Selected bit,
                               Completed bit,
                               PRIMARY KEY(Selected, Completed, ID))

  DECLARE @SelectedDatabases TABLE (DatabaseName nvarchar(max),
                                    DatabaseType nvarchar(max),
                                    Selected bit)

  DECLARE @CurrentDirectories TABLE (ID int PRIMARY KEY,
                                     DirectoryPath nvarchar(max),
                                     CreateCompleted bit,
                                     CleanupCompleted bit,
                                     CreateOutput int,
                                     CleanupOutput int)

  DECLARE @CurrentFiles TABLE (CurrentFilePath nvarchar(max))

  DECLARE @Error int
  DECLARE @ReturnCode int

  SET @Error = 0
  SET @ReturnCode = 0

  SET @Version = CAST(LEFT(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max)),CHARINDEX('.',CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max))) - 1) + '.' + REPLACE(RIGHT(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max)), LEN(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max))) - CHARINDEX('.',CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max)))),'.','') AS numeric(18,10))

  ----------------------------------------------------------------------------------------------------
  --// Log initial information                                                                    //--
  ----------------------------------------------------------------------------------------------------
  
  SET @StartMessage = 'Date and time: ' + CONVERT(nvarchar,GETDATE(),120) + CHAR(13) + CHAR(10)
  SET @StartMessage = @StartMessage + 'Server: ' + CAST(SERVERPROPERTY('ServerName') AS nvarchar) + CHAR(13) + CHAR(10)
  SET @StartMessage = @StartMessage + 'Version: ' + CAST(SERVERPROPERTY('ProductVersion') AS nvarchar) + CHAR(13) + CHAR(10)
  SET @StartMessage = @StartMessage + 'Edition: ' + CAST(SERVERPROPERTY('Edition') AS nvarchar) + CHAR(13) + CHAR(10)
  SET @StartMessage = @StartMessage + 'Procedure: ' + QUOTENAME(DB_NAME(DB_ID())) + '.' + (SELECT QUOTENAME(schemas.name) FROM sys.schemas schemas INNER JOIN sys.objects objects ON schemas.[schema_id] = objects.[schema_id] WHERE [object_id] = @@PROCID) + '.' + QUOTENAME(OBJECT_NAME(@@PROCID)) + CHAR(13) + CHAR(10)
  SET @StartMessage = @StartMessage + 'Parameters: @Databases = ' + ISNULL('''' + REPLACE(@Databases,'''','''''') + '''','NULL')
  SET @StartMessage = @StartMessage + ', @Directory = ' + ISNULL('''' + REPLACE(@Directory,'''','''''') + '''','NULL')
  SET @StartMessage = @StartMessage + ', @BackupType = ' + ISNULL('''' + REPLACE(@BackupType,'''','''''') + '''','NULL')
  SET @StartMessage = @StartMessage + ', @Verify = ' + ISNULL('''' + REPLACE(@Verify,'''','''''') + '''','NULL')
  SET @StartMessage = @StartMessage + ', @CleanupTime = ' + ISNULL(CAST(@CleanupTime AS nvarchar),'NULL')
  SET @StartMessage = @StartMessage + ', @Compress = ' + ISNULL('''' + REPLACE(@Compress,'''','''''') + '''','NULL')
  SET @StartMessage = @StartMessage + ', @CopyOnly = ' + ISNULL('''' + REPLACE(@CopyOnly,'''','''''') + '''','NULL')
  SET @StartMessage = @StartMessage + ', @ChangeBackupType = ' + ISNULL('''' + REPLACE(@ChangeBackupType,'''','''''') + '''','NULL')
  SET @StartMessage = @StartMessage + ', @BackupSoftware = ' + ISNULL('''' + REPLACE(@BackupSoftware,'''','''''') + '''','NULL')
  SET @StartMessage = @StartMessage + ', @CheckSum = ' + ISNULL('''' + REPLACE(@CheckSum,'''','''''') + '''','NULL')
  SET @StartMessage = @StartMessage + ', @BlockSize = ' + ISNULL(CAST(@BlockSize AS nvarchar),'NULL')
  SET @StartMessage = @StartMessage + ', @BufferCount = ' + ISNULL(CAST(@BufferCount AS nvarchar),'NULL')
  SET @StartMessage = @StartMessage + ', @MaxTransferSize = ' + ISNULL(CAST(@MaxTransferSize AS nvarchar),'NULL')
  SET @StartMessage = @StartMessage + ', @NumberOfFiles = ' + ISNULL(CAST(@NumberOfFiles AS nvarchar),'NULL')
  SET @StartMessage = @StartMessage + ', @CompressionLevel = ' + ISNULL(CAST(@CompressionLevel AS nvarchar),'NULL')
  SET @StartMessage = @StartMessage + ', @Description = ' + ISNULL('''' + REPLACE(@Description,'''','''''') + '''','NULL')
  SET @StartMessage = @StartMessage + ', @Threads = ' + ISNULL(CAST(@Threads AS nvarchar),'NULL')
  SET @StartMessage = @StartMessage + ', @Throttle = ' + ISNULL(CAST(@Throttle AS nvarchar),'NULL')
  SET @StartMessage = @StartMessage + ', @Encrypt = ' + ISNULL('''' + REPLACE(@Encrypt,'''','''''') + '''','NULL')
  SET @StartMessage = @StartMessage + ', @EncryptionType = ' + ISNULL('''' + REPLACE(@EncryptionType,'''','''''') + '''','NULL')
  SET @StartMessage = @StartMessage + ', @EncryptionKey = ' + ISNULL('''' + REPLACE(@EncryptionKey,'''','''''') + '''','NULL')
  SET @StartMessage = @StartMessage + ', @ReadWriteFileGroups = ' + ISNULL('''' + REPLACE(@ReadWriteFileGroups,'''','''''') + '''','NULL')
  SET @StartMessage = @StartMessage + ', @LogToTable = ' + ISNULL('''' + REPLACE(@LogToTable,'''','''''') + '''','NULL')
  SET @StartMessage = @StartMessage + ', @Execute = ' + ISNULL('''' + REPLACE(@Execute,'''','''''') + '''','NULL') + CHAR(13) + CHAR(10)
  SET @StartMessage = @StartMessage + 'Source: http://ola.hallengren.com' + CHAR(13) + CHAR(10)
  SET @StartMessage = REPLACE(@StartMessage,'%','%%') + ' '
  RAISERROR(@StartMessage,10,1) WITH NOWAIT

  ----------------------------------------------------------------------------------------------------
  --// Check core requirements                                                                    //--
  ----------------------------------------------------------------------------------------------------

  IF NOT EXISTS (SELECT * FROM sys.objects objects INNER JOIN sys.schemas schemas ON objects.[schema_id] = schemas.[schema_id] WHERE objects.[type] = 'P' AND schemas.[name] = 'dbo' AND objects.[name] = 'CommandExecute')
  BEGIN
    SET @ErrorMessage = 'The stored procedure CommandExecute is missing. Download http://ola.hallengren.com/scripts/CommandExecute.sql.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF EXISTS (SELECT * FROM sys.objects objects INNER JOIN sys.schemas schemas ON objects.[schema_id] = schemas.[schema_id] WHERE objects.[type] = 'P' AND schemas.[name] = 'dbo' AND objects.[name] = 'CommandExecute' AND OBJECT_DEFINITION(objects.[object_id]) NOT LIKE '%@LogToTable%')
  BEGIN
    SET @ErrorMessage = 'The stored procedure CommandExecute needs to be updated. Download http://ola.hallengren.com/scripts/CommandExecute.sql.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF @LogToTable = 'Y' AND NOT EXISTS (SELECT * FROM sys.objects objects INNER JOIN sys.schemas schemas ON objects.[schema_id] = schemas.[schema_id] WHERE objects.[type] = 'U' AND schemas.[name] = 'dbo' AND objects.[name] = 'CommandLog')
  BEGIN
    SET @ErrorMessage = 'The table CommandLog is missing. Download http://ola.hallengren.com/scripts/CommandLog.sql.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF @Error <> 0
  BEGIN
    SET @ReturnCode = @Error
    GOTO Logging
  END;

  ----------------------------------------------------------------------------------------------------
  --// Select databases                                                                           //--
  ----------------------------------------------------------------------------------------------------

  WITH Databases1 (DatabaseItems) AS
  (
  SELECT REPLACE(@Databases, ', ', ',') AS DatabaseItems
  ),
  Databases2 (DatabaseItem, String, [Continue]) AS
  (
  SELECT CASE WHEN CHARINDEX(',', DatabaseItems) = 0 THEN @Databases ELSE SUBSTRING(DatabaseItems, 1, CHARINDEX(',', DatabaseItems) - 1) END AS DatabaseItem,
         CASE WHEN CHARINDEX(',', DatabaseItems) = 0 THEN '' ELSE SUBSTRING(DatabaseItems, CHARINDEX(',', DatabaseItems) + 1, LEN(DatabaseItems)) END AS String,
         CASE WHEN CHARINDEX(',', DatabaseItems) = 0 THEN 0 ELSE 1 END [Continue]
  FROM Databases1
  WHERE @Databases IS NOT NULL
  UNION ALL
  SELECT CASE WHEN CHARINDEX(',', String) = 0 THEN String ELSE SUBSTRING(String, 1, CHARINDEX(',', String) - 1) END AS DatabaseItem,
         CASE WHEN CHARINDEX(',', String) = 0 THEN '' ELSE SUBSTRING(String, CHARINDEX(',', String) + 1, LEN(String)) END AS String,
         CASE WHEN CHARINDEX(',', String) = 0 THEN 0 ELSE 1 END [Continue]
  FROM Databases2
  WHERE [Continue] = 1
  ),
  Databases3 (DatabaseItem, Selected) AS
  (
  SELECT CASE WHEN DatabaseItem LIKE '-%' THEN RIGHT(DatabaseItem,LEN(DatabaseItem) - 1) ELSE DatabaseItem END AS DatabaseItem,
         CASE WHEN DatabaseItem LIKE '-%' THEN 0 ELSE 1 END AS Selected
  FROM Databases2
  ),
  Databases4 (DatabaseItem, DatabaseType, Selected) AS
  (
  SELECT CASE WHEN DatabaseItem IN('ALL_DATABASES','SYSTEM_DATABASES','USER_DATABASES') THEN '%' ELSE DatabaseItem END AS DatabaseItem,
         CASE WHEN DatabaseItem = 'SYSTEM_DATABASES' THEN 'S' WHEN DatabaseItem = 'USER_DATABASES' THEN 'U' ELSE NULL END AS DatabaseType,
         Selected
  FROM Databases3
  ),
  Databases5 (DatabaseName, DatabaseType, Selected) AS
  (
  SELECT CASE WHEN LEFT(DatabaseItem,1) = '[' AND RIGHT(DatabaseItem,1) = ']' THEN PARSENAME(DatabaseItem,1) ELSE DatabaseItem END AS DatabaseItem,
         DatabaseType,
         Selected
  FROM Databases4
  )
  INSERT INTO @SelectedDatabases (DatabaseName, DatabaseType, Selected)
  SELECT DatabaseName,
         DatabaseType,
         Selected
  FROM Databases5

  INSERT INTO @tmpDatabases (DatabaseName, DatabaseNameFS, DatabaseType, Selected, Completed)
  SELECT [name] AS DatabaseName,
         REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE([name],'\',''),'/',''),':',''),'*',''),'?',''),'"',''),'<',''),'>',''),'|',''),' ','') AS DatabaseNameFS,
         CASE WHEN name IN('master','msdb','model') THEN 'S' ELSE 'U' END AS DatabaseType,
         0 AS Selected,
         0 AS Completed
  FROM sys.databases
  WHERE [name] <> 'tempdb'
  AND source_database_id IS NULL
  ORDER BY [name] ASC

  UPDATE tmpDatabases
  SET tmpDatabases.Selected = SelectedDatabases.Selected
  FROM @tmpDatabases tmpDatabases
  INNER JOIN @SelectedDatabases SelectedDatabases
  ON tmpDatabases.DatabaseName LIKE REPLACE(SelectedDatabases.DatabaseName,'_','[_]')
  AND (tmpDatabases.DatabaseType = SelectedDatabases.DatabaseType OR SelectedDatabases.DatabaseType IS NULL)
  WHERE SelectedDatabases.Selected = 1

  UPDATE tmpDatabases
  SET tmpDatabases.Selected = SelectedDatabases.Selected
  FROM @tmpDatabases tmpDatabases
  INNER JOIN @SelectedDatabases SelectedDatabases
  ON tmpDatabases.DatabaseName LIKE REPLACE(SelectedDatabases.DatabaseName,'_','[_]')
  AND (tmpDatabases.DatabaseType = SelectedDatabases.DatabaseType OR SelectedDatabases.DatabaseType IS NULL)
  WHERE SelectedDatabases.Selected = 0

  IF @Databases IS NULL OR NOT EXISTS(SELECT * FROM @SelectedDatabases) OR EXISTS(SELECT * FROM @SelectedDatabases WHERE DatabaseName IS NULL OR DatabaseName = '')
  BEGIN
    SET @ErrorMessage = 'The value for the parameter @Databases is not supported.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END;

  ----------------------------------------------------------------------------------------------------
  --// Check database names                                                                       //--
  ----------------------------------------------------------------------------------------------------

  SET @ErrorMessage = ''
  SELECT @ErrorMessage = @ErrorMessage + QUOTENAME(DatabaseName) + ', '
  FROM @tmpDatabases
  WHERE Selected = 1
  AND DatabaseNameFS = ''
  ORDER BY DatabaseName ASC
  IF @@ROWCOUNT > 0
  BEGIN
    SET @ErrorMessage = 'The names of the following databases are not supported: ' + LEFT(@ErrorMessage,LEN(@ErrorMessage)-1) + '.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  SET @ErrorMessage = ''
  SELECT @ErrorMessage = @ErrorMessage + QUOTENAME(DatabaseName) + ', '
  FROM @tmpDatabases
  WHERE UPPER(DatabaseNameFS) IN(SELECT UPPER(DatabaseNameFS) FROM @tmpDatabases GROUP BY UPPER(DatabaseNameFS) HAVING COUNT(*) > 1)
  AND UPPER(DatabaseNameFS) IN(SELECT UPPER(DatabaseNameFS) FROM @tmpDatabases WHERE Selected = 1)
  AND DatabaseNameFS <> ''
  ORDER BY DatabaseName ASC
  OPTION (RECOMPILE)
  IF @@ROWCOUNT > 0
  BEGIN
    SET @ErrorMessage = 'The names of the following databases are not unique in the file system: ' + LEFT(@ErrorMessage,LEN(@ErrorMessage)-1) + '.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  ----------------------------------------------------------------------------------------------------
  --// Select directories                                                                         //--
  ----------------------------------------------------------------------------------------------------

  IF @Directory IS NULL
  BEGIN
    EXECUTE [master].dbo.xp_instance_regread N'HKEY_LOCAL_MACHINE', N'SOFTWARE\Microsoft\MSSQLServer\MSSQLServer', N'BackupDirectory', @DefaultDirectory OUTPUT

    INSERT INTO @Directories (ID, DirectoryPath, Completed)
    SELECT 1, @DefaultDirectory, 0
  END
  ELSE
  BEGIN
    WITH Directory AS
    (
    SELECT REPLACE(@Directory, ', ', ',') AS DirectoryName
    ),
    Directories AS
    (
    SELECT CASE WHEN CHARINDEX(',', DirectoryName) = 0 THEN DirectoryName ELSE SUBSTRING(DirectoryName, 1, CHARINDEX(',', DirectoryName) - 1) END AS Directory,
           CASE WHEN CHARINDEX(',', DirectoryName) = 0 THEN '' ELSE SUBSTRING(DirectoryName, CHARINDEX(',', DirectoryName) + 1, LEN(DirectoryName)) END AS String,
           1 AS [ID],
         CASE WHEN CHARINDEX(',', DirectoryName) = 0 THEN 0 ELSE 1 END [Continue]
    FROM Directory
    UNION ALL
    SELECT CASE WHEN CHARINDEX(',', String) = 0 THEN String ELSE SUBSTRING(String, 1, CHARINDEX(',', String) - 1) END AS Directory,
           CASE WHEN CHARINDEX(',', String) = 0 THEN '' ELSE SUBSTRING(String, CHARINDEX(',', String) + 1, LEN(String)) END AS String,
           [ID] + 1  AS [ID],
           CASE WHEN CHARINDEX(',', String) = 0 THEN 0 ELSE 1 END [Continue]
    FROM Directories
    WHERE [Continue] = 1
    )
    INSERT INTO @Directories (ID, DirectoryPath, Completed)
    SELECT ID, Directory, 0
    FROM Directories
  END

  ----------------------------------------------------------------------------------------------------
  --// Check directories                                                                          //--
  ----------------------------------------------------------------------------------------------------

  IF EXISTS(SELECT * FROM @Directories WHERE NOT (DirectoryPath LIKE '_:' OR DirectoryPath LIKE '_:\%' OR DirectoryPath LIKE '\\%\%') OR DirectoryPath IS NULL OR LEFT(DirectoryPath,1) = ' ' OR RIGHT(DirectoryPath,1) = ' ') OR EXISTS (SELECT * FROM @Directories GROUP BY DirectoryPath HAVING COUNT(*) <> 1)
  BEGIN
    SET @ErrorMessage = 'The value for the parameter @Directory is not supported.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END
  ELSE
  BEGIN
    WHILE EXISTS(SELECT * FROM @Directories WHERE Completed = 0)
    BEGIN
      SELECT TOP 1 @CurrentRootDirectoryID = ID,
                   @CurrentRootDirectoryPath = DirectoryPath
      FROM @Directories
      WHERE Completed = 0
      ORDER BY ID ASC

      INSERT INTO @DirectoryInfo (FileExists, FileIsADirectory, ParentDirectoryExists)
      EXECUTE [master].dbo.xp_fileexist @CurrentRootDirectoryPath

      IF NOT EXISTS (SELECT * FROM @DirectoryInfo WHERE FileExists = 0 AND FileIsADirectory = 1 AND ParentDirectoryExists = 1)
      BEGIN
        SET @ErrorMessage = 'The directory ' + @CurrentRootDirectoryPath + ' does not exist.' + CHAR(13) + CHAR(10) + ' '
        RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
        SET @Error = @@ERROR
      END

      UPDATE @Directories
      SET Completed = 1
      WHERE ID = @CurrentRootDirectoryID

      SET @CurrentRootDirectoryID = NULL
      SET @CurrentRootDirectoryPath = NULL

      DELETE FROM @DirectoryInfo
    END
  END

  ----------------------------------------------------------------------------------------------------
  --// Get default compression                                                                    //--
  ----------------------------------------------------------------------------------------------------

  IF @Compress IS NULL
  BEGIN
    SELECT @Compress = CASE
    WHEN @BackupSoftware IS NULL AND EXISTS(SELECT * FROM sys.configurations WHERE name = 'backup compression default' AND value_in_use = 1) THEN 'Y'
    WHEN @BackupSoftware IS NULL AND NOT EXISTS(SELECT * FROM sys.configurations WHERE name = 'backup compression default' AND value_in_use = 1) THEN 'N'
    WHEN @BackupSoftware IS NOT NULL AND (@CompressionLevel IS NULL OR @CompressionLevel > 0)  THEN 'Y'
    WHEN @BackupSoftware IS NOT NULL AND @CompressionLevel = 0  THEN 'N'
    END
  END

  ----------------------------------------------------------------------------------------------------
  --// Get number of files                                                                        //--
  ----------------------------------------------------------------------------------------------------

  IF @NumberOfFiles IS NULL
  BEGIN
    SELECT @NumberOfFiles = (SELECT COUNT(*) FROM @Directories)
  END

  ----------------------------------------------------------------------------------------------------
  --// Check input parameters                                                                     //--
  ----------------------------------------------------------------------------------------------------

  IF @BackupType NOT IN ('FULL','DIFF','LOG') OR @BackupType IS NULL
  BEGIN
    SET @ErrorMessage = 'The value for the parameter @BackupType is not supported.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF @Verify NOT IN ('Y','N') OR @Verify IS NULL OR (@BackupSoftware = 'SQLSAFE' AND @Encrypt = 'Y' AND @Verify = 'Y')
  BEGIN
    SET @ErrorMessage = 'The value for the parameter @Verify is not supported.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF @CleanupTime < 0
  BEGIN
    SET @ErrorMessage = 'The value for the parameter @CleanupTime is not supported.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF @Compress NOT IN ('Y','N') OR @Compress IS NULL OR (@Compress = 'Y' AND @BackupSoftware IS NULL AND NOT ((@Version >= 10 AND @Version < 10.5 AND SERVERPROPERTY('EngineEdition') = 3) OR (@Version >= 10.5 AND (SERVERPROPERTY('EngineEdition') = 3 OR SERVERPROPERTY('EditionID') IN (-1534726760, 284895786))))) OR (@Compress = 'N' AND @BackupSoftware IS NOT NULL AND (@CompressionLevel IS NULL OR @CompressionLevel >= 1)) OR (@Compress = 'Y' AND @BackupSoftware IS NOT NULL AND @CompressionLevel = 0)
  BEGIN
    SET @ErrorMessage = 'The value for the parameter @Compress is not supported.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF @CopyOnly NOT IN ('Y','N') OR @CopyOnly IS NULL
  BEGIN
    SET @ErrorMessage = 'The value for the parameter @CopyOnly is not supported.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF @ChangeBackupType NOT IN ('Y','N') OR @ChangeBackupType IS NULL
  BEGIN
    SET @ErrorMessage = 'The value for the parameter @ChangeBackupType is not supported.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF @BackupSoftware NOT IN ('LITESPEED','SQLBACKUP','HYPERBAC','SQLSAFE')
  BEGIN
    SET @ErrorMessage = 'The value for the parameter @BackupSoftware is not supported.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF @BackupSoftware = 'LITESPEED' AND NOT EXISTS (SELECT * FROM [master].sys.objects WHERE [type] = 'X' AND [name] = 'xp_backup_database')
  BEGIN
    SET @ErrorMessage = 'NetVault LiteSpeed for SQL Server is not installed. Download http://www.quest.com/litespeed-for-sql-server/.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF @BackupSoftware = 'SQLBACKUP' AND NOT EXISTS (SELECT * FROM [master].sys.objects WHERE [type] = 'X' AND [name] = 'sqlbackup')
  BEGIN
    SET @ErrorMessage = 'Red Gate SQL Backup is not installed. Download http://www.red-gate.com/products/dba/sql-backup/.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF @BackupSoftware = 'SQLSAFE' AND NOT EXISTS (SELECT * FROM [master].sys.objects WHERE [type] = 'X' AND [name] = 'xp_ss_backup')
  BEGIN
    SET @ErrorMessage = 'Idera SQL safe backup is not installed. Download http://www.idera.com/Products/SQL-Server/SQL-safe-backup/.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF @CheckSum NOT IN ('Y','N') OR @CheckSum IS NULL
  BEGIN
    SET @ErrorMessage = 'The value for the parameter @CheckSum is not supported.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF @BlockSize NOT IN (512,1024,2048,4096,8192,16384,32768,65536) OR (@BlockSize IS NOT NULL AND @BackupSoftware = 'SQLBACKUP') OR (@BlockSize IS NOT NULL AND @BackupSoftware = 'SQLSAFE')
  BEGIN
    SET @ErrorMessage = 'The value for the parameter @BlockSize is not supported.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF @BufferCount <= 0 OR @BufferCount > 2147483647 OR (@BufferCount IS NOT NULL AND @BackupSoftware = 'SQLBACKUP') OR (@BufferCount IS NOT NULL AND @BackupSoftware = 'SQLSAFE')
  BEGIN
    SET @ErrorMessage = 'The value for the parameter @BufferCount is not supported.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF @MaxTransferSize < 65536 OR @MaxTransferSize > 4194304 OR @MaxTransferSize % 65536 > 0 OR (@MaxTransferSize > 1048576 AND @BackupSoftware = 'SQLBACKUP') OR (@MaxTransferSize IS NOT NULL AND @BackupSoftware = 'SQLSAFE')
  BEGIN
    SET @ErrorMessage = 'The value for the parameter @MaxTransferSize is not supported.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF @NumberOfFiles < 1 OR @NumberOfFiles > 64 OR (@NumberOfFiles > 32 AND @BackupSoftware = 'SQLBACKUP') OR @NumberOfFiles IS NULL OR @NumberOfFiles < (SELECT COUNT(*) FROM @Directories) OR @NumberOfFiles % (SELECT COUNT(*) FROM @Directories) > 0
  BEGIN
    SET @ErrorMessage = 'The value for the parameter @NumberOfFiles is not supported.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF (@BackupSoftware IS NULL AND @CompressionLevel IS NOT NULL) OR (@BackupSoftware = 'HYPERBAC' AND @CompressionLevel IS NOT NULL) OR (@BackupSoftware = 'LITESPEED' AND (@CompressionLevel < 0 OR @CompressionLevel > 8)) OR (@BackupSoftware = 'SQLBACKUP' AND (@CompressionLevel < 0 OR @CompressionLevel > 4)) OR (@BackupSoftware = 'SQLSAFE' AND (@CompressionLevel < 1 OR @CompressionLevel > 4))
  BEGIN
    SET @ErrorMessage = 'The value for the parameter @CompressionLevel is not supported.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF LEN(@Description) > 255 OR (@BackupSoftware = 'LITESPEED' AND LEN(@Description) > 128)
  BEGIN
    SET @ErrorMessage = 'The value for the parameter @Description is not supported.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF @Threads IS NOT NULL AND (@BackupSoftware NOT IN('LITESPEED','SQLBACKUP','SQLSAFE') OR @BackupSoftware IS NULL) OR @Threads < 2 OR @Threads > 32
  BEGIN
    SET @ErrorMessage = 'The value for the parameter @Threads is not supported.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF @Throttle IS NOT NULL AND (@BackupSoftware NOT IN('LITESPEED') OR @BackupSoftware IS NULL) OR @Throttle < 1 OR @Throttle > 100
  BEGIN
    SET @ErrorMessage = 'The value for the parameter @Throttle is not supported.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF @Encrypt NOT IN('Y','N') OR @Encrypt IS NULL OR (@Encrypt = 'Y' AND @BackupSoftware IS NULL)
  BEGIN
    SET @ErrorMessage = 'The value for the parameter @Encrypt is not supported.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF (@EncryptionType IS NOT NULL AND @BackupSoftware IS NULL) OR (@EncryptionType IS NOT NULL AND @BackupSoftware = 'HYPERBAC') OR (@EncryptionType IS NOT NULL AND @Encrypt = 'N') OR ((@EncryptionType NOT IN('RC2-40','RC2-56','RC2-112','RC2-128','3DES-168','RC4-128','AES-128','AES-192','AES-256') OR @EncryptionType IS NULL) AND @Encrypt = 'Y' AND @BackupSoftware = 'LITESPEED') OR ((@EncryptionType NOT IN('AES-128','AES-256') OR @EncryptionType IS NULL) AND @Encrypt = 'Y' AND @BackupSoftware = 'SQLBACKUP') OR ((@EncryptionType NOT IN('AES-128','AES-256') OR @EncryptionType IS NULL) AND @Encrypt = 'Y' AND @BackupSoftware = 'SQLSAFE')
  BEGIN
    SET @ErrorMessage = 'The value for the parameter @EncryptionType is not supported.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF (@EncryptionKey IS NOT NULL AND @BackupSoftware IS NULL) OR (@EncryptionKey IS NOT NULL AND @BackupSoftware = 'HYPERBAC') OR (@EncryptionKey IS NOT NULL AND @Encrypt = 'N') OR (@EncryptionKey IS NULL AND @Encrypt = 'Y' AND @BackupSoftware IN('LITESPEED','SQLBACKUP','SQLSAFE'))
  BEGIN
    SET @ErrorMessage = 'The value for the parameter @EncryptionKey is not supported.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF @ReadWriteFileGroups NOT IN('Y','N') OR @ReadWriteFileGroups IS NULL OR (@ReadWriteFileGroups = 'Y' AND @BackupType = 'LOG')
  BEGIN
    SET @ErrorMessage = 'The value for the parameter @ReadWriteFileGroups is not supported.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF @LogToTable NOT IN('Y','N') OR @LogToTable IS NULL
  BEGIN
    SET @ErrorMessage = 'The value for the parameter @LogToTable is not supported.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF @Execute NOT IN('Y','N') OR @Execute IS NULL
  BEGIN
    SET @ErrorMessage = 'The value for the parameter @Execute is not supported.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF @Error <> 0
  BEGIN
    SET @ErrorMessage = 'The documentation is available at http://ola.hallengren.com/sql-server-backup.html.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @ReturnCode = @Error
    GOTO Logging
  END

  ----------------------------------------------------------------------------------------------------
  --// Check Availability Group cluster name                                                      //--
  ----------------------------------------------------------------------------------------------------

  IF @Version >= 11
  BEGIN
    SELECT @Cluster = cluster_name
    FROM sys.dm_hadr_cluster
  END

  ----------------------------------------------------------------------------------------------------
  --// Execute backup commands                                                                    //--
  ----------------------------------------------------------------------------------------------------

  WHILE EXISTS (SELECT * FROM @tmpDatabases WHERE Selected = 1 AND Completed = 0)
  BEGIN

    SELECT TOP 1 @CurrentDBID = ID,
                 @CurrentDatabaseName = DatabaseName,
                 @CurrentDatabaseNameFS = DatabaseNameFS
    FROM @tmpDatabases
    WHERE Selected = 1
    AND Completed = 0
    ORDER BY ID ASC

    SET @CurrentDatabaseID = DB_ID(@CurrentDatabaseName)

    IF DATABASEPROPERTYEX(@CurrentDatabaseName,'Status') = 'ONLINE'
    BEGIN
      IF EXISTS (SELECT * FROM sys.database_recovery_status WHERE database_id = @CurrentDatabaseID AND database_guid IS NOT NULL)
      BEGIN
        SET @CurrentIsDatabaseAccessible = 1
      END
      ELSE
      BEGIN
        SET @CurrentIsDatabaseAccessible = 0
      END
    END
    ELSE
    BEGIN
      SET @CurrentIsDatabaseAccessible = 0
    END

    SELECT @CurrentDifferentialBaseLSN = differential_base_lsn
    FROM sys.master_files
    WHERE database_id = @CurrentDatabaseID
    AND [type] = 0
    AND [file_id] = 1

    -- Workaround for a bug in SQL Server 2005
    IF @Version >= 9 AND @Version < 10
    AND EXISTS(SELECT * FROM sys.master_files WHERE database_id = @CurrentDatabaseID AND [type] = 0 AND [file_id] = 1 AND differential_base_lsn IS NOT NULL AND differential_base_guid IS NOT NULL AND differential_base_time IS NULL)
    BEGIN
      SET @CurrentDifferentialBaseLSN = NULL
    END

    SELECT @CurrentDifferentialBaseIsSnapshot = is_snapshot
    FROM msdb.dbo.backupset
    WHERE database_name = @CurrentDatabaseName
    AND [type] = 'D'
    AND checkpoint_lsn = @CurrentDifferentialBaseLSN

    IF DATABASEPROPERTYEX(@CurrentDatabaseName,'Status') = 'ONLINE'
    BEGIN
      SELECT @CurrentLogLSN = last_log_backup_lsn
      FROM sys.database_recovery_status
      WHERE database_id = @CurrentDatabaseID
    END

    SET @CurrentBackupType = @BackupType

    IF @ChangeBackupType = 'Y'
    BEGIN
      IF @CurrentBackupType = 'LOG' AND DATABASEPROPERTYEX(@CurrentDatabaseName,'Recovery') <> 'SIMPLE' AND @CurrentLogLSN IS NULL AND @CurrentDatabaseName <> 'master'
      BEGIN
        SET @CurrentBackupType = 'DIFF'
      END
      IF @CurrentBackupType = 'DIFF' AND @CurrentDifferentialBaseLSN IS NULL AND @CurrentDatabaseName <> 'master'
      BEGIN
        SET @CurrentBackupType = 'FULL'
      END
    END

    IF @CurrentBackupType = 'LOG'
    BEGIN
      SELECT @CurrentLatestBackup = MAX(backup_finish_date)
      FROM msdb.dbo.backupset
      WHERE [type] IN('D','I')
      AND is_damaged = 0
      AND database_name = @CurrentDatabaseName
    END

    IF @Version >= 11 AND @Cluster IS NOT NULL
    BEGIN
      SELECT @CurrentAvailabilityGroup = availability_groups.name,
             @CurrentAvailabilityGroupRole = dm_hadr_availability_replica_states.role_desc
      FROM sys.databases databases
      INNER JOIN sys.availability_databases_cluster availability_databases_cluster ON databases.group_database_id = availability_databases_cluster.group_database_id
      INNER JOIN sys.availability_groups availability_groups ON availability_databases_cluster.group_id = availability_groups.group_id
      INNER JOIN sys.dm_hadr_availability_replica_states dm_hadr_availability_replica_states ON availability_groups.group_id = dm_hadr_availability_replica_states.group_id AND databases.replica_id = dm_hadr_availability_replica_states.replica_id
      WHERE databases.name = @CurrentDatabaseName
    END

    IF @Version >= 11 AND @Cluster IS NOT NULL AND @CurrentAvailabilityGroup IS NOT NULL
    BEGIN
      SELECT @CurrentIsPreferredBackupReplica = sys.fn_hadr_backup_is_preferred_replica(@CurrentDatabaseName)
    END

    SELECT @CurrentDatabaseMirroringRole = UPPER(mirroring_role_desc)
    FROM sys.database_mirroring
    WHERE database_id = @CurrentDatabaseID

    IF EXISTS (SELECT * FROM msdb.dbo.log_shipping_primary_databases WHERE primary_database = @CurrentDatabaseName)
    BEGIN
      SET @CurrentLogShippingRole = 'PRIMARY'
    END
    ELSE
    IF EXISTS (SELECT * FROM msdb.dbo.log_shipping_secondary_databases WHERE secondary_database = @CurrentDatabaseName)
    BEGIN
      SET @CurrentLogShippingRole = 'SECONDARY'
    END

    -- Set database message
    SET @DatabaseMessage = 'Date and time: ' + CONVERT(nvarchar,GETDATE(),120) + CHAR(13) + CHAR(10)
    SET @DatabaseMessage = @DatabaseMessage + 'Database: ' + QUOTENAME(@CurrentDatabaseName) + CHAR(13) + CHAR(10)
    SET @DatabaseMessage = @DatabaseMessage + 'Status: ' + CAST(DATABASEPROPERTYEX(@CurrentDatabaseName,'Status') AS nvarchar) + CHAR(13) + CHAR(10)
    SET @DatabaseMessage = @DatabaseMessage + 'Standby: ' + CASE WHEN DATABASEPROPERTYEX(@CurrentDatabaseName,'IsInStandBy') = 1 THEN 'Yes' ELSE 'No' END + CHAR(13) + CHAR(10)
    SET @DatabaseMessage = @DatabaseMessage + 'Updateability: ' + CAST(DATABASEPROPERTYEX(@CurrentDatabaseName,'Updateability') AS nvarchar) + CHAR(13) + CHAR(10)
    SET @DatabaseMessage = @DatabaseMessage + 'User access: ' + CAST(DATABASEPROPERTYEX(@CurrentDatabaseName,'UserAccess') AS nvarchar) + CHAR(13) + CHAR(10)
    SET @DatabaseMessage = @DatabaseMessage + 'Is accessible: ' + CASE WHEN @CurrentIsDatabaseAccessible = 1 THEN 'Yes' ELSE 'No' END + CHAR(13) + CHAR(10)
    SET @DatabaseMessage = @DatabaseMessage + 'Recovery model: ' + CAST(DATABASEPROPERTYEX(@CurrentDatabaseName,'Recovery') AS nvarchar) + CHAR(13) + CHAR(10)
    IF @CurrentAvailabilityGroup IS NOT NULL SET @DatabaseMessage = @DatabaseMessage + 'Availability group: ' + @CurrentAvailabilityGroup + CHAR(13) + CHAR(10)
    IF @CurrentAvailabilityGroup IS NOT NULL SET @DatabaseMessage = @DatabaseMessage + 'Availability group role: ' + @CurrentAvailabilityGroupRole + CHAR(13) + CHAR(10)
    IF @CurrentAvailabilityGroup IS NOT NULL SET @DatabaseMessage = @DatabaseMessage + 'Is preferred backup replica: ' + CASE WHEN @CurrentIsPreferredBackupReplica = 1 THEN 'Yes' WHEN @CurrentIsPreferredBackupReplica = 0 THEN 'No' ELSE 'N/A' END + CHAR(13) + CHAR(10)
    IF @CurrentDatabaseMirroringRole IS NOT NULL SET @DatabaseMessage = @DatabaseMessage + 'Database mirroring role: ' + @CurrentDatabaseMirroringRole + CHAR(13) + CHAR(10)
    IF @CurrentLogShippingRole IS NOT NULL SET @DatabaseMessage = @DatabaseMessage + 'Log shipping role: ' + @CurrentLogShippingRole + CHAR(13) + CHAR(10)
    SET @DatabaseMessage = @DatabaseMessage + 'Differential base LSN: ' + ISNULL(CAST(@CurrentDifferentialBaseLSN AS nvarchar),'N/A') + CHAR(13) + CHAR(10)
    SET @DatabaseMessage = @DatabaseMessage + 'Differential base is snapshot: ' + CASE WHEN @CurrentDifferentialBaseIsSnapshot = 1 THEN 'Yes' WHEN @CurrentDifferentialBaseIsSnapshot = 0 THEN 'No' ELSE 'N/A' END + CHAR(13) + CHAR(10)
    SET @DatabaseMessage = @DatabaseMessage + 'Last log backup LSN: ' + ISNULL(CAST(@CurrentLogLSN AS nvarchar),'N/A') + CHAR(13) + CHAR(10)
    SET @DatabaseMessage = REPLACE(@DatabaseMessage,'%','%%') + ' '
    RAISERROR(@DatabaseMessage,10,1) WITH NOWAIT

    IF DATABASEPROPERTYEX(@CurrentDatabaseName,'Status') = 'ONLINE'
    AND NOT (DATABASEPROPERTYEX(@CurrentDatabaseName,'UserAccess') = 'SINGLE_USER' AND @CurrentIsDatabaseAccessible = 0)
    AND DATABASEPROPERTYEX(@CurrentDatabaseName,'IsInStandBy') = 0
    AND NOT (@CurrentBackupType = 'LOG' AND (DATABASEPROPERTYEX(@CurrentDatabaseName,'Recovery') = 'SIMPLE' OR @CurrentLogLSN IS NULL))
    AND NOT (@CurrentBackupType = 'DIFF' AND @CurrentDifferentialBaseLSN IS NULL)
    AND NOT (@CurrentBackupType IN('DIFF','LOG') AND @CurrentDatabaseName = 'master')
    AND NOT (@CurrentAvailabilityGroup IS NOT NULL AND @CurrentBackupType = 'FULL' AND @CopyOnly = 'N' AND (@CurrentAvailabilityGroupRole <> 'PRIMARY' OR @CurrentAvailabilityGroupRole IS NULL))
    AND NOT (@CurrentAvailabilityGroup IS NOT NULL AND @CurrentBackupType = 'FULL' AND @CopyOnly = 'Y' AND (@CurrentIsPreferredBackupReplica <> 1 OR @CurrentIsPreferredBackupReplica IS NULL))
    AND NOT (@CurrentAvailabilityGroup IS NOT NULL AND @CurrentBackupType = 'DIFF' AND (@CurrentAvailabilityGroupRole <> 'PRIMARY' OR @CurrentAvailabilityGroupRole IS NULL))
    AND NOT (@CurrentAvailabilityGroup IS NOT NULL AND @CurrentBackupType = 'LOG' AND @CopyOnly = 'N' AND (@CurrentIsPreferredBackupReplica <> 1 OR @CurrentIsPreferredBackupReplica IS NULL))
    AND NOT (@CurrentAvailabilityGroup IS NOT NULL AND @CurrentBackupType = 'LOG' AND @CopyOnly = 'Y' AND (@CurrentAvailabilityGroupRole <> 'PRIMARY' OR @CurrentAvailabilityGroupRole IS NULL))
    AND NOT ((@CurrentLogShippingRole = 'PRIMARY' AND @CurrentLogShippingRole IS NOT NULL) AND @CurrentBackupType = 'LOG')
    BEGIN

      -- Set variables
      SET @CurrentDate = GETDATE()

      IF @CleanupTime IS NULL OR (@CurrentBackupType = 'LOG' AND @CurrentLatestBackup IS NULL) OR @CurrentBackupType <> @BackupType
      BEGIN
        SET @CurrentCleanupDate = NULL
      END
      ELSE
      IF @CurrentBackupType = 'LOG'
      BEGIN
        SET @CurrentCleanupDate = (SELECT MIN([Date]) FROM(SELECT DATEADD(hh,-(@CleanupTime),@CurrentDate) AS [Date] UNION SELECT @CurrentLatestBackup AS [Date]) Dates)
      END
      ELSE
      BEGIN
        SET @CurrentCleanupDate = DATEADD(hh,-(@CleanupTime),@CurrentDate)
      END

      SELECT @CurrentFileExtension = CASE
      WHEN @BackupSoftware IS NULL AND @CurrentBackupType = 'FULL' THEN 'bak'
      WHEN @BackupSoftware IS NULL AND @CurrentBackupType = 'DIFF' THEN 'bak'
      WHEN @BackupSoftware IS NULL AND @CurrentBackupType = 'LOG' THEN 'trn'
      WHEN @BackupSoftware = 'LITESPEED' AND @CurrentBackupType = 'FULL' THEN 'bak'
      WHEN @BackupSoftware = 'LITESPEED' AND @CurrentBackupType = 'DIFF' THEN 'bak'
      WHEN @BackupSoftware = 'LITESPEED' AND @CurrentBackupType = 'LOG' THEN 'trn'
      WHEN @BackupSoftware = 'SQLBACKUP' AND @CurrentBackupType = 'FULL' THEN 'sqb'
      WHEN @BackupSoftware = 'SQLBACKUP' AND @CurrentBackupType = 'DIFF' THEN 'sqb'
      WHEN @BackupSoftware = 'SQLBACKUP' AND @CurrentBackupType = 'LOG' THEN 'sqb'
      WHEN @BackupSoftware = 'HYPERBAC' AND @CurrentBackupType = 'FULL' AND @Encrypt = 'N' THEN 'hbc'
      WHEN @BackupSoftware = 'HYPERBAC' AND @CurrentBackupType = 'DIFF' AND @Encrypt = 'N' THEN 'hbc'
      WHEN @BackupSoftware = 'HYPERBAC' AND @CurrentBackupType = 'LOG' AND @Encrypt = 'N' THEN 'hbc'
      WHEN @BackupSoftware = 'HYPERBAC' AND @CurrentBackupType = 'FULL' AND @Encrypt = 'Y' THEN 'hbe'
      WHEN @BackupSoftware = 'HYPERBAC' AND @CurrentBackupType = 'DIFF' AND @Encrypt = 'Y' THEN 'hbe'
      WHEN @BackupSoftware = 'HYPERBAC' AND @CurrentBackupType = 'LOG' AND @Encrypt = 'Y' THEN 'hbe'
      WHEN @BackupSoftware = 'SQLSAFE' AND @CurrentBackupType = 'FULL' THEN 'safe'
      WHEN @BackupSoftware = 'SQLSAFE' AND @CurrentBackupType = 'DIFF' THEN 'safe'
      WHEN @BackupSoftware = 'SQLSAFE' AND @CurrentBackupType = 'LOG' THEN 'safe'
      END

      INSERT INTO @CurrentDirectories (ID, DirectoryPath, CreateCompleted, CleanupCompleted)
      SELECT ROW_NUMBER() OVER (ORDER BY ID), DirectoryPath + CASE WHEN RIGHT(DirectoryPath,1) = '\' THEN '' ELSE '\' END + CASE WHEN @CurrentAvailabilityGroup IS NOT NULL THEN @Cluster + '$' + @CurrentAvailabilityGroup ELSE REPLACE(CAST(SERVERPROPERTY('servername') AS nvarchar),'\','$') END + '\' + @CurrentDatabaseNameFS + '\' + UPPER(@CurrentBackupType) + CASE WHEN @ReadWriteFileGroups = 'Y' THEN '_PARTIAL' ELSE '' END + CASE WHEN @CopyOnly = 'Y' THEN '_COPY_ONLY' ELSE '' END, 0, 0
      FROM @Directories
      ORDER BY ID ASC

      SET @CurrentFileNumber = 0

      WHILE @CurrentFileNumber < @NumberOfFiles
      BEGIN
        SET @CurrentFileNumber = @CurrentFileNumber + 1

        SELECT @CurrentDirectoryPath = DirectoryPath
        FROM @CurrentDirectories
        WHERE @CurrentFileNumber >= (ID - 1) * (SELECT @NumberOfFiles / COUNT(*) FROM @CurrentDirectories) + 1
        AND @CurrentFileNumber <= ID * (SELECT @NumberOfFiles / COUNT(*) FROM @CurrentDirectories)

        SET @CurrentFilePath = @CurrentDirectoryPath + '\' + CASE WHEN @CurrentAvailabilityGroup IS NOT NULL THEN @Cluster + '$' + @CurrentAvailabilityGroup ELSE REPLACE(CAST(SERVERPROPERTY('servername') AS nvarchar),'\','$') END + '_' + @CurrentDatabaseNameFS + '_' + UPPER(@CurrentBackupType) + CASE WHEN @ReadWriteFileGroups = 'Y' THEN '_PARTIAL' ELSE '' END + CASE WHEN @CopyOnly = 'Y' THEN '_COPY_ONLY' ELSE '' END + '_' + REPLACE(REPLACE(REPLACE((CONVERT(nvarchar,@CurrentDate,120)),'-',''),' ','_'),':','') + CASE WHEN @NumberOfFiles > 1 AND @NumberOfFiles <= 9 THEN '_' + CAST(@CurrentFileNumber AS nvarchar) WHEN @NumberOfFiles >= 10 THEN '_' + RIGHT('0' + CAST(@CurrentFileNumber AS nvarchar),2) ELSE '' END + '.' + @CurrentFileExtension

        IF LEN(@CurrentFilePath) > 259
        BEGIN
          SET @CurrentFilePath = @CurrentDirectoryPath + '\' + CASE WHEN @CurrentAvailabilityGroup IS NOT NULL THEN @Cluster + '$' + @CurrentAvailabilityGroup ELSE REPLACE(CAST(SERVERPROPERTY('servername') AS nvarchar),'\','$') END + '_' + LEFT(@CurrentDatabaseNameFS,CASE WHEN (LEN(@CurrentDatabaseNameFS) + 259 - LEN(@CurrentFilePath) - 3) < 20 THEN 20 ELSE (LEN(@CurrentDatabaseNameFS) + 259 - LEN(@CurrentFilePath) - 3) END) + '...' + '_' + UPPER(@CurrentBackupType) + CASE WHEN @ReadWriteFileGroups = 'Y' THEN '_PARTIAL' ELSE '' END + CASE WHEN @CopyOnly = 'Y' THEN '_COPY_ONLY' ELSE '' END + '_' + REPLACE(REPLACE(REPLACE((CONVERT(nvarchar,@CurrentDate,120)),'-',''),' ','_'),':','') + CASE WHEN @NumberOfFiles > 1 AND @NumberOfFiles <= 9 THEN '_' + CAST(@CurrentFileNumber AS nvarchar) WHEN @NumberOfFiles >= 10 THEN '_' + RIGHT('0' + CAST(@CurrentFileNumber AS nvarchar),2) ELSE '' END + '.' + @CurrentFileExtension
        END

        INSERT INTO @CurrentFiles (CurrentFilePath)
        SELECT @CurrentFilePath

        SET @CurrentDirectoryPath = NULL
        SET @CurrentFilePath = NULL
      END

      -- Create directory
      WHILE EXISTS (SELECT * FROM @CurrentDirectories WHERE CreateCompleted = 0)
      BEGIN
        SELECT TOP 1 @CurrentDirectoryID = ID,
                     @CurrentDirectoryPath = DirectoryPath
        FROM @CurrentDirectories
        WHERE CreateCompleted = 0
        ORDER BY ID ASC

        SET @CurrentCommandType01 = 'xp_create_subdir'
        SET @CurrentCommand01 = 'DECLARE @ReturnCode int EXECUTE @ReturnCode = [master].dbo.xp_create_subdir N''' + REPLACE(@CurrentDirectoryPath,'''','''''') + ''' IF @ReturnCode <> 0 RAISERROR(''Error creating directory.'', 16, 1)'
        EXECUTE @CurrentCommandOutput01 = [dbo].[CommandExecute] @Command = @CurrentCommand01, @CommandType = @CurrentCommandType01, @Mode = 1, @DatabaseName = @CurrentDatabaseName, @LogToTable = @LogToTable, @Execute = @Execute
        SET @Error = @@ERROR
        IF @Error <> 0 SET @CurrentCommandOutput01 = @Error
        IF @CurrentCommandOutput01 <> 0 SET @ReturnCode = @CurrentCommandOutput01

        UPDATE @CurrentDirectories
        SET CreateCompleted = 1,
            CreateOutput = @CurrentCommandOutput01
        WHERE ID = @CurrentDirectoryID

        SET @CurrentDirectoryID = NULL
        SET @CurrentDirectoryPath = NULL

        SET @CurrentCommand01 = NULL

        SET @CurrentCommandOutput01 = NULL

        SET @CurrentCommandType01 = NULL
      END

      -- Perform a backup
      IF NOT EXISTS (SELECT * FROM @CurrentDirectories WHERE CreateOutput <> 0 OR CreateOutput IS NULL)
      BEGIN
        IF @BackupSoftware IS NULL
        BEGIN
          SELECT @CurrentCommandType02 = CASE
          WHEN @CurrentBackupType IN('DIFF','FULL') THEN 'BACKUP_DATABASE'
          WHEN @CurrentBackupType = 'LOG' THEN 'BACKUP_LOG'
          END

          SELECT @CurrentCommand02 = CASE
          WHEN @CurrentBackupType IN('DIFF','FULL') THEN 'BACKUP DATABASE ' + QUOTENAME(@CurrentDatabaseName)
          WHEN @CurrentBackupType = 'LOG' THEN 'BACKUP LOG ' + QUOTENAME(@CurrentDatabaseName)
          END

          IF @ReadWriteFileGroups = 'Y' SET @CurrentCommand02 = @CurrentCommand02 + ' READ_WRITE_FILEGROUPS'

          SET @CurrentCommand02 = @CurrentCommand02 + ' TO'

          SELECT @CurrentCommand02 = @CurrentCommand02 + ' DISK = N''' + REPLACE(CurrentFilePath,'''','''''') + '''' + CASE WHEN ROW_NUMBER() OVER (ORDER BY CurrentFilePath ASC) <> @NumberOfFiles THEN ',' ELSE '' END
          FROM @CurrentFiles
          ORDER BY CurrentFilePath ASC

          SET @CurrentCommand02 = @CurrentCommand02 + ' WITH '
          IF @CheckSum = 'Y' SET @CurrentCommand02 = @CurrentCommand02 + 'CHECKSUM'
          IF @CheckSum = 'N' SET @CurrentCommand02 = @CurrentCommand02 + 'NO_CHECKSUM'
          IF @Compress = 'Y' SET @CurrentCommand02 = @CurrentCommand02 + ', COMPRESSION'
          IF @Compress = 'N' AND @Version >= 10 SET @CurrentCommand02 = @CurrentCommand02 + ', NO_COMPRESSION'
          IF @CurrentBackupType = 'DIFF' SET @CurrentCommand02 = @CurrentCommand02 + ', DIFFERENTIAL'
          IF @CopyOnly = 'Y' SET @CurrentCommand02 = @CurrentCommand02 + ', COPY_ONLY'
          IF @BlockSize IS NOT NULL SET @CurrentCommand02 = @CurrentCommand02 + ', BLOCKSIZE = ' + CAST(@BlockSize AS nvarchar)
          IF @BufferCount IS NOT NULL SET @CurrentCommand02 = @CurrentCommand02 + ', BUFFERCOUNT = ' + CAST(@BufferCount AS nvarchar)
          IF @MaxTransferSize IS NOT NULL SET @CurrentCommand02 = @CurrentCommand02 + ', MAXTRANSFERSIZE = ' + CAST(@MaxTransferSize AS nvarchar)
          IF @Description IS NOT NULL SET @CurrentCommand02 = @CurrentCommand02 + ', DESCRIPTION = N''' + REPLACE(@Description,'''','''''') + ''''
        END

        IF @BackupSoftware = 'LITESPEED'
        BEGIN
          SELECT @CurrentCommandType02 = CASE
          WHEN @CurrentBackupType IN('DIFF','FULL') THEN 'xp_backup_database'
          WHEN @CurrentBackupType = 'LOG' THEN 'xp_backup_log'
          END

          SELECT @CurrentCommand02 = CASE
          WHEN @CurrentBackupType IN('DIFF','FULL') THEN 'DECLARE @ReturnCode int EXECUTE @ReturnCode = [master].dbo.xp_backup_database @database = N''' + REPLACE(@CurrentDatabaseName,'''','''''') + ''''
          WHEN @CurrentBackupType = 'LOG' THEN 'DECLARE @ReturnCode int EXECUTE @ReturnCode = [master].dbo.xp_backup_log @database = N''' + REPLACE(@CurrentDatabaseName,'''','''''') + ''''
          END

          SELECT @CurrentCommand02 = @CurrentCommand02 + ', @filename = N''' + REPLACE(CurrentFilePath,'''','''''') + ''''
          FROM @CurrentFiles
          ORDER BY CurrentFilePath ASC

          SET @CurrentCommand02 = @CurrentCommand02 + ', @with = '''
          IF @CheckSum = 'Y' SET @CurrentCommand02 = @CurrentCommand02 + 'CHECKSUM'
          IF @CheckSum = 'N' SET @CurrentCommand02 = @CurrentCommand02 + 'NO_CHECKSUM'
          IF @CurrentBackupType = 'DIFF' SET @CurrentCommand02 = @CurrentCommand02 + ', DIFFERENTIAL'
          IF @CopyOnly = 'Y' SET @CurrentCommand02 = @CurrentCommand02 + ', COPY_ONLY'
          IF @BlockSize IS NOT NULL SET @CurrentCommand02 = @CurrentCommand02 + ', BLOCKSIZE = ' + CAST(@BlockSize AS nvarchar)
          SET @CurrentCommand02 = @CurrentCommand02 + ''''
          IF @ReadWriteFileGroups = 'Y' SET @CurrentCommand02 = @CurrentCommand02 + ', @read_write_filegroups = 1'
          IF @CompressionLevel IS NOT NULL SET @CurrentCommand02 = @CurrentCommand02 + ', @compressionlevel = ' + CAST(@CompressionLevel AS nvarchar)
          IF @BufferCount IS NOT NULL SET @CurrentCommand02 = @CurrentCommand02 + ', @buffercount = ' + CAST(@BufferCount AS nvarchar)
          IF @MaxTransferSize IS NOT NULL SET @CurrentCommand02 = @CurrentCommand02 + ', @maxtransfersize = ' + CAST(@MaxTransferSize AS nvarchar)
          IF @Threads IS NOT NULL SET @CurrentCommand02 = @CurrentCommand02 + ', @threads = ' + CAST(@Threads AS nvarchar)
          IF @Throttle IS NOT NULL SET @CurrentCommand02 = @CurrentCommand02 + ', @throttle = ' + CAST(@Throttle AS nvarchar)
          IF @Description IS NOT NULL SET @CurrentCommand02 = @CurrentCommand02 + ', @desc = N''' + REPLACE(@Description,'''','''''') + ''''

          IF @EncryptionType IS NOT NULL SET @CurrentCommand02 = @CurrentCommand02 + ', @cryptlevel = ' + CASE
          WHEN @EncryptionType = 'RC2-40' THEN '0'
          WHEN @EncryptionType = 'RC2-56' THEN '1'
          WHEN @EncryptionType = 'RC2-112' THEN '2'
          WHEN @EncryptionType = 'RC2-128' THEN '3'
          WHEN @EncryptionType = '3DES-168' THEN '4'
          WHEN @EncryptionType = 'RC4-128' THEN '5'
          WHEN @EncryptionType = 'AES-128' THEN '6'
          WHEN @EncryptionType = 'AES-192' THEN '7'
          WHEN @EncryptionType = 'AES-256' THEN '8'
          END

          IF @EncryptionKey IS NOT NULL SET @CurrentCommand02 = @CurrentCommand02 + ', @encryptionkey = N''' + REPLACE(@EncryptionKey,'''','''''') + ''''
          SET @CurrentCommand02 = @CurrentCommand02 + ' IF @ReturnCode <> 0 RAISERROR(''Error performing LiteSpeed backup.'', 16, 1)'
        END

        IF @BackupSoftware = 'SQLBACKUP'
        BEGIN
          SET @CurrentCommandType02 = 'sqlbackup'

          SELECT @CurrentCommand02 = CASE
          WHEN @CurrentBackupType IN('DIFF','FULL') THEN 'BACKUP DATABASE ' + QUOTENAME(@CurrentDatabaseName)
          WHEN @CurrentBackupType = 'LOG' THEN 'BACKUP LOG ' + QUOTENAME(@CurrentDatabaseName)
          END

          IF @ReadWriteFileGroups = 'Y' SET @CurrentCommand02 = @CurrentCommand02 + ' READ_WRITE_FILEGROUPS'

          SET @CurrentCommand02 = @CurrentCommand02 + ' TO'

          SELECT @CurrentCommand02 = @CurrentCommand02 + ' DISK = N''' + REPLACE(CurrentFilePath,'''','''''') + '''' + CASE WHEN ROW_NUMBER() OVER (ORDER BY CurrentFilePath ASC) <> @NumberOfFiles THEN ',' ELSE '' END
          FROM @CurrentFiles
          ORDER BY CurrentFilePath ASC

          SET @CurrentCommand02 = @CurrentCommand02 + ' WITH '
          IF @CheckSum = 'Y' SET @CurrentCommand02 = @CurrentCommand02 + 'CHECKSUM'
          IF @CheckSum = 'N' SET @CurrentCommand02 = @CurrentCommand02 + 'NO_CHECKSUM'
          IF @CurrentBackupType = 'DIFF' SET @CurrentCommand02 = @CurrentCommand02 + ', DIFFERENTIAL'
          IF @CopyOnly = 'Y' SET @CurrentCommand02 = @CurrentCommand02 + ', COPY_ONLY'
          IF @CompressionLevel IS NOT NULL SET @CurrentCommand02 = @CurrentCommand02 + ', COMPRESSION = ' + CAST(@CompressionLevel AS nvarchar)
          IF @Threads IS NOT NULL SET @CurrentCommand02 = @CurrentCommand02 + ', THREADCOUNT = ' + CAST(@Threads AS nvarchar)
          IF @MaxTransferSize IS NOT NULL SET @CurrentCommand02 = @CurrentCommand02 + ', MAXTRANSFERSIZE = ' + CAST(@MaxTransferSize AS nvarchar)
          IF @Description IS NOT NULL SET @CurrentCommand02 = @CurrentCommand02 + ', DESCRIPTION = N''' + REPLACE(@Description,'''','''''') + ''''

          IF @EncryptionType IS NOT NULL SET @CurrentCommand02 = @CurrentCommand02 + ', KEYSIZE = ' + CASE
          WHEN @EncryptionType = 'AES-128' THEN '128'
          WHEN @EncryptionType = 'AES-256' THEN '256'
          END

          IF @EncryptionKey IS NOT NULL SET @CurrentCommand02 = @CurrentCommand02 + ', PASSWORD = N''' + REPLACE(@EncryptionKey,'''','''''') + ''''
          SET @CurrentCommand02 = 'DECLARE @ReturnCode int EXECUTE @ReturnCode = [master].dbo.sqlbackup N''-SQL "' + REPLACE(@CurrentCommand02,'''','''''') + '"''' + ' IF @ReturnCode <> 0 RAISERROR(''Error performing SQLBackup backup.'', 16, 1)'
        END

        IF @BackupSoftware = 'HYPERBAC'
        BEGIN
          SET @CurrentCommandType02 = 'BACKUP_DATABASE'

          SELECT @CurrentCommand02 = CASE
          WHEN @CurrentBackupType IN('DIFF','FULL') THEN 'BACKUP DATABASE ' + QUOTENAME(@CurrentDatabaseName)
          WHEN @CurrentBackupType = 'LOG' THEN 'BACKUP LOG ' + QUOTENAME(@CurrentDatabaseName)
          END

          IF @ReadWriteFileGroups = 'Y' SET @CurrentCommand02 = @CurrentCommand02 + ' READ_WRITE_FILEGROUPS'

          SET @CurrentCommand02 = @CurrentCommand02 + ' TO'

          SELECT @CurrentCommand02 = @CurrentCommand02 + ' DISK = N''' + REPLACE(CurrentFilePath,'''','''''') + '''' + CASE WHEN ROW_NUMBER() OVER (ORDER BY CurrentFilePath ASC) <> @NumberOfFiles THEN ',' ELSE '' END
          FROM @CurrentFiles
          ORDER BY CurrentFilePath ASC

          SET @CurrentCommand02 = @CurrentCommand02 + ' WITH '
          IF @CheckSum = 'Y' SET @CurrentCommand02 = @CurrentCommand02 + 'CHECKSUM'
          IF @CheckSum = 'N' SET @CurrentCommand02 = @CurrentCommand02 + 'NO_CHECKSUM'
          IF @CurrentBackupType = 'DIFF' SET @CurrentCommand02 = @CurrentCommand02 + ', DIFFERENTIAL'
          IF @CopyOnly = 'Y' SET @CurrentCommand02 = @CurrentCommand02 + ', COPY_ONLY'
          IF @BlockSize IS NOT NULL SET @CurrentCommand02 = @CurrentCommand02 + ', BLOCKSIZE = ' + CAST(@BlockSize AS nvarchar)
          IF @BufferCount IS NOT NULL SET @CurrentCommand02 = @CurrentCommand02 + ', BUFFERCOUNT = ' + CAST(@BufferCount AS nvarchar)
          IF @MaxTransferSize IS NOT NULL SET @CurrentCommand02 = @CurrentCommand02 + ', MAXTRANSFERSIZE = ' + CAST(@MaxTransferSize AS nvarchar)
          IF @Description IS NOT NULL SET @CurrentCommand02 = @CurrentCommand02 + ', DESCRIPTION = N''' + REPLACE(@Description,'''','''''') + ''''
        END

        IF @BackupSoftware = 'SQLSAFE'
        BEGIN
          SET @CurrentCommandType02 = 'xp_ss_backup'

          SET @CurrentCommand02 = 'DECLARE @ReturnCode int EXECUTE @ReturnCode = [master].dbo.xp_ss_backup @database = N''' + REPLACE(@CurrentDatabaseName,'''','''''') + ''''

          SELECT @CurrentCommand02 = @CurrentCommand02 + ', ' + CASE WHEN ROW_NUMBER() OVER (ORDER BY CurrentFilePath ASC) = 1 THEN '@filename' ELSE '@backupfile' END + ' = N''' + REPLACE(CurrentFilePath,'''','''''') + ''''
          FROM @CurrentFiles
          ORDER BY CurrentFilePath ASC

          SET @CurrentCommand02 = @CurrentCommand02 + ', @backuptype = ' + CASE WHEN @CurrentBackupType = 'FULL' THEN '''Full''' WHEN @CurrentBackupType = 'DIFF' THEN '''Differential''' WHEN @CurrentBackupType = 'LOG' THEN '''Log''' END
          IF @ReadWriteFileGroups = 'Y' SET @CurrentCommand02 = @CurrentCommand02 + ', @readwritefilegroups = 1'
          SET @CurrentCommand02 = @CurrentCommand02 + ', @checksum = ' + CASE WHEN @CheckSum = 'Y' THEN '1' WHEN @CheckSum = 'N' THEN '0' END
          SET @CurrentCommand02 = @CurrentCommand02 + ', @copyonly = ' + CASE WHEN @CopyOnly = 'Y' THEN '1' WHEN @CopyOnly = 'N' THEN '0' END
          IF @CompressionLevel IS NOT NULL SET @CurrentCommand02 = @CurrentCommand02 + ', @compressionlevel = ' + CAST(@CompressionLevel AS nvarchar)
          IF @Threads IS NOT NULL SET @CurrentCommand02 = @CurrentCommand02 + ', @threads = ' + CAST(@Threads AS nvarchar)
          IF @Description IS NOT NULL SET @CurrentCommand02 = @CurrentCommand02 + ', @desc = N''' + REPLACE(@Description,'''','''''') + ''''

          IF @EncryptionType IS NOT NULL SET @CurrentCommand02 = @CurrentCommand02 + ', @encryptiontype = N''' + CASE
          WHEN @EncryptionType = 'AES-128' THEN 'AES128'
          WHEN @EncryptionType = 'AES-256' THEN 'AES256'
          END + ''''

          IF @EncryptionKey IS NOT NULL SET @CurrentCommand02 = @CurrentCommand02 + ', @encryptedbackuppassword = N''' + REPLACE(@EncryptionKey,'''','''''') + ''''
          SET @CurrentCommand02 = @CurrentCommand02 + ' IF @ReturnCode <> 0 RAISERROR(''Error performing SQLsafe backup.'', 16, 1)'
        END

        EXECUTE @CurrentCommandOutput02 = [dbo].[CommandExecute] @Command = @CurrentCommand02, @CommandType = @CurrentCommandType02, @Mode = 1, @DatabaseName = @CurrentDatabaseName, @LogToTable = @LogToTable, @Execute = @Execute
        SET @Error = @@ERROR
        IF @Error <> 0 SET @CurrentCommandOutput02 = @Error
        IF @CurrentCommandOutput02 <> 0 SET @ReturnCode = @CurrentCommandOutput02
      END

      -- Verify the backup
      IF @CurrentCommandOutput02 = 0 AND @Verify = 'Y'
      BEGIN
        IF @BackupSoftware IS NULL
        BEGIN
          SET @CurrentCommandType03 = 'RESTORE_VERIFYONLY'

          SET @CurrentCommand03 = 'RESTORE VERIFYONLY FROM'

          SELECT @CurrentCommand03 = @CurrentCommand03 + ' DISK = N''' + REPLACE(CurrentFilePath,'''','''''') + '''' + CASE WHEN ROW_NUMBER() OVER (ORDER BY CurrentFilePath ASC) <> @NumberOfFiles THEN ',' ELSE '' END
          FROM @CurrentFiles
          ORDER BY CurrentFilePath ASC

          SET @CurrentCommand03 = @CurrentCommand03 + ' WITH '
          IF @CheckSum = 'Y' SET @CurrentCommand03 = @CurrentCommand03 + 'CHECKSUM'
          IF @CheckSum = 'N' SET @CurrentCommand03 = @CurrentCommand03 + 'NO_CHECKSUM'
        END

        IF @BackupSoftware = 'LITESPEED'
        BEGIN
          SET @CurrentCommandType03 = 'xp_restore_verifyonly'

          SET @CurrentCommand03 = 'DECLARE @ReturnCode int EXECUTE @ReturnCode = [master].dbo.xp_restore_verifyonly'

          SELECT @CurrentCommand03 = @CurrentCommand03 + ' @filename = N''' + REPLACE(CurrentFilePath,'''','''''') + '''' + CASE WHEN ROW_NUMBER() OVER (ORDER BY CurrentFilePath ASC) <> @NumberOfFiles THEN ',' ELSE '' END
          FROM @CurrentFiles
          ORDER BY CurrentFilePath ASC

          SET @CurrentCommand03 = @CurrentCommand03 + ', @with = '''
          IF @CheckSum = 'Y' SET @CurrentCommand03 = @CurrentCommand03 + 'CHECKSUM'
          IF @CheckSum = 'N' SET @CurrentCommand03 = @CurrentCommand03 + 'NO_CHECKSUM'
          SET @CurrentCommand03 = @CurrentCommand03 + ''''
          IF @EncryptionKey IS NOT NULL SET @CurrentCommand03 = @CurrentCommand03 + ', @encryptionkey = N''' + REPLACE(@EncryptionKey,'''','''''') + ''''

          SET @CurrentCommand03 = @CurrentCommand03 + ' IF @ReturnCode <> 0 RAISERROR(''Error verifying LiteSpeed backup.'', 16, 1)'
        END

        IF @BackupSoftware = 'SQLBACKUP'
        BEGIN
          SET @CurrentCommandType03 = 'sqlbackup'

          SET @CurrentCommand03 = 'RESTORE VERIFYONLY FROM'

          SELECT @CurrentCommand03 = @CurrentCommand03 + ' DISK = N''' + REPLACE(CurrentFilePath,'''','''''') + '''' + CASE WHEN ROW_NUMBER() OVER (ORDER BY CurrentFilePath ASC) <> @NumberOfFiles THEN ',' ELSE '' END
          FROM @CurrentFiles
          ORDER BY CurrentFilePath ASC

          SET @CurrentCommand03 = @CurrentCommand03 + ' WITH '
          IF @CheckSum = 'Y' SET @CurrentCommand03 = @CurrentCommand03 + 'CHECKSUM'
          IF @CheckSum = 'N' SET @CurrentCommand03 = @CurrentCommand03 + 'NO_CHECKSUM'
          IF @EncryptionKey IS NOT NULL SET @CurrentCommand03 = @CurrentCommand03 + ', PASSWORD = N''' + REPLACE(@EncryptionKey,'''','''''') + ''''

          SET @CurrentCommand03 = 'DECLARE @ReturnCode int EXECUTE @ReturnCode = [master].dbo.sqlbackup N''-SQL "' + REPLACE(@CurrentCommand03,'''','''''') + '"''' + ' IF @ReturnCode <> 0 RAISERROR(''Error verifying SQLBackup backup.'', 16, 1)'
        END

        IF @BackupSoftware = 'HYPERBAC'
        BEGIN
          SET @CurrentCommandType03 = 'RESTORE_VERIFYONLY'

          SET @CurrentCommand03 = 'RESTORE VERIFYONLY FROM'

          SELECT @CurrentCommand03 = @CurrentCommand03 + ' DISK = N''' + REPLACE(CurrentFilePath,'''','''''') + '''' + CASE WHEN ROW_NUMBER() OVER (ORDER BY CurrentFilePath ASC) <> @NumberOfFiles THEN ',' ELSE '' END
          FROM @CurrentFiles
          ORDER BY CurrentFilePath ASC

          SET @CurrentCommand03 = @CurrentCommand03 + ' WITH '
          IF @CheckSum = 'Y' SET @CurrentCommand03 = @CurrentCommand03 + 'CHECKSUM'
          IF @CheckSum = 'N' SET @CurrentCommand03 = @CurrentCommand03 + 'NO_CHECKSUM'
        END

        IF @BackupSoftware = 'SQLSAFE'
        BEGIN
          SET @CurrentCommandType03 = 'xp_ss_verify'

          SET @CurrentCommand03 = 'DECLARE @ReturnCode int EXECUTE @ReturnCode = [master].dbo.xp_ss_verify @database = N''' + REPLACE(@CurrentDatabaseName,'''','''''') + ''''

          SELECT @CurrentCommand03 = @CurrentCommand03 + ', ' + CASE WHEN ROW_NUMBER() OVER (ORDER BY CurrentFilePath ASC) = 1 THEN '@filename' ELSE '@backupfile' END + ' = N''' + REPLACE(CurrentFilePath,'''','''''') + ''''
          FROM @CurrentFiles
          ORDER BY CurrentFilePath ASC

          SET @CurrentCommand03 = @CurrentCommand03 + ' IF @ReturnCode <> 0 RAISERROR(''Error verifying SQLsafe backup.'', 16, 1)'
        END

        EXECUTE @CurrentCommandOutput03 = [dbo].[CommandExecute] @Command = @CurrentCommand03, @CommandType = @CurrentCommandType03, @Mode = 1, @DatabaseName = @CurrentDatabaseName, @LogToTable = @LogToTable, @Execute = @Execute
        SET @Error = @@ERROR
        IF @Error <> 0 SET @CurrentCommandOutput03 = @Error
        IF @CurrentCommandOutput03 <> 0 SET @ReturnCode = @CurrentCommandOutput03
      END

      -- Delete old backup files
      IF (@CurrentCommandOutput02 = 0 AND @Verify = 'N' AND @CurrentCleanupDate IS NOT NULL)
      OR (@CurrentCommandOutput02 = 0 AND @Verify = 'Y' AND @CurrentCommandOutput03 = 0 AND @CurrentCleanupDate IS NOT NULL)
      BEGIN
        WHILE EXISTS (SELECT * FROM @CurrentDirectories WHERE CleanupCompleted = 0)
        BEGIN
          SELECT TOP 1 @CurrentDirectoryID = ID,
                       @CurrentDirectoryPath = DirectoryPath
          FROM @CurrentDirectories
          WHERE CleanupCompleted = 0
          ORDER BY ID ASC

          IF @BackupSoftware IS NULL
          BEGIN
            SET @CurrentCommandType04 = 'xp_delete_file'

            SET @CurrentCommand04 = 'DECLARE @ReturnCode int EXECUTE @ReturnCode = [master].dbo.xp_delete_file 0, N''' + REPLACE(@CurrentDirectoryPath,'''','''''') + ''', ''' + @CurrentFileExtension + ''', ''' + CONVERT(nvarchar(19),@CurrentCleanupDate,126) + ''' IF @ReturnCode <> 0 RAISERROR(''Error deleting files.'', 16, 1)'
          END

          IF @BackupSoftware = 'LITESPEED'
          BEGIN
            SET @CurrentCommandType04 = 'xp_slssqlmaint'

            SET @CurrentCommand04 = 'DECLARE @ReturnCode int EXECUTE @ReturnCode = [master].dbo.xp_slssqlmaint N''-MAINTDEL -DELFOLDER "' + REPLACE(@CurrentDirectoryPath,'''','''''') + '" -DELEXTENSION "' + @CurrentFileExtension + '" -DELUNIT "' + CAST(DATEDIFF(mi,@CurrentCleanupDate,GETDATE()) + 1 AS nvarchar) + '" -DELUNITTYPE "minutes" -DELUSEAGE'' IF @ReturnCode <> 0 RAISERROR(''Error deleting LiteSpeed backup files.'', 16, 1)'
          END

          IF @BackupSoftware = 'SQLBACKUP'
          BEGIN
            SET @CurrentCommandType04 = 'sqbutility'

            SET @CurrentCommand04 = 'DECLARE @ReturnCode int EXECUTE @ReturnCode = [master].dbo.sqbutility 1032, N''' + REPLACE(@CurrentDatabaseName,'''','''''') + ''', N''' + REPLACE(@CurrentDirectoryPath,'''','''''') + ''', ''' + CASE WHEN @CurrentBackupType = 'FULL' THEN 'D' WHEN @CurrentBackupType = 'DIFF' THEN 'I' WHEN @CurrentBackupType = 'LOG' THEN 'L' END + ''', ''' + CAST(DATEDIFF(hh,@CurrentCleanupDate,GETDATE()) + 1 AS nvarchar) + 'h'', ' + ISNULL('''' + REPLACE(@EncryptionKey,'''','''''') + '''','NULL') + ' IF @ReturnCode <> 0 RAISERROR(''Error deleting SQLBackup backup files.'', 16, 1)'
          END

          IF @BackupSoftware = 'HYPERBAC'
          BEGIN
            SET @CurrentCommandType04 = 'xp_delete_file'

            SET @CurrentCommand04 = 'DECLARE @ReturnCode int EXECUTE @ReturnCode = [master].dbo.xp_delete_file 0, N''' + REPLACE(@CurrentDirectoryPath,'''','''''') + ''', ''' + @CurrentFileExtension + ''', ''' + CONVERT(nvarchar(19),@CurrentCleanupDate,126) + ''' IF @ReturnCode <> 0 RAISERROR(''Error deleting files.'', 16, 1)'
          END

          IF @BackupSoftware = 'SQLSAFE'
          BEGIN
            SET @CurrentCommandType04 = 'xp_ss_delete'

            SET @CurrentCommand04 = 'DECLARE @ReturnCode int EXECUTE @ReturnCode = [master].dbo.xp_ss_delete @filename = N''' + REPLACE(@CurrentDirectoryPath,'''','''''') + '\*.' + @CurrentFileExtension + ''', @age = ''' + CAST(DATEDIFF(mi,@CurrentCleanupDate,GETDATE()) + 1 AS nvarchar) + 'Minutes'' IF @ReturnCode <> 0 RAISERROR(''Error deleting SQLsafe backup files.'', 16, 1)'
          END

          EXECUTE @CurrentCommandOutput04 = [dbo].[CommandExecute] @Command = @CurrentCommand04, @CommandType = @CurrentCommandType04, @Mode = 1, @DatabaseName = @CurrentDatabaseName, @LogToTable = @LogToTable, @Execute = @Execute
          SET @Error = @@ERROR
          IF @Error <> 0 SET @CurrentCommandOutput04 = @Error
          IF @CurrentCommandOutput04 <> 0 SET @ReturnCode = @CurrentCommandOutput04

          UPDATE @CurrentDirectories
          SET CleanupCompleted = 1,
              CleanupOutput = @CurrentCommandOutput04
          WHERE ID = @CurrentDirectoryID

          SET @CurrentDirectoryID = NULL
          SET @CurrentDirectoryPath = NULL

          SET @CurrentCommand04 = NULL

          SET @CurrentCommandOutput04 = NULL

          SET @CurrentCommandType04 = NULL
        END
      END
    END

    -- Update that the database is completed
    UPDATE @tmpDatabases
    SET Completed = 1
    WHERE Selected = 1
    AND Completed = 0
    AND ID = @CurrentDBID

    -- Clear variables
    SET @CurrentDBID = NULL
    SET @CurrentDatabaseID = NULL
    SET @CurrentDatabaseName = NULL
    SET @CurrentBackupType = NULL
    SET @CurrentFileExtension = NULL
    SET @CurrentFileNumber = NULL
    SET @CurrentDifferentialBaseLSN = NULL
    SET @CurrentDifferentialBaseIsSnapshot = NULL
    SET @CurrentLogLSN = NULL
    SET @CurrentLatestBackup = NULL
    SET @CurrentDatabaseNameFS = NULL
    SET @CurrentDate = NULL
    SET @CurrentCleanupDate = NULL
    SET @CurrentIsDatabaseAccessible = NULL
    SET @CurrentAvailabilityGroup = NULL
    SET @CurrentAvailabilityGroupRole = NULL
    SET @CurrentIsPreferredBackupReplica = NULL
    SET @CurrentDatabaseMirroringRole = NULL
    SET @CurrentLogShippingRole = NULL

    SET @CurrentCommand02 = NULL
    SET @CurrentCommand03 = NULL

    SET @CurrentCommandOutput02 = NULL
    SET @CurrentCommandOutput03 = NULL

    SET @CurrentCommandType02 = NULL
    SET @CurrentCommandType03 = NULL

    DELETE FROM @CurrentDirectories
    DELETE FROM @CurrentFiles

  END

  ----------------------------------------------------------------------------------------------------
  --// Log completing information                                                                 //--
  ----------------------------------------------------------------------------------------------------

  Logging:
  SET @EndMessage = 'Date and time: ' + CONVERT(nvarchar,GETDATE(),120)
  SET @EndMessage = REPLACE(@EndMessage,'%','%%')
  RAISERROR(@EndMessage,10,1) WITH NOWAIT

  IF @ReturnCode <> 0
  BEGIN
    RETURN @ReturnCode
  END

  ----------------------------------------------------------------------------------------------------

END



GO
/****** Object:  StoredProcedure [dbo].[DatabaseIntegrityCheck]    Script Date: 27/10/2015 09:31:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[DatabaseIntegrityCheck]

@Databases nvarchar(max),
@CheckCommands nvarchar(max) = 'CHECKDB',
@PhysicalOnly nvarchar(max) = 'N',
@NoIndex nvarchar(max) = 'N',
@ExtendedLogicalChecks nvarchar(max) = 'N',
@TabLock nvarchar(max) = 'N',
@FileGroups nvarchar(max) = NULL,
@Objects nvarchar(max) = NULL,
@LogToTable nvarchar(max) = 'N',
@Execute nvarchar(max) = 'Y'

AS

BEGIN

  ----------------------------------------------------------------------------------------------------
  --// Source: http://ola.hallengren.com                                                          //--
  ----------------------------------------------------------------------------------------------------

  SET NOCOUNT ON

  SET LOCK_TIMEOUT 3600000

  DECLARE @StartMessage nvarchar(max)
  DECLARE @EndMessage nvarchar(max)
  DECLARE @DatabaseMessage nvarchar(max)
  DECLARE @ErrorMessage nvarchar(max)

  DECLARE @Version numeric(18,10)

  DECLARE @Cluster nvarchar(max)

  DECLARE @CurrentDBID int
  DECLARE @CurrentDatabaseID int
  DECLARE @CurrentDatabaseName nvarchar(max)
  DECLARE @CurrentIsDatabaseAccessible bit
  DECLARE @CurrentAvailabilityGroup nvarchar(max)
  DECLARE @CurrentAvailabilityGroupRole nvarchar(max)
  DECLARE @CurrentDatabaseMirroringRole nvarchar(max)
  DECLARE @CurrentLogShippingRole nvarchar(max)

  DECLARE @CurrentFGID int
  DECLARE @CurrentFileGroupID int
  DECLARE @CurrentFileGroupName nvarchar(max)
  DECLARE @CurrentFileGroupExists bit

  DECLARE @CurrentOID int
  DECLARE @CurrentSchemaID int
  DECLARE @CurrentSchemaName nvarchar(max)
  DECLARE @CurrentObjectID int
  DECLARE @CurrentObjectName nvarchar(max)
  DECLARE @CurrentObjectType nvarchar(max)
  DECLARE @CurrentObjectExists bit

  DECLARE @CurrentCommand01 nvarchar(max)
  DECLARE @CurrentCommand02 nvarchar(max)
  DECLARE @CurrentCommand03 nvarchar(max)
  DECLARE @CurrentCommand04 nvarchar(max)
  DECLARE @CurrentCommand05 nvarchar(max)
  DECLARE @CurrentCommand06 nvarchar(max)
  DECLARE @CurrentCommand07 nvarchar(max)
  DECLARE @CurrentCommand08 nvarchar(max)
  DECLARE @CurrentCommand09 nvarchar(max)

  DECLARE @CurrentCommandOutput01 int
  DECLARE @CurrentCommandOutput04 int
  DECLARE @CurrentCommandOutput05 int
  DECLARE @CurrentCommandOutput08 int
  DECLARE @CurrentCommandOutput09 int

  DECLARE @CurrentCommandType01 nvarchar(max)
  DECLARE @CurrentCommandType04 nvarchar(max)
  DECLARE @CurrentCommandType05 nvarchar(max)
  DECLARE @CurrentCommandType08 nvarchar(max)
  DECLARE @CurrentCommandType09 nvarchar(max)

  DECLARE @tmpDatabases TABLE (ID int IDENTITY,
                               DatabaseName nvarchar(max),
                               DatabaseType nvarchar(max),
                               Selected bit,
                               Completed bit,
                               PRIMARY KEY(Selected, Completed, ID))

  DECLARE @tmpFileGroups TABLE (ID int IDENTITY,
                                FileGroupID int,
                                FileGroupName nvarchar(max),
                                Selected bit,
                                Completed bit,
                                PRIMARY KEY(Selected, Completed, ID))

  DECLARE @tmpObjects TABLE (ID int IDENTITY,
                             SchemaID int,
                             SchemaName nvarchar(max),
                             ObjectID int,
                             ObjectName nvarchar(max),
                             ObjectType nvarchar(max),
                             Selected bit,
                             Completed bit,
                             PRIMARY KEY(Selected, Completed, ID))

  DECLARE @SelectedDatabases TABLE (DatabaseName nvarchar(max),
                                    DatabaseType nvarchar(max),
                                    Selected bit)

  DECLARE @SelectedFileGroups TABLE (DatabaseName nvarchar(max),
                                     FileGroupName nvarchar(max),
                                     Selected bit)

  DECLARE @SelectedObjects TABLE (DatabaseName nvarchar(max),
                                  SchemaName nvarchar(max),
                                  ObjectName nvarchar(max),
                                  Selected bit)

  DECLARE @SelectedCheckCommands TABLE (CheckCommand nvarchar(max))

  DECLARE @Error int
  DECLARE @ReturnCode int

  SET @Error = 0
  SET @ReturnCode = 0

  SET @Version = CAST(LEFT(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max)),CHARINDEX('.',CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max))) - 1) + '.' + REPLACE(RIGHT(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max)), LEN(CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max))) - CHARINDEX('.',CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(max)))),'.','') AS numeric(18,10))

  ----------------------------------------------------------------------------------------------------
  --// Log initial information                                                                    //--
  ----------------------------------------------------------------------------------------------------

  SET @StartMessage = 'Date and time: ' + CONVERT(nvarchar,GETDATE(),120) + CHAR(13) + CHAR(10)
  SET @StartMessage = @StartMessage + 'Server: ' + CAST(SERVERPROPERTY('ServerName') AS nvarchar) + CHAR(13) + CHAR(10)
  SET @StartMessage = @StartMessage + 'Version: ' + CAST(SERVERPROPERTY('ProductVersion') AS nvarchar) + CHAR(13) + CHAR(10)
  SET @StartMessage = @StartMessage + 'Edition: ' + CAST(SERVERPROPERTY('Edition') AS nvarchar) + CHAR(13) + CHAR(10)
  SET @StartMessage = @StartMessage + 'Procedure: ' + QUOTENAME(DB_NAME(DB_ID())) + '.' + (SELECT QUOTENAME(schemas.name) FROM sys.schemas schemas INNER JOIN sys.objects objects ON schemas.[schema_id] = objects.[schema_id] WHERE [object_id] = @@PROCID) + '.' + QUOTENAME(OBJECT_NAME(@@PROCID)) + CHAR(13) + CHAR(10)
  SET @StartMessage = @StartMessage + 'Parameters: @Databases = ' + ISNULL('''' + REPLACE(@Databases,'''','''''') + '''','NULL')
  SET @StartMessage = @StartMessage + ', @CheckCommands = ' + ISNULL('''' + REPLACE(@CheckCommands,'''','''''') + '''','NULL')
  SET @StartMessage = @StartMessage + ', @PhysicalOnly = ' + ISNULL('''' + REPLACE(@PhysicalOnly,'''','''''') + '''','NULL')
  SET @StartMessage = @StartMessage + ', @NoIndex = ' + ISNULL('''' + REPLACE(@NoIndex,'''','''''') + '''','NULL')
  SET @StartMessage = @StartMessage + ', @ExtendedLogicalChecks = ' + ISNULL('''' + REPLACE(@ExtendedLogicalChecks,'''','''''') + '''','NULL')
  SET @StartMessage = @StartMessage + ', @TabLock = ' + ISNULL('''' + REPLACE(@TabLock,'''','''''') + '''','NULL')
  SET @StartMessage = @StartMessage + ', @FileGroups = ' + ISNULL('''' + REPLACE(@FileGroups,'''','''''') + '''','NULL')
  SET @StartMessage = @StartMessage + ', @Objects = ' + ISNULL('''' + REPLACE(@Objects,'''','''''') + '''','NULL')
  SET @StartMessage = @StartMessage + ', @LogToTable = ' + ISNULL('''' + REPLACE(@LogToTable,'''','''''') + '''','NULL')
  SET @StartMessage = @StartMessage + ', @Execute = ' + ISNULL('''' + REPLACE(@Execute,'''','''''') + '''','NULL') + CHAR(13) + CHAR(10)
  SET @StartMessage = @StartMessage + 'Source: http://ola.hallengren.com' + CHAR(13) + CHAR(10)
  SET @StartMessage = REPLACE(@StartMessage,'%','%%') + ' '
  RAISERROR(@StartMessage,10,1) WITH NOWAIT

  ----------------------------------------------------------------------------------------------------
  --// Check core requirements                                                                    //--
  ----------------------------------------------------------------------------------------------------

  IF NOT EXISTS (SELECT * FROM sys.objects objects INNER JOIN sys.schemas schemas ON objects.[schema_id] = schemas.[schema_id] WHERE objects.[type] = 'P' AND schemas.[name] = 'dbo' AND objects.[name] = 'CommandExecute')
  BEGIN
    SET @ErrorMessage = 'The stored procedure CommandExecute is missing. Download http://ola.hallengren.com/scripts/CommandExecute.sql.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF EXISTS (SELECT * FROM sys.objects objects INNER JOIN sys.schemas schemas ON objects.[schema_id] = schemas.[schema_id] WHERE objects.[type] = 'P' AND schemas.[name] = 'dbo' AND objects.[name] = 'CommandExecute' AND OBJECT_DEFINITION(objects.[object_id]) NOT LIKE '%@LogToTable%')
  BEGIN
    SET @ErrorMessage = 'The stored procedure CommandExecute needs to be updated. Download http://ola.hallengren.com/scripts/CommandExecute.sql.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF @LogToTable = 'Y' AND NOT EXISTS (SELECT * FROM sys.objects objects INNER JOIN sys.schemas schemas ON objects.[schema_id] = schemas.[schema_id] WHERE objects.[type] = 'U' AND schemas.[name] = 'dbo' AND objects.[name] = 'CommandLog')
  BEGIN
    SET @ErrorMessage = 'The table CommandLog is missing. Download http://ola.hallengren.com/scripts/CommandLog.sql.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF @Error <> 0
  BEGIN
    SET @ReturnCode = @Error
    GOTO Logging
  END;

  ----------------------------------------------------------------------------------------------------
  --// Select databases                                                                           //--
  ----------------------------------------------------------------------------------------------------

  WITH Databases1 (DatabaseItems) AS
  (
  SELECT REPLACE(@Databases, ', ', ',') AS DatabaseItems
  ),
  Databases2 (DatabaseItem, String, [Continue]) AS
  (
  SELECT CASE WHEN CHARINDEX(',', DatabaseItems) = 0 THEN @Databases ELSE SUBSTRING(DatabaseItems, 1, CHARINDEX(',', DatabaseItems) - 1) END AS DatabaseItem,
         CASE WHEN CHARINDEX(',', DatabaseItems) = 0 THEN '' ELSE SUBSTRING(DatabaseItems, CHARINDEX(',', DatabaseItems) + 1, LEN(DatabaseItems)) END AS String,
         CASE WHEN CHARINDEX(',', DatabaseItems) = 0 THEN 0 ELSE 1 END [Continue]
  FROM Databases1
  WHERE @Databases IS NOT NULL
  UNION ALL
  SELECT CASE WHEN CHARINDEX(',', String) = 0 THEN String ELSE SUBSTRING(String, 1, CHARINDEX(',', String) - 1) END AS DatabaseItem,
         CASE WHEN CHARINDEX(',', String) = 0 THEN '' ELSE SUBSTRING(String, CHARINDEX(',', String) + 1, LEN(String)) END AS String,
         CASE WHEN CHARINDEX(',', String) = 0 THEN 0 ELSE 1 END [Continue]
  FROM Databases2
  WHERE [Continue] = 1
  ),
  Databases3 (DatabaseItem, Selected) AS
  (
  SELECT CASE WHEN DatabaseItem LIKE '-%' THEN RIGHT(DatabaseItem,LEN(DatabaseItem) - 1) ELSE DatabaseItem END AS DatabaseItem,
         CASE WHEN DatabaseItem LIKE '-%' THEN 0 ELSE 1 END AS Selected
  FROM Databases2
  ),
  Databases4 (DatabaseItem, DatabaseType, Selected) AS
  (
  SELECT CASE WHEN DatabaseItem IN('ALL_DATABASES','SYSTEM_DATABASES','USER_DATABASES') THEN '%' ELSE DatabaseItem END AS DatabaseItem,
         CASE WHEN DatabaseItem = 'SYSTEM_DATABASES' THEN 'S' WHEN DatabaseItem = 'USER_DATABASES' THEN 'U' ELSE NULL END AS DatabaseType,
         Selected
  FROM Databases3
  ),
  Databases5 (DatabaseName, DatabaseType, Selected) AS
  (
  SELECT CASE WHEN LEFT(DatabaseItem,1) = '[' AND RIGHT(DatabaseItem,1) = ']' THEN PARSENAME(DatabaseItem,1) ELSE DatabaseItem END AS DatabaseItem,
         DatabaseType,
         Selected
  FROM Databases4
  )
  INSERT INTO @SelectedDatabases (DatabaseName, DatabaseType, Selected)
  SELECT DatabaseName,
         DatabaseType,
         Selected
  FROM Databases5

  INSERT INTO @tmpDatabases (DatabaseName, DatabaseType, Selected, Completed)
  SELECT [name] AS DatabaseName,
         CASE WHEN name IN('master','msdb','model') THEN 'S' ELSE 'U' END AS DatabaseType,
         0 AS Selected,
         0 AS Completed
  FROM sys.databases
  WHERE [name] <> 'tempdb'
  AND source_database_id IS NULL
  ORDER BY [name] ASC

  UPDATE tmpDatabases
  SET tmpDatabases.Selected = SelectedDatabases.Selected
  FROM @tmpDatabases tmpDatabases
  INNER JOIN @SelectedDatabases SelectedDatabases
  ON tmpDatabases.DatabaseName LIKE REPLACE(SelectedDatabases.DatabaseName,'_','[_]')
  AND (tmpDatabases.DatabaseType = SelectedDatabases.DatabaseType OR SelectedDatabases.DatabaseType IS NULL)
  WHERE SelectedDatabases.Selected = 1

  UPDATE tmpDatabases
  SET tmpDatabases.Selected = SelectedDatabases.Selected
  FROM @tmpDatabases tmpDatabases
  INNER JOIN @SelectedDatabases SelectedDatabases
  ON tmpDatabases.DatabaseName LIKE REPLACE(SelectedDatabases.DatabaseName,'_','[_]')
  AND (tmpDatabases.DatabaseType = SelectedDatabases.DatabaseType OR SelectedDatabases.DatabaseType IS NULL)
  WHERE SelectedDatabases.Selected = 0

  IF @Databases IS NULL OR NOT EXISTS(SELECT * FROM @SelectedDatabases) OR EXISTS(SELECT * FROM @SelectedDatabases WHERE DatabaseName IS NULL OR DatabaseName = '')
  BEGIN
    SET @ErrorMessage = 'The value for the parameter @Databases is not supported.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END;

  ----------------------------------------------------------------------------------------------------
  --// Select filegroups                                                                          //--
  ----------------------------------------------------------------------------------------------------

  WITH FileGroups1 (FileGroupItems) AS
  (
  SELECT REPLACE(@FileGroups, ', ', ',') AS FileGroupItems
  ),
  FileGroups2 (FileGroupItem, String, [Continue]) AS
  (
  SELECT CASE WHEN CHARINDEX(',', FileGroupItems) = 0 THEN @FileGroups ELSE SUBSTRING(FileGroupItems, 1, CHARINDEX(',', FileGroupItems) - 1) END AS FileGroupItem,
         CASE WHEN CHARINDEX(',', FileGroupItems) = 0 THEN '' ELSE SUBSTRING(FileGroupItems, CHARINDEX(',', FileGroupItems) + 1, LEN(FileGroupItems)) END AS String,
         CASE WHEN CHARINDEX(',', FileGroupItems) = 0 THEN 0 ELSE 1 END [Continue]
  FROM FileGroups1
  WHERE @FileGroups IS NOT NULL
  UNION ALL
  SELECT CASE WHEN CHARINDEX(',', String) = 0 THEN String ELSE SUBSTRING(String, 1, CHARINDEX(',', String) - 1) END AS FileGroupItem,
         CASE WHEN CHARINDEX(',', String) = 0 THEN '' ELSE SUBSTRING(String, CHARINDEX(',', String) + 1, LEN(String)) END AS String,
         CASE WHEN CHARINDEX(',', String) = 0 THEN 0 ELSE 1 END [Continue]
  FROM FileGroups2
  WHERE [Continue] = 1
  ),
  FileGroups3 (FileGroupItem, Selected) AS
  (
  SELECT CASE WHEN FileGroupItem LIKE '-%' THEN RIGHT(FileGroupItem,LEN(FileGroupItem) - 1) ELSE FileGroupItem END AS FileGroupItem,
         CASE WHEN FileGroupItem LIKE '-%' THEN 0 ELSE 1 END AS Selected
  FROM FileGroups2
  ),
  FileGroups4 (FileGroupItem, Selected) AS
  (
  SELECT CASE WHEN FileGroupItem = 'ALL_FILEGROUPS' THEN '%.%' ELSE FileGroupItem END AS FileGroupItem,
         Selected
  FROM FileGroups3
  ),
  FileGroups5 (DatabaseName, FileGroupName, Selected) AS
  (
  SELECT CASE WHEN PARSENAME(FileGroupItem,4) IS NULL AND PARSENAME(FileGroupItem,3) IS NULL THEN PARSENAME(FileGroupItem,2) ELSE NULL END AS DatabaseName,
         CASE WHEN PARSENAME(FileGroupItem,4) IS NULL AND PARSENAME(FileGroupItem,3) IS NULL THEN PARSENAME(FileGroupItem,1) ELSE NULL END AS FileGroupName,
         Selected
  FROM FileGroups4
  )
  INSERT INTO @SelectedFileGroups (DatabaseName, FileGroupName, Selected)
  SELECT DatabaseName, FileGroupName, Selected
  FROM FileGroups5;

  ----------------------------------------------------------------------------------------------------
  --// Select objects                                                                             //--
  ----------------------------------------------------------------------------------------------------

  WITH Objects1 (ObjectItems) AS
  (
  SELECT REPLACE(@Objects, ', ', ',') AS ObjectItems
  ),
  Objects2 (ObjectItem, String, [Continue]) AS
  (
  SELECT CASE WHEN CHARINDEX(',', ObjectItems) = 0 THEN @Objects ELSE SUBSTRING(ObjectItems, 1, CHARINDEX(',', ObjectItems) - 1) END AS ObjectItem,
         CASE WHEN CHARINDEX(',', ObjectItems) = 0 THEN '' ELSE SUBSTRING(ObjectItems, CHARINDEX(',', ObjectItems) + 1, LEN(ObjectItems)) END AS String,
         CASE WHEN CHARINDEX(',', ObjectItems) = 0 THEN 0 ELSE 1 END [Continue]
  FROM Objects1
  WHERE @Objects IS NOT NULL
  UNION ALL
  SELECT CASE WHEN CHARINDEX(',', String) = 0 THEN String ELSE SUBSTRING(String, 1, CHARINDEX(',', String) - 1) END AS ObjectItem,
         CASE WHEN CHARINDEX(',', String) = 0 THEN '' ELSE SUBSTRING(String, CHARINDEX(',', String) + 1, LEN(String)) END AS String,
         CASE WHEN CHARINDEX(',', String) = 0 THEN 0 ELSE 1 END [Continue]
  FROM Objects2
  WHERE [Continue] = 1
  ),
  Objects3 (ObjectItem, Selected) AS
  (
  SELECT CASE WHEN ObjectItem LIKE '-%' THEN RIGHT(ObjectItem,LEN(ObjectItem) - 1) ELSE ObjectItem END AS ObjectItem,
         CASE WHEN ObjectItem LIKE '-%' THEN 0 ELSE 1 END AS Selected
  FROM Objects2
  ),
  Objects4 (ObjectItem, Selected) AS
  (
  SELECT CASE WHEN ObjectItem = 'ALL_OBJECTS' THEN '%.%.%' ELSE ObjectItem END AS ObjectItem,
         Selected
  FROM Objects3
  ),
  Objects5 (DatabaseName, SchemaName, ObjectName, Selected) AS
  (
  SELECT CASE WHEN PARSENAME(ObjectItem,4) IS NULL THEN PARSENAME(ObjectItem,3) ELSE NULL END AS DatabaseName,
         CASE WHEN PARSENAME(ObjectItem,4) IS NULL THEN PARSENAME(ObjectItem,2) ELSE NULL END AS SchemaName,
         CASE WHEN PARSENAME(ObjectItem,4) IS NULL THEN PARSENAME(ObjectItem,1) ELSE NULL END AS ObjectName,
         Selected
  FROM Objects4
  )
  INSERT INTO @SelectedObjects (DatabaseName, SchemaName, ObjectName, Selected)
  SELECT DatabaseName, SchemaName, ObjectName, Selected
  FROM Objects5;

  ----------------------------------------------------------------------------------------------------
  --// Select check commands                                                                      //--
  ----------------------------------------------------------------------------------------------------

  WITH CheckCommands AS
  (
  SELECT CASE WHEN CHARINDEX(',', @CheckCommands) = 0 THEN @CheckCommands ELSE SUBSTRING(@CheckCommands, 1, CHARINDEX(',', @CheckCommands) - 1) END AS CheckCommand,
         CASE WHEN CHARINDEX(',', @CheckCommands) = 0 THEN '' ELSE SUBSTRING(@CheckCommands, CHARINDEX(',', @CheckCommands) + 1, LEN(@CheckCommands)) END AS String,
         CASE WHEN CHARINDEX(',', @CheckCommands) = 0 THEN 0 ELSE 1 END [Continue]
  WHERE @CheckCommands IS NOT NULL
  UNION ALL
  SELECT CASE WHEN CHARINDEX(',', String) = 0 THEN String ELSE SUBSTRING(String, 1, CHARINDEX(',', String) - 1) END AS CheckCommand,
         CASE WHEN CHARINDEX(',', String) = 0 THEN '' ELSE SUBSTRING(String, CHARINDEX(',', String) + 1, LEN(String)) END AS String,
         CASE WHEN CHARINDEX(',', String) = 0 THEN 0 ELSE 1 END [Continue]
  FROM CheckCommands
  WHERE [Continue] = 1
  )
  INSERT INTO @SelectedCheckCommands (CheckCommand)
  SELECT CheckCommand
  FROM CheckCommands

  ----------------------------------------------------------------------------------------------------
  --// Check input parameters                                                                     //--
  ----------------------------------------------------------------------------------------------------

  IF EXISTS (SELECT * FROM @SelectedCheckCommands WHERE CheckCommand NOT IN('CHECKDB','CHECKFILEGROUP','CHECKALLOC','CHECKTABLE','CHECKCATALOG')) OR EXISTS (SELECT * FROM @SelectedCheckCommands GROUP BY CheckCommand HAVING COUNT(*) > 1) OR NOT EXISTS (SELECT * FROM @SelectedCheckCommands) OR (EXISTS (SELECT * FROM @SelectedCheckCommands WHERE CheckCommand IN('CHECKDB')) AND EXISTS (SELECT CheckCommand FROM @SelectedCheckCommands WHERE CheckCommand IN('CHECKFILEGROUP','CHECKALLOC','CHECKTABLE','CHECKCATALOG'))) OR (EXISTS (SELECT * FROM @SelectedCheckCommands WHERE CheckCommand IN('CHECKFILEGROUP')) AND EXISTS (SELECT CheckCommand FROM @SelectedCheckCommands WHERE CheckCommand IN('CHECKALLOC','CHECKTABLE')))
  BEGIN
    SET @ErrorMessage = 'The value for the parameter @CheckCommands is not supported.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF @PhysicalOnly NOT IN ('Y','N') OR @PhysicalOnly IS NULL
  BEGIN
    SET @ErrorMessage = 'The value for the parameter @PhysicalOnly is not supported.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF @NoIndex NOT IN ('Y','N') OR @NoIndex IS NULL
  BEGIN
    SET @ErrorMessage = 'The value for the parameter @NoIndex is not supported.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF @ExtendedLogicalChecks NOT IN ('Y','N') OR @ExtendedLogicalChecks IS NULL OR (@ExtendedLogicalChecks = 'Y' AND NOT @Version >= 10) OR (@PhysicalOnly = 'Y' AND @ExtendedLogicalChecks = 'Y')
  BEGIN
    SET @ErrorMessage = 'The value for the parameter @ExtendedLogicalChecks is not supported.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF @TabLock NOT IN ('Y','N') OR @TabLock IS NULL
  BEGIN
    SET @ErrorMessage = 'The value for the parameter @TabLock is not supported.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF EXISTS(SELECT * FROM @SelectedFileGroups WHERE DatabaseName IS NULL OR FileGroupName IS NULL) OR (@FileGroups IS NOT NULL AND NOT EXISTS(SELECT * FROM @SelectedFileGroups)) OR (@FileGroups IS NOT NULL AND NOT EXISTS (SELECT * FROM @SelectedCheckCommands WHERE CheckCommand = 'CHECKFILEGROUP'))
  BEGIN
    SET @ErrorMessage = 'The value for the parameter @FileGroups is not supported.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF EXISTS(SELECT * FROM @SelectedObjects WHERE DatabaseName IS NULL OR SchemaName IS NULL OR ObjectName IS NULL) OR (@Objects IS NOT NULL AND NOT EXISTS(SELECT * FROM @SelectedObjects)) OR (@Objects IS NOT NULL AND NOT EXISTS (SELECT * FROM @SelectedCheckCommands WHERE CheckCommand = 'CHECKTABLE'))
  BEGIN
    SET @ErrorMessage = 'The value for the parameter @Objects is not supported.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF @LogToTable NOT IN('Y','N') OR @LogToTable IS NULL
  BEGIN
    SET @ErrorMessage = 'The value for the parameter @LogToTable is not supported.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF @Execute NOT IN('Y','N') OR @Execute IS NULL
  BEGIN
    SET @ErrorMessage = 'The value for the parameter @Execute is not supported.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @Error = @@ERROR
  END

  IF @Error <> 0
  BEGIN
    SET @ErrorMessage = 'The documentation is available at http://ola.hallengren.com/sql-server-integrity-check.html.' + CHAR(13) + CHAR(10) + ' '
    RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
    SET @ReturnCode = @Error
    GOTO Logging
  END

  ----------------------------------------------------------------------------------------------------
  --// Check Availability Group cluster name                                                      //--
  ----------------------------------------------------------------------------------------------------

  IF @Version >= 11
  BEGIN
    SELECT @Cluster = cluster_name
    FROM sys.dm_hadr_cluster
  END

  ----------------------------------------------------------------------------------------------------
  --// Execute commands                                                                           //--
  ----------------------------------------------------------------------------------------------------

  WHILE EXISTS (SELECT * FROM @tmpDatabases WHERE Selected = 1 AND Completed = 0)
  BEGIN

    SELECT TOP 1 @CurrentDBID = ID,
                 @CurrentDatabaseName = DatabaseName
    FROM @tmpDatabases
    WHERE Selected = 1
    AND Completed = 0
    ORDER BY ID ASC

    SET @CurrentDatabaseID = DB_ID(@CurrentDatabaseName)

    IF DATABASEPROPERTYEX(@CurrentDatabaseName,'Status') = 'ONLINE'
    BEGIN
      IF EXISTS (SELECT * FROM sys.database_recovery_status WHERE database_id = @CurrentDatabaseID AND database_guid IS NOT NULL)
      BEGIN
        SET @CurrentIsDatabaseAccessible = 1
      END
      ELSE
      BEGIN
        SET @CurrentIsDatabaseAccessible = 0
      END
    END
    ELSE
    BEGIN
      SET @CurrentIsDatabaseAccessible = 0
    END

    IF @Version >= 11 AND @Cluster IS NOT NULL
    BEGIN
      SELECT @CurrentAvailabilityGroup = availability_groups.name,
             @CurrentAvailabilityGroupRole = dm_hadr_availability_replica_states.role_desc
      FROM sys.databases databases
      INNER JOIN sys.availability_databases_cluster availability_databases_cluster ON databases.group_database_id = availability_databases_cluster.group_database_id
      INNER JOIN sys.availability_groups availability_groups ON availability_databases_cluster.group_id = availability_groups.group_id
      INNER JOIN sys.dm_hadr_availability_replica_states dm_hadr_availability_replica_states ON availability_groups.group_id = dm_hadr_availability_replica_states.group_id AND databases.replica_id = dm_hadr_availability_replica_states.replica_id
      WHERE databases.name = @CurrentDatabaseName
    END

    SELECT @CurrentDatabaseMirroringRole = UPPER(mirroring_role_desc)
    FROM sys.database_mirroring
    WHERE database_id = @CurrentDatabaseID

    IF EXISTS (SELECT * FROM msdb.dbo.log_shipping_primary_databases WHERE primary_database = @CurrentDatabaseName)
    BEGIN
      SET @CurrentLogShippingRole = 'PRIMARY'
    END
    ELSE
    IF EXISTS (SELECT * FROM msdb.dbo.log_shipping_secondary_databases WHERE secondary_database = @CurrentDatabaseName)
    BEGIN
      SET @CurrentLogShippingRole = 'SECONDARY'
    END

    -- Set database message
    SET @DatabaseMessage = 'Date and time: ' + CONVERT(nvarchar,GETDATE(),120) + CHAR(13) + CHAR(10)
    SET @DatabaseMessage = @DatabaseMessage + 'Database: ' + QUOTENAME(@CurrentDatabaseName) + CHAR(13) + CHAR(10)
    SET @DatabaseMessage = @DatabaseMessage + 'Status: ' + CAST(DATABASEPROPERTYEX(@CurrentDatabaseName,'Status') AS nvarchar) + CHAR(13) + CHAR(10)
    SET @DatabaseMessage = @DatabaseMessage + 'Standby: ' + CASE WHEN DATABASEPROPERTYEX(@CurrentDatabaseName,'IsInStandBy') = 1 THEN 'Yes' ELSE 'No' END + CHAR(13) + CHAR(10)
    SET @DatabaseMessage = @DatabaseMessage + 'Updateability: ' + CAST(DATABASEPROPERTYEX(@CurrentDatabaseName,'Updateability') AS nvarchar) + CHAR(13) + CHAR(10)
    SET @DatabaseMessage = @DatabaseMessage + 'User access: ' + CAST(DATABASEPROPERTYEX(@CurrentDatabaseName,'UserAccess') AS nvarchar) + CHAR(13) + CHAR(10)
    SET @DatabaseMessage = @DatabaseMessage + 'Is accessible: ' + CASE WHEN @CurrentIsDatabaseAccessible = 1 THEN 'Yes' ELSE 'No' END + CHAR(13) + CHAR(10)
    SET @DatabaseMessage = @DatabaseMessage + 'Recovery model: ' + CAST(DATABASEPROPERTYEX(@CurrentDatabaseName,'Recovery') AS nvarchar) + CHAR(13) + CHAR(10)
    IF @CurrentAvailabilityGroup IS NOT NULL SET @DatabaseMessage = @DatabaseMessage + 'Availability group: ' + @CurrentAvailabilityGroup + CHAR(13) + CHAR(10)
    IF @CurrentAvailabilityGroup IS NOT NULL SET @DatabaseMessage = @DatabaseMessage + 'Availability group role: ' + @CurrentAvailabilityGroupRole + CHAR(13) + CHAR(10)
    IF @CurrentDatabaseMirroringRole IS NOT NULL SET @DatabaseMessage = @DatabaseMessage + 'Database mirroring role: ' + @CurrentDatabaseMirroringRole + CHAR(13) + CHAR(10)
    IF @CurrentLogShippingRole IS NOT NULL SET @DatabaseMessage = @DatabaseMessage + 'Log shipping role: ' + @CurrentLogShippingRole + CHAR(13) + CHAR(10)
    SET @DatabaseMessage = REPLACE(@DatabaseMessage,'%','%%') + ' '
    RAISERROR(@DatabaseMessage,10,1) WITH NOWAIT

    IF DATABASEPROPERTYEX(@CurrentDatabaseName,'Status') = 'ONLINE'
    AND NOT (DATABASEPROPERTYEX(@CurrentDatabaseName,'UserAccess') = 'SINGLE_USER' AND @CurrentIsDatabaseAccessible = 0)
    BEGIN

      -- Check database
      IF EXISTS(SELECT * FROM @SelectedCheckCommands WHERE CheckCommand = 'CHECKDB')
      BEGIN
        SET @CurrentCommandType01 = 'DBCC_CHECKDB'

        SET @CurrentCommand01 = 'DBCC CHECKDB (' + QUOTENAME(@CurrentDatabaseName)
        IF @NoIndex = 'Y' SET @CurrentCommand01 = @CurrentCommand01 + ', NOINDEX'
        SET @CurrentCommand01 = @CurrentCommand01 + ') WITH NO_INFOMSGS, ALL_ERRORMSGS'
        IF @PhysicalOnly = 'N' SET @CurrentCommand01 = @CurrentCommand01 + ', DATA_PURITY'
        IF @PhysicalOnly = 'Y' SET @CurrentCommand01 = @CurrentCommand01 + ', PHYSICAL_ONLY'
        IF @ExtendedLogicalChecks = 'Y' SET @CurrentCommand01 = @CurrentCommand01 + ', EXTENDED_LOGICAL_CHECKS'
        IF @TabLock = 'Y' SET @CurrentCommand01 = @CurrentCommand01 + ', TABLOCK'

        EXECUTE @CurrentCommandOutput01 = [dbo].[CommandExecute] @Command = @CurrentCommand01, @CommandType = @CurrentCommandType01, @Mode = 1, @DatabaseName = @CurrentDatabaseName, @LogToTable = @LogToTable, @Execute = @Execute
        SET @Error = @@ERROR
        IF @Error <> 0 SET @CurrentCommandOutput01 = @Error
        IF @CurrentCommandOutput01 <> 0 SET @ReturnCode = @CurrentCommandOutput01
      END

      -- Check filegroups
      IF EXISTS(SELECT * FROM @SelectedCheckCommands WHERE CheckCommand = 'CHECKFILEGROUP')
      BEGIN
        SET @CurrentCommand02 = 'SELECT data_space_id AS FileGroupID, name AS FileGroupName, 0 AS Selected, 0 AS Completed FROM ' + QUOTENAME(@CurrentDatabaseName) + '.sys.filegroups filegroups ORDER BY CASE WHEN filegroups.name = ''PRIMARY'' THEN 1 ELSE 0 END DESC, filegroups.name ASC'

        INSERT INTO @tmpFileGroups (FileGroupID, FileGroupName, Selected, Completed)
        EXECUTE sp_executesql @statement = @CurrentCommand02
        SET @Error = @@ERROR
        IF @Error <> 0 SET @ReturnCode = @Error
        IF @Error = 1222
        BEGIN
          SET @ErrorMessage = 'The filegroup system table is locked in the database ' + QUOTENAME(@CurrentDatabaseName) + '.' + CHAR(13) + CHAR(10) + ' '
          SET @ErrorMessage = REPLACE(@ErrorMessage,'%','%%')
          RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
        END

        IF @FileGroups IS NULL
        BEGIN
          UPDATE tmpFileGroups
          SET tmpFileGroups.Selected = 1
          FROM @tmpFileGroups tmpFileGroups
        END
        ELSE
        BEGIN
          UPDATE tmpFileGroups
          SET tmpFileGroups.Selected = SelectedFileGroups.Selected
          FROM @tmpFileGroups tmpFileGroups
          INNER JOIN @SelectedFileGroups SelectedFileGroups
          ON @CurrentDatabaseName LIKE REPLACE(SelectedFileGroups.DatabaseName,'_','[_]') AND tmpFileGroups.FileGroupName LIKE REPLACE(SelectedFileGroups.FileGroupName,'_','[_]')
          WHERE SelectedFileGroups.Selected = 1

          UPDATE tmpFileGroups
          SET tmpFileGroups.Selected = SelectedFileGroups.Selected
          FROM @tmpFileGroups tmpFileGroups
          INNER JOIN @SelectedFileGroups SelectedFileGroups
          ON @CurrentDatabaseName LIKE REPLACE(SelectedFileGroups.DatabaseName,'_','[_]') AND tmpFileGroups.FileGroupName LIKE REPLACE(SelectedFileGroups.FileGroupName,'_','[_]')
          WHERE SelectedFileGroups.Selected = 0
        END

        WHILE EXISTS (SELECT * FROM @tmpFileGroups WHERE Selected = 1 AND Completed = 0)
        BEGIN
          SELECT TOP 1 @CurrentFGID = ID,
                       @CurrentFileGroupID = FileGroupID,
                       @CurrentFileGroupName = FileGroupName
          FROM @tmpFileGroups
          WHERE Selected = 1
          AND Completed = 0
          ORDER BY ID ASC

          -- Does the filegroup exist?
          SET @CurrentCommand03 = 'IF EXISTS(SELECT * FROM ' + QUOTENAME(@CurrentDatabaseName) + '.sys.filegroups filegroups WHERE filegroups.data_space_id = @ParamFileGroupID AND filegroups.[name] = @ParamFileGroupName) BEGIN SET @ParamFileGroupExists = 1 END'

          EXECUTE sp_executesql @statement = @CurrentCommand03, @params = N'@ParamFileGroupID int, @ParamFileGroupName sysname, @ParamFileGroupExists bit OUTPUT', @ParamFileGroupID = @CurrentFileGroupID, @ParamFileGroupName = @CurrentFileGroupName, @ParamFileGroupExists = @CurrentFileGroupExists OUTPUT
          SET @Error = @@ERROR
          IF @Error = 0 AND @CurrentFileGroupExists IS NULL SET @CurrentFileGroupExists = 0
          IF @Error <> 0
          BEGIN
            SET @ReturnCode = @Error
          END

          IF @CurrentFileGroupExists = 1
          BEGIN
            SET @CurrentCommandType04 = 'DBCC_CHECKFILEGROUP'

            SET @CurrentCommand04 = 'USE ' + QUOTENAME(@CurrentDatabaseName) + '; DBCC CHECKFILEGROUP (' + QUOTENAME(@CurrentFileGroupName)
            IF @NoIndex = 'Y' SET @CurrentCommand04 = @CurrentCommand04 + ', NOINDEX'
            SET @CurrentCommand04 = @CurrentCommand04 + ') WITH NO_INFOMSGS, ALL_ERRORMSGS'
            IF @PhysicalOnly = 'Y' SET @CurrentCommand04 = @CurrentCommand04 + ', PHYSICAL_ONLY'
            IF @TabLock = 'Y' SET @CurrentCommand04 = @CurrentCommand04 + ', TABLOCK'

            EXECUTE @CurrentCommandOutput04 = [dbo].[CommandExecute] @Command = @CurrentCommand04, @CommandType = @CurrentCommandType04, @Mode = 1, @DatabaseName = @CurrentDatabaseName, @LogToTable = @LogToTable, @Execute = @Execute
            SET @Error = @@ERROR
            IF @Error <> 0 SET @CurrentCommandOutput04 = @Error
            IF @CurrentCommandOutput04 <> 0 SET @ReturnCode = @CurrentCommandOutput04
          END

          UPDATE @tmpFileGroups
          SET Completed = 1
          WHERE Selected = 1
          AND Completed = 0
          AND ID = @CurrentFGID

          SET @CurrentFGID = NULL
          SET @CurrentFileGroupID = NULL
          SET @CurrentFileGroupName = NULL
          SET @CurrentFileGroupExists = NULL

          SET @CurrentCommand03 = NULL
          SET @CurrentCommand04 = NULL

          SET @CurrentCommandOutput04 = NULL

          SET @CurrentCommandType04 = NULL
        END
      END

      -- Check disk space allocation structures
      IF EXISTS(SELECT * FROM @SelectedCheckCommands WHERE CheckCommand = 'CHECKALLOC')
      BEGIN
        SET @CurrentCommandType05 = 'DBCC_CHECKALLOC'

        SET @CurrentCommand05 = 'DBCC CHECKALLOC (' + QUOTENAME(@CurrentDatabaseName)
        SET @CurrentCommand05 = @CurrentCommand05 + ') WITH NO_INFOMSGS, ALL_ERRORMSGS'
        IF @TabLock = 'Y' SET @CurrentCommand05 = @CurrentCommand05 + ', TABLOCK'

        EXECUTE @CurrentCommandOutput05 = [dbo].[CommandExecute] @Command = @CurrentCommand05, @CommandType = @CurrentCommandType05, @Mode = 1, @DatabaseName = @CurrentDatabaseName, @LogToTable = @LogToTable, @Execute = @Execute
        SET @Error = @@ERROR
        IF @Error <> 0 SET @CurrentCommandOutput05 = @Error
        IF @CurrentCommandOutput05 <> 0 SET @ReturnCode = @CurrentCommandOutput05
      END

      -- Check objects
      IF EXISTS(SELECT * FROM @SelectedCheckCommands WHERE CheckCommand = 'CHECKTABLE')
      BEGIN
        SET @CurrentCommand06 = 'SELECT schemas.[schema_id] AS SchemaID, schemas.[name] AS SchemaName, objects.[object_id] AS ObjectID, objects.[name] AS ObjectName, RTRIM(objects.[type]) AS ObjectType, 0 AS Selected, 0 AS Completed FROM ' + QUOTENAME(@CurrentDatabaseName) + '.sys.objects objects INNER JOIN ' + QUOTENAME(@CurrentDatabaseName) + '.sys.schemas schemas ON objects.schema_id = schemas.schema_id WHERE objects.[type] IN(''U'',''V'') AND EXISTS(SELECT * FROM ' + QUOTENAME(@CurrentDatabaseName) + '.sys.indexes indexes WHERE indexes.object_id = objects.object_id) ORDER BY schemas.name ASC, objects.name ASC'

        INSERT INTO @tmpObjects (SchemaID, SchemaName, ObjectID, ObjectName, ObjectType, Selected, Completed)
        EXECUTE sp_executesql @statement = @CurrentCommand06
        SET @Error = @@ERROR
        IF @Error <> 0 SET @ReturnCode = @Error
        IF @Error = 1222
        BEGIN
          SET @ErrorMessage = 'The object system tables are locked in the database ' + QUOTENAME(@CurrentDatabaseName) + '.' + CHAR(13) + CHAR(10) + ' '
          SET @ErrorMessage = REPLACE(@ErrorMessage,'%','%%')
          RAISERROR(@ErrorMessage,16,1) WITH NOWAIT
        END

        IF @Objects IS NULL
        BEGIN
          UPDATE tmpObjects
          SET tmpObjects.Selected = 1
          FROM @tmpObjects tmpObjects
        END
        ELSE
        BEGIN
          UPDATE tmpObjects
          SET tmpObjects.Selected = SelectedObjects.Selected
          FROM @tmpObjects tmpObjects
          INNER JOIN @SelectedObjects SelectedObjects
          ON @CurrentDatabaseName LIKE REPLACE(SelectedObjects.DatabaseName,'_','[_]') AND tmpObjects.SchemaName LIKE REPLACE(SelectedObjects.SchemaName,'_','[_]') AND tmpObjects.ObjectName LIKE REPLACE(SelectedObjects.ObjectName,'_','[_]')
          WHERE SelectedObjects.Selected = 1

          UPDATE tmpObjects
          SET tmpObjects.Selected = SelectedObjects.Selected
          FROM @tmpObjects tmpObjects
          INNER JOIN @SelectedObjects SelectedObjects
          ON @CurrentDatabaseName LIKE REPLACE(SelectedObjects.DatabaseName,'_','[_]') AND tmpObjects.SchemaName LIKE REPLACE(SelectedObjects.SchemaName,'_','[_]') AND tmpObjects.ObjectName LIKE REPLACE(SelectedObjects.ObjectName,'_','[_]')
          WHERE SelectedObjects.Selected = 0
        END

        WHILE EXISTS (SELECT * FROM @tmpObjects WHERE Selected = 1 AND Completed = 0)
        BEGIN
          SELECT TOP 1 @CurrentOID = ID,
                       @CurrentSchemaID = SchemaID,
                       @CurrentSchemaName = SchemaName,
                       @CurrentObjectID = ObjectID,
                       @CurrentObjectName = ObjectName,
                       @CurrentObjectType = ObjectType
          FROM @tmpObjects
          WHERE Selected = 1
          AND Completed = 0
          ORDER BY ID ASC

          -- Does the object exist?
          SET @CurrentCommand07 = 'IF EXISTS(SELECT schemas.[schema_id] AS SchemaID, schemas.[name] AS SchemaName, objects.[object_id] AS ObjectID, objects.[name] AS ObjectName, RTRIM(objects.[type]) AS ObjectType, 0 AS Selected, 0 AS Completed FROM ' + QUOTENAME(@CurrentDatabaseName) + '.sys.objects objects INNER JOIN ' + QUOTENAME(@CurrentDatabaseName) + '.sys.schemas schemas ON objects.schema_id = schemas.schema_id WHERE objects.[type] IN(''U'',''V'') AND EXISTS(SELECT * FROM ' + QUOTENAME(@CurrentDatabaseName) + '.sys.indexes indexes WHERE indexes.object_id = objects.object_id) AND schemas.[schema_id] = @ParamSchemaID AND schemas.[name] = @ParamSchemaName AND objects.[object_id] = @ParamObjectID AND objects.[name] = @ParamObjectName AND objects.[type] = @ParamObjectType) BEGIN SET @ParamObjectExists = 1 END'

          EXECUTE sp_executesql @statement = @CurrentCommand07, @params = N'@ParamSchemaID int, @ParamSchemaName sysname, @ParamObjectID int, @ParamObjectName sysname, @ParamObjectType sysname, @ParamObjectExists bit OUTPUT', @ParamSchemaID = @CurrentSchemaID, @ParamSchemaName = @CurrentSchemaName, @ParamObjectID = @CurrentObjectID, @ParamObjectName = @CurrentObjectName, @ParamObjectType = @CurrentObjectType, @ParamObjectExists = @CurrentObjectExists OUTPUT
          SET @Error = @@ERROR
          IF @Error = 0 AND @CurrentObjectExists IS NULL SET @CurrentObjectExists = 0
          IF @Error <> 0
          BEGIN
            SET @ReturnCode = @Error
          END

          IF @CurrentObjectExists = 1
          BEGIN
            SET @CurrentCommandType08 = 'DBCC_CHECKTABLE'

            SET @CurrentCommand08 = 'DBCC CHECKTABLE (''' + QUOTENAME(@CurrentDatabaseName) + '.' + QUOTENAME(@CurrentSchemaName) + '.' + QUOTENAME(@CurrentObjectName) + ''''
            IF @NoIndex = 'Y' SET @CurrentCommand08 = @CurrentCommand08 + ', NOINDEX'
            SET @CurrentCommand08 = @CurrentCommand08 + ') WITH NO_INFOMSGS, ALL_ERRORMSGS'
            IF @PhysicalOnly = 'N' SET @CurrentCommand08 = @CurrentCommand08 + ', DATA_PURITY'
            IF @PhysicalOnly = 'Y' SET @CurrentCommand08 = @CurrentCommand08 + ', PHYSICAL_ONLY'
            IF @ExtendedLogicalChecks = 'Y' SET @CurrentCommand08 = @CurrentCommand08 + ', EXTENDED_LOGICAL_CHECKS'
            IF @TabLock = 'Y' SET @CurrentCommand08 = @CurrentCommand08 + ', TABLOCK'

            EXECUTE @CurrentCommandOutput08 = [dbo].[CommandExecute] @Command = @CurrentCommand08, @CommandType = @CurrentCommandType08, @Mode = 1, @DatabaseName = @CurrentDatabaseName, @SchemaName = @CurrentSchemaName, @ObjectName = @CurrentObjectName, @ObjectType = @CurrentObjectType, @LogToTable = @LogToTable, @Execute = @Execute
            SET @Error = @@ERROR
            IF @Error <> 0 SET @CurrentCommandOutput08 = @Error
            IF @CurrentCommandOutput08 <> 0 SET @ReturnCode = @CurrentCommandOutput08
          END

          UPDATE @tmpObjects
          SET Completed = 1
          WHERE Selected = 1
          AND Completed = 0
          AND ID = @CurrentOID

          SET @CurrentOID = NULL
          SET @CurrentSchemaID = NULL
          SET @CurrentSchemaName = NULL
          SET @CurrentObjectID = NULL
          SET @CurrentObjectName = NULL
          SET @CurrentObjectType = NULL
          SET @CurrentObjectExists = NULL

          SET @CurrentCommand07 = NULL
          SET @CurrentCommand08 = NULL

          SET @CurrentCommandOutput08 = NULL

          SET @CurrentCommandType08 = NULL
        END
      END

      -- Check catalog
      IF EXISTS(SELECT * FROM @SelectedCheckCommands WHERE CheckCommand = 'CHECKCATALOG')
      BEGIN
        SET @CurrentCommandType09 = 'DBCC_CHECKCATALOG'

        SET @CurrentCommand09 = 'DBCC CHECKCATALOG (' + QUOTENAME(@CurrentDatabaseName)
        SET @CurrentCommand09 = @CurrentCommand09 + ') WITH NO_INFOMSGS'

        EXECUTE @CurrentCommandOutput09 = [dbo].[CommandExecute] @Command = @CurrentCommand09, @CommandType = @CurrentCommandType09, @Mode = 1, @DatabaseName = @CurrentDatabaseName, @LogToTable = @LogToTable, @Execute = @Execute
        SET @Error = @@ERROR
        IF @Error <> 0 SET @CurrentCommandOutput09 = @Error
        IF @CurrentCommandOutput09 <> 0 SET @ReturnCode = @CurrentCommandOutput09
      END

    END

    -- Update that the database is completed
    UPDATE @tmpDatabases
    SET Completed = 1
    WHERE Selected = 1
    AND Completed = 0
    AND ID = @CurrentDBID

    -- Clear variables
    SET @CurrentDBID = NULL
    SET @CurrentDatabaseID = NULL
    SET @CurrentDatabaseName = NULL
    SET @CurrentIsDatabaseAccessible = NULL
    SET @CurrentAvailabilityGroup = NULL
    SET @CurrentAvailabilityGroupRole = NULL
    SET @CurrentDatabaseMirroringRole = NULL
    SET @CurrentLogShippingRole = NULL

    SET @CurrentCommand01 = NULL
    SET @CurrentCommand02 = NULL
    SET @CurrentCommand05 = NULL
    SET @CurrentCommand06 = NULL
    SET @CurrentCommand09 = NULL

    SET @CurrentCommandOutput01 = NULL
    SET @CurrentCommandOutput05 = NULL
    SET @CurrentCommandOutput09 = NULL

    SET @CurrentCommandType01 = NULL
    SET @CurrentCommandType05 = NULL
    SET @CurrentCommandType09 = NULL

    DELETE FROM @tmpFileGroups
    DELETE FROM @tmpObjects

  END

  ----------------------------------------------------------------------------------------------------
  --// Log completing information                                                                 //--
  ----------------------------------------------------------------------------------------------------

  Logging:
  SET @EndMessage = 'Date and time: ' + CONVERT(nvarchar,GETDATE(),120)
  SET @EndMessage = REPLACE(@EndMessage,'%','%%')
  RAISERROR(@EndMessage,10,1) WITH NOWAIT

  IF @ReturnCode <> 0
  BEGIN
    RETURN @ReturnCode
  END

  ----------------------------------------------------------------------------------------------------

END



GO
/****** Object:  StoredProcedure [dbo].[DatabaseSizes]    Script Date: 27/10/2015 09:31:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[DatabaseSizes]
AS

/*

        Author:  Ben Anderson
        Date:    18/02/04
        Function:  Returns information on database sizes and growth rates.

*/

set nocount on
SET ANSI_NULLS ON



GO
/****** Object:  StoredProcedure [dbo].[dba_indexDefrag_sp]    Script Date: 27/10/2015 09:31:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[dba_indexDefrag_sp]
 
    /* Declare Parameters */
      @minFragmentation     FLOAT           = 5.0  
        /* in percent, will not defrag if fragmentation less than specified */
    , @rebuildThreshold     FLOAT           = 30.0  
        /* in percent, greater than @rebuildThreshold will result in rebuild instead of reorg */
    , @executeSQL           BIT             = 1     
        /* 1 = execute; 0 = print command only */
    , @DATABASE             VARCHAR(128)    = Null
        /* Option to specify a database name; null will return all */
    , @tableName            VARCHAR(4000)   = Null  -- databaseName.schema.tableName
        /* Option to specify a table name; null will return all */
    , @onlineRebuild        BIT             = 1     
        /* 1 = online rebuild; 0 = offline rebuild; only in Enterprise */
    , @maxDopRestriction    TINYINT         = Null
        /* Option to restrict the number of processors for the operation; only in Enterprise */
    , @printCommands        BIT             = 0     
        /* 1 = print commands; 0 = do not print commands */
    , @printFragmentation   BIT             = 0
        /* 1 = print fragmentation prior to defrag; 
           0 = do not print */
    , @defragDelay          CHAR(8)         = '00:00:05'
        /* time to wait between defrag commands */
    , @scanMode             NVARCHAR(8)     = N'Limited'
        /* scan level to be used with dm_db_index_physical_stats. Options are DEFAULT, NULL, LIMITED, SAMPLED, or DETAILED. The default (NULL) is LIMITED */
    , @debugMode            BIT             = 0
        /* display some useful comments to help determine if/where issues occur */
AS
/*********************************************************************************
    Name:       dba_indexDefrag_sp
 
    Author:     Michelle Ufford, http://sqlfool.com
 
    Purpose:    Defrags all indexes for one or more databases
 
    Notes:
 
    CAUTION: TRANSACTION LOG SIZE MUST BE MONITORED CLOSELY WHEN DEFRAGMENTING.
 
      @minFragmentation     defaulted to 10%, will not defrag if fragmentation 
                            is less than that
 
      @rebuildThreshold     defaulted to 30% as recommended by Microsoft in BOL;
                            greater than 30% will result in rebuild instead
 
      @executeSQL           1 = execute the SQL generated by this proc; 
                            0 = print command only
 
      @database             Optional, specify specific database name to defrag;
                            If not specified, all non-system databases will
                            be defragged.
 
      @tableName            Specify if you only want to defrag indexes for a 
                            specific table, format = databaseName.schema.tableName;
                            if not specified, all tables will be defragged.
 
      @onlineRebuild        1 = online rebuild; 
                            0 = offline rebuild
 
      @maxDopRestriction    Option to specify a processor limit for index rebuilds
 
      @printCommands        1 = print commands to screen; 
                            0 = do not print commands
 
      @printFragmentation   1 = print fragmentation to screen;
                            0 = do not print fragmentation
 
      @defragDelay          time to wait between defrag commands; gives the
                            server a little time to catch up 
      
      @scanMode             scan level to be used with dm_db_index_physical_stats. 
                            Options are DEFAULT, NULL, LIMITED, SAMPLED, or 
                            DETAILED. The default (NULL) is LIMITED
 
      @debugMode            1 = display debug comments; helps with troubleshooting
                            0 = do not display debug comments
 
    Called by:  SQL Agent Job or DBA
 
    Date        Initials	Description
    ----------------------------------------------------------------------------
    2008-10-27  MFU         Initial Release for public consumption
    2008-11-17  MFU         Added page-count to log table
                            , added @printFragmentation option
    2009-03-17  MFU         Provided support for centralized execution, 
                            , consolidated Enterprise & Standard versions
                            , added @debugMode, @maxDopRestriction
                            , modified LOB and partition logic
    2009-05-12  JAP         Added @scanMode                            
*********************************************************************************
    Exec dbo.dba_indexDefrag_sp
          @executeSQL           = 0
        , @minFragmentation     = 20
        , @printCommands        = 1
        , @debugMode            = 1
        , @printFragmentation   = 1
        , @database             = 'PARE'
        , @tableName            = '';
*********************************************************************************/																
 
SET NOCOUNT ON;
SET XACT_Abort ON;
SET Quoted_Identifier ON;
 
BEGIN
 
    IF @debugMode = 1 RAISERROR('Dusting off the spiderwebs and starting up...', 0, 42) WITH NoWait;
 
    /* Declare our variables */
    DECLARE   @objectID             INT
            , @databaseID           INT
            , @databaseName         NVARCHAR(128)
            , @indexID              INT
            , @partitionCount       BIGINT
            , @schemaName           NVARCHAR(128)
            , @objectName           NVARCHAR(128)
            , @indexName            NVARCHAR(128)
            , @partitionNumber      SMALLINT
            , @partitions           SMALLINT
            , @fragmentation        FLOAT
            , @pageCount            INT
            , @sqlCommand           NVARCHAR(4000)
            , @rebuildCommand       NVARCHAR(200)
            , @dateTimeStart        DATETIME
            , @dateTimeEnd          DATETIME
            , @containsLOB          BIT
            , @editionCheck         BIT
            , @debugMessage         VARCHAR(128)
            , @updateSQL            NVARCHAR(4000)
            , @partitionSQL         NVARCHAR(4000)
            , @partitionSQL_Param   NVARCHAR(1000)
            , @LOB_SQL              NVARCHAR(4000)
            , @LOB_SQL_Param        NVARCHAR(1000);
 
    /* Create our temporary tables */
    CREATE TABLE #indexDefragList
    (
          databaseID        INT
        , databaseName      NVARCHAR(128)
        , objectID          INT
        , indexID           INT
        , partitionNumber   SMALLINT
        , fragmentation     FLOAT
        , page_count        INT
        , defragStatus      BIT
        , schemaName        NVARCHAR(128)   Null
        , objectName        NVARCHAR(128)   Null
        , indexName         NVARCHAR(128)   Null
    );
 
    CREATE TABLE #databaseList
    (
          databaseID        INT
        , databaseName      VARCHAR(128)
    );
 
    CREATE TABLE #processor 
    (
          [INDEX]           INT
        , Name              VARCHAR(128)
        , Internal_Value    INT
        , Character_Value   INT
    );
 
    IF @debugMode = 1 RAISERROR('Beginning validation...', 0, 42) WITH NoWait;
 
    /* Just a little validation... */
    IF @minFragmentation Not Between 0.00 And 100.0
        SET @minFragmentation = 5.0;
 
    IF @rebuildThreshold Not Between 0.00 And 100.0
        SET @rebuildThreshold = 30.0;
 
    IF @defragDelay Not Like '00:[0-5][0-9]:[0-5][0-9]'
        SET @defragDelay = '00:00:05';
 
    /* Make sure we're not exceeding the number of processors we have available */
    INSERT INTO #processor
    EXECUTE XP_MSVER 'ProcessorCount';
 
    IF @maxDopRestriction IS Not Null And @maxDopRestriction > (SELECT Internal_Value FROM #processor)
        SELECT @maxDopRestriction = Internal_Value
        FROM #processor;
 
    /* Check our server version; 1804890536 = Enterprise, 610778273 = Enterprise Evaluation, -2117995310 = Developer */
    IF (SELECT SERVERPROPERTY('EditionID')) In (1804890536, 610778273, -2117995310) 
        SET @editionCheck = 1 -- supports online rebuilds
    ELSE
        SET @editionCheck = 0; -- does not support online rebuilds
 
    IF @debugMode = 1 RAISERROR('Grabbing a list of our databases...', 0, 42) WITH NoWait;
 
    /* Retrieve the list of databases to investigate */
    INSERT INTO #databaseList
    SELECT database_id
        , name
    FROM sys.databases
    WHERE name = IsNull(@DATABASE, name)
        And database_id > 4 -- exclude system databases
        And [STATE] = 0; -- state must be ONLINE
 
    IF @debugMode = 1 RAISERROR('Looping through our list of databases and checking for fragmentation...', 0, 42) WITH NoWait;
 
    /* Loop through our list of databases */
    WHILE (SELECT COUNT(*) FROM #databaseList) > 0
    BEGIN
 
        SELECT TOP 1 @databaseID = databaseID
        FROM #databaseList;
 
        SELECT @debugMessage = '  working on ' + DB_NAME(@databaseID) + '...';
 
        IF @debugMode = 1
            RAISERROR(@debugMessage, 0, 42) WITH NoWait;
 
       /* Determine which indexes to defrag using our user-defined parameters */
        INSERT INTO #indexDefragList
        SELECT
              database_id AS databaseID
            , QUOTENAME(DB_NAME(database_id)) AS 'databaseName'
            , [OBJECT_ID] AS objectID
            , index_id AS indexID
            , partition_number AS partitionNumber
            , avg_fragmentation_in_percent AS fragmentation
            , page_count 
            , 0 AS 'defragStatus' /* 0 = unprocessed, 1 = processed */
            , Null AS 'schemaName'
            , Null AS 'objectName'
            , Null AS 'indexName'
        FROM sys.dm_db_index_physical_stats (@databaseID, OBJECT_ID(@tableName), Null , Null, @scanMode)
        WHERE avg_fragmentation_in_percent >= @minFragmentation 
            And index_id > 0 -- ignore heaps
            And page_count > 8 -- ignore objects with less than 1 extent
        OPTION (MaxDop 1);
 
        DELETE FROM #databaseList
        WHERE databaseID = @databaseID;
 
    END
 
    CREATE CLUSTERED INDEX CIX_temp_indexDefragList
        ON #indexDefragList(databaseID, objectID, indexID, partitionNumber);
 
    SELECT @debugMessage = 'Looping through our list... there''s ' + CAST(COUNT(*) AS VARCHAR(10)) + ' indexes to defrag!'
    FROM #indexDefragList;
 
    IF @debugMode = 1 RAISERROR(@debugMessage, 0, 42) WITH NoWait;
 
    /* Begin our loop for defragging */
    WHILE (SELECT COUNT(*) FROM #indexDefragList WHERE defragStatus = 0) > 0
    BEGIN
 
        IF @debugMode = 1 RAISERROR('  Picking an index to beat into shape...', 0, 42) WITH NoWait;
 
        /* Grab the most fragmented index first to defrag */
        SELECT TOP 1 
              @objectID         = objectID
            , @indexID          = indexID
            , @databaseID       = databaseID
            , @databaseName     = databaseName
            , @fragmentation    = fragmentation
            , @partitionNumber  = partitionNumber
            , @pageCount        = page_count
        FROM #indexDefragList
        WHERE defragStatus = 0
        ORDER BY fragmentation DESC;
 
        IF @debugMode = 1 RAISERROR('  Looking up the specifics for our index...', 0, 42) WITH NoWait;
 
        /* Look up index information */
        SELECT @updateSQL = N'Update idl
            Set schemaName = QuoteName(s.name)
                , objectName = QuoteName(o.name)
                , indexName = QuoteName(i.name)
            From #indexDefragList As idl
            Inner Join ' + @databaseName + '.sys.objects As o
                On idl.objectID = o.object_id
            Inner Join ' + @databaseName + '.sys.indexes As i
                On o.object_id = i.object_id
            Inner Join ' + @databaseName + '.sys.schemas As s
                On o.schema_id = s.schema_id
            Where o.object_id = ' + CAST(@objectID AS VARCHAR(10)) + '
                And i.index_id = ' + CAST(@indexID AS VARCHAR(10)) + '
                And i.type > 0
                And idl.databaseID = ' + CAST(@databaseID AS VARCHAR(10));
 
        EXECUTE SP_EXECUTESQL @updateSQL;
 
        /* Grab our object names */
        SELECT @objectName  = objectName
            , @schemaName   = schemaName
            , @indexName    = indexName
        FROM #indexDefragList
        WHERE objectID = @objectID
            And indexID = @indexID
            And databaseID = @databaseID;
 
        IF @debugMode = 1 RAISERROR('  Grabbing the partition count...', 0, 42) WITH NoWait;
 
        /* Determine if the index is partitioned */
        SELECT @partitionSQL = 'Select @partitionCount_OUT = Count(*)
                                    From ' + @databaseName + '.sys.partitions
                                    Where object_id = ' + CAST(@objectID AS VARCHAR(10)) + '
                                        And index_id = ' + CAST(@indexID AS VARCHAR(10)) + ';'
            , @partitionSQL_Param = '@partitionCount_OUT int OutPut';
 
        EXECUTE SP_EXECUTESQL @partitionSQL, @partitionSQL_Param, @partitionCount_OUT = @partitionCount OUTPUT;
 
        IF @debugMode = 1 RAISERROR('  Seeing if there''s any LOBs to be handled...', 0, 42) WITH NoWait;
 
        /* Determine if the table contains LOBs */
        SELECT @LOB_SQL = ' Select Top 1 @containsLOB_OUT = column_id
                            From ' + @databaseName + '.sys.columns With (NoLock) 
                            Where [object_id] = ' + CAST(@objectID AS VARCHAR(10)) + '
                                And (system_type_id In (34, 35, 99)
                                        Or max_length = -1);'
                            /*  system_type_id --> 34 = image, 35 = text, 99 = ntext
                                max_length = -1 --> varbinary(max), varchar(max), nvarchar(max), xml */
                , @LOB_SQL_Param = '@containsLOB_OUT int OutPut';
 
        EXECUTE SP_EXECUTESQL @LOB_SQL, @LOB_SQL_Param, @containsLOB_OUT = @containsLOB OUTPUT;
 
        IF @debugMode = 1 RAISERROR('  Building our SQL statements...', 0, 42) WITH NoWait;
 
        /* If there's not a lot of fragmentation, or if we have a LOB, we should reorganize */
        IF @fragmentation < @rebuildThreshold Or @containsLOB = 1 Or @partitionCount > 1
        BEGIN
 
            SET @sqlCommand = N'Alter Index ' + @indexName + N' On ' + @databaseName + N'.' 
                                + @schemaName + N'.' + @objectName + N' ReOrganize';
 
            /* If our index is partitioned, we should always reorganize */
            IF @partitionCount > 1
                SET @sqlCommand = @sqlCommand + N' Partition = ' 
                                + CAST(@partitionNumber AS NVARCHAR(10));
 
        END;
 
        /* If the index is heavily fragmented and doesn't contain any partitions or LOB's, rebuild it */
        IF @fragmentation >= @rebuildThreshold And IsNull(@containsLOB, 0)!= 1 And @partitionCount <= 1
        BEGIN
 
            /* Set online rebuild options; requires Enterprise Edition */
            IF @onlineRebuild = 1 And @editionCheck = 1 
                SET @rebuildCommand = N' Rebuild With (Online = On';
            ELSE
                SET @rebuildCommand = N' Rebuild With (Online = Off';
 
            /* Set processor restriction options; requires Enterprise Edition */
            IF @maxDopRestriction IS Not Null And @editionCheck = 1
                SET @rebuildCommand = @rebuildCommand + N', MaxDop = ' + CAST(@maxDopRestriction AS VARCHAR(2)) + N')';
            ELSE
                SET @rebuildCommand = @rebuildCommand + N')';
 
            SET @sqlCommand = N'Alter Index ' + @indexName + N' On ' + @databaseName + N'.'
                            + @schemaName + N'.' + @objectName + @rebuildCommand;
 
        END;
 
        /* Are we executing the SQL?  If so, do it */
        IF @executeSQL = 1
        BEGIN
 
            IF @debugMode = 1 RAISERROR('  Executing SQL statements...', 0, 42) WITH NoWait;
 
            /* Grab the time for logging purposes */
            SET @dateTimeStart  = GETDATE();
            EXECUTE SP_EXECUTESQL @sqlCommand;
            SET @dateTimeEnd  = GETDATE();
 
            /* Log our actions */
            INSERT INTO dbo.dba_indexDefragLog
            (
                  databaseID
                , databaseName
                , objectID
                , objectName
                , indexID
                , indexName
                , partitionNumber
                , fragmentation
                , page_count
                , dateTimeStart
                , durationSeconds
            )
            SELECT
                  @databaseID
                , @databaseName
                , @objectID
                , @objectName
                , @indexID
                , @indexName
                , @partitionNumber
                , @fragmentation
                , @pageCount
                , @dateTimeStart
                , DATEDIFF(SECOND, @dateTimeStart, @dateTimeEnd);
 
            /* Just a little breather for the server */
            WAITFOR Delay @defragDelay;
 
            /* Print if specified to do so */
            IF @printCommands = 1
                PRINT N'Executed: ' + @sqlCommand;
        END
        ELSE
        /* Looks like we're not executing, just printing the commands */
        BEGIN
            IF @debugMode = 1 RAISERROR('  Printing SQL statements...', 0, 42) WITH NoWait;
 
            IF @printCommands = 1 PRINT IsNull(@sqlCommand, 'error!');
        END
 
        IF @debugMode = 1 RAISERROR('  Updating our index defrag status...', 0, 42) WITH NoWait;
 
        /* Update our index defrag list so we know we've finished with that index */
        UPDATE #indexDefragList
        SET defragStatus = 1
        WHERE databaseID       = @databaseID
          And objectID         = @objectID
          And indexID          = @indexID
          And partitionNumber  = @partitionNumber;
 
    END
 
    /* Do we want to output our fragmentation results? */
    IF @printFragmentation = 1
    BEGIN
 
        IF @debugMode = 1 RAISERROR('  Displaying fragmentation results...', 0, 42) WITH NoWait;
 
        SELECT databaseID
            , databaseName
            , objectID
            , objectName
            , indexID
            , indexName
            , fragmentation
            , page_count
        FROM #indexDefragList;
 
    END;
 
    /* When everything is said and done, make sure to get rid of our temp table */
    DROP TABLE #indexDefragList;
    DROP TABLE #databaseList;
    DROP TABLE #processor;
 
    IF @debugMode = 1 RAISERROR('DONE!  Thank you for taking care of your indexes! &nbsp;:)', 0, 42) WITH NoWait;
 
    SET NOCOUNT OFF;
	RETURN 0
END



GO
/****** Object:  StoredProcedure [dbo].[FragmentationCheck]    Script Date: 27/10/2015 09:31:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[FragmentationCheck] (@TargetDatabase AS VARCHAR(255))
AS
/*
Simon D'Morias
30th August 2005
Performs a DBCC SHOWCONTIG on all databases in all user databases and logs the results to the FragmentationLevels table	
*/		
SET NOCOUNT ON
SET XACT_ABORT ON

SET @TargetDatabase = LTRIM(RTRIM(@TargetDatabase))

DECLARE @SQLLine AS NVARCHAR(3000)

SET @SQLLine = 
'USE [' + @TargetDatabase + ']
	SET NOCOUNT ON
	SET XACT_ABORT ON
	SET QUOTED_IDENTIFIER OFF

DECLARE @tablename VARCHAR (128)

-- Declare cursor
DECLARE tables2 CURSOR FOR
   SELECT TABLE_SCHEMA + ''.'' + TABLE_NAME
   FROM INFORMATION_SCHEMA.TABLES
   WHERE TABLE_NAME NOT LIKE ''%000%''
	AND TABLE_TYPE = ''BASE TABLE''

-- Create the table
CREATE TABLE #fraglist (
   ObjectName CHAR (255),
   ObjectId INT,
   IndexName CHAR (255),
   IndexId INT,
   Lvl INT,
   CountPages INT,
   CountRows INT,
   MinRecSize INT,
   MaxRecSize INT,
   AvgRecSize INT,
   ForRecCount INT,
   Extents INT,
   ExtentSwitches INT,
   AvgFreeBytes INT,
   AvgPageDensity INT,
   ScanDensity DECIMAL,
   BestCount INT,
   ActualCount INT,
   LogicalFrag DECIMAL,
   ExtentFrag DECIMAL)

-- Open the cursor
OPEN tables2


-- Loop through all the tables in the database
FETCH NEXT
   FROM tables2
   INTO @tablename

WHILE @@FETCH_STATUS = 0
BEGIN
-- Do the showcontig of all indexes of the table
   INSERT INTO #fraglist 
   EXEC ("DBCC SHOWCONTIG (""" + @tablename + """) 
      WITH FAST, TABLERESULTS, ALL_INDEXES, NO_INFOMSGS")
   FETCH NEXT
      FROM tables2
      INTO @tablename
END

-- Close and deallocate the cursor
CLOSE tables2
DEALLOCATE tables2

INSERT INTO SYSTEM.dbo.FragmentationLevels
SELECT 	@@ServerName,
	db_Name(),
	ObjectName,
	IndexName,
	CountPages,
	CountRows,
	MinRecSize,
   	MaxRecSize,
   	AvgRecSize,
	ForRecCount,
	Extents,
   	AvgFreeBytes,
   	AvgPageDensity,
   	ScanDensity,
   	BestCount,
   	ActualCount,
   	LogicalFrag,
   	ExtentFrag,
	GETDATE()
FROM #fraglist
DROP TABLE #fraglist'
EXECUTE SP_ExecuteSQL @SQLLine



GO
/****** Object:  StoredProcedure [dbo].[GetPartitionInfo]    Script Date: 27/10/2015 09:31:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[GetPartitionInfo] @ObjectName varchar(255)
AS

select partition_id, SDS.name [FileGroup], partition_number, [value] [Range], P.rows [Rows]
	from sys.indexes I 
		LEFT JOIN sys.partition_schemes PS ON I.Data_Space_ID = PS.data_space_id
		LEFT JOIN sys.partition_functions PF ON PF.function_id = PS.Function_ID
		LEFT JOIN sys.partition_range_values RV ON RV.function_id = PF.function_id
		LEFT JOIN sys.partitions P	ON P.Partition_number = RV.boundary_id AND p.index_id = I.index_id
		LEFT JOIN sys.destination_data_spaces DS ON DS.destination_id = P.Partition_Number AND DS.partition_scheme_id = PS.data_space_id
		LEFT JOIN sys.data_spaces SDS ON SDS.data_space_id = DS.data_space_id
	WHERE I.object_id = object_id(@ObjectName) 
		AND P.object_id = object_id(@ObjectName)
		order by partition_number



GO
/****** Object:  StoredProcedure [dbo].[JobDurations]    Script Date: 27/10/2015 09:31:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[JobDurations]
As

/*

        Author:  Ben Anderson
        Date:    18/02/04
        Function:Returns job run time  information from the daily updated table JobAnalysis.

*/

SELECT 	server, SUBSTRING(jobname,1,75) as 'Job',
 convert(varchar(10),dateadd(s,avg(datediff(s,rundatetime,rundatetime+cast(duration_txt as datetime))),0),108) as [AvgDuration],
 case datalength(convert(varchar(6),MIN(duration_int)))
                        when 6 then (select substring(convert(varchar(6),MIN(duration_int)),1,2) + ':' + substring(convert(varchar(6),MIN(duration_int)),3,2) + ':' + substring(convert(varchar(6),MIN(duration_int)),5,2))
                        when 5 then (select '0' + substring(convert(varchar(6),MIN(duration_int)),1,1) + ':' + substring(convert(varchar(6),MIN(duration_int)),2,2) + ':' + substring(convert(varchar(6),MIN(duration_int)),4,2))
                        when 4 then (select '00:' + substring(convert(varchar(6),MIN(duration_int)),1,2) + ':' + substring(convert(varchar(6),MIN(duration_int)),3,2))
                        when 3 then (select '00:0' + substring(convert(varchar(6),MIN(duration_int)),1,1) + ':' + substring(convert(varchar(6),MIN(duration_int)),2,2))
                        when 2 then (select '00:00:' + substring(convert(varchar(6),MIN(duration_int)),1,2))
                        when 1 then (select '00:00:0' + substring(convert(varchar(6),MIN(duration_int)),1,1))
                        end AS 'LowDuration',
 case datalength(convert(varchar(6),MAX(duration_int)))
                        when 6 then (select substring(convert(varchar(6),MAX(duration_int)),1,2) + ':' + substring(convert(varchar(6),MAX(duration_int)),3,2) + ':' + substring(convert(varchar(6),MAX(duration_int)),5,2))
                        when 5 then (select '0' + substring(convert(varchar(6),MAX(duration_int)),1,1) + ':' + substring(convert(varchar(6),MAX(duration_int)),2,2) + ':' + substring(convert(varchar(6),MAX(duration_int)),4,2))
                        when 4 then (select '00:' + substring(convert(varchar(6),MAX(duration_int)),1,2) + ':' + substring(convert(varchar(6),MAX(duration_int)),3,2))
                        when 3 then (select '00:0' + substring(convert(varchar(6),MAX(duration_int)),1,1) + ':' + substring(convert(varchar(6),MAX(duration_int)),2,2))
                        when 2 then (select '00:00:' + substring(convert(varchar(6),MAX(duration_int)),1,2))
                        when 1 then (select '00:00:0' + substring(convert(varchar(6),MAX(duration_int)),1,1))
                        end AS 'HighDuration'
FROM	JobAnalysis
where jobname in (select [name] from msdb.dbo.sysjobs (nolock) where enabled = 1)
GROUP BY jobname, server
ORDER BY jobname



GO
/****** Object:  StoredProcedure [dbo].[JobFailures]    Script Date: 27/10/2015 09:31:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[JobFailures]
AS
/*

        Author:  Ben Anderson
        Date:    18/02/04
        Function:  Returns all failed job steps that are in msdb.dbo.syshistory that are 
                        not currently running or haven't been succesfully re-ran
	Used by the Failed Jobs Job to collect data
*/
SET NOCOUNT ON

CREATE TABLE #job_results (job_id                UNIQUEIDENTIFIER NOT NULL,
                            last_run_date         INT              NOT NULL,
                            last_run_time         INT              NOT NULL,
                            next_run_date         INT              NOT NULL,
                            next_run_time         INT              NOT NULL,
                            next_run_schedule_id  INT              NOT NULL,
                            requested_to_run      INT              NOT NULL, 
                            request_source        INT              NOT NULL,
                            request_source_id     sysname          COLLATE database_default NULL,
                            running               INT              NOT NULL, 
                            current_step          INT              NOT NULL,
                            current_retry_attempt INT              NOT NULL,
                            job_state             INT              NOT NULL)

    INSERT INTO #job_results
    EXECUTE master.dbo.xp_sqlagent_enum_jobs 1, sa, null

    DELETE FROM #job_results
        WHERE running = 0

   create clustered index temp1  on #job_results (job_id)

		TRUNCATE TABLE Job_Failures
		
		INSERT INTO dbo.Job_Failures
        select js.job_id, @@servername, sj.name ,js.step_id, convert(datetime,convert(varchar(10),convert(datetime,convert(varchar(8),case js.last_run_date when 0 then '19500101' else js.last_run_date end)),101) + ' ' + 
        	case datalength(convert(varchar(6),js.last_run_time))
        	when 6 then (select substring(convert(varchar(6),js.last_run_time),1,2) + ':' + substring(convert(varchar(6),js.last_run_time),3,2) + ':' + substring(convert(varchar(6),js.last_run_time),5,2))
        	when 5 then (select '0' + substring(convert(varchar(6),js.last_run_time),1,1) + ':' + substring(convert(varchar(6),js.last_run_time),2,2) + ':' + substring(convert(varchar(6),js.last_run_time),4,2))
        	when 4 then (select '00:' + substring(convert(varchar(6),js.last_run_time),1,2) + ':' + substring(convert(varchar(6),js.last_run_time),3,2))
        	when 3 then (select '00:0' + substring(convert(varchar(6),js.last_run_time),1,1) + ':' + substring(convert(varchar(6),js.last_run_time),2,2))
        	when 2 then (select '00:00:' + substring(convert(varchar(6),js.last_run_time),1,2))
        	when 1 then (select '00:00:0' + substring(convert(varchar(6),js.last_run_time),1,1))
        	end) AS 'run_time',JR.running
        from msdb.dbo.sysjobsteps js 
                join msdb.dbo.sysjobs sj
                on js.job_id = sj.job_id
			LEFT JOIN #job_results JR 
				ON JR.job_id=js.job_id
        where --js.job_id not in (select job_id from #job_results) and 
				sj.enabled = 1
                and js.last_run_outcome = 0
                --and js.last_run_time <> 0
                and js.last_run_date <> 0

        drop table #job_results



GO
/****** Object:  StoredProcedure [dbo].[JobHistory]    Script Date: 27/10/2015 09:31:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[JobHistory] @jobid uniqueidentifier

AS

/*
--exec [JobHistory] @jobid='BC49D48F-53FD-4177-AA13-C10C1A437D3B'
        Author:  Ben Anderson
        Date:    18/02/04
        Function:  Returns SQL Agent job history for any given jobid.

*/

SET NOCOUNT ON

IF EXISTS (select TOP 100 step_id, step_name, run_status, run_date, run_time, run_duration, message  
		from msdb.dbo.sysjobhistory (nolock)
			where job_id = @jobid)
	BEGIN
		DECLARE @JobOverview TABLE (
			[ID] int identity(1,1),
			instance_id int
		)
		
		INSERT INTO @JobOverview (instance_id)
		select instance_id
		from msdb.dbo.sysjobhistory sh1
		WHERE sh1.job_id = @jobid
		AND sh1.step_id = 0
		ORDER BY instance_id


-------------
CREATE TABLE #Tempscheduleinfo
(	job_id varchar(100),
	server varchar(100),
	jobname varchar(100),
	schedulename varchar(100),
	enabled varchar(100),
	frequency varchar(100),
	interval varchar(100),
	time varchar(100),
	nextrun varchar(100)
)

insert into #Tempscheduleinfo
select
SJ.job_id,'Server'       = left(@@ServerName,20),
'JobName'      = left(S.name,30),
'ScheduleName' = left(ss.name,25),
'Enabled'      = CASE (S.enabled)
                  WHEN 0 THEN 'No'
                  WHEN 1 THEN 'Yes'
                  ELSE '??'
                END,
'Frequency'    = CASE(ss.freq_type)
                  WHEN 1  THEN 'Once'
                  WHEN 4  THEN 'Daily'
                  WHEN 8  THEN 
                    (case when (ss.freq_recurrence_factor > 1) 
                        then  'Every ' + convert(varchar(3),ss.freq_recurrence_factor) + ' Weeks'  else 'Weekly'  end)
                  WHEN 16 THEN 
                    (case when (ss.freq_recurrence_factor > 1) 
                    then  'Every ' + convert(varchar(3),ss.freq_recurrence_factor) + ' Months' else 'Monthly' end)
                  WHEN 32 THEN 'Every ' + convert(varchar(3),ss.freq_recurrence_factor) + ' Months' -- RELATIVE
                  WHEN 64 THEN 'SQL Startup'
                  WHEN 128 THEN 'SQL Idle'
                  ELSE '??'
                END,
'Interval'    = CASE
                 WHEN (freq_type = 1)                       then 'One time only'
                 WHEN (freq_type = 4 and freq_interval = 1) then 'Every Day'
                 WHEN (freq_type = 4 and freq_interval > 1) then 'Every ' + convert(varchar(10),freq_interval) + ' Days'
                 WHEN (freq_type = 8) then (select 'Weekly Schedule' = D1+ D2+D3+D4+D5+D6+D7 
                       from (select ss.schedule_id,
                     freq_interval, 
                     'D1' = CASE WHEN (freq_interval & 1  <> 0) then 'Sun ' ELSE '' END,
                     'D2' = CASE WHEN (freq_interval & 2  <> 0) then 'Mon '  ELSE '' END,
                     'D3' = CASE WHEN (freq_interval & 4  <> 0) then 'Tue '  ELSE '' END,
                     'D4' = CASE WHEN (freq_interval & 8  <> 0) then 'Wed '  ELSE '' END,
                    'D5' = CASE WHEN (freq_interval & 16 <> 0) then 'Thu '  ELSE '' END,
                     'D6' = CASE WHEN (freq_interval & 32 <> 0) then 'Fri '  ELSE '' END,
                     'D7' = CASE WHEN (freq_interval & 64 <> 0) then 'Sat '  ELSE '' END
                                 from msdb..sysschedules ss (nolock)
                                where freq_type = 8
                           ) as F
                       where schedule_id = sj.schedule_id
                                            )
                 WHEN (freq_type = 16) then 'Day ' + convert(varchar(2),freq_interval) 
                 WHEN (freq_type = 32) then (select freq_rel + WDAY 
                    from (select ss.schedule_id,
                                 'freq_rel' = CASE(freq_relative_interval)
                                                WHEN 1 then 'First'
                                                WHEN 2 then 'Second'
                                                WHEN 4 then 'Third'
                                                WHEN 8 then 'Fourth'
                                                WHEN 16 then 'Last'
                                                ELSE '??'
                                              END,
                                'WDAY'     = CASE (freq_interval)
                                                WHEN 1 then ' Sun'
                                                WHEN 2 then ' Mon'
                                                WHEN 3 then ' Tue'
                                                WHEN 4 then ' Wed'
                                                WHEN 5 then ' Thu'
                                                WHEN 6 then ' Fri'
                                                WHEN 7 then ' Sat'
                                                WHEN 8 then ' Day'
                                                WHEN 9 then ' Weekday'
                                                WHEN 10 then ' Weekend'
                                                ELSE '??'
                                              END
                            from msdb..sysschedules ss (nolock)
                            where ss.freq_type = 32
                         ) as WS 
                   where WS.schedule_id =ss.schedule_id
                   ) 
               END,
'Time' = CASE (freq_subday_type)
                WHEN 1 then   left(stuff((stuff((replicate('0', 6 - len(Active_Start_Time)))+ convert(varchar(6),Active_Start_Time),3,0,':')),6,0,':'),8)
                WHEN 2 then 'Every ' + convert(varchar(10),freq_subday_interval) + ' seconds'
                WHEN 4 then 'Every ' + convert(varchar(10),freq_subday_interval) + ' minutes'
                WHEN 8 then 'Every ' + convert(varchar(10),freq_subday_interval) + ' hours'
                ELSE '??'
              END,

'Next Run Time' = CASE SJ.next_run_date
                   WHEN 0 THEN cast('n/a' as char(10))
                   ELSE convert(char(10), convert(datetime, convert(char(8),SJ.next_run_date)),120)  + ' ' + left(stuff((stuff((replicate('0', 6 - len(next_run_time)))+ convert(varchar(6),next_run_time),3,0,':')),6,0,':'),8)
                 END
  
   from msdb.dbo.sysjobschedules SJ (nolock)
   join msdb.dbo.sysjobs         S (nolock) on S.job_id       = SJ.job_id
   join msdb.dbo.sysschedules    SS (nolock) on ss.schedule_id = sj.schedule_id
where  sj.job_id = @jobid
order by S.name





------------





		select TOP 100 (
				SELECT TOP 1 [ID]
				FROM @JobOverview
				WHERE instance_id >= sh.instance_id
				ORDER BY [ID]
			) As [Group], step_id, step_name, run_status, convert(varchar(10),convert(datetime,convert(varchar(8),run_date)),103) AS 'run_date',
			case datalength(convert(varchar(6),run_time))
			when 6 then (select substring(convert(varchar(6),run_time),1,2) + ':' + substring(convert(varchar(6),run_time),3,2) + ':' + substring(convert(varchar(6),run_time),5,2))
			when 5 then (select '0' + substring(convert(varchar(6),run_time),1,1) + ':' + substring(convert(varchar(6),run_time),2,2) + ':' + substring(convert(varchar(6),run_time),4,2))
			when 4 then (select '00:' + substring(convert(varchar(6),run_time),1,2) + ':' + substring(convert(varchar(6),run_time),3,2))
			when 3 then (select '00:0' + substring(convert(varchar(6),run_time),1,1) + ':' + substring(convert(varchar(6),run_time),2,2))
			when 2 then (select '00:00:' + substring(convert(varchar(6),run_time),1,2))
			when 1 then (select '00:00:0' + substring(convert(varchar(6),run_time),1,1))
			end AS 'run_time', 
			case datalength(convert(varchar(6),run_duration))
			when 6 then (select substring(convert(varchar(6),run_duration),1,2) + ':' + substring(convert(varchar(6),run_duration),3,2) + ':' + substring(convert(varchar(6),run_duration),5,2))
			when 5 then (select '0' + substring(convert(varchar(6),run_duration),1,1) + ':' + substring(convert(varchar(6),run_duration),2,2) + ':' + substring(convert(varchar(6),run_duration),4,2))
			when 4 then (select '00:' + substring(convert(varchar(6),run_duration),1,2) + ':' + substring(convert(varchar(6),run_duration),3,2))
			when 3 then (select '00:0' + substring(convert(varchar(6),run_duration),1,1) + ':' + substring(convert(varchar(6),run_duration),2,2))
			when 2 then (select '00:00:' + substring(convert(varchar(6),run_duration),1,2))
			when 1 then (select '00:00:0' + substring(convert(varchar(6),run_duration),1,1))
			end AS 'run_duration'
			, message,SI.frequency,SI.interval,Si.time,SI.nextrun
		from msdb.dbo.sysjobhistory  sh (nolock)
JOIN #Tempscheduleinfo SI
ON SI.job_id=sh.job_id
where sh.job_id = @jobid
		order by [Group] DESC, step_id
--		order by convert(datetime,convert(varchar(8),run_date)) DESC, run_time DESC, SortOrder, step_id DESC
	END
ELSE
	BEGIN
		select '' as [Group],'' as step_id,'' as step_name,'' as run_status,'' as run_date,'' as run_time,
				'' as run_duration,'' as message,'' as frequency,'' as interval,'' as [time], '' as nextrun
	END



GO
/****** Object:  StoredProcedure [dbo].[JobReporting]    Script Date: 27/10/2015 09:31:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE PROCEDURE [dbo].[JobReporting] AS

SET NOCOUNT ON

PRINT 'Average, Min and Max Run-Duration for Jobs on Server: ' + @@SERVERNAME + ' 
  '
SELECT 	server,
	SUBSTRING(jobname,1,50),
	AvgDuration = AVG(duration_int),
	LowDuration = MIN(duration_int),
	HighDuration = MAX(duration_int)
FROM	JobAnalysis
GROUP BY server, jobname, runstatus

PRINT ' '
PRINT 'Failures for Jobs on Server: ' + @@SERVERNAME + ' 
  '
SELECT  Server = server	,
	Job	= jobname,
	Status  = runstatus,
	RunTime     = runtime,
	DayOfWeek = dayofweek,
	DayOfMonth  = DAY(rundatetime)
FROM	JobAnalysis
WHERE	runstatus <> 'Succeeded'
AND rundatetime > GETDATE()-7
GROUP BY server, jobname, runstatus, runtime, dayofweek, DAY(rundatetime)
IF @@ROWCOUNT = 0 
	BEGIN 
		PRINT 'NO FAILURES IN THE LAST 7 DAYS - YAY!'
	END

PRINT ' '
PRINT 'Jobs Taking Longer Than Usual for Jobs on Server: ' + @@SERVERNAME + ' 
  '
SELECT  o.server,
	o.jobname,
	avg_duration = LEFT(RIGHT('000000'+CONVERT(VARCHAR(6),avg_duration), 6),2)+':'+
			  SUBSTRING(RIGHT('000000'+CONVERT(VARCHAR(6),avg_duration), 6), 3, 2)+':'+
			  RIGHT(RIGHT('000000'+CONVERT(VARCHAR(6),avg_duration), 6),2),
	this_duration = duration_txt,
	rundatetime,
	dayofweek
FROM 	JobAnalysis o
JOIN	(SELECT	server,
		jobname, 
		AVG(duration_int) AS avg_duration
	FROM 	JobAnalysis
	WHERE	duration_int > 0
	GROUP BY server, jobname) AS avgs
ON 	o.server = avgs.server 
AND 	o.jobname = avgs.jobname 
WHERE 	duration_int > ( avg_duration*2)
AND rundatetime > GETDATE()-7
ORDER BY rundatetime
IF @@ROWCOUNT = 0 
	BEGIN 
		PRINT 'ALL JOBS RUNNING AS USUAL!'
	END



GO
/****** Object:  StoredProcedure [dbo].[List_DBRoles]    Script Date: 27/10/2015 09:31:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create procedure [dbo].[List_DBRoles]

(

@database nvarchar(128)=null,
@user varchar(20)=null,
@dbo char(1)=null,
@access char(1)=null,
@security char(1)=null,
@ddl char(1)=null,
@datareader char(1)=null,
@datawriter char(1)=null,
@denyread char(1)=null,
@denywrite char(1)=null,
@backupop char(1)=null
)

as

declare @dbname varchar(200)
declare @mSql1 varchar(8000)

CREATE TABLE #DBROLES	( 
DBName sysname not null,
UserName sysname not null,
db_owner varchar(3) not null,
db_accessadmin varchar(3) not null,
db_securityadmin varchar(3) not null,
db_ddladmin varchar(3) not null,
db_datareader varchar(3) not null,
db_datawriter varchar(3) not null,
db_denydatareader varchar(3) not null,
db_denydatawriter varchar(3) not null,
db_backupoperator varchar(3) not null,
Cur_Date datetime not null default getdate()
)

DECLARE DBName_Cursor CURSOR FOR
select name
from master.dbo.sysdatabases
where name not in ('mssecurity','tempdb')
Order by name

OPEN DBName_Cursor
FETCH NEXT FROM DBName_Cursor INTO @dbname
WHILE @@FETCH_STATUS = 0

BEGIN
Set @mSQL1 = ' Insert into #DBROLES ( DBName, UserName, db_owner, db_accessadmin,
db_securityadmin, db_ddladmin, db_datareader, db_datawriter,
db_denydatareader, db_denydatawriter, db_backupoperator)
SELECT '+''''+@dbName +''''+ ' as DBName ,UserName, '+char(13)+ '
Max(CASE RoleName WHEN ''db_owner'' THEN ''Yes'' ELSE ''No'' END) AS db_owner,
Max(CASE RoleName WHEN ''db_accessadmin '' THEN ''Yes'' ELSE ''No'' END) AS db_accessadmin ,
Max(CASE RoleName WHEN ''db_securityadmin'' THEN ''Yes'' ELSE ''No'' END) AS db_securityadmin,
Max(CASE RoleName WHEN ''db_ddladmin'' THEN ''Yes'' ELSE ''No'' END) AS db_ddladmin,
Max(CASE RoleName WHEN ''db_datareader'' THEN ''Yes'' ELSE ''No'' END) AS db_datareader,
Max(CASE RoleName WHEN ''db_datawriter'' THEN ''Yes'' ELSE ''No'' END) AS db_datawriter,
Max(CASE RoleName WHEN ''db_denydatareader'' THEN ''Yes'' ELSE ''No'' END) AS db_denydatareader,
Max(CASE RoleName WHEN ''db_denydatawriter'' THEN ''Yes'' ELSE ''No'' END) AS db_denydatawriter,
Max(CASE RoleName WHEN ''db_backupoperator'' THEN ''Yes'' ELSE ''No'' END) AS db_backupoperator
from (
select b.name as USERName, c.name as RoleName
from ' + @dbName+'.dbo.sysmembers a '+char(13)+
' join '+ @dbName+'.dbo.sysusers b '+char(13)+
' on a.memberuid = b.uid join '+@dbName +'.dbo.sysusers c
on a.groupuid = c.uid )s
Group by USERName
order by UserName'

--Print @mSql1

Execute (@mSql1)
FETCH NEXT FROM DBName_Cursor INTO @dbname
END
CLOSE DBName_Cursor
DEALLOCATE DBName_Cursor
Select * from #DBRoles
where ((@database is null) OR (DBName LIKE '%'+@database+'%')) AND
((@user is null) OR (UserName LIKE '%'+@user+'%')) AND
((@dbo is null) OR (db_owner = 'Yes')) AND
((@access is null) OR (db_accessadmin = 'Yes')) AND
((@security is null) OR (db_securityadmin = 'Yes')) AND
((@ddl is null) OR (db_ddladmin = 'Yes')) AND
((@datareader is null) OR (db_datareader = 'Yes')) AND
((@datawriter is null) OR (db_datawriter = 'Yes')) AND
((@denyread is null) OR (db_denydatareader = 'Yes')) AND
((@denywrite is null) OR (db_denydatawriter = 'Yes')) AND
((@backupop is null) OR (db_backupoperator = 'Yes'))




GO
/****** Object:  StoredProcedure [dbo].[Reindex]    Script Date: 27/10/2015 09:31:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[Reindex]
 
    /* Declare Parameters */
      @minFragmentation     FLOAT           = 5.0  
        /* in percent, will not defrag if fragmentation less than specified */
    , @rebuildThreshold     FLOAT           = 30.0  
        /* in percent, greater than @rebuildThreshold will result in rebuild instead of reorg */
    , @executeSQL           BIT             = 1     
        /* 1 = execute; 0 = print command only */
    , @DATABASE             VARCHAR(128)    = Null
        /* Option to specify a database name; null will return all */
    , @tableName            VARCHAR(4000)   = Null  -- databaseName.schema.tableName
        /* Option to specify a table name; null will return all */
    , @onlineRebuild        BIT             = 1     
        /* 1 = online rebuild; 0 = offline rebuild; only in Enterprise */
    , @maxDopRestriction    TINYINT         = Null
        /* Option to restrict the number of processors for the operation; only in Enterprise */
    , @printCommands        BIT             = 0     
        /* 1 = print commands; 0 = do not print commands */
    , @printFragmentation   BIT             = 0
        /* 1 = print fragmentation prior to defrag; 
           0 = do not print */
    , @defragDelay          CHAR(8)         = '00:00:05'
        /* time to wait between defrag commands */
    , @scanMode             NVARCHAR(8)     = N'Limited'
        /* scan level to be used with dm_db_index_physical_stats. Options are DEFAULT, NULL, LIMITED, SAMPLED, or DETAILED. The default (NULL) is LIMITED */
    , @debugMode            BIT             = 0
        /* display some useful comments to help determine if/where issues occur */
AS
/*********************************************************************************
    Name:       dba_indexDefrag_sp
 
    Author:     Michelle Ufford, http://sqlfool.com
 
    Purpose:    Defrags all indexes for one or more databases
 
    Notes:
 
    CAUTION: TRANSACTION LOG SIZE MUST BE MONITORED CLOSELY WHEN DEFRAGMENTING.
 
      @minFragmentation     defaulted to 10%, will not defrag if fragmentation 
                            is less than that
 
      @rebuildThreshold     defaulted to 30% as recommended by Microsoft in BOL;
                            greater than 30% will result in rebuild instead
 
      @executeSQL           1 = execute the SQL generated by this proc; 
                            0 = print command only
 
      @database             Optional, specify specific database name to defrag;
                            If not specified, all non-system databases will
                            be defragged.
 
      @tableName            Specify if you only want to defrag indexes for a 
                            specific table, format = databaseName.schema.tableName;
                            if not specified, all tables will be defragged.
 
      @onlineRebuild        1 = online rebuild; 
                            0 = offline rebuild
 
      @maxDopRestriction    Option to specify a processor limit for index rebuilds
 
      @printCommands        1 = print commands to screen; 
                            0 = do not print commands
 
      @printFragmentation   1 = print fragmentation to screen;
                            0 = do not print fragmentation
 
      @defragDelay          time to wait between defrag commands; gives the
                            server a little time to catch up 
      
      @scanMode             scan level to be used with dm_db_index_physical_stats. 
                            Options are DEFAULT, NULL, LIMITED, SAMPLED, or 
                            DETAILED. The default (NULL) is LIMITED
 
      @debugMode            1 = display debug comments; helps with troubleshooting
                            0 = do not display debug comments
 
    Called by:  SQL Agent Job or DBA
 
    Date        Initials	Description
    ----------------------------------------------------------------------------
    2008-10-27  MFU         Initial Release for public consumption
    2008-11-17  MFU         Added page-count to log table
                            , added @printFragmentation option
    2009-03-17  MFU         Provided support for centralized execution, 
                            , consolidated Enterprise & Standard versions
                            , added @debugMode, @maxDopRestriction
                            , modified LOB and partition logic
    2009-05-12  JAP         Added @scanMode                            
*********************************************************************************
    Exec dbo.dba_indexDefrag_sp
          @executeSQL           = 0
        , @minFragmentation     = 20
        , @printCommands        = 1
        , @debugMode            = 1
        , @printFragmentation   = 1
        , @database             = 'PARE'
        , @tableName            = '';
*********************************************************************************/																
 
SET NOCOUNT ON;
SET XACT_Abort ON;
SET Quoted_Identifier ON;
 
BEGIN
	
    IF @debugMode = 1 RAISERROR('Dusting off the spiderwebs and starting up...', 0, 42) WITH NoWait;
 -----------------------------------------------------------
    /* Declare our variables */
    DECLARE   @objectID             INT
            , @databaseID           INT
            , @databaseName         NVARCHAR(128)
            , @indexID              INT
            , @partitionCount       BIGINT
            , @schemaName           NVARCHAR(128)
            , @objectName           NVARCHAR(128)
            , @indexName            NVARCHAR(128)
            , @partitionNumber      SMALLINT
            , @partitions           SMALLINT
            , @fragmentation        FLOAT
            , @pageCount            INT
            , @sqlCommand           NVARCHAR(4000)
            , @rebuildCommand       NVARCHAR(200)
            , @dateTimeStart        DATETIME
            , @dateTimeEnd          DATETIME
            , @containsLOB          BIT
            , @editionCheck         BIT
            , @debugMessage         VARCHAR(128)
            , @updateSQL            NVARCHAR(4000)
            , @partitionSQL         NVARCHAR(4000)
            , @partitionSQL_Param   NVARCHAR(1000)
            , @LOB_SQL              NVARCHAR(4000)
            , @LOB_SQL_Param        NVARCHAR(1000);
 
    /* Create our temporary tables */
    CREATE TABLE #indexDefragList
    (
          databaseID        INT
        , databaseName      NVARCHAR(128)
        , objectID          INT
        , indexID           INT
        , partitionNumber   SMALLINT
        , fragmentation     FLOAT
        , page_count        INT
        , defragStatus      BIT
        , schemaName        NVARCHAR(128)   Null
        , objectName        NVARCHAR(128)   Null
        , indexName         NVARCHAR(128)   Null
    );
 
    CREATE TABLE #databaseList
    (
          databaseID        INT
        , databaseName      VARCHAR(128)
    );
 
    CREATE TABLE #processor 
    (
          [INDEX]           INT
        , Name              VARCHAR(128)
        , Internal_Value    INT
        , Character_Value   INT
    );
 
    IF @debugMode = 1 RAISERROR('Beginning validation...', 0, 42) WITH NoWait;
 
    /* Just a little validation... */
    IF @minFragmentation Not Between 0.00 And 100.0
        SET @minFragmentation = 5.0;
 
    IF @rebuildThreshold Not Between 0.00 And 100.0
        SET @rebuildThreshold = 30.0;
 
    IF @defragDelay Not Like '00:[0-5][0-9]:[0-5][0-9]'
        SET @defragDelay = '00:00:05';
 
    /* Make sure we're not exceeding the number of processors we have available */
    INSERT INTO #processor
    EXECUTE XP_MSVER 'ProcessorCount';
 
    IF @maxDopRestriction IS Not Null And @maxDopRestriction > (SELECT Internal_Value FROM #processor)
        SELECT @maxDopRestriction = Internal_Value
        FROM #processor;
 
    /* Check our server version; 1804890536 = Enterprise, 610778273 = Enterprise Evaluation, -2117995310 = Developer */
    IF (SELECT SERVERPROPERTY('EditionID')) In (1804890536, 610778273, -2117995310) 
        SET @editionCheck = 1 -- supports online rebuilds
    ELSE
        SET @editionCheck = 0; -- does not support online rebuilds
 
    IF @debugMode = 1 RAISERROR('Grabbing a list of our databases...', 0, 42) WITH NoWait;
 
    /* Retrieve the list of databases to investigate */
    INSERT INTO #databaseList
    SELECT database_id
        , name
    FROM sys.databases
    WHERE name = IsNull(@DATABASE, name)
        And database_id > 4 -- exclude system databases
        And [STATE] = 0; -- state must be ONLINE
 
    IF @debugMode = 1 RAISERROR('Looping through our list of databases and checking for fragmentation...', 0, 42) WITH NoWait;
 
    /* Loop through our list of databases */
    WHILE (SELECT COUNT(*) FROM #databaseList) > 0
    BEGIN
 
        SELECT TOP 1 @databaseID = databaseID
        FROM #databaseList;
 
        SELECT @debugMessage = '  working on ' + DB_NAME(@databaseID) + '...';
 
        IF @debugMode = 1
            RAISERROR(@debugMessage, 0, 42) WITH NoWait;
 
       /* Determine which indexes to defrag using our user-defined parameters */
        INSERT INTO #indexDefragList
        SELECT
              database_id AS databaseID
            , QUOTENAME(DB_NAME(database_id)) AS 'databaseName'
            , [OBJECT_ID] AS objectID
            , index_id AS indexID
            , partition_number AS partitionNumber
            , avg_fragmentation_in_percent AS fragmentation
            , page_count 
            , 0 AS 'defragStatus' /* 0 = unprocessed, 1 = processed */
            , Null AS 'schemaName'
            , Null AS 'objectName'
            , Null AS 'indexName'
        FROM sys.dm_db_index_physical_stats (@databaseID, OBJECT_ID(@tableName), Null , Null, @scanMode)
        WHERE avg_fragmentation_in_percent >= @minFragmentation 
            And index_id > 0 -- ignore heaps
            And page_count > 8 -- ignore objects with less than 1 extent
        OPTION (MaxDop 1);
 
        DELETE FROM #databaseList
        WHERE databaseID = @databaseID;
 
    END
 
    CREATE CLUSTERED INDEX CIX_temp_indexDefragList
        ON #indexDefragList(databaseID, objectID, indexID, partitionNumber);
 
    SELECT @debugMessage = 'Looping through our list... there''s ' + CAST(COUNT(*) AS VARCHAR(10)) + ' indexes to defrag!'
    FROM #indexDefragList;
 
    IF @debugMode = 1 RAISERROR(@debugMessage, 0, 42) WITH NoWait;
 
    /* Begin our loop for defragging */
    WHILE (SELECT COUNT(*) FROM #indexDefragList WHERE defragStatus = 0) > 0
    BEGIN
 
        IF @debugMode = 1 RAISERROR('  Picking an index to beat into shape...', 0, 42) WITH NoWait;
 
        /* Grab the most fragmented index first to defrag */
        SELECT TOP 1 
              @objectID         = objectID
            , @indexID          = indexID
            , @databaseID       = databaseID
            , @databaseName     = databaseName
            , @fragmentation    = fragmentation
            , @partitionNumber  = partitionNumber
            , @pageCount        = page_count
        FROM #indexDefragList
        WHERE defragStatus = 0
        ORDER BY fragmentation DESC;
 
        IF @debugMode = 1 RAISERROR('  Looking up the specifics for our index...', 0, 42) WITH NoWait;
 
        /* Look up index information */
        SELECT @updateSQL = N'Update idl
            Set schemaName = QuoteName(s.name)
                , objectName = QuoteName(o.name)
                , indexName = QuoteName(i.name)
            From #indexDefragList As idl
            Inner Join ' + @databaseName + '.sys.objects As o
                On idl.objectID = o.object_id
            Inner Join ' + @databaseName + '.sys.indexes As i
                On o.object_id = i.object_id
            Inner Join ' + @databaseName + '.sys.schemas As s
                On o.schema_id = s.schema_id
            Where o.object_id = ' + CAST(@objectID AS VARCHAR(10)) + '
                And i.index_id = ' + CAST(@indexID AS VARCHAR(10)) + '
                And i.type > 0
                And idl.databaseID = ' + CAST(@databaseID AS VARCHAR(10));
 
        EXECUTE SP_EXECUTESQL @updateSQL;
 
        /* Grab our object names */
        SELECT @objectName  = objectName
            , @schemaName   = schemaName
            , @indexName    = indexName
        FROM #indexDefragList
        WHERE objectID = @objectID
            And indexID = @indexID
            And databaseID = @databaseID;
 
        IF @debugMode = 1 RAISERROR('  Grabbing the partition count...', 0, 42) WITH NoWait;
 
        /* Determine if the index is partitioned */
        SELECT @partitionSQL = 'Select @partitionCount_OUT = Count(*)
                                    From ' + @databaseName + '.sys.partitions
                                    Where object_id = ' + CAST(@objectID AS VARCHAR(10)) + '
                                        And index_id = ' + CAST(@indexID AS VARCHAR(10)) + ';'
            , @partitionSQL_Param = '@partitionCount_OUT int OutPut';
 
        EXECUTE SP_EXECUTESQL @partitionSQL, @partitionSQL_Param, @partitionCount_OUT = @partitionCount OUTPUT;
 
        IF @debugMode = 1 RAISERROR('  Seeing if there''s any LOBs to be handled...', 0, 42) WITH NoWait;
 
        /* Determine if the table contains LOBs */
        SELECT @LOB_SQL = ' Select Top 1 @containsLOB_OUT = column_id
                            From ' + @databaseName + '.sys.columns With (NoLock) 
                            Where [object_id] = ' + CAST(@objectID AS VARCHAR(10)) + '
                                And (system_type_id In (34, 35, 99)
                                        Or max_length = -1);'
                            /*  system_type_id --> 34 = image, 35 = text, 99 = ntext
                                max_length = -1 --> varbinary(max), varchar(max), nvarchar(max), xml */
                , @LOB_SQL_Param = '@containsLOB_OUT int OutPut';
 
        EXECUTE SP_EXECUTESQL @LOB_SQL, @LOB_SQL_Param, @containsLOB_OUT = @containsLOB OUTPUT;
 
        IF @debugMode = 1 RAISERROR('  Building our SQL statements...', 0, 42) WITH NoWait;
 
        /* If there's not a lot of fragmentation, or if we have a LOB, we should reorganize */
        IF @fragmentation < @rebuildThreshold Or @containsLOB = 1 Or @partitionCount > 1 
        BEGIN
 
            SET @sqlCommand = N'Alter Index ' + @indexName + N' On ' + @databaseName + N'.' 
                                + @schemaName + N'.' + @objectName + N' ReOrganize';
 
            /* If our index is partitioned, we should always reorganize */
            IF @partitionCount > 1
                SET @sqlCommand = @sqlCommand + N' Partition = ' 
                                + CAST(@partitionNumber AS NVARCHAR(10));
 
        END;

        /* If the index is heavily fragmented and doesn't contain any partitions or LOB's, rebuild it */
        IF @fragmentation >= @rebuildThreshold And IsNull(@containsLOB, 0)!= 1 And @partitionCount <= 1 
			And  DATEPART(HOUR,GETDATE()) BETWEEN 4 AND 6
        BEGIN
 
            /* Set online rebuild options; requires Enterprise Edition */
            IF @onlineRebuild = 1 And @editionCheck = 1 
                SET @rebuildCommand = N' Rebuild With (Online = On';
            ELSE
                SET @rebuildCommand = N' Rebuild With (Online = Off';
 
            /* Set processor restriction options; requires Enterprise Edition */
            IF @maxDopRestriction IS Not Null And @editionCheck = 1
                SET @rebuildCommand = @rebuildCommand + N', MaxDop = ' + CAST(@maxDopRestriction AS VARCHAR(2)) + N')';
            ELSE
                SET @rebuildCommand = @rebuildCommand + N')';
 
            SET @sqlCommand = N'Alter Index ' + @indexName + N' On ' + @databaseName + N'.'
                            + @schemaName + N'.' + @objectName + @rebuildCommand;
 
        END;
 
        /* Are we executing the SQL?  If so, do it */
        IF @executeSQL = 1
        BEGIN
 
            IF @debugMode = 1 RAISERROR('  Executing SQL statements...', 0, 42) WITH NoWait;
 
            /* Grab the time for logging purposes */
            SET @dateTimeStart  = GETDATE();
            EXECUTE SP_EXECUTESQL @sqlCommand;
            SET @dateTimeEnd  = GETDATE();
 
            /* Log our actions */
            INSERT INTO dbo.dba_indexDefragLog
            (
                  databaseID
                , databaseName
                , objectID
                , objectName
                , indexID
                , indexName
                , partitionNumber
                , fragmentation
                , page_count
                , dateTimeStart
                , durationSeconds
            )
            SELECT
                  @databaseID
                , @databaseName
                , @objectID
                , @objectName
                , @indexID
                , @indexName
                , @partitionNumber
                , @fragmentation
                , @pageCount
                , @dateTimeStart
                , DATEDIFF(SECOND, @dateTimeStart, @dateTimeEnd);
 
            /* Just a little breather for the server */
            WAITFOR Delay @defragDelay;
 
            /* Print if specified to do so */
            IF @printCommands = 1
                PRINT N'Executed: ' + @sqlCommand;
        END
        ELSE
        /* Looks like we're not executing, just printing the commands */
        BEGIN
            IF @debugMode = 1 RAISERROR('  Printing SQL statements...', 0, 42) WITH NoWait;
 
            IF @printCommands = 1 PRINT IsNull(@sqlCommand, 'error!');
        END
 
        IF @debugMode = 1 RAISERROR('  Updating our index defrag status...', 0, 42) WITH NoWait;
 
        /* Update our index defrag list so we know we've finished with that index */
        UPDATE #indexDefragList
        SET defragStatus = 1
        WHERE databaseID       = @databaseID
          And objectID         = @objectID
          And indexID          = @indexID
          And partitionNumber  = @partitionNumber;
 
    END
 
    /* Do we want to output our fragmentation results? */
    IF @printFragmentation = 1
    BEGIN
 
        IF @debugMode = 1 RAISERROR('  Displaying fragmentation results...', 0, 42) WITH NoWait;
 
        SELECT databaseID
            , databaseName
            , objectID
            , objectName
            , indexID
            , indexName
            , fragmentation
            , page_count
        FROM #indexDefragList;
 
    END;
 
    /* When everything is said and done, make sure to get rid of our temp table */
    DROP TABLE #indexDefragList;
    DROP TABLE #databaseList;
    DROP TABLE #processor;
 
    IF @debugMode = 1 RAISERROR('DONE!  Thank you for taking care of your indexes! &nbsp;:)', 0, 42) WITH NoWait;
 
    SET NOCOUNT OFF;
	RETURN 0
END



GO
/****** Object:  StoredProcedure [dbo].[Reindexing]    Script Date: 27/10/2015 09:31:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Reindexing] @db_name varchar(400), @MaxHours int
AS

SET NOCOUNT ON

DECLARE @EntryDate DATETIME, @dbid INT, @StartTime DATETIME, @referenceDate DATETIME, @StartTimeInMinutes INT, @fragmentThreshold INT, @logThreshold INT, @indexThreshold INT, @idleThreshold INT, @SQL VARCHAR(2000)
SET @EntryDate = CAST(CONVERT(VARCHAR(11),GETDATE(),113) AS DATETIME)
SET @dbid = DB_ID(@db_name)
SET @referenceDate = '01 Jan 2000'
SET @StartTime = GETDATE()
SET @StartTimeInMinutes = DATEDIFF(MINUTE, @referenceDate, @StartTime)
SET @fragmentThreshold = 25			-- 25%, defragmentation required to trigger rebuild process
SET @logThreshold = 50				-- 50%, log usage to backup log instead of rebuilding index
SET @indexThreshold = 15000000		-- 15GB, total size of indexes to rebuild should not exceed this number
SET @idleThreshold = 120			-- 120 min, time between index rebuilds to trigger DBA alerts

-- CREATE THE TEMP TABLE TO STORE THE TABLES TO EXCLUDE
IF OBJECT_ID('tempdb..#TablesToExcludeReIndex') IS NOT NULL 
	DROP TABLE [dbo].[#TablesToExcludeReIndex]
CREATE TABLE #TablesToExcludeReIndex (
	[database_name] [varchar](100) NOT NULL,
	[object_id] [int] NOT NULL,
	[table_name] [varchar](100) NOT NULL
)

BEGIN TRY
	SET @SQL = 'USE ' + @db_name + ' SELECT DISTINCT c.TABLE_CATALOG, i.[object_id], c.TABLE_NAME
			FROM sys.indexes i JOIN INFORMATION_SCHEMA.COLUMNS c
			ON object_name(i.object_id) = c.TABLE_NAME
			WHERE c.DATA_TYPE IN (''text'', ''ntext'', ''image'', ''xml'') 
			OR (c.DATA_TYPE IN (''varchar'', ''nvarchar'', ''varbinary'') AND c.CHARACTER_MAXIMUM_LENGTH = -1)' 
	INSERT INTO #TablesToExcludeReIndex 
	EXEC (@SQL)
END TRY
BEGIN CATCH
	PRINT ERROR_MESSAGE()
END CATCH

--CHECK TO SEE IF ANY REINDEXING HAS BEEN DONE BY CHECKING THE RECORD_COUNT COLUMN
IF (SELECT COUNT(*) FROM system.dbo.PhysicalStats WHERE EntryDate = @EntryDate AND database_id = @dbid AND record_count IS NOT NULL) = 0
BEGIN
	DELETE FROM system.dbo.PhysicalStats WHERE EntryDate = @EntryDate AND database_id = @dbid
	
	--INSERT THE LATEST STATS INTO THE SYSTEM TABLE
	INSERT INTO system.dbo.PhysicalStats (EntryDate, database_id, object_id, index_id, partition_number, index_type_desc, alloc_unit_type_desc, index_depth, index_level, avg_fragmentation_in_percent, fragment_count, avg_fragment_size_in_pages, page_count, avg_page_space_used_in_percent, record_count, ghost_record_count, version_ghost_record_count, min_record_size_in_bytes, max_record_size_in_bytes, avg_record_size_in_bytes, forwarded_record_count)
		SELECT @EntryDate [EntryDate]
		,[database_id]
		,[object_id]
		,[index_id]
		,[partition_number]
		,[index_type_desc]
		,[alloc_unit_type_desc]
		,[index_depth]
		,[index_level]
		,[avg_fragmentation_in_percent]
		,[fragment_count]
		,[avg_fragment_size_in_pages]
		,[page_count]
		,[avg_page_space_used_in_percent]
		,[record_count]
		,[ghost_record_count]
		,[version_ghost_record_count]
		,[min_record_size_in_bytes]
		,[max_record_size_in_bytes]
		,[avg_record_size_in_bytes]
		,[forwarded_record_count] 
	FROM sys.dm_db_index_physical_stats (@dbid, NULL, NULL , NULL, 'DETAILED')
	WHERE [index_id] > 0
	
	--TIMESTAMPING GOOD INDEXES AS DONE
	UPDATE system.dbo.PhysicalStats
	SET record_count = @StartTimeInMinutes
	WHERE database_id = @dbid
		AND entryDate = @EntryDate
		AND avg_fragmentation_in_percent < @fragmentThreshold
		AND record_count IS NULL

END

--CREATE LIST OF INDEXES TO REINDEX
IF OBJECT_ID('tempdb..#work_to_do') IS NOT NULL 
	DROP TABLE [dbo].#work_to_do
CREATE TABLE #work_to_do (
	[Schema] VARCHAR(10),
	[TableName] VARCHAR(100),
	[IndexName] VARCHAR(100),
	[index_id] INT,
	[object_id] INT,
	[partition_number] INT,
	[avg_fragmentation_in_percent] FLOAT,
	[IndexSizeKB] BIGINT
)
SET @SQL = 
	'USE ' + @db_name + ' SELECT s.name AS ''Schema'', t.name AS ''TableName'', i.name AS ''IndexName'', p.index_id, p.object_id, p.partition_number, p.avg_fragmentation_in_percent, SUM(ps.used_page_count) * 8 AS ''IndexSizeKB''
	FROM system.dbo.PhysicalStats p JOIN sys.tables t ON p.object_id = t.object_id
	JOIN sys.indexes i ON t.object_id = i.object_id and p.index_id = i.index_id
	JOIN sys.objects o ON t.object_id = o.object_id
	JOIN sys.schemas s ON o.schema_id = s.schema_id
	JOIN sys.dm_db_partition_stats ps ON i.object_id = ps.object_id AND i.index_id = ps.index_id
	WHERE database_id = ' + CAST(@dbid AS VARCHAR) +
	' AND entryDate = ''' + CAST(@EntryDate AS VARCHAR) + '''' +
	' AND avg_fragmentation_in_percent >= ' + CAST(@fragmentThreshold AS VARCHAR) +
	' AND p.record_count IS NULL
	GROUP BY s.name, t.name, i.name, p.index_id, p.object_id, p.partition_number, p.avg_fragmentation_in_percent'
INSERT INTO #work_to_do
	EXEC (@SQL)
DELETE FROM #work_to_do WHERE object_id in (SELECT object_id FROM #TablesToExcludeReIndex)

IF (SELECT COUNT(*) FROM #work_to_do) > 0
BEGIN
	IF OBJECT_ID('tempdb..#LogCheck') IS NOT NULL 
		DROP TABLE #LogCheck
	CREATE TABLE #LogCheck(
		DatabaseName	VARCHAR(100),
		LogSizeMB		REAL,
		LogUsedPercent	REAL,
		StatusFlag		INT)
	
	INSERT INTO #LogCheck
	EXEC ('dbcc sqlperf(logspace)')

	--CHECK IF LOG IS > THRESHOLD
	--IF (SELECT LogUsedPercent FROM #LogCheck WHERE DatabaseName = @db_name) > @logThreshold
	--BEGIN
	--	PRINT 'Log usage exceeded ' + CAST(@logThreshold AS VARCHAR) + '%, backing up log...'
	--	--BACKUP LOG
	--	DECLARE @fileName VARCHAR(200), @fileDate VARCHAR(200), @path VARCHAR(200)
	--	SET @fileDate =CONVERT(VARCHAR(17),GETDATE(),112)+REPLACE(CONVERT(VARCHAR(17),GETDATE(),108),':','')
	--	SET @path = 'Z:\Backups\'

	--	EXEC msdb.dbo.sp_start_job N'DB Maint - Log Backups'
		
	--END
	----LOG < THRESHOLD, PROCEED TO GATHER INDEXES TO REINDEX
	--ELSE
	BEGIN
		DECLARE @firstLoop BIT, @rebuildSchema VARCHAR(10), @rebuildTable VARCHAR(100), @rebuildObjectID INT, @rebuildIndex VARCHAR(100), @rebuildIndexID INT, @rebuildPartitionNum INT, @rebuildIndexSize BIGINT
		SET @firstLoop = 1
		
		WHILE @indexThreshold > 0
		BEGIN
			SELECT TOP 1
				@rebuildSchema = [Schema],
				@rebuildTable = [TableName],
				@rebuildObjectID = [object_id],
				@rebuildIndex = [IndexName],
				@rebuildIndexID = [index_id],
				@rebuildPartitionNum = [partition_number],
				@rebuildIndexSize = [IndexSizeKB]
			FROM #work_to_do
			WHERE IndexSizeKB <= CASE WHEN @firstLoop = 1 THEN IndexSizeKB ELSE @indexThreshold END --we need to pull at least 1 index to rebuild, so omitting criteria on 1st run
			ORDER BY IndexSizeKB DESC
			
			SET @firstLoop = 0

			IF @rebuildIndex IS NOT NULL
			BEGIN
				BEGIN TRY
					PRINT 'Rebuilding Index ' + @rebuildIndex + ': Index Size = ' + CAST(@rebuildIndexSize AS VARCHAR) + ', Threshold = ' + CAST(@indexThreshold AS VARCHAR)
					SET @SQL = N'ALTER INDEX ['+ @rebuildIndex + N'] ON [' +  + @db_name + '].[' + @rebuildSchema + N'].[' + @rebuildTable + N'] REBUILD';
					PRINT @SQL
					IF @rebuildPartitionNum > 1
						SET @SQL = @SQL + N' PARTITION=' + CAST(@rebuildPartitionNum AS NVARCHAR(10))
					ELSE
						SET @SQL = @SQL + ' WITH (ONLINE = ON)'
					EXEC (@SQL)

					--UPDATE TABLE TO INDICIATE THAT THIS INDEX HAS BEEN REINDEXED
					UPDATE system.dbo.PhysicalStats
					SET record_count = DATEDIFF(MINUTE, @referenceDate, GETDATE()),
						max_record_size_in_bytes = @rebuildIndexSize
					WHERE object_id = @rebuildObjectID
						AND database_id = @dbid
						AND index_id = @rebuildIndexID
						AND EntryDate = @EntryDate
					
					DELETE FROM #work_to_do WHERE TableName = @rebuildTable AND IndexName = @rebuildIndex
					
					SET @indexThreshold = @indexThreshold - @rebuildIndexSize
					SET @rebuildIndex = NULL

					PRINT N'  Executed: ' + @SQL;
					IF GETDATE() > DATEADD(HOUR, @MaxHours, @StartTime)
					BEGIN
						PRINT 'Exiting due to max hours reached'
						BREAK
					END
				END TRY
				BEGIN CATCH
					PRINT ERROR_MESSAGE()
				END CATCH
			END
			ELSE
			BEGIN
				PRINT 'No more valid indexes to rebuild for this iteration'
				BREAK -- no valid index to rebuild (either because we are done or they are too big for this run)
			END
		END
	END

	--CHECK IF QUALIFIED INDEXES HAVE NOT BEEN REBUILT FOR A CERTAIN AMOUNT OF TIME
	DECLARE @lastRebuildTime BIGINT
	SELECT @lastRebuildTime = MAX(record_count) FROM system.dbo.PhysicalStats WHERE database_id  = @dbid AND EntryDate = @EntryDate AND record_count IS NOT NULL
	IF (@lastRebuildTime IS NOT NULL AND @StartTimeInMinutes-@lastRebuildTime >= @idleThreshold)
	BEGIN
		DECLARE @logUsage varchar(10)
		SELECT @logUsage = CONVERT(VARCHAR(20),ROUND(LogUsedPercent,2)) FROM #LogCheck WHERE DatabaseName  = @db_name
		PRINT 'We have a problem!'
		PRINT 'Reindexing has not occur for ' + @db_name + ' for ' + CAST(@StartTimeInMinutes-@lastRebuildTime AS VARCHAR) + ' minutes.'
		PRINT 'Current transaction log usage is ' + @logUsage + '%.'
		
		RETURN 
	END
	
	DROP TABLE #LogCheck
END

-- DROP THE TEMPORARY TABLES
DROP TABLE #work_to_do
DROP TABLE #TablesToExcludeReIndex



GO
/****** Object:  StoredProcedure [dbo].[ResourceConsumers]    Script Date: 27/10/2015 09:31:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE  PROCEDURE [dbo].[ResourceConsumers] AS

/* Simon DM - 04/11/04 - returns the processes using SQL CPU */

SET NOCOUNT ON
DECLARE @TotalCpu decimal(8)
DECLARE @TotalIO decimal(8)

CREATE TABLE #who1(
	SPID int,
	CPUTime int,
	DiskIO int,
	login varchar(50),
	HostName varchar(50),
	ProgramName varchar(200),
	LastBatch datetime,
	BlkBy int)

DECLARE @FirstTime datetime
SET @FirstTime = getdate()
INSERT INTO #who1 SELECT SPID, sum(cpu), sum(physical_io), loginame, hostname, program_name, last_batch, blocked from master.dbo.sysprocesses (nolock)
	group  by spid, loginame, hostname, program_name, last_batch, blocked

WAITFOR DELAY '00:00:01'

CREATE TABLE #who2(
	SPID int,
	CPUTime int,
	DiskIO int)

INSERT INTO #who2 SELECT SPID, sum(cpu), sum(physical_io) from master.dbo.sysprocesses (nolock) where login_time < @FirstTime
	and spid in (select spid from #who1)
	 group by spid


Select @TotalCpu = sum(B.CPUTime-A.CPUTime), @TotalIO = sum(B.DiskIO-A.DiskIO)
	from #Who1 A JOIN #Who2 B on a.SPID = b.SPID
where B.CPUTime >= A.CPUTime or B.DiskIO >= A.DiskIO

Select A.SPID, rtrim(A.Login) as login, rtrim(A.HostName) as HostName, 
	Case when left(A.ProgramName, 15) = 'SQLAgent - TSQL' THEN dbo.GetJobName(A.ProgramName) ELSE A.ProgramName END as ProgramName,
	A.LastBatch, A.BlkBy,
	(Case when sum(B.CPUTime - A.CPUTime)=0 THEN 0 ELSE sum(B.CPUTime - A.CPUTime)/@TotalCPU END)*100 as [% CPU],
	(Case when sum(B.DiskIO - A.DiskIO)=0 THEN 0 ELSE sum(B.DiskIO - A.DiskIO)/@TotalIO END)*100 as [% Disk]
	from #Who1 A JOIN #Who2 B on a.SPID = b.SPID
	where B.CPUTime >= A.CPUTime or B.DiskIO >= A.DiskIO
	group by A.SPID, A.Login, A.HostName, A.ProgramName, A.LastBatch, A.BlkBy
	order by (Case when sum(B.CPUTime - A.CPUTime)=0 THEN 0 ELSE sum(B.CPUTime - A.CPUTime)/@TotalCPU END) +
			(Case when sum(B.DiskIO - A.DiskIO)=0 THEN 0 ELSE sum(B.DiskIO - A.DiskIO)/@TotalIO END) DESC


DROP TABLE #Who1
DROP TABLE #Who2



GO
/****** Object:  StoredProcedure [dbo].[ServiceBrokerInfo]    Script Date: 27/10/2015 09:31:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[ServiceBrokerInfo] @ResultSetType VARCHAR(20)
AS

--USED WITH SCOM 2012 TO RETURN SERVICE BROKER QUEUE INFO

IF EXISTS(SELECT 1 FROM SYS.DATABASES WHERE NAME = 'PARE')
BEGIN

	--RETURNS ALL QUEUES THAT ARE NOT 
	IF @ResultSetType = 'DISCOVERY'
	BEGIN
		SELECT
			name
		FROM
			PARE.sys.service_queues
		WHERE
			is_ms_shipped = 0
	END

	--RETURNS QUEUE COUNTS
	IF @ResultSetType = 'QUEUES'
	BEGIN
		SELECT 
			q.name,p.rows
		FROM
			PARE.sys.objects AS o 
			JOIN PARE.sys.partitions AS p ON p.object_id = o.object_id 
			JOIN PARE.sys.objects AS q ON o.parent_object_id = q.object_id 
		WHERE
			p.index_id = 1 
			AND
			q.is_ms_shipped = 0
		UNION ALL --USING UNION ALL TO AVOID SORTING
		SELECT
			o.name,p.rows 
		FROM
			PARE.sys.objects AS o 
			JOIN PARE.sys.partitions AS p ON p.object_id = o.object_id 
		WHERE
			o.name = 'sysxmitqueue'
		UNION ALL
		SELECT
			o.name, p.rows
		FROM
			PARE.sys.objects AS o 
			JOIN PARE.sys.partitions AS p ON p.object_id = o.object_id 
		WHERE
			o.name = 'sysdesend'
	END

	--RETURNS CONFIG OF QUEUES
	IF @ResultSetType = 'CONFIG'
	BEGIN
		SELECT
			object_id,
			name ,
			is_activation_enabled,
			is_receive_enabled,
			is_enqueue_enabled
		FROM
			PARE.sys.service_queues
		WHERE
			is_ms_shipped = 0
	END
END
ELSE
BEGIN
	--RETURNS NULL IF NOT APPLICABLE
	SELECT NULL
END
GO
/****** Object:  StoredProcedure [dbo].[sp_Blitz]    Script Date: 27/10/2015 09:31:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_Blitz]
    @CheckUserDatabaseObjects TINYINT = 1 ,
    @CheckProcedureCache TINYINT = 0 ,
    @OutputType VARCHAR(20) = 'TABLE' ,
    @OutputProcedureCache TINYINT = 0 ,
    @CheckProcedureCacheFilter VARCHAR(10) = NULL ,
    @CheckServerInfo TINYINT = 0 ,
    @Version INT = NULL OUTPUT
AS 
    SET NOCOUNT ON;
/*
    sp_Blitz v16 - December 13, 2012
    
    (C) 2012, Brent Ozar Unlimited

To learn more, visit http://www.BrentOzar.com/blitz where you can download
new versions for free, watch training videos on how it works, get more info on
the findings, and more.  To contribute code and see your name in the change
log, email your improvements & checks to Help@BrentOzar.com.

Explanation of priority levels:
  1 - Critical risk of data loss.  Fix this ASAP.
 10 - Security risk.
 20 - Security risk due to unusual configuration, but requires more research.
 50 - Reliability risk.
 60 - Reliability risk due to unusual configuration, but requires more research.
100 - Performance risk.
110 - Performance risk due to unusual configuration, but requires more research.
200 - Informational.
250 - Server info. Not warnings, just explaining data about the server.

Known limitations of this version:
 - No support for SQL Server 2000 or compatibility mode 80.
 - If a database name has a question mark in it, some tests will fail.  Gotta
   love that unsupported sp_MSforeachdb.

Unknown limitations of this version:
 - None.  (If we knew them, they'd be known.  Duh.)

Changes in v16:
 - Chris Fradenburg @ChrisFradenburg http://www.fradensql.com:
   - Check 81 for non-active sp_configure options not yet taking effect.
   - Improved check 35 to not alert if Optimize for Ad Hoc is already enabled.
 - Rob Sullivan @DataChomp http://datachomp.com:
   - Suggested to add output variable @Version to manage server installations.
 - Vadim Mordkovich:
   - Added check 85 for database users with elevated database roles like
     db_owner, db_securityadmin, etc.
 - Vladimir Vissoultchev rewrote the DBCC CHECKDB check to work around a bug in
   SQL Server 2008 & R2 that report dbi_dbccLastKnownGood twice. For more info
   on the bug, check Connect ID 485869.
 - Added check 77 for database snapshots.
 - Added check 78 for stored procedures with WITH RECOMPILE in the source code.
 - Added check 79 for Agent jobs with SHRINKDATABASE or SHRINKFILE.
 - Added check 80 for databases with a max file size set.
 - Added @CheckServerInfo perameter default 0. Adds additional server inventory
   data in checks 83-85 for things like CPU, memory, service logins.  None of
   these are problems, but if you're using sp_Blitz to assess a server you've
   never seen, you may want to know more about what you're working with. I do.
 - Tweaked check 75 for large log files so that it only alerts on files > 1GB.
 - Changed one of the two check 59's to be check 82. (Doh!)
 - Added WITH NO_INFOMSGS to the DBCC calls to ease life for automation folks.
 - Works with offline and restoring databases. (Just happened to test it in
   this version and it already worked - must have fixed this earlier.)

Changes in v15:
 - Mikael Wedham caught bugs in a few checks that reported the wrong database name.
 - Bob Klimes fixed bugs in several checks where v14 broke case sensitivity.
 - Seth Washeck fixed bugs in the VLF checks so they include the number of VLFs.

Changes in v14:
 - Lori Edwards @LoriEdwards http://sqlservertimes2.com
     - Did all the coding in this version! She did a killer job of integrating
	   improvements and suggestions from all kinds of people, including:
 - Chris Fradenburg @ChrisFradenburg http://www.fradensql.com 
     - Check 74 to identify globally enabled traceflags
 - Jeremy Lowell @DataRealized http://datarealized.com added:
     - Check 72 for non-aligned indexes on partitioned tables
 - Paul Anderton @Panders69 added check 69 to check for high VLF count
 - Ron van Moorsel added several changes
	 - Added a change to check 6 to use sys.server_principals instead of syslogins
	 - Added a change to check 25 to check whether tempdb was set to autogrow.  
	 - Added a change to check 49 to check for linked servers configured with the SA login
 - Shaun Stuart @shaunjstu http://shaunjstuart.com added several changes:
	 - Added check 68 to check for the last successful DBCC CHECKDB
	 - Updated check 1 to verify the backup came from the current 
	 - Added check 70 to verify that @@servername is not null
 - Typo in check 51 changing free to present thanks to Sabu Varghese
 - Check 73 to determine if a failsafe operator has been configured
 - Check 75 for transaction log files larger than data files suggested by Chris Adkin
 - Fixed a bunch of bugs for oddball database names (like apostrophes).

Changes in v13:
 - Fixed typos in descriptions of checks 60 & 61 thanks to Mark Hions.
 - Improved check 14 to work with collations thanks to Greg Ackerland.
 - Improved several of the backup checks to exclude database snapshots and
   databases that are currently being restored thanks to Greg Ackerland.
 - Improved wording on check 51 thanks to Stephen Criddle.
 - Added top line introducing the reader to sp_Blitz and the version number.
 - Changed Brent Ozar PLF, LLC to Brent Ozar Unlimited. Great catch by
   Hondo Henriques, @SQLHondo.
 - If you've submitted code recently to sp_Blitz, hang in there! We're still
   building a big new version with lots of new checks. Just fixing bugs in
   this small release.

Changes in v12:
 - Added plan cache (aka procedure cache) analysis. Examines top resource-using
   queries for common problems like implicit conversions, missing indexes, etc.
 - Added @CheckProcedureCacheFilter to focus plan cache analysis on
   CPU, Reads, Duration, or ExecCount. If null, we analyze all of them.
 - Added @OutputProcedureCache to include the queries we analyzed. Results are
   sorted using the @CheckProcedureCacheFilter parameter, otherwise by CPU.
 - Fixed case sensitive calls of sp_MSforeachdb reported by several users.

Changes in v11:
 - Added check for optimize for ad hoc workloads in sys.configurations.
 - Added @OutputType parameter. Choices:
 	- 'TABLE' - default of one result set table with all warnings.
	- 'COUNT' - Sesame Street's favorite character will tell you how many
				problems sp_Blitz found.  Useful if you want to use a
				monitoring tool to alert you when something changed.

Changes in v10:
 - Jeremiah Peschka added check 59 for file growths set to a percentage.
 - Ned Otter added check 62 for old compatibility levels.
 - Wayne Sheffield improved checks 38 & 39 by excluding more system tables.
 - Christopher Fradenburg improved check 30 (missing alerts) by making sure
   that alerts are set up for all of the severity levels involved, not just
   some of them.
 - James Siebengartner and others improved check 14 (page verification) by
   excluding TempDB, which can't be set to checksum in older versions.
 - Added check 60 for index fill factors <> 0, 100.
 - Added check 61 for unusual SQL Server editions (not Standard, Enterprise, or
   Developer)
 - Added limitations note to point out that compatibility mode 80 won't work.
 - Fixed a bug where changes in sp_configure weren't always reported.

Changes in v9:
 - Alex Pixley fixed a spelling typo.
 - Steinar Anderson http://www.sqlservice.se fixed a date bug in checkid 2.
   That bug was reported by several users, but Steinar coded the fix.
 - Stephen Schissler added a filter for checkid 2 (missing log backups) to look
   only for databases where source_database_id is null because these are
   database snapshots, and you can't run transaction log backups on snapshots.
 - Mark Fleming @markflemingnl added checkid 62 looking for disabled alerts.
 - Checkid 17 typo changed from "disabled" to "enabled" - the check
   functionality was right, but it was warning that auto update stats async
   was "disabled".  Disabled is actually the default, but the check was
   firing because it had been enabled.  (This one was reported by many.)

Changes in v8 May 10 2012:
 - Switched more-details URLs to be short.  This way they'll render better
   when viewed in our SQL Server Management Studio reports.
 - Removed ?VersionNumber querystring parameter to shorten links in SSMS.
 - Eliminated duplicate check for startup stored procedures.

Changes in v7 April 30 2012:
 - Thomas Rushton http://thelonedba.wordpress.com/ @ThomasRushton added check
   58 for database collations that don't match the server collation.
 - Rob Pellicaan caught a bug in check 13: it was only checking for plan guides
   in the master database rather than all user databases.
 - Michal Tinthofer http://www.woodler.eu improved check 2 to work across
   collations and fix a bug in the backup_finish_date check.  (Several people
   reported this, but Michal contributed the most improvements to this check.)
 - Chris Fradenburg improved checks 38 and 39 by excluding heaps if they are
   marked is_ms_shipped, thereby excluding more system stuff.
 - Jack Whittaker fixed a bug in checkid 1.  When checking for databases
   without a full backup, we were ignoring the model database, but some shops
   really do need to back up model because they put stuff in there to be
   copied into each new database, so let's alert on that too.  Larry Silverman
   also noticed this bug.
 - Michael Burgess caught a bug in the untrusted key/constraint checks that
   were not checking for is_disabled = 0.
 - Alex Friedman fixed a bug in check 44 which required a running trace.
 - New check for SQL Agent alerts configured without operator notifications.
 - Even if @CheckUserDatabaseObjects was set to 0, some user database object
   checks were being done.
 - Check 48 for untrusted foreign keys now just returns one line per database
   that has the issue rather than listing every foreign key individually. For
   the full list of untrusted keys, run the query in the finding's URL.

Changes in v6 Dec 26 2011:
 - Jonathan Allen @FatherJack suggested tweaking sp_BlitzUpdate's error message
    about Ad Hoc Queries not being enabled so that it also includes
    instructions on how to disable them again after temporarily enabling
    it to update sp_Blitz. 

Changes in v5 Dec 18 2011:
 - John Miner suggested tweaking checkid 48 and 56, the untrusted constraints
    and keys, to look for is_not_for_replication = 0 too.  This filters out
    constraints/keys that are only used for replication and don't need to
    be trusted.
 - Ned Otter caught a bug in the URL for check 7, startup stored procs.
 - Scott (Anon) recommended using SUSER_SNAME(0x01) instead of 'sa' when
    checking for job ownership, database ownership, etc.
 - Martin Schmidt http://www.geniiius.com/blog/ caught a bug in checkid 1 and
    contributed code to catch databases that had never been backed up.
 - Added parameter for @CheckProcedureCache.  When set to 0, we skip the checks
    that are typically the slowest on servers with lots of memory.  I'm
    defaulting this to 0 so more users can get results back faster.

Changes in v4 Nov 1 2011:
 - Andreas Schubert caught a typo in the explanations for checks 15-17.
 - K. Brian Kelley @kbriankelley added checkid 57 for SQL Agent jobs set to
      start automatically on startup.
 - Added parameter for @CheckUserDatabaseObjects.  When set to 0, we skip the
    checks that are typically the slowest on large servers, the user
    database schema checks for things like triggers, hypothetical
    indexes, untrusted constraints, etc.

Changes in v3 Oct 16 2011:
 - David Tolbert caught a bug in checkid 2.  If some backups had failed or
        been aborted, we raised a false alarm about no transaction log backups.
 - Fixed more bugs in checking for SQL Server 2005. (I need more 2005 VMs!)

Changes in v2 Oct 14 2011:
 - Ali Razeghi http://www.alirazeghi.com added checkid 55 looking for
   databases owned by <> SA.
 - Fixed bugs in checking for SQL Server 2005 (leading % signs)

*/

    IF OBJECT_ID('tempdb..#BlitzResults') IS NOT NULL 
        DROP TABLE #BlitzResults;
    CREATE TABLE #BlitzResults
        (
          ID INT IDENTITY(1, 1) ,
          CheckID INT ,
          Priority TINYINT ,
          FindingsGroup VARCHAR(50) ,
          Finding VARCHAR(200) ,
          URL VARCHAR(200) ,
          Details NVARCHAR(4000) ,
          QueryPlan [XML] NULL ,
          QueryPlanFiltered [NVARCHAR](MAX) NULL
        );

    IF OBJECT_ID('tempdb..#ConfigurationDefaults') IS NOT NULL 
        DROP TABLE #ConfigurationDefaults;
    CREATE TABLE #ConfigurationDefaults
        (
          name NVARCHAR(128) ,
          DefaultValue BIGINT
        );

    IF @CheckProcedureCache = 1 
        BEGIN
            IF OBJECT_ID('tempdb..#dm_exec_query_stats') IS NOT NULL 
                DROP TABLE #dm_exec_query_stats;
            CREATE TABLE #dm_exec_query_stats
                (
                  [id] [int] NOT NULL
                             IDENTITY(1, 1) ,
                  [sql_handle] [varbinary](64) NOT NULL ,
                  [statement_start_offset] [int] NOT NULL ,
                  [statement_end_offset] [int] NOT NULL ,
                  [plan_generation_num] [bigint] NOT NULL ,
                  [plan_handle] [varbinary](64) NOT NULL ,
                  [creation_time] [datetime] NOT NULL ,
                  [last_execution_time] [datetime] NOT NULL ,
                  [execution_count] [bigint] NOT NULL ,
                  [total_worker_time] [bigint] NOT NULL ,
                  [last_worker_time] [bigint] NOT NULL ,
                  [min_worker_time] [bigint] NOT NULL ,
                  [max_worker_time] [bigint] NOT NULL ,
                  [total_physical_reads] [bigint] NOT NULL ,
                  [last_physical_reads] [bigint] NOT NULL ,
                  [min_physical_reads] [bigint] NOT NULL ,
                  [max_physical_reads] [bigint] NOT NULL ,
                  [total_logical_writes] [bigint] NOT NULL ,
                  [last_logical_writes] [bigint] NOT NULL ,
                  [min_logical_writes] [bigint] NOT NULL ,
                  [max_logical_writes] [bigint] NOT NULL ,
                  [total_logical_reads] [bigint] NOT NULL ,
                  [last_logical_reads] [bigint] NOT NULL ,
                  [min_logical_reads] [bigint] NOT NULL ,
                  [max_logical_reads] [bigint] NOT NULL ,
                  [total_clr_time] [bigint] NOT NULL ,
                  [last_clr_time] [bigint] NOT NULL ,
                  [min_clr_time] [bigint] NOT NULL ,
                  [max_clr_time] [bigint] NOT NULL ,
                  [total_elapsed_time] [bigint] NOT NULL ,
                  [last_elapsed_time] [bigint] NOT NULL ,
                  [min_elapsed_time] [bigint] NOT NULL ,
                  [max_elapsed_time] [bigint] NOT NULL ,
                  [query_hash] [binary](8) NULL ,
                  [query_plan_hash] [binary](8) NULL ,
                  [query_plan] [xml] NULL ,
                  [query_plan_filtered] [nvarchar](MAX) NULL ,
                  [text] [nvarchar](MAX) COLLATE SQL_Latin1_General_CP1_CI_AS
                                         NULL ,
                  [text_filtered] [nvarchar](MAX)
                    COLLATE SQL_Latin1_General_CP1_CI_AS
                    NULL
                )
	
        END

    DECLARE @StringToExecute NVARCHAR(4000);

    INSERT  INTO #BlitzResults
            ( CheckID ,
              Priority ,
              FindingsGroup ,
              Finding ,
              URL ,
              Details
            )
            SELECT  1 AS CheckID ,
                    1 AS Priority ,
                    'Backup' AS FindingsGroup ,
                    'Backups Not Performed Recently' AS Finding ,
                    'http://BrentOzar.com/go/nobak' AS URL ,
                    'Database ' + d.Name + ' last backed up: '
                    + CAST(COALESCE(MAX(b.backup_finish_date), ' never ') AS VARCHAR(200)) AS Details
            FROM    master.sys.databases d
                    LEFT OUTER JOIN msdb.dbo.backupset b ON d.name = b.database_name
                                                            AND b.type = 'D'
                                                            AND b.server_name = @@SERVERNAME /*Backupset ran on current server */
            WHERE   d.database_id <> 2  /* Bonus points if you know what that means */
                    AND d.state <> 1 /* Not currently restoring, like log shipping databases */
                    AND d.is_in_standby = 0 /* Not a log shipping target database */
                    AND d.source_database_id IS NULL /* Excludes database snapshots */
            GROUP BY d.name
            HAVING  MAX(b.backup_finish_date) <= DATEADD(dd, -7, GETDATE());


    INSERT  INTO #BlitzResults
            ( CheckID ,
              Priority ,
              FindingsGroup ,
              Finding ,
              URL ,
              Details
              
            )
            SELECT  1 AS CheckID ,
                    1 AS Priority ,
                    'Backup' AS FindingsGroup ,
                    'Backups Not Performed Recently' AS Finding ,
                    'http://BrentOzar.com/go/nobak' AS URL ,
                    ( 'Database ' + d.Name + ' never backed up.' ) AS Details
            FROM    master.sys.databases d
            WHERE   d.database_id <> 2 /* Bonus points if you know what that means */
                    AND d.state <> 1 /* Not currently restoring, like log shipping databases */
                    AND d.is_in_standby = 0 /* Not a log shipping target database */
                    AND d.source_database_id IS NULL /* Excludes database snapshots */
                    AND NOT EXISTS ( SELECT *
                                     FROM   msdb.dbo.backupset b
                                     WHERE  d.name = b.database_name
                                            AND b.type = 'D'
                                            AND b.server_name = @@SERVERNAME /*Backupset ran on current server */)

    INSERT  INTO #BlitzResults
            ( CheckID ,
              Priority ,
              FindingsGroup ,
              Finding ,
              URL ,
              Details
            )
            SELECT DISTINCT
                    2 AS CheckID ,
                    1 AS Priority ,
                    'Backup' AS FindingsGroup ,
                    'Full Recovery Mode w/o Log Backups' AS Finding ,
                    'http://BrentOzar.com/go/biglogs' AS URL ,
                    ( 'Database ' + ( d.Name COLLATE database_default )
                      + ' is in ' + d.recovery_model_desc
                      + ' recovery mode but has not had a log backup in the last week.' ) AS Details
            FROM    master.sys.databases d
            WHERE   d.recovery_model IN ( 1, 2 )
                    AND d.database_id NOT IN ( 2, 3 )
                    AND d.source_database_id IS NULL
                    AND d.state <> 1 /* Not currently restoring, like log shipping databases */
                    AND d.is_in_standby = 0 /* Not a log shipping target database */
                    AND d.source_database_id IS NULL /* Excludes database snapshots */
                    AND NOT EXISTS ( SELECT *
                                     FROM   msdb.dbo.backupset b
                                     WHERE  d.name = b.database_name
                                            AND b.type = 'L'
                                            AND b.backup_finish_date >= DATEADD(dd,
                                                              -7, GETDATE()) );




    INSERT  INTO #BlitzResults
            ( CheckID ,
              Priority ,
              FindingsGroup ,
              Finding ,
              URL ,
              Details
            )
            SELECT TOP 1
                    3 AS CheckID ,
                    200 AS Priority ,
                    'Backup' AS FindingsGroup ,
                    'MSDB Backup History Not Purged' AS Finding ,
                    'http://BrentOzar.com/go/history' AS URL ,
                    ( 'Database backup history retained back to '
                      + CAST(bs.backup_start_date AS VARCHAR(20)) ) AS Details
            FROM    msdb.dbo.backupset bs
            WHERE   bs.backup_start_date <= DATEADD(dd, -60, GETDATE())
            ORDER BY backup_set_id ASC;


    INSERT  INTO #BlitzResults
            ( CheckID ,
              Priority ,
              FindingsGroup ,
              Finding ,
              URL ,
              Details
            )
            SELECT  4 AS CheckID ,
                    10 AS Priority ,
                    'Security' AS FindingsGroup ,
                    'Sysadmins' AS Finding ,
                    'http://BrentOzar.com/go/sa' AS URL ,
                    ( 'Login [' + l.name
                      + '] is a sysadmin - meaning they can do absolutely anything in SQL Server, including dropping databases or hiding their tracks.' ) AS Details
            FROM    master.sys.syslogins l
            WHERE   l.sysadmin = 1
                    AND l.name <> SUSER_SNAME(0x01)
                    AND l.denylogin = 0;

    INSERT  INTO #BlitzResults
            ( CheckID ,
              Priority ,
              FindingsGroup ,
              Finding ,
              URL ,
              Details
            )
            SELECT  5 AS CheckID ,
                    10 AS Priority ,
                    'Security' AS FindingsGroup ,
                    'Security Admins' AS Finding ,
                    'http://BrentOzar.com/go/sa' AS URL ,
                    ( 'Login [' + l.name
                      + '] is a security admin - meaning they can give themselves permission to do absolutely anything in SQL Server, including dropping databases or hiding their tracks.' ) AS Details
            FROM    master.sys.syslogins l
            WHERE   l.securityadmin = 1
                    AND l.name <> SUSER_SNAME(0x01)
                    AND l.denylogin = 0;

    INSERT  INTO #BlitzResults
            ( CheckID ,
              Priority ,
              FindingsGroup ,
              Finding ,
              URL ,
              Details
            )
            SELECT  6 AS CheckID ,
                    200 AS Priority ,
                    'Security' AS FindingsGroup ,
                    'Jobs Owned By Users' AS Finding ,
                    'http://BrentOzar.com/go/owners' AS URL ,
                    ( 'Job [' + j.name + '] is owned by [' + sl.name
                      + '] - meaning if their login is disabled or not available due to Active Directory problems, the job will stop working.' ) AS Details
            FROM    msdb.dbo.sysjobs j
                    LEFT OUTER JOIN sys.server_principals sl ON j.owner_sid = sl.sid
            WHERE   j.enabled = 1
                    AND sl.name <> SUSER_SNAME(0x01);

    INSERT  INTO #BlitzResults
            ( CheckID ,
              Priority ,
              FindingsGroup ,
              Finding ,
              URL ,
              Details
            )
            SELECT  7 AS CheckID ,
                    10 AS Priority ,
                    'Security' AS FindingsGroup ,
                    'Stored Procedure Runs at Startup' AS Finding ,
                    'http://BrentOzar.com/go/startup' AS URL ,
                    ( 'Stored procedure [master].[' + r.SPECIFIC_SCHEMA
                      + '].[' + r.SPECIFIC_NAME
                      + '] runs automatically when SQL Server starts up.  Make sure you know exactly what this stored procedure is doing, because it could pose a security risk.' ) AS Details
            FROM    master.INFORMATION_SCHEMA.ROUTINES r
            WHERE   OBJECTPROPERTY(OBJECT_ID(ROUTINE_NAME), 'ExecIsStartup') = 1;

    IF @@VERSION NOT LIKE '%Microsoft SQL Server 2000%'
        AND @@VERSION NOT LIKE '%Microsoft SQL Server 2005%' 
        BEGIN
            SET @StringToExecute = 'INSERT INTO #BlitzResults (CheckID, Priority, FindingsGroup, Finding, URL, Details)
SELECT 8 AS CheckID, 150 AS Priority, ''Security'' AS FindingsGroup, ''Server Audits Running'' AS Finding, 
    ''http://BrentOzar.com/go/audits'' AS URL,
    (''SQL Server built-in audit functionality is being used by server audit: '' + [name]) AS Details FROM sys.dm_server_audit_status'
            EXECUTE(@StringToExecute)
        END;

    IF @@VERSION NOT LIKE '%Microsoft SQL Server 2000%' 
        BEGIN
            SET @StringToExecute = 'INSERT INTO #BlitzResults (CheckID, Priority, FindingsGroup, Finding, URL, Details)
SELECT 9 AS CheckID, 200 AS Priority, ''Surface Area'' AS FindingsGroup, ''Endpoints Configured'' AS Finding, 
    ''http://BrentOzar.com/go/endpoints/'' AS URL,
    (''SQL Server endpoints are configured.  These can be used for database mirroring or Service Broker, but if you do not need them, avoid leaving them enabled.  Endpoint name: '' + [name]) AS Details FROM sys.endpoints WHERE type <> 2'
            EXECUTE(@StringToExecute)
        END;

    IF @@VERSION NOT LIKE '%Microsoft SQL Server 2000%'
        AND @@VERSION NOT LIKE '%Microsoft SQL Server 2005%' 
        BEGIN
            SET @StringToExecute = 'INSERT INTO #BlitzResults (CheckID, Priority, FindingsGroup, Finding, URL, Details)
SELECT 10 AS CheckID, 100 AS Priority, ''Performance'' AS FindingsGroup, ''Resource Governor Enabled'' AS Finding, 
    ''http://BrentOzar.com/go/rg'' AS URL,
    (''Resource Governor is enabled.  Queries may be throttled.  Make sure you understand how the Classifier Function is configured.'') AS Details FROM sys.resource_governor_configuration WHERE is_enabled = 1'
            EXECUTE(@StringToExecute)
        END;


    IF @@VERSION NOT LIKE '%Microsoft SQL Server 2000%' 
        BEGIN
            SET @StringToExecute = 'INSERT INTO #BlitzResults (CheckID, Priority, FindingsGroup, Finding, URL, Details)
SELECT 11 AS CheckID, 100 AS Priority, ''Performance'' AS FindingsGroup, ''Server Triggers Enabled'' AS Finding, 
    ''http://BrentOzar.com/go/logontriggers/'' AS URL,
    (''Server Trigger ['' + [name] ++ ''] is enabled, so it runs every time someone logs in.  Make sure you understand what that trigger is doing - the less work it does, the better.'') AS Details FROM sys.server_triggers WHERE is_disabled = 0 AND is_ms_shipped = 0'
            EXECUTE(@StringToExecute)
        END;


    INSERT  INTO #BlitzResults
            ( CheckID ,
              Priority ,
              FindingsGroup ,
              Finding ,
              URL ,
              Details
            )
            SELECT  12 AS CheckID ,
                    10 AS Priority ,
                    'Performance' AS FindingsGroup ,
                    'Auto-Close Enabled' AS Finding ,
                    'http://BrentOzar.com/go/autoclose' AS URL ,
                    ( 'Database [' + [name]
                      + '] has auto-close enabled.  This setting can dramatically decrease performance.' ) AS Details
            FROM    sys.databases
            WHERE   is_auto_close_on = 1;

    INSERT  INTO #BlitzResults
            ( CheckID ,
              Priority ,
              FindingsGroup ,
              Finding ,
              URL ,
              Details
            )
            SELECT  12 AS CheckID ,
                    10 AS Priority ,
                    'Performance' AS FindingsGroup ,
                    'Auto-Shrink Enabled' AS Finding ,
                    'http://BrentOzar.com/go/autoshrink' AS URL ,
                    ( 'Database [' + [name]
                      + '] has auto-shrink enabled.  This setting can dramatically decrease performance.' ) AS Details
            FROM    sys.databases
            WHERE   is_auto_shrink_on = 1;


    IF @@VERSION LIKE '%Microsoft SQL Server 2000%' 
        BEGIN
            SET @StringToExecute = 'INSERT INTO #BlitzResults (CheckID, Priority, FindingsGroup, Finding, URL, Details)
SELECT 14 AS CheckID, 50 AS Priority, ''Reliability'' AS FindingsGroup, ''Page Verification Not Optimal'' AS Finding, 
    ''http://BrentOzar.com/go/torn'' AS URL,
    (''Database ['' + [name] + ''] has '' + [page_verify_option_desc] + '' for page verification.  SQL Server may have a harder time recognizing and recovering from storage corruption.  Consider using CHECKSUM instead.'') COLLATE database_default AS Details FROM sys.databases WHERE page_verify_option < 1 AND name <> ''tempdb'''
            EXECUTE(@StringToExecute)
        END;

    IF @@VERSION NOT LIKE '%Microsoft SQL Server 2000%' 
        BEGIN
            SET @StringToExecute = 'INSERT INTO #BlitzResults (CheckID, Priority, FindingsGroup, Finding, URL, Details)
SELECT 14 AS CheckID, 50 AS Priority, ''Reliability'' AS FindingsGroup, ''Page Verification Not Optimal'' AS Finding, 
    ''http://BrentOzar.com/go/torn'' AS URL,
    (''Database ['' + [name] + ''] has '' + [page_verify_option_desc] + '' for page verification.  SQL Server may have a harder time recognizing and recovering from storage corruption.  Consider using CHECKSUM instead.'') AS Details FROM sys.databases WHERE page_verify_option < 2 AND name <> ''tempdb'''
            EXECUTE(@StringToExecute)
        END;

    INSERT  INTO #BlitzResults
            ( CheckID ,
              Priority ,
              FindingsGroup ,
              Finding ,
              URL ,
              Details
            )
            SELECT  15 AS CheckID ,
                    110 AS Priority ,
                    'Performance' AS FindingsGroup ,
                    'Auto-Create Stats Disabled' AS Finding ,
                    'http://BrentOzar.com/go/acs' AS URL ,
                    ( 'Database [' + [name]
                      + '] has auto-create-stats disabled.  SQL Server uses statistics to build better execution plans, and without the ability to automatically create more, performance may suffer.' ) AS Details
            FROM    sys.databases
            WHERE   is_auto_create_stats_on = 0;

    INSERT  INTO #BlitzResults
            ( CheckID ,
              Priority ,
              FindingsGroup ,
              Finding ,
              URL ,
              Details
            )
            SELECT  16 AS CheckID ,
                    110 AS Priority ,
                    'Performance' AS FindingsGroup ,
                    'Auto-Update Stats Disabled' AS Finding ,
                    'http://BrentOzar.com/go/aus' AS URL ,
                    ( 'Database [' + [name]
                      + '] has auto-update-stats disabled.  SQL Server uses statistics to build better execution plans, and without the ability to automatically update them, performance may suffer.' ) AS Details
            FROM    sys.databases
            WHERE   is_auto_update_stats_on = 0;

    INSERT  INTO #BlitzResults
            ( CheckID ,
              Priority ,
              FindingsGroup ,
              Finding ,
              URL ,
              Details
            )
            SELECT  17 AS CheckID ,
                    110 AS Priority ,
                    'Performance' AS FindingsGroup ,
                    'Stats Updated Asynchronously' AS Finding ,
                    'http://BrentOzar.com/go/asyncstats' AS URL ,
                    ( 'Database [' + [name]
                      + '] has auto-update-stats-async enabled.  When SQL Server gets a query for a table with out-of-date statistics, it will run the query with the stats it has - while updating stats to make later queries better. The initial run of the query may suffer, though.' ) AS Details
            FROM    sys.databases
            WHERE   is_auto_update_stats_async_on = 1;


    INSERT  INTO #BlitzResults
            ( CheckID ,
              Priority ,
              FindingsGroup ,
              Finding ,
              URL ,
              Details
            )
            SELECT  18 AS CheckID ,
                    110 AS Priority ,
                    'Performance' AS FindingsGroup ,
                    'Forced Parameterization On' AS Finding ,
                    'http://BrentOzar.com/go/forced' AS URL ,
                    ( 'Database [' + [name]
                      + '] has forced parameterization enabled.  SQL Server will aggressively reuse query execution plans even if the applications do not parameterize their queries.  This can be a performance booster with some programming languages, or it may use universally bad execution plans when better alternatives are available for certain parameters.' ) AS Details
            FROM    sys.databases
            WHERE   is_parameterization_forced = 1;


    INSERT  INTO #BlitzResults
            ( CheckID ,
              Priority ,
              FindingsGroup ,
              Finding ,
              URL ,
              Details
            )
            SELECT  19 AS CheckID ,
                    200 AS Priority ,
                    'Informational' AS FindingsGroup ,
                    'Replication In Use' AS Finding ,
                    'http://BrentOzar.com/go/repl' AS URL ,
                    ( 'Database [' + [name]
                      + '] is a replication publisher, subscriber, or distributor.' ) AS Details
            FROM    sys.databases
            WHERE   is_published = 1
                    OR is_subscribed = 1
                    OR is_merge_published = 1
                    OR is_distributor = 1;

    INSERT  INTO #BlitzResults
            ( CheckID ,
              Priority ,
              FindingsGroup ,
              Finding ,
              URL ,
              Details
            )
            SELECT  20 AS CheckID ,
                    110 AS Priority ,
                    'Informational' AS FindingsGroup ,
                    'Date Correlation On' AS Finding ,
                    'http://BrentOzar.com/go/corr' AS URL ,
                    ( 'Database [' + [name]
                      + '] has date correlation enabled.  This is not a default setting, and it has some performance overhead.  It tells SQL Server that date fields in two tables are related, and SQL Server maintains statistics showing that relation.' ) AS Details
            FROM    sys.databases
            WHERE   is_date_correlation_on = 1;

    IF @@VERSION NOT LIKE '%Microsoft SQL Server 2000%'
        AND @@VERSION NOT LIKE '%Microsoft SQL Server 2005%' 
        BEGIN
            SET @StringToExecute = 'INSERT INTO #BlitzResults (CheckID, Priority, FindingsGroup, Finding, URL, Details)
SELECT 21 AS CheckID, 20 AS Priority, ''Encryption'' AS FindingsGroup, ''Database Encrypted'' AS Finding, 
    ''http://BrentOzar.com/go/tde'' AS URL,
    (''Database ['' + [name] + ''] has Transparent Data Encryption enabled.  Make absolutely sure you have backed up the certificate and private key, or else you will not be able to restore this database.'') AS Details FROM sys.databases WHERE is_encrypted = 1'
            EXECUTE(@StringToExecute)
        END;

/* Compare sp_configure defaults */
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'Ad Hoc Distributed Queries', 0 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'affinity I/O mask', 0 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'affinity mask', 0 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'Agent XPs', 0 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'allow updates', 0 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'awe enabled', 0 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'blocked process threshold', 0 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'c2 audit mode', 0 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'clr enabled', 0 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'cost threshold for parallelism', 5 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'cross db ownership chaining', 0 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'cursor threshold', -1 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'Database Mail XPs', 0 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'default full-text language', 1033 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'default language', 0 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'default trace enabled', 1 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'disallow results from triggers', 0 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'fill factor (%)', 0 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'ft crawl bandwidth (max)', 100 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'ft crawl bandwidth (min)', 0 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'ft notify bandwidth (max)', 100 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'ft notify bandwidth (min)', 0 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'index create memory (KB)', 0 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'in-doubt xact resolution', 0 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'lightweight pooling', 0 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'locks', 0 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'max degree of parallelism', 0 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'max full-text crawl range', 4 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'max server memory (MB)', 2147483647 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'max text repl size (B)', 65536 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'max worker threads', 0 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'media retention', 0 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'min memory per query (KB)', 1024 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'min server memory (MB)', 0 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'nested triggers', 1 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'network packet size (B)', 4096 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'Ole Automation Procedures', 0 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'open objects', 0 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'optimize for ad hoc workloads', 0 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'PH timeout (s)', 60 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'precompute rank', 0 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'priority boost', 0 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'query governor cost limit', 0 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'query wait (s)', -1 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'recovery interval (min)', 0 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'remote access', 1 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'remote admin connections', 0 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'remote login timeout (s)', 20 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'remote proc trans', 0 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'remote query timeout (s)', 600 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'Replication XPs', 0 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'RPC parameter data validation', 0 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'scan for startup procs', 0 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'server trigger recursion', 1 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'set working set size', 0 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'show advanced options', 0 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'SMO and DMO XPs', 1 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'SQL Mail XPs', 0 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'transform noise words', 0 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'two digit year cutoff', 2049 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'user connections', 0 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'user options', 0 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'Web Assistant Procedures', 0 );
    INSERT  INTO #ConfigurationDefaults
    VALUES  ( 'xp_cmdshell', 0 );

    INSERT  INTO #BlitzResults
            ( CheckID ,
              Priority ,
              FindingsGroup ,
              Finding ,
              URL ,
              Details
            )
            SELECT  22 AS CheckID ,
                    200 AS Priority ,
                    'Non-Default Server Config' AS FindingsGroup ,
                    cd.name AS Finding ,
                    'http://BrentOzar.com/go/conf' AS URL ,
                    ( 'This sp_configure option has been changed.  Its default value is '
                      + CAST(cd.[DefaultValue] AS VARCHAR(100))
                      + ' and it has been set to '
                      + CAST(cr.value_in_use AS VARCHAR(100)) + '.' ) AS Details
            FROM    #ConfigurationDefaults cd
                    INNER JOIN sys.configurations cr ON cd.name = cr.name
            WHERE   cd.DefaultValue <> cr.value_in_use;

    INSERT  INTO #BlitzResults
            ( CheckID ,
              Priority ,
              FindingsGroup ,
              Finding ,
              URL ,
              Details
            )
            SELECT DISTINCT
                    24 AS CheckID ,
                    20 AS Priority ,
                    'Reliability' AS FindingsGroup ,
                    'System Database on C Drive' AS Finding ,
                    'http://BrentOzar.com/go/drivec' AS URL ,
                    ( 'The ' + DB_NAME(database_id)
                      + ' database has a file on the C drive.  Putting system databases on the C drive runs the risk of crashing the server when it runs out of space.' ) AS Details
            FROM    sys.master_files
            WHERE   UPPER(LEFT(physical_name, 1)) = 'C'
                    AND DB_NAME(database_id) IN ( 'master', 'model', 'msdb' );

    INSERT  INTO #BlitzResults
            ( CheckID ,
              Priority ,
              FindingsGroup ,
              Finding ,
              URL ,
              Details
            )
            SELECT TOP 1
                    25 AS CheckID ,
                    100 AS Priority ,
                    'Performance' AS FindingsGroup ,
                    'TempDB on C Drive' AS Finding ,
                    'http://BrentOzar.com/go/drivec' AS URL ,
                    CASE WHEN growth > 0
                         THEN ( 'The tempdb database has files on the C drive.  TempDB frequently grows unpredictably, putting your server at risk of running out of C drive space and crashing hard.  C is also often much slower than other drives, so performance may be suffering.' )
                         ELSE ( 'The tempdb database has files on the C drive.  TempDB is not set to Autogrow, hopefully it is big enough.  C is also often much slower than other drives, so performance may be suffering.' )
                    END AS Details
            FROM    sys.master_files
            WHERE   UPPER(LEFT(physical_name, 1)) = 'C'
                    AND DB_NAME(database_id) = 'tempdb';

    INSERT  INTO #BlitzResults
            ( CheckID ,
              Priority ,
              FindingsGroup ,
              Finding ,
              URL ,
              Details
            )
            SELECT DISTINCT
                    26 AS CheckID ,
                    20 AS Priority ,
                    'Reliability' AS FindingsGroup ,
                    'User Databases on C Drive' AS Finding ,
                    'http://BrentOzar.com/go/cdrive' AS URL ,
                    ( 'The ' + DB_NAME(database_id)
                      + ' database has a file on the C drive.  Putting databases on the C drive runs the risk of crashing the server when it runs out of space.' ) AS Details
            FROM    sys.master_files
            WHERE   UPPER(LEFT(physical_name, 1)) = 'C'
                    AND DB_NAME(database_id) NOT IN ( 'master', 'model',
                                                      'msdb', 'tempdb' );


    INSERT  INTO #BlitzResults
            ( CheckID ,
              Priority ,
              FindingsGroup ,
              Finding ,
              URL ,
              Details
            )
            SELECT  27 AS CheckID ,
                    200 AS Priority ,
                    'Informational' AS FindingsGroup ,
                    'Tables in the Master Database' AS Finding ,
                    'http://BrentOzar.com/go/mastuser' AS URL ,
                    ( 'The ' + name
                      + ' table in the master database was created by end users on '
                      + CAST(create_date AS VARCHAR(20))
                      + '. Tables in the master database may not be restored in the event of a disaster.' ) AS Details
            FROM    master.sys.tables
            WHERE   is_ms_shipped = 0;

    INSERT  INTO #BlitzResults
            ( CheckID ,
              Priority ,
              FindingsGroup ,
              Finding ,
              URL ,
              Details
            )
            SELECT  28 AS CheckID ,
                    200 AS Priority ,
                    'Informational' AS FindingsGroup ,
                    'Tables in the MSDB Database' AS Finding ,
                    'http://BrentOzar.com/go/msdbuser' AS URL ,
                    ( 'The ' + name
                      + ' table in the msdb database was created by end users on '
                      + CAST(create_date AS VARCHAR(20))
                      + '. Tables in the msdb database may not be restored in the event of a disaster.' ) AS Details
            FROM    msdb.sys.tables
            WHERE   is_ms_shipped = 0;

    INSERT  INTO #BlitzResults
            ( CheckID ,
              Priority ,
              FindingsGroup ,
              Finding ,
              URL ,
              Details
            )
            SELECT  29 AS CheckID ,
                    200 AS Priority ,
                    'Informational' AS FindingsGroup ,
                    'Tables in the Model Database' AS Finding ,
                    'http://BrentOzar.com/go/model' AS URL ,
                    ( 'The ' + name
                      + ' table in the model database was created by end users on '
                      + CAST(create_date AS VARCHAR(20))
                      + '. Tables in the model database are automatically copied into all new databases.' ) AS Details
            FROM    model.sys.tables
            WHERE   is_ms_shipped = 0;


    IF ( SELECT COUNT(*)
         FROM   msdb.dbo.sysalerts
         WHERE  severity BETWEEN 19 AND 25
       ) < 7 
        INSERT  INTO #BlitzResults
                ( CheckID ,
                  Priority ,
                  FindingsGroup ,
                  Finding ,
                  URL ,
                  Details
                )
                SELECT  30 AS CheckID ,
                        50 AS Priority ,
                        'Reliability' AS FindingsGroup ,
                        'Not All Alerts Configured' AS Finding ,
                        'http://BrentOzar.com/go/alert' AS URL ,
                        ( 'Not all SQL Server Agent alerts have been configured.  This is a free, easy way to get notified of corruption, job failures, or major outages even before monitoring systems pick it up.' ) AS Details;
    
    IF EXISTS ( SELECT  *
                FROM    msdb.dbo.sysalerts
                WHERE   enabled = 1
                        AND COALESCE(has_notification, 0) = 0
                        AND job_id IS NULL ) 
        INSERT  INTO #BlitzResults
                ( CheckID ,
                  Priority ,
                  FindingsGroup ,
                  Finding ,
                  URL ,
                  Details
                )
                SELECT  59 AS CheckID ,
                        50 AS Priority ,
                        'Reliability' AS FindingsGroup ,
                        'Alerts Configured without Follow Up' AS Finding ,
                        'http://BrentOzar.com/go/alert' AS URL ,
                        ( 'SQL Server Agent alerts have been configured but they either do not notify anyone or else they do not take any action.  This is a free, easy way to get notified of corruption, job failures, or major outages even before monitoring systems pick it up.' ) AS Details;

    IF NOT EXISTS ( SELECT  *
                    FROM    msdb.dbo.sysalerts
                    WHERE   message_id IN ( 823, 824, 825 ) ) 
        INSERT  INTO #BlitzResults
                ( CheckID ,
                  Priority ,
                  FindingsGroup ,
                  Finding ,
                  URL ,
                  Details
                )
                SELECT  60 AS CheckID ,
                        50 AS Priority ,
                        'Reliability' AS FindingsGroup ,
                        'No Alerts for Corruption' AS Finding ,
                        'http://BrentOzar.com/go/alert' AS URL ,
                        ( 'SQL Server Agent alerts do not exist for errors 823, 824, and 825.  These three errors can give you notification about early hardware failure. Enabling them can prevent you a lot of heartbreak.' ) AS Details;

    IF NOT EXISTS ( SELECT  *
                    FROM    msdb.dbo.sysalerts
                    WHERE   severity BETWEEN 19 AND 25 ) 
        INSERT  INTO #BlitzResults
                ( CheckID ,
                  Priority ,
                  FindingsGroup ,
                  Finding ,
                  URL ,
                  Details
                )
                SELECT  61 AS CheckID ,
                        50 AS Priority ,
                        'Reliability' AS FindingsGroup ,
                        'No Alerts for Sev 19-25' AS Finding ,
                        'http://BrentOzar.com/go/alert' AS URL ,
                        ( 'SQL Server Agent alerts do not exist for severity levels 19 through 25.  These are some very severe SQL Server errors. Knowing that these are happening may let you recover from errors faster.' ) AS Details;

            --check for disabled alerts
    IF EXISTS ( SELECT  name
                FROM    msdb.dbo.sysalerts
                WHERE   enabled = 0 ) 
        INSERT  INTO #BlitzResults
                ( CheckID ,
                  Priority ,
                  FindingsGroup ,
                  Finding ,
                  URL ,
                  Details
            
                )
                SELECT  62 AS CheckID ,
                        50 AS Priority ,
                        'Reliability' AS FindingsGroup ,
                        'Alerts Disabled' AS Finding ,
                        'http://www.BrentOzar.com/go/alerts/' AS URL ,
                        ( 'The following Alert is disabled, please review and enable if desired: '
                          + name ) AS Details
                FROM    msdb.dbo.sysalerts
                WHERE   enabled = 0


    IF NOT EXISTS ( SELECT  *
                    FROM    msdb.dbo.sysoperators
                    WHERE   enabled = 1 ) 
        INSERT  INTO #BlitzResults
                ( CheckID ,
                  Priority ,
                  FindingsGroup ,
                  Finding ,
                  URL ,
                  Details
                )
                SELECT  31 AS CheckID ,
                        50 AS Priority ,
                        'Reliability' AS FindingsGroup ,
                        'No Operators Configured/Enabled' AS Finding ,
                        'http://BrentOzar.com/go/op' AS URL ,
                        ( 'No SQL Server Agent operators (emails) have been configured.  This is a free, easy way to get notified of corruption, job failures, or major outages even before monitoring systems pick it up.' ) AS Details;

    IF @@VERSION NOT LIKE '%Microsoft SQL Server 2000%'
        AND @@VERSION NOT LIKE '%Microsoft SQL Server 2005%' 
        BEGIN
            EXEC dbo.sp_MSforeachdb 'USE [?]; INSERT INTO #BlitzResults (CheckID, Priority, FindingsGroup, Finding, URL, Details) SELECT DISTINCT 33, 200, ''Licensing'', ''Enterprise Edition Features In Use'', ''http://BrentOzar.com/go/ee'', (''The ['' + DB_NAME() + ''] database is using '' + feature_name + ''.  If this database is restored onto a Standard Edition server, the restore will fail.'') FROM [?].sys.dm_db_persisted_sku_features';
        END;

    IF @@VERSION NOT LIKE '%Microsoft SQL Server 2000%'
        AND @@VERSION NOT LIKE '%Microsoft SQL Server 2005%' 
        BEGIN
            SET @StringToExecute = 'INSERT INTO #BlitzResults (CheckID, Priority, FindingsGroup, Finding, URL, Details)
            SELECT TOP 1
                    34 AS CheckID ,
                    1 AS Priority ,
                    ''Corruption'' AS FindingsGroup ,
                    ''Database Corruption Detected'' AS Finding ,
                    ''http://BrentOzar.com/go/repair'' AS URL ,
                    ( ''Database mirroring has automatically repaired at least one corrupt page in the last 30 days. For more information, query the DMV sys.dm_db_mirroring_auto_page_repair.'' ) AS Details
            FROM    sys.dm_db_mirroring_auto_page_repair
            WHERE   modification_time >= DATEADD(dd, -30, GETDATE()) ;'
            EXECUTE(@StringToExecute)
        END;

    INSERT  INTO #BlitzResults
            ( CheckID ,
              Priority ,
              FindingsGroup ,
              Finding ,
              URL ,
              Details
            )
            SELECT DISTINCT
                    36 AS CheckID ,
                    100 AS Priority ,
                    'Performance' AS FindingsGroup ,
                    'Slow Storage Reads on Drive '
                    + UPPER(LEFT(mf.physical_name, 1)) AS Finding ,
                    'http://BrentOzar.com/go/slow' AS URL ,
                    'Reads are averaging longer than 100ms for at least one database on this drive.  For specific database file speeds, run the query from the information link.' AS Details
            FROM    sys.dm_io_virtual_file_stats(NULL, NULL) AS fs
                    INNER JOIN sys.master_files AS mf ON fs.database_id = mf.database_id
                                                         AND fs.[file_id] = mf.[file_id]
            WHERE   ( io_stall_read_ms / ( 1.0 + num_of_reads ) ) > 100;

    INSERT  INTO #BlitzResults
            ( CheckID ,
              Priority ,
              FindingsGroup ,
              Finding ,
              URL ,
              Details
            )
            SELECT DISTINCT
                    37 AS CheckID ,
                    100 AS Priority ,
                    'Performance' AS FindingsGroup ,
                    'Slow Storage Writes on Drive '
                    + UPPER(LEFT(mf.physical_name, 1)) AS Finding ,
                    'http://BrentOzar.com/go/slow' AS URL ,
                    'Writes are averaging longer than 20ms for at least one database on this drive.  For specific database file speeds, run the query from the information link.' AS Details
            FROM    sys.dm_io_virtual_file_stats(NULL, NULL) AS fs
                    INNER JOIN sys.master_files AS mf ON fs.database_id = mf.database_id
                                                         AND fs.[file_id] = mf.[file_id]
            WHERE   ( io_stall_write_ms / ( 1.0 + num_of_writes ) ) > 20;


    IF ( SELECT COUNT(*)
         FROM   tempdb.sys.database_files
         WHERE  type_desc = 'ROWS'
       ) = 1 
        BEGIN
            INSERT  INTO #BlitzResults
                    ( CheckID ,
                      Priority ,
                      FindingsGroup ,
                      Finding ,
                      URL ,
                      Details
                    )
            VALUES  ( 40 ,
                      100 ,
                      'Performance' ,
                      'TempDB Only Has 1 Data File' ,
                      'http://BrentOzar.com/go/tempdb' ,
                      'TempDB is only configured with one data file.  More data files are usually required to alleviate SGAM contention.'
                    );
        END;

    EXEC dbo.sp_MSforeachdb 'use [?]; INSERT INTO #BlitzResults (CheckID, Priority, FindingsGroup, Finding, URL, Details) SELECT 41, 100, ''Performance'', ''Multiple Log Files on One Drive'', ''http://BrentOzar.com/go/manylogs'', (''The ['' + DB_NAME() + ''] database has multiple log files on the '' + LEFT(physical_name, 1) + '' drive. This is not a performance booster because log file access is sequential, not parallel.'') FROM [?].sys.database_files WHERE type_desc = ''LOG'' AND ''?'' <> ''[tempdb]'' GROUP BY LEFT(physical_name, 1) HAVING COUNT(*) > 1';

    EXEC dbo.sp_MSforeachdb 'use [?]; INSERT INTO #BlitzResults (CheckID, Priority, FindingsGroup, Finding, URL, Details) SELECT DISTINCT 42, 100, ''Performance'', ''Uneven File Growth Settings in One Filegroup'', ''http://BrentOzar.com/go/grow'', (''The ['' + DB_NAME() + ''] database has multiple data files in one filegroup, but they are not all set up to grow in identical amounts.  This can lead to uneven file activity inside the filegroup.'') FROM [?].sys.database_files WHERE type_desc = ''ROWS'' GROUP BY data_space_id HAVING COUNT(DISTINCT growth) > 1 OR COUNT(DISTINCT is_percent_growth) > 1';

    INSERT  INTO #BlitzResults
            ( CheckID ,
              Priority ,
              FindingsGroup ,
              Finding ,
              URL ,
              Details
                    
            )
            SELECT  44 AS CheckID ,
                    110 AS Priority ,
                    'Performance' AS FindingsGroup ,
                    'Queries Forcing Order Hints' AS Finding ,
                    'http://BrentOzar.com/go/hints' AS URL ,
                    CAST(occurrence AS VARCHAR(10))
                    + ' instances of order hinting have been recorded since restart.  This means queries are bossing the SQL Server optimizer around, and if they don''t know what they''re doing, this can cause more harm than good.  This can also explain why DBA tuning efforts aren''t working.' AS Details
            FROM    sys.dm_exec_query_optimizer_info
            WHERE   counter = 'order hint'
                    AND occurrence > 1

    INSERT  INTO #BlitzResults
            ( CheckID ,
              Priority ,
              FindingsGroup ,
              Finding ,
              URL ,
              Details
            )
            SELECT  45 AS CheckID ,
                    110 AS Priority ,
                    'Performance' AS FindingsGroup ,
                    'Queries Forcing Join Hints' AS Finding ,
                    'http://BrentOzar.com/go/hints' AS URL ,
                    CAST(occurrence AS VARCHAR(10))
                    + ' instances of join hinting have been recorded since restart.  This means queries are bossing the SQL Server optimizer around, and if they don''t know what they''re doing, this can cause more harm than good.  This can also explain why DBA tuning efforts aren''t working.' AS Details
            FROM    sys.dm_exec_query_optimizer_info
            WHERE   counter = 'join hint'
                    AND occurrence > 1



    INSERT  INTO #BlitzResults
            ( CheckID ,
              Priority ,
              FindingsGroup ,
              Finding ,
              URL ,
              Details
            )
            SELECT DISTINCT
                    49 AS CheckID ,
                    200 AS Priority ,
                    'Informational' AS FindingsGroup ,
                    'Linked Server Configured' AS Finding ,
                    'http://BrentOzar.com/go/link' AS URL ,
                    +CASE WHEN l.remote_name = 'sa'
                          THEN s.data_source
                               + ' is configured as a linked server. Check its security configuration as it is connecting with sa, because any user who queries it will get admin-level permissions.'
                          ELSE s.data_source
                               + ' is configured as a linked server. Check its security configuration to make sure it isn''t connecting with SA or some other bone-headed administrative login, because any user who queries it might get admin-level permissions.'
                     END AS Details
            FROM    sys.servers s
                    INNER JOIN sys.linked_logins l ON s.server_id = l.server_id
            WHERE   s.is_linked = 1



    IF @@VERSION NOT LIKE '%Microsoft SQL Server 2000%'
        AND @@VERSION NOT LIKE '%Microsoft SQL Server 2005%' 
        BEGIN
            SET @StringToExecute = 'INSERT INTO #BlitzResults (CheckID, Priority, FindingsGroup, Finding, URL, Details)
            SELECT  50 AS CheckID ,
                    100 AS Priority ,
                    ''Performance'' AS FindingsGroup ,
                    ''Max Memory Set Too High'' AS Finding ,
                    ''http://BrentOzar.com/go/max'' AS URL ,
                    ''SQL Server max memory is set to ''
                    + CAST(c.value_in_use AS VARCHAR(20))
                    + '' megabytes, but the server only has ''
                    + CAST(( CAST(m.total_physical_memory_kb AS BIGINT) / 1024 ) AS VARCHAR(20))
                    + '' megabytes.  SQL Server may drain the system dry of memory, and under certain conditions, this can cause Windows to swap to disk.'' AS Details
            FROM    sys.dm_os_sys_memory m
                    INNER JOIN sys.configurations c ON c.name = ''max server memory (MB)''
            WHERE   CAST(m.total_physical_memory_kb AS BIGINT) < ( CAST(c.value_in_use AS BIGINT) * 1024 )'
            EXECUTE(@StringToExecute)
        END;


    IF @@VERSION NOT LIKE '%Microsoft SQL Server 2000%'
        AND @@VERSION NOT LIKE '%Microsoft SQL Server 2005%' 
        BEGIN
            SET @StringToExecute = 'INSERT INTO #BlitzResults (CheckID, Priority, FindingsGroup, Finding, URL, Details)
            SELECT  51 AS CheckID ,
                    1 AS Priority ,
                    ''Performance'' AS FindingsGroup ,
                    ''Memory Dangerously Low'' AS Finding ,
                    ''http://BrentOzar.com/go/max'' AS URL ,
                    ''Although available memory is ''
                    + CAST(( CAST(m.available_physical_memory_kb AS BIGINT)
                             / 1024 ) AS VARCHAR(20))
                    + '' megabytes, only ''
                    + CAST(( CAST(m.total_physical_memory_kb AS BIGINT) / 1024 ) AS VARCHAR(20))
                    + ''megabytes of memory are present.  As the server runs out of memory, there is danger of swapping to disk, which will kill performance.'' AS Details
            FROM    sys.dm_os_sys_memory m
            WHERE   CAST(m.available_physical_memory_kb AS BIGINT) < 262144'
            EXECUTE(@StringToExecute)
        END;


    INSERT  INTO #BlitzResults
            ( CheckID ,
              Priority ,
              FindingsGroup ,
              Finding ,
              URL ,
              Details
            )
            SELECT TOP 1
                    53 AS CheckID ,
                    200 AS Priority ,
                    'High Availability' AS FindingsGroup ,
                    'Cluster Node' AS Finding ,
                    'http://BrentOzar.com/go/node' AS URL ,
                    'This is a node in a cluster.' AS Details
            FROM    sys.dm_os_cluster_nodes

    INSERT  INTO #BlitzResults
            ( CheckID ,
              Priority ,
              FindingsGroup ,
              Finding ,
              URL ,
              Details
            )
            SELECT  55 AS CheckID ,
                    200 AS Priority ,
                    'Security' AS FindingsGroup ,
                    'Database Owner <> SA' AS Finding ,
                    'http://BrentOzar.com/go/owndb' AS URL ,
                    ( 'Database name: ' + name + '   ' + 'Owner name: '
                      + SUSER_SNAME(owner_sid) ) AS Details
            FROM    sys.databases
            WHERE   SUSER_SNAME(owner_sid) <> SUSER_SNAME(0x01);

    INSERT  INTO #BlitzResults
            ( CheckID ,
              Priority ,
              FindingsGroup ,
              Finding ,
              URL ,
              Details
            )
            SELECT  57 AS CheckID ,
                    10 AS Priority ,
                    'Security' AS FindingsGroup ,
                    'SQL Agent Job Runs at Startup' AS Finding ,
                    'http://BrentOzar.com/go/startup' AS URL ,
                    ( 'Job ' + j.name
                      + '] runs automatically when SQL Server Agent starts up.  Make sure you know exactly what this job is doing, because it could pose a security risk.' ) AS Details
            FROM    msdb.dbo.sysschedules sched
                    JOIN msdb.dbo.sysjobschedules jsched ON sched.schedule_id = jsched.schedule_id
                    JOIN msdb.dbo.sysjobs j ON jsched.job_id = j.job_id
            WHERE   sched.freq_type = 64;


    INSERT  INTO #BlitzResults
            ( CheckID ,
              Priority ,
              FindingsGroup ,
              Finding ,
              URL ,
              Details
            )
            SELECT  58 AS CheckID ,
                    200 AS Priority ,
                    'Reliability' AS FindingsGroup ,
                    'Database Collation Mismatch' AS Finding ,
                    'http://BrentOzar.com/go/collate' AS URL ,
                    ( 'Database ' + d.NAME + ' has collation '
                      + d.collation_name + '; Server collation is '
                      + CONVERT(VARCHAR(100), SERVERPROPERTY('collation')) ) AS Details
            FROM    master.sys.databases d
            WHERE   d.collation_name <> SERVERPROPERTY('collation')

    EXEC sp_MSforeachdb 'use [?]; INSERT INTO #BlitzResults (CheckID, Priority, FindingsGroup, Finding, URL, Details)
SELECT  DISTINCT 82 AS CheckID, 
        100 AS Priority, 
        ''Performance'' AS FindingsGroup, 
        ''File growth set to percent'', 
        ''http://brentozar.com/go/percentgrowth'' AS URL,
        ''The ['' + DB_NAME() + ''] database is using percent filegrowth settings. This can lead to out of control filegrowth.''
FROM    [?].sys.database_files 
WHERE   is_percent_growth = 1 ';


    INSERT  INTO #BlitzResults
            ( CheckID ,
              Priority ,
              FindingsGroup ,
              Finding ,
              URL ,
              Details
            )
            SELECT  61 AS CheckID ,
                    100 AS Priority ,
                    'Performance' AS FindingsGroup ,
                    'Unusual SQL Server Edition' AS Finding ,
                    'http://BrentOzar.com/go/workgroup' AS URL ,
                    ( 'This server is using '
                      + CAST(SERVERPROPERTY('edition') AS VARCHAR(100))
                      + ', which is capped at low amounts of CPU and memory.' ) AS Details
            WHERE   CAST(SERVERPROPERTY('edition') AS VARCHAR(100)) NOT LIKE '%Standard%'
                    AND CAST(SERVERPROPERTY('edition') AS VARCHAR(100)) NOT LIKE '%Enterprise%'
                    AND CAST(SERVERPROPERTY('edition') AS VARCHAR(100)) NOT LIKE '%Developer%'

    INSERT  INTO #BlitzResults
            ( CheckID ,
              Priority ,
              FindingsGroup ,
              Finding ,
              URL ,
              Details
	          
            )
            SELECT  62 AS CheckID ,
                    200 AS Priority ,
                    'Performance' AS FindingsGroup ,
                    'Old Compatibility Level' AS Finding ,
                    'http://BrentOzar.com/go/compatlevel' AS URL ,
                    ( 'Database ' + name + ' is compatibility level '
                      + CAST(compatibility_level AS VARCHAR(20))
                      + ', which may cause unwanted results when trying to run queries that have newer T-SQL features.' ) AS Details
            FROM    sys.databases
            WHERE   compatibility_level <> ( SELECT compatibility_level
                                             FROM   sys.databases
                                             WHERE  name = 'model'
                                           )
	  
	  
	  

    IF @CheckUserDatabaseObjects = 1 
        BEGIN

            EXEC dbo.sp_MSforeachdb 'USE [?]; INSERT INTO #BlitzResults (CheckID, Priority, FindingsGroup, Finding, URL, Details) SELECT DISTINCT 32, 110, ''Performance'', ''Triggers on Tables'', ''http://BrentOzar.com/go/trig'', (''The ['' + DB_NAME() + ''] database has triggers on the '' + s.name + ''.'' + o.name + '' table.'') FROM [?].sys.triggers t INNER JOIN [?].sys.objects o ON t.parent_id = o.object_id INNER JOIN [?].sys.schemas s ON o.schema_id = s.schema_id WHERE t.is_ms_shipped = 0';

            EXEC dbo.sp_MSforeachdb 'USE [?]; INSERT INTO #BlitzResults (CheckID, Priority, FindingsGroup, Finding, URL, Details) SELECT DISTINCT 38, 110, ''Performance'', ''Active Tables Without Clustered Indexes'', ''http://BrentOzar.com/go/heaps'', (''The ['' + DB_NAME() + ''] database has heaps - tables without a clustered index - that are being actively queried.'') FROM [?].sys.indexes i INNER JOIN [?].sys.objects o ON i.object_id = o.object_id INNER JOIN [?].sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id INNER JOIN sys.databases sd ON sd.name = ''?'' LEFT OUTER JOIN [?].sys.dm_db_index_usage_stats ius ON i.object_id = ius.object_id AND i.index_id = ius.index_id AND ius.database_id = sd.database_id WHERE i.type_desc = ''HEAP'' AND COALESCE(ius.user_seeks, ius.user_scans, ius.user_lookups, ius.user_updates) IS NOT NULL AND sd.name <> ''tempdb'' AND o.is_ms_shipped = 0 AND o.type <> ''S''';

            EXEC dbo.sp_MSforeachdb 'USE [?]; INSERT INTO #BlitzResults (CheckID, Priority, FindingsGroup, Finding, URL, Details) SELECT DISTINCT 39, 110, ''Performance'', ''Inactive Tables Without Clustered Indexes'', ''http://BrentOzar.com/go/heaps'', (''The ['' + DB_NAME() + ''] database has heaps - tables without a clustered index - that have not been queried since the last restart.  These may be backup tables carelessly left behind.'') FROM [?].sys.indexes i INNER JOIN [?].sys.objects o ON i.object_id = o.object_id INNER JOIN [?].sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id INNER JOIN sys.databases sd ON sd.name = ''?'' LEFT OUTER JOIN [?].sys.dm_db_index_usage_stats ius ON i.object_id = ius.object_id AND i.index_id = ius.index_id AND ius.database_id = sd.database_id WHERE i.type_desc = ''HEAP'' AND COALESCE(ius.user_seeks, ius.user_scans, ius.user_lookups, ius.user_updates) IS NULL AND sd.name <> ''tempdb'' AND o.is_ms_shipped = 0 AND o.type <> ''S''';

            EXEC dbo.sp_MSforeachdb 'USE [?]; INSERT INTO #BlitzResults (CheckID, Priority, FindingsGroup, Finding, URL, Details) SELECT 46, 100, ''Performance'', ''Leftover Fake Indexes From Wizards'', ''http://BrentOzar.com/go/hypo'', (''The index ['' + DB_NAME() + ''].['' + s.name + ''].['' + o.name + ''].['' + i.name + ''] is a leftover hypothetical index from the Index Tuning Wizard or Database Tuning Advisor.  This index is not actually helping performance and should be removed.'') from [?].sys.indexes i INNER JOIN [?].sys.objects o ON i.object_id = o.object_id INNER JOIN [?].sys.schemas s ON o.schema_id = s.schema_id WHERE i.is_hypothetical = 1';

            EXEC dbo.sp_MSforeachdb 'USE [?]; INSERT INTO #BlitzResults (CheckID, Priority, FindingsGroup, Finding, URL, Details) SELECT 47, 100, ''Performance'', ''Indexes Disabled'', ''http://BrentOzar.com/go/ixoff'', (''The index ['' + DB_NAME() + ''].['' + s.name + ''].['' + o.name + ''].['' + i.name + ''] is disabled.  This index is not actually helping performance and should either be enabled or removed.'') from [?].sys.indexes i INNER JOIN [?].sys.objects o ON i.object_id = o.object_id INNER JOIN [?].sys.schemas s ON o.schema_id = s.schema_id WHERE i.is_disabled = 1';

            EXEC dbo.sp_MSforeachdb 'USE [?]; INSERT INTO #BlitzResults (CheckID, Priority, FindingsGroup, Finding, URL, Details) SELECT DISTINCT 48, 100, ''Performance'', ''Foreign Keys Not Trusted'', ''http://BrentOzar.com/go/trust'', (''The ['' + DB_NAME() + ''] database has foreign keys that were probably disabled, data was changed, and then the key was enabled again.  Simply enabling the key is not enough for the optimizer to use this key - we have to alter the table using the WITH CHECK CHECK CONSTRAINT parameter.'') from [?].sys.foreign_keys i INNER JOIN [?].sys.objects o ON i.parent_object_id = o.object_id INNER JOIN [?].sys.schemas s ON o.schema_id = s.schema_id WHERE i.is_not_trusted = 1 AND i.is_not_for_replication = 0 AND i.is_disabled = 0';

            EXEC dbo.sp_MSforeachdb 'USE [?]; INSERT INTO #BlitzResults (CheckID, Priority, FindingsGroup, Finding, URL, Details) SELECT 56, 100, ''Performance'', ''Check Constraint Not Trusted'', ''http://BrentOzar.com/go/trust'', (''The check constraint ['' + DB_NAME() + ''].['' + s.name + ''].['' + o.name + ''].['' + i.name + ''] is not trusted - meaning, it was disabled, data was changed, and then the constraint was enabled again.  Simply enabling the constraint is not enough for the optimizer to use this constraint - we have to alter the table using the WITH CHECK CHECK CONSTRAINT parameter.'') from [?].sys.check_constraints i INNER JOIN [?].sys.objects o ON i.parent_object_id = o.object_id INNER JOIN [?].sys.schemas s ON o.schema_id = s.schema_id WHERE i.is_not_trusted = 1 AND i.is_not_for_replication = 0 AND i.is_disabled = 0';

            IF @@VERSION NOT LIKE '%Microsoft SQL Server 2000%'
                AND @@VERSION NOT LIKE '%Microsoft SQL Server 2005%' 
                BEGIN
                    EXEC dbo.sp_MSforeachdb 'USE [?]; INSERT INTO #BlitzResults (CheckID, Priority, FindingsGroup, Finding, URL, Details) SELECT TOP 1 13 AS CheckID, 110 AS Priority, ''Performance'' AS FindingsGroup, ''Plan Guides Enabled'' AS Finding, ''http://BrentOzar.com/go/guides'' AS URL, (''Database ['' + DB_NAME() + ''] has query plan guides so a query will always get a specific execution plan. If you are having trouble getting query performance to improve, it might be due to a frozen plan. Review the DMV sys.plan_guides to learn more about the plan guides in place on this server.'') AS Details FROM [?].sys.plan_guides WHERE is_disabled = 0'
                END;

            EXEC sp_MSforeachdb 'USE [?]; INSERT INTO #BlitzResults (CheckID, Priority, FindingsGroup, Finding, URL, Details)
		SELECT  DISTINCT 60 AS CheckID, 
		        100 AS Priority, 
		        ''Performance'' AS FindingsGroup, 
		        ''Fill Factor Changed'', 
		        ''http://brentozar.com/go/fillfactor'' AS URL,
		        ''The ['' + DB_NAME() + ''] database has objects with fill factor <> 0. This can cause memory and storage performance problems, but may also prevent page splits.''
		FROM    [?].sys.indexes 
		WHERE   fill_factor <> 0 AND fill_factor <> 100 AND is_disabled = 0 AND is_hypothetical = 0';

            EXEC dbo.sp_MSforeachdb 'USE [?]; INSERT INTO #BlitzResults (CheckID, Priority, FindingsGroup, Finding, URL, Details) SELECT 78, 100, ''Performance'', ''Stored Procedure WITH RECOMPILE'', ''http://BrentOzar.com/go/recompile'', (''['' + DB_NAME() + ''].['' + SPECIFIC_SCHEMA + ''].['' + SPECIFIC_NAME + ''] has WITH RECOMPILE in the stored procedure code, which may cause increased CPU usage due to constant recompiles of the code.'') from [?].INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_DEFINITION LIKE N''%WITH RECOMPILE%''';

            EXEC dbo.sp_MSforeachdb 'USE [?]; INSERT INTO #BlitzResults (CheckID, Priority, FindingsGroup, Finding, URL, Details) SELECT DISTINCT 86, 20, ''Security'', ''Elevated Permissions on a Database'', ''http://BrentOzar.com/go/elevated'', (''In ['' + DB_NAME() + ''], user ['' + u.name + '']  has the role ['' + g.name + ''].  This user can perform tasks beyond just reading and writing data.'') FROM [?].dbo.sysmembers m inner join [?].dbo.sysusers u on m.memberuid = u.uid inner join sysusers g on m.groupuid = g.uid where u.name <> ''dbo'' and g.name in (''db_owner'' , ''db_accessAdmin'' , ''db_securityadmin'' , ''db_ddladmin'')';



        END /* IF @CheckUserDatabaseObjects = 1 */


    IF @CheckProcedureCache = 1 
        BEGIN
			
            INSERT  INTO #BlitzResults
                    ( CheckID ,
                      Priority ,
                      FindingsGroup ,
                      Finding ,
                      URL ,
                      Details
	                    
                    )
                    SELECT  35 AS CheckID ,
                            100 AS Priority ,
                            'Performance' AS FindingsGroup ,
                            'Single-Use Plans in Procedure Cache' AS Finding ,
                            'http://BrentOzar.com/go/single' AS URL ,
                            ( CAST(COUNT(*) AS VARCHAR(10))
                              + ' query plans are taking up memory in the procedure cache. This may be wasted memory if we cache plans for queries that never get called again. This may be a good use case for SQL Server 2008''s Optimize for Ad Hoc or for Forced Parameterization.' ) AS Details
                    FROM    sys.dm_exec_cached_plans AS cp
                    WHERE   cp.usecounts = 1
                            AND cp.objtype = 'Adhoc'
                            AND EXISTS ( SELECT 1
                                         FROM   sys.configurations
                                         WHERE  name = 'optimize for ad hoc workloads'
                                                AND value_in_use = 0 )
                    HAVING  COUNT(*) > 1;


				/* Set up the cache tables. Different on 2005 since it doesn't support query_hash, query_plan_hash. */
            IF @@VERSION LIKE '%Microsoft SQL Server 2005%' 
                BEGIN
                    IF @CheckProcedureCacheFilter = 'CPU'
                        OR @CheckProcedureCacheFilter IS NULL 
                        BEGIN
                            SET @StringToExecute = 'WITH queries ([sql_handle],[statement_start_offset],[statement_end_offset],[plan_generation_num],[plan_handle],[creation_time],[last_execution_time],[execution_count],[total_worker_time],[last_worker_time],[min_worker_time],[max_worker_time],[total_physical_reads],[last_physical_reads],[min_physical_reads],[max_physical_reads],[total_logical_writes],[last_logical_writes],[min_logical_writes],[max_logical_writes],[total_logical_reads],[last_logical_reads],[min_logical_reads],[max_logical_reads],[total_clr_time],[last_clr_time],[min_clr_time],[max_clr_time],[total_elapsed_time],[last_elapsed_time],[min_elapsed_time],[max_elapsed_time])
			            AS (SELECT TOP 20 qs.[sql_handle],qs.[statement_start_offset],qs.[statement_end_offset],qs.[plan_generation_num],qs.[plan_handle],qs.[creation_time],qs.[last_execution_time],qs.[execution_count],qs.[total_worker_time],qs.[last_worker_time],qs.[min_worker_time],qs.[max_worker_time],qs.[total_physical_reads],qs.[last_physical_reads],qs.[min_physical_reads],qs.[max_physical_reads],qs.[total_logical_writes],qs.[last_logical_writes],qs.[min_logical_writes],qs.[max_logical_writes],qs.[total_logical_reads],qs.[last_logical_reads],qs.[min_logical_reads],qs.[max_logical_reads],qs.[total_clr_time],qs.[last_clr_time],qs.[min_clr_time],qs.[max_clr_time],qs.[total_elapsed_time],qs.[last_elapsed_time],qs.[min_elapsed_time],qs.[max_elapsed_time]
						FROM sys.dm_exec_query_stats qs
						ORDER BY qs.total_worker_time DESC)
						INSERT INTO #dm_exec_query_stats ([sql_handle],[statement_start_offset],[statement_end_offset],[plan_generation_num],[plan_handle],[creation_time],[last_execution_time],[execution_count],[total_worker_time],[last_worker_time],[min_worker_time],[max_worker_time],[total_physical_reads],[last_physical_reads],[min_physical_reads],[max_physical_reads],[total_logical_writes],[last_logical_writes],[min_logical_writes],[max_logical_writes],[total_logical_reads],[last_logical_reads],[min_logical_reads],[max_logical_reads],[total_clr_time],[last_clr_time],[min_clr_time],[max_clr_time],[total_elapsed_time],[last_elapsed_time],[min_elapsed_time],[max_elapsed_time])
						SELECT qs.[sql_handle],qs.[statement_start_offset],qs.[statement_end_offset],qs.[plan_generation_num],qs.[plan_handle],qs.[creation_time],qs.[last_execution_time],qs.[execution_count],qs.[total_worker_time],qs.[last_worker_time],qs.[min_worker_time],qs.[max_worker_time],qs.[total_physical_reads],qs.[last_physical_reads],qs.[min_physical_reads],qs.[max_physical_reads],qs.[total_logical_writes],qs.[last_logical_writes],qs.[min_logical_writes],qs.[max_logical_writes],qs.[total_logical_reads],qs.[last_logical_reads],qs.[min_logical_reads],qs.[max_logical_reads],qs.[total_clr_time],qs.[last_clr_time],qs.[min_clr_time],qs.[max_clr_time],qs.[total_elapsed_time],qs.[last_elapsed_time],qs.[min_elapsed_time],qs.[max_elapsed_time]
						FROM queries qs
						LEFT OUTER JOIN #dm_exec_query_stats qsCaught ON qs.sql_handle = qsCaught.sql_handle AND qs.plan_handle = qsCaught.plan_handle AND qs.statement_start_offset = qsCaught.statement_start_offset
						WHERE qsCaught.sql_handle IS NULL;'
                            EXECUTE(@StringToExecute)
                        END

                    IF @CheckProcedureCacheFilter = 'Reads'
                        OR @CheckProcedureCacheFilter IS NULL 
                        BEGIN
                            SET @StringToExecute = 'WITH queries ([sql_handle],[statement_start_offset],[statement_end_offset],[plan_generation_num],[plan_handle],[creation_time],[last_execution_time],[execution_count],[total_worker_time],[last_worker_time],[min_worker_time],[max_worker_time],[total_physical_reads],[last_physical_reads],[min_physical_reads],[max_physical_reads],[total_logical_writes],[last_logical_writes],[min_logical_writes],[max_logical_writes],[total_logical_reads],[last_logical_reads],[min_logical_reads],[max_logical_reads],[total_clr_time],[last_clr_time],[min_clr_time],[max_clr_time],[total_elapsed_time],[last_elapsed_time],[min_elapsed_time],[max_elapsed_time])
			            AS (SELECT TOP 20 qs.[sql_handle],qs.[statement_start_offset],qs.[statement_end_offset],qs.[plan_generation_num],qs.[plan_handle],qs.[creation_time],qs.[last_execution_time],qs.[execution_count],qs.[total_worker_time],qs.[last_worker_time],qs.[min_worker_time],qs.[max_worker_time],qs.[total_physical_reads],qs.[last_physical_reads],qs.[min_physical_reads],qs.[max_physical_reads],qs.[total_logical_writes],qs.[last_logical_writes],qs.[min_logical_writes],qs.[max_logical_writes],qs.[total_logical_reads],qs.[last_logical_reads],qs.[min_logical_reads],qs.[max_logical_reads],qs.[total_clr_time],qs.[last_clr_time],qs.[min_clr_time],qs.[max_clr_time],qs.[total_elapsed_time],qs.[last_elapsed_time],qs.[min_elapsed_time],qs.[max_elapsed_time]
						FROM sys.dm_exec_query_stats qs
						ORDER BY qs.total_logical_reads DESC)
						INSERT INTO #dm_exec_query_stats ([sql_handle],[statement_start_offset],[statement_end_offset],[plan_generation_num],[plan_handle],[creation_time],[last_execution_time],[execution_count],[total_worker_time],[last_worker_time],[min_worker_time],[max_worker_time],[total_physical_reads],[last_physical_reads],[min_physical_reads],[max_physical_reads],[total_logical_writes],[last_logical_writes],[min_logical_writes],[max_logical_writes],[total_logical_reads],[last_logical_reads],[min_logical_reads],[max_logical_reads],[total_clr_time],[last_clr_time],[min_clr_time],[max_clr_time],[total_elapsed_time],[last_elapsed_time],[min_elapsed_time],[max_elapsed_time])
						SELECT qs.[sql_handle],qs.[statement_start_offset],qs.[statement_end_offset],qs.[plan_generation_num],qs.[plan_handle],qs.[creation_time],qs.[last_execution_time],qs.[execution_count],qs.[total_worker_time],qs.[last_worker_time],qs.[min_worker_time],qs.[max_worker_time],qs.[total_physical_reads],qs.[last_physical_reads],qs.[min_physical_reads],qs.[max_physical_reads],qs.[total_logical_writes],qs.[last_logical_writes],qs.[min_logical_writes],qs.[max_logical_writes],qs.[total_logical_reads],qs.[last_logical_reads],qs.[min_logical_reads],qs.[max_logical_reads],qs.[total_clr_time],qs.[last_clr_time],qs.[min_clr_time],qs.[max_clr_time],qs.[total_elapsed_time],qs.[last_elapsed_time],qs.[min_elapsed_time],qs.[max_elapsed_time]
						FROM queries qs
						LEFT OUTER JOIN #dm_exec_query_stats qsCaught ON qs.sql_handle = qsCaught.sql_handle AND qs.plan_handle = qsCaught.plan_handle AND qs.statement_start_offset = qsCaught.statement_start_offset
						WHERE qsCaught.sql_handle IS NULL;'
                        END

                    IF @CheckProcedureCacheFilter = 'ExecCount'
                        OR @CheckProcedureCacheFilter IS NULL 
                        BEGIN
                            SET @StringToExecute = 'WITH queries ([sql_handle],[statement_start_offset],[statement_end_offset],[plan_generation_num],[plan_handle],[creation_time],[last_execution_time],[execution_count],[total_worker_time],[last_worker_time],[min_worker_time],[max_worker_time],[total_physical_reads],[last_physical_reads],[min_physical_reads],[max_physical_reads],[total_logical_writes],[last_logical_writes],[min_logical_writes],[max_logical_writes],[total_logical_reads],[last_logical_reads],[min_logical_reads],[max_logical_reads],[total_clr_time],[last_clr_time],[min_clr_time],[max_clr_time],[total_elapsed_time],[last_elapsed_time],[min_elapsed_time],[max_elapsed_time])
			            AS (SELECT TOP 20 qs.[sql_handle],qs.[statement_start_offset],qs.[statement_end_offset],qs.[plan_generation_num],qs.[plan_handle],qs.[creation_time],qs.[last_execution_time],qs.[execution_count],qs.[total_worker_time],qs.[last_worker_time],qs.[min_worker_time],qs.[max_worker_time],qs.[total_physical_reads],qs.[last_physical_reads],qs.[min_physical_reads],qs.[max_physical_reads],qs.[total_logical_writes],qs.[last_logical_writes],qs.[min_logical_writes],qs.[max_logical_writes],qs.[total_logical_reads],qs.[last_logical_reads],qs.[min_logical_reads],qs.[max_logical_reads],qs.[total_clr_time],qs.[last_clr_time],qs.[min_clr_time],qs.[max_clr_time],qs.[total_elapsed_time],qs.[last_elapsed_time],qs.[min_elapsed_time],qs.[max_elapsed_time]
						FROM sys.dm_exec_query_stats qs
						ORDER BY qs.execution_count DESC)
						INSERT INTO #dm_exec_query_stats ([sql_handle],[statement_start_offset],[statement_end_offset],[plan_generation_num],[plan_handle],[creation_time],[last_execution_time],[execution_count],[total_worker_time],[last_worker_time],[min_worker_time],[max_worker_time],[total_physical_reads],[last_physical_reads],[min_physical_reads],[max_physical_reads],[total_logical_writes],[last_logical_writes],[min_logical_writes],[max_logical_writes],[total_logical_reads],[last_logical_reads],[min_logical_reads],[max_logical_reads],[total_clr_time],[last_clr_time],[min_clr_time],[max_clr_time],[total_elapsed_time],[last_elapsed_time],[min_elapsed_time],[max_elapsed_time])
						SELECT qs.[sql_handle],qs.[statement_start_offset],qs.[statement_end_offset],qs.[plan_generation_num],qs.[plan_handle],qs.[creation_time],qs.[last_execution_time],qs.[execution_count],qs.[total_worker_time],qs.[last_worker_time],qs.[min_worker_time],qs.[max_worker_time],qs.[total_physical_reads],qs.[last_physical_reads],qs.[min_physical_reads],qs.[max_physical_reads],qs.[total_logical_writes],qs.[last_logical_writes],qs.[min_logical_writes],qs.[max_logical_writes],qs.[total_logical_reads],qs.[last_logical_reads],qs.[min_logical_reads],qs.[max_logical_reads],qs.[total_clr_time],qs.[last_clr_time],qs.[min_clr_time],qs.[max_clr_time],qs.[total_elapsed_time],qs.[last_elapsed_time],qs.[min_elapsed_time],qs.[max_elapsed_time]
						FROM queries qs
						LEFT OUTER JOIN #dm_exec_query_stats qsCaught ON qs.sql_handle = qsCaught.sql_handle AND qs.plan_handle = qsCaught.plan_handle AND qs.statement_start_offset = qsCaught.statement_start_offset
						WHERE qsCaught.sql_handle IS NULL;'
                            EXECUTE(@StringToExecute)
                        END

                    IF @CheckProcedureCacheFilter = 'Duration'
                        OR @CheckProcedureCacheFilter IS NULL 
                        BEGIN
                            SET @StringToExecute = 'WITH queries ([sql_handle],[statement_start_offset],[statement_end_offset],[plan_generation_num],[plan_handle],[creation_time],[last_execution_time],[execution_count],[total_worker_time],[last_worker_time],[min_worker_time],[max_worker_time],[total_physical_reads],[last_physical_reads],[min_physical_reads],[max_physical_reads],[total_logical_writes],[last_logical_writes],[min_logical_writes],[max_logical_writes],[total_logical_reads],[last_logical_reads],[min_logical_reads],[max_logical_reads],[total_clr_time],[last_clr_time],[min_clr_time],[max_clr_time],[total_elapsed_time],[last_elapsed_time],[min_elapsed_time],[max_elapsed_time])
			            AS (SELECT TOP 20 qs.[sql_handle],qs.[statement_start_offset],qs.[statement_end_offset],qs.[plan_generation_num],qs.[plan_handle],qs.[creation_time],qs.[last_execution_time],qs.[execution_count],qs.[total_worker_time],qs.[last_worker_time],qs.[min_worker_time],qs.[max_worker_time],qs.[total_physical_reads],qs.[last_physical_reads],qs.[min_physical_reads],qs.[max_physical_reads],qs.[total_logical_writes],qs.[last_logical_writes],qs.[min_logical_writes],qs.[max_logical_writes],qs.[total_logical_reads],qs.[last_logical_reads],qs.[min_logical_reads],qs.[max_logical_reads],qs.[total_clr_time],qs.[last_clr_time],qs.[min_clr_time],qs.[max_clr_time],qs.[total_elapsed_time],qs.[last_elapsed_time],qs.[min_elapsed_time],qs.[max_elapsed_time]
						FROM sys.dm_exec_query_stats qs
						ORDER BY qs.total_elapsed_time DESC)
						INSERT INTO #dm_exec_query_stats ([sql_handle],[statement_start_offset],[statement_end_offset],[plan_generation_num],[plan_handle],[creation_time],[last_execution_time],[execution_count],[total_worker_time],[last_worker_time],[min_worker_time],[max_worker_time],[total_physical_reads],[last_physical_reads],[min_physical_reads],[max_physical_reads],[total_logical_writes],[last_logical_writes],[min_logical_writes],[max_logical_writes],[total_logical_reads],[last_logical_reads],[min_logical_reads],[max_logical_reads],[total_clr_time],[last_clr_time],[min_clr_time],[max_clr_time],[total_elapsed_time],[last_elapsed_time],[min_elapsed_time],[max_elapsed_time])
						SELECT qs.[sql_handle],qs.[statement_start_offset],qs.[statement_end_offset],qs.[plan_generation_num],qs.[plan_handle],qs.[creation_time],qs.[last_execution_time],qs.[execution_count],qs.[total_worker_time],qs.[last_worker_time],qs.[min_worker_time],qs.[max_worker_time],qs.[total_physical_reads],qs.[last_physical_reads],qs.[min_physical_reads],qs.[max_physical_reads],qs.[total_logical_writes],qs.[last_logical_writes],qs.[min_logical_writes],qs.[max_logical_writes],qs.[total_logical_reads],qs.[last_logical_reads],qs.[min_logical_reads],qs.[max_logical_reads],qs.[total_clr_time],qs.[last_clr_time],qs.[min_clr_time],qs.[max_clr_time],qs.[total_elapsed_time],qs.[last_elapsed_time],qs.[min_elapsed_time],qs.[max_elapsed_time]
						FROM queries qs
						LEFT OUTER JOIN #dm_exec_query_stats qsCaught ON qs.sql_handle = qsCaught.sql_handle AND qs.plan_handle = qsCaught.plan_handle AND qs.statement_start_offset = qsCaught.statement_start_offset
						WHERE qsCaught.sql_handle IS NULL;'
                            EXECUTE(@StringToExecute)
                        END

                END;
            IF @@VERSION LIKE '%Microsoft SQL Server 2008%'
                OR @@VERSION LIKE '%Microsoft SQL Server 2012%' 
                BEGIN
                    IF @CheckProcedureCacheFilter = 'CPU'
                        OR @CheckProcedureCacheFilter IS NULL 
                        BEGIN
                            SET @StringToExecute = 'WITH queries ([sql_handle],[statement_start_offset],[statement_end_offset],[plan_generation_num],[plan_handle],[creation_time],[last_execution_time],[execution_count],[total_worker_time],[last_worker_time],[min_worker_time],[max_worker_time],[total_physical_reads],[last_physical_reads],[min_physical_reads],[max_physical_reads],[total_logical_writes],[last_logical_writes],[min_logical_writes],[max_logical_writes],[total_logical_reads],[last_logical_reads],[min_logical_reads],[max_logical_reads],[total_clr_time],[last_clr_time],[min_clr_time],[max_clr_time],[total_elapsed_time],[last_elapsed_time],[min_elapsed_time],[max_elapsed_time],[query_hash],[query_plan_hash])
			            AS (SELECT TOP 20 qs.[sql_handle],qs.[statement_start_offset],qs.[statement_end_offset],qs.[plan_generation_num],qs.[plan_handle],qs.[creation_time],qs.[last_execution_time],qs.[execution_count],qs.[total_worker_time],qs.[last_worker_time],qs.[min_worker_time],qs.[max_worker_time],qs.[total_physical_reads],qs.[last_physical_reads],qs.[min_physical_reads],qs.[max_physical_reads],qs.[total_logical_writes],qs.[last_logical_writes],qs.[min_logical_writes],qs.[max_logical_writes],qs.[total_logical_reads],qs.[last_logical_reads],qs.[min_logical_reads],qs.[max_logical_reads],qs.[total_clr_time],qs.[last_clr_time],qs.[min_clr_time],qs.[max_clr_time],qs.[total_elapsed_time],qs.[last_elapsed_time],qs.[min_elapsed_time],qs.[max_elapsed_time],qs.[query_hash],qs.[query_plan_hash]
						FROM sys.dm_exec_query_stats qs
						ORDER BY qs.total_worker_time DESC)
						INSERT INTO #dm_exec_query_stats ([sql_handle],[statement_start_offset],[statement_end_offset],[plan_generation_num],[plan_handle],[creation_time],[last_execution_time],[execution_count],[total_worker_time],[last_worker_time],[min_worker_time],[max_worker_time],[total_physical_reads],[last_physical_reads],[min_physical_reads],[max_physical_reads],[total_logical_writes],[last_logical_writes],[min_logical_writes],[max_logical_writes],[total_logical_reads],[last_logical_reads],[min_logical_reads],[max_logical_reads],[total_clr_time],[last_clr_time],[min_clr_time],[max_clr_time],[total_elapsed_time],[last_elapsed_time],[min_elapsed_time],[max_elapsed_time],[query_hash],[query_plan_hash])
						SELECT qs.[sql_handle],qs.[statement_start_offset],qs.[statement_end_offset],qs.[plan_generation_num],qs.[plan_handle],qs.[creation_time],qs.[last_execution_time],qs.[execution_count],qs.[total_worker_time],qs.[last_worker_time],qs.[min_worker_time],qs.[max_worker_time],qs.[total_physical_reads],qs.[last_physical_reads],qs.[min_physical_reads],qs.[max_physical_reads],qs.[total_logical_writes],qs.[last_logical_writes],qs.[min_logical_writes],qs.[max_logical_writes],qs.[total_logical_reads],qs.[last_logical_reads],qs.[min_logical_reads],qs.[max_logical_reads],qs.[total_clr_time],qs.[last_clr_time],qs.[min_clr_time],qs.[max_clr_time],qs.[total_elapsed_time],qs.[last_elapsed_time],qs.[min_elapsed_time],qs.[max_elapsed_time],qs.[query_hash],qs.[query_plan_hash]
						FROM queries qs
						LEFT OUTER JOIN #dm_exec_query_stats qsCaught ON qs.sql_handle = qsCaught.sql_handle AND qs.plan_handle = qsCaught.plan_handle AND qs.statement_start_offset = qsCaught.statement_start_offset
						WHERE qsCaught.sql_handle IS NULL;'
                            EXECUTE(@StringToExecute)
                        END

                    IF @CheckProcedureCacheFilter = 'Reads'
                        OR @CheckProcedureCacheFilter IS NULL 
                        BEGIN
                            SET @StringToExecute = 'WITH queries ([sql_handle],[statement_start_offset],[statement_end_offset],[plan_generation_num],[plan_handle],[creation_time],[last_execution_time],[execution_count],[total_worker_time],[last_worker_time],[min_worker_time],[max_worker_time],[total_physical_reads],[last_physical_reads],[min_physical_reads],[max_physical_reads],[total_logical_writes],[last_logical_writes],[min_logical_writes],[max_logical_writes],[total_logical_reads],[last_logical_reads],[min_logical_reads],[max_logical_reads],[total_clr_time],[last_clr_time],[min_clr_time],[max_clr_time],[total_elapsed_time],[last_elapsed_time],[min_elapsed_time],[max_elapsed_time],[query_hash],[query_plan_hash])
			            AS (SELECT TOP 20 qs.[sql_handle],qs.[statement_start_offset],qs.[statement_end_offset],qs.[plan_generation_num],qs.[plan_handle],qs.[creation_time],qs.[last_execution_time],qs.[execution_count],qs.[total_worker_time],qs.[last_worker_time],qs.[min_worker_time],qs.[max_worker_time],qs.[total_physical_reads],qs.[last_physical_reads],qs.[min_physical_reads],qs.[max_physical_reads],qs.[total_logical_writes],qs.[last_logical_writes],qs.[min_logical_writes],qs.[max_logical_writes],qs.[total_logical_reads],qs.[last_logical_reads],qs.[min_logical_reads],qs.[max_logical_reads],qs.[total_clr_time],qs.[last_clr_time],qs.[min_clr_time],qs.[max_clr_time],qs.[total_elapsed_time],qs.[last_elapsed_time],qs.[min_elapsed_time],qs.[max_elapsed_time],qs.[query_hash],qs.[query_plan_hash]
						FROM sys.dm_exec_query_stats qs
						ORDER BY qs.total_logical_reads DESC)
						INSERT INTO #dm_exec_query_stats ([sql_handle],[statement_start_offset],[statement_end_offset],[plan_generation_num],[plan_handle],[creation_time],[last_execution_time],[execution_count],[total_worker_time],[last_worker_time],[min_worker_time],[max_worker_time],[total_physical_reads],[last_physical_reads],[min_physical_reads],[max_physical_reads],[total_logical_writes],[last_logical_writes],[min_logical_writes],[max_logical_writes],[total_logical_reads],[last_logical_reads],[min_logical_reads],[max_logical_reads],[total_clr_time],[last_clr_time],[min_clr_time],[max_clr_time],[total_elapsed_time],[last_elapsed_time],[min_elapsed_time],[max_elapsed_time],[query_hash],[query_plan_hash])
						SELECT qs.[sql_handle],qs.[statement_start_offset],qs.[statement_end_offset],qs.[plan_generation_num],qs.[plan_handle],qs.[creation_time],qs.[last_execution_time],qs.[execution_count],qs.[total_worker_time],qs.[last_worker_time],qs.[min_worker_time],qs.[max_worker_time],qs.[total_physical_reads],qs.[last_physical_reads],qs.[min_physical_reads],qs.[max_physical_reads],qs.[total_logical_writes],qs.[last_logical_writes],qs.[min_logical_writes],qs.[max_logical_writes],qs.[total_logical_reads],qs.[last_logical_reads],qs.[min_logical_reads],qs.[max_logical_reads],qs.[total_clr_time],qs.[last_clr_time],qs.[min_clr_time],qs.[max_clr_time],qs.[total_elapsed_time],qs.[last_elapsed_time],qs.[min_elapsed_time],qs.[max_elapsed_time],qs.[query_hash],qs.[query_plan_hash]
						FROM queries qs
						LEFT OUTER JOIN #dm_exec_query_stats qsCaught ON qs.sql_handle = qsCaught.sql_handle AND qs.plan_handle = qsCaught.plan_handle AND qs.statement_start_offset = qsCaught.statement_start_offset
						WHERE qsCaught.sql_handle IS NULL;'
                            EXECUTE(@StringToExecute)
                        END
	
                    IF @CheckProcedureCacheFilter = 'ExecCount'
                        OR @CheckProcedureCacheFilter IS NULL 
                        BEGIN
                            SET @StringToExecute = 'WITH queries ([sql_handle],[statement_start_offset],[statement_end_offset],[plan_generation_num],[plan_handle],[creation_time],[last_execution_time],[execution_count],[total_worker_time],[last_worker_time],[min_worker_time],[max_worker_time],[total_physical_reads],[last_physical_reads],[min_physical_reads],[max_physical_reads],[total_logical_writes],[last_logical_writes],[min_logical_writes],[max_logical_writes],[total_logical_reads],[last_logical_reads],[min_logical_reads],[max_logical_reads],[total_clr_time],[last_clr_time],[min_clr_time],[max_clr_time],[total_elapsed_time],[last_elapsed_time],[min_elapsed_time],[max_elapsed_time],[query_hash],[query_plan_hash])
			            AS (SELECT TOP 20 qs.[sql_handle],qs.[statement_start_offset],qs.[statement_end_offset],qs.[plan_generation_num],qs.[plan_handle],qs.[creation_time],qs.[last_execution_time],qs.[execution_count],qs.[total_worker_time],qs.[last_worker_time],qs.[min_worker_time],qs.[max_worker_time],qs.[total_physical_reads],qs.[last_physical_reads],qs.[min_physical_reads],qs.[max_physical_reads],qs.[total_logical_writes],qs.[last_logical_writes],qs.[min_logical_writes],qs.[max_logical_writes],qs.[total_logical_reads],qs.[last_logical_reads],qs.[min_logical_reads],qs.[max_logical_reads],qs.[total_clr_time],qs.[last_clr_time],qs.[min_clr_time],qs.[max_clr_time],qs.[total_elapsed_time],qs.[last_elapsed_time],qs.[min_elapsed_time],qs.[max_elapsed_time],qs.[query_hash],qs.[query_plan_hash]
						FROM sys.dm_exec_query_stats qs
						ORDER BY qs.execution_count DESC)
						INSERT INTO #dm_exec_query_stats ([sql_handle],[statement_start_offset],[statement_end_offset],[plan_generation_num],[plan_handle],[creation_time],[last_execution_time],[execution_count],[total_worker_time],[last_worker_time],[min_worker_time],[max_worker_time],[total_physical_reads],[last_physical_reads],[min_physical_reads],[max_physical_reads],[total_logical_writes],[last_logical_writes],[min_logical_writes],[max_logical_writes],[total_logical_reads],[last_logical_reads],[min_logical_reads],[max_logical_reads],[total_clr_time],[last_clr_time],[min_clr_time],[max_clr_time],[total_elapsed_time],[last_elapsed_time],[min_elapsed_time],[max_elapsed_time],[query_hash],[query_plan_hash])
						SELECT qs.[sql_handle],qs.[statement_start_offset],qs.[statement_end_offset],qs.[plan_generation_num],qs.[plan_handle],qs.[creation_time],qs.[last_execution_time],qs.[execution_count],qs.[total_worker_time],qs.[last_worker_time],qs.[min_worker_time],qs.[max_worker_time],qs.[total_physical_reads],qs.[last_physical_reads],qs.[min_physical_reads],qs.[max_physical_reads],qs.[total_logical_writes],qs.[last_logical_writes],qs.[min_logical_writes],qs.[max_logical_writes],qs.[total_logical_reads],qs.[last_logical_reads],qs.[min_logical_reads],qs.[max_logical_reads],qs.[total_clr_time],qs.[last_clr_time],qs.[min_clr_time],qs.[max_clr_time],qs.[total_elapsed_time],qs.[last_elapsed_time],qs.[min_elapsed_time],qs.[max_elapsed_time],qs.[query_hash],qs.[query_plan_hash]
						FROM queries qs
						LEFT OUTER JOIN #dm_exec_query_stats qsCaught ON qs.sql_handle = qsCaught.sql_handle AND qs.plan_handle = qsCaught.plan_handle AND qs.statement_start_offset = qsCaught.statement_start_offset
						WHERE qsCaught.sql_handle IS NULL;'
                            EXECUTE(@StringToExecute)
                        END

                    IF @CheckProcedureCacheFilter = 'Duration'
                        OR @CheckProcedureCacheFilter IS NULL 
                        BEGIN
                            SET @StringToExecute = 'WITH queries ([sql_handle],[statement_start_offset],[statement_end_offset],[plan_generation_num],[plan_handle],[creation_time],[last_execution_time],[execution_count],[total_worker_time],[last_worker_time],[min_worker_time],[max_worker_time],[total_physical_reads],[last_physical_reads],[min_physical_reads],[max_physical_reads],[total_logical_writes],[last_logical_writes],[min_logical_writes],[max_logical_writes],[total_logical_reads],[last_logical_reads],[min_logical_reads],[max_logical_reads],[total_clr_time],[last_clr_time],[min_clr_time],[max_clr_time],[total_elapsed_time],[last_elapsed_time],[min_elapsed_time],[max_elapsed_time],[query_hash],[query_plan_hash])
			            AS (SELECT TOP 20 qs.[sql_handle],qs.[statement_start_offset],qs.[statement_end_offset],qs.[plan_generation_num],qs.[plan_handle],qs.[creation_time],qs.[last_execution_time],qs.[execution_count],qs.[total_worker_time],qs.[last_worker_time],qs.[min_worker_time],qs.[max_worker_time],qs.[total_physical_reads],qs.[last_physical_reads],qs.[min_physical_reads],qs.[max_physical_reads],qs.[total_logical_writes],qs.[last_logical_writes],qs.[min_logical_writes],qs.[max_logical_writes],qs.[total_logical_reads],qs.[last_logical_reads],qs.[min_logical_reads],qs.[max_logical_reads],qs.[total_clr_time],qs.[last_clr_time],qs.[min_clr_time],qs.[max_clr_time],qs.[total_elapsed_time],qs.[last_elapsed_time],qs.[min_elapsed_time],qs.[max_elapsed_time],qs.[query_hash],qs.[query_plan_hash]
						FROM sys.dm_exec_query_stats qs
						ORDER BY qs.total_elapsed_time DESC)
						INSERT INTO #dm_exec_query_stats ([sql_handle],[statement_start_offset],[statement_end_offset],[plan_generation_num],[plan_handle],[creation_time],[last_execution_time],[execution_count],[total_worker_time],[last_worker_time],[min_worker_time],[max_worker_time],[total_physical_reads],[last_physical_reads],[min_physical_reads],[max_physical_reads],[total_logical_writes],[last_logical_writes],[min_logical_writes],[max_logical_writes],[total_logical_reads],[last_logical_reads],[min_logical_reads],[max_logical_reads],[total_clr_time],[last_clr_time],[min_clr_time],[max_clr_time],[total_elapsed_time],[last_elapsed_time],[min_elapsed_time],[max_elapsed_time],[query_hash],[query_plan_hash])
						SELECT qs.[sql_handle],qs.[statement_start_offset],qs.[statement_end_offset],qs.[plan_generation_num],qs.[plan_handle],qs.[creation_time],qs.[last_execution_time],qs.[execution_count],qs.[total_worker_time],qs.[last_worker_time],qs.[min_worker_time],qs.[max_worker_time],qs.[total_physical_reads],qs.[last_physical_reads],qs.[min_physical_reads],qs.[max_physical_reads],qs.[total_logical_writes],qs.[last_logical_writes],qs.[min_logical_writes],qs.[max_logical_writes],qs.[total_logical_reads],qs.[last_logical_reads],qs.[min_logical_reads],qs.[max_logical_reads],qs.[total_clr_time],qs.[last_clr_time],qs.[min_clr_time],qs.[max_clr_time],qs.[total_elapsed_time],qs.[last_elapsed_time],qs.[min_elapsed_time],qs.[max_elapsed_time],qs.[query_hash],qs.[query_plan_hash]
						FROM queries qs
						LEFT OUTER JOIN #dm_exec_query_stats qsCaught ON qs.sql_handle = qsCaught.sql_handle AND qs.plan_handle = qsCaught.plan_handle AND qs.statement_start_offset = qsCaught.statement_start_offset
						WHERE qsCaught.sql_handle IS NULL;'
                            EXECUTE(@StringToExecute)
                        END

					/* Populate the query_plan_filtered field. Only works in 2005SP2+, but we're just doing it in 2008 to be safe. */
                    UPDATE  #dm_exec_query_stats
                    SET     query_plan_filtered = qp.query_plan
                    FROM    #dm_exec_query_stats qs
                            CROSS APPLY sys.dm_exec_text_query_plan(qs.plan_handle,
                                                              qs.statement_start_offset,
                                                              qs.statement_end_offset)
                            AS qp 

                END;

				/* Populate the additional query_plan, text, and text_filtered fields */
            UPDATE  #dm_exec_query_stats
            SET     query_plan = qp.query_plan ,
                    [text] = st.[text] ,
                    text_filtered = SUBSTRING(st.text,
                                              ( qs.statement_start_offset / 2 )
                                              + 1,
                                              ( ( CASE qs.statement_end_offset
                                                    WHEN -1
                                                    THEN DATALENGTH(st.text)
                                                    ELSE qs.statement_end_offset
                                                  END
                                                  - qs.statement_start_offset )
                                                / 2 ) + 1)
            FROM    #dm_exec_query_stats qs
                    CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS st
                    CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) AS qp

				/* Dump instances of our own script. We're not trying to tune ourselves. */
            DELETE  #dm_exec_query_stats
            WHERE   text LIKE '%sp_Blitz%'
                    OR text LIKE '%#BlitzResults%'

				/* Look for implicit conversions */
            INSERT  INTO #BlitzResults
                    ( CheckID ,
                      Priority ,
                      FindingsGroup ,
                      Finding ,
                      URL ,
                      Details ,
                      QueryPlan ,
                      QueryPlanFiltered
						  
                    )
                    SELECT  63 AS CheckID ,
                            120 AS Priority ,
                            'Query Plans' AS FindingsGroup ,
                            'Implicit Conversion' AS Finding ,
                            'http://BrentOzar.com/go/implicit' AS URL ,
                            ( 'One of the top resource-intensive queries is comparing two fields that are not the same datatype.' ) AS Details ,
                            qs.query_plan ,
                            qs.query_plan_filtered
                    FROM    #dm_exec_query_stats qs
                    WHERE   COALESCE(qs.query_plan_filtered,
                                     CAST(qs.query_plan AS NVARCHAR(MAX))) LIKE '%CONVERT_IMPLICIT%'
                            AND COALESCE(qs.query_plan_filtered,
                                         CAST(qs.query_plan AS NVARCHAR(MAX))) LIKE '%PhysicalOp="Index Scan"%'

            INSERT  INTO #BlitzResults
                    ( CheckID ,
                      Priority ,
                      FindingsGroup ,
                      Finding ,
                      URL ,
                      Details ,
                      QueryPlan ,
                      QueryPlanFiltered
								  
                    )
                    SELECT  63 AS CheckID ,
                            120 AS Priority ,
                            'Query Plans' AS FindingsGroup ,
                            'Implicit Conversion Affecting Cardinality' AS Finding ,
                            'http://BrentOzar.com/go/implicit' AS URL ,
                            ( 'One of the top resource-intensive queries has an implicit conversion that is affecting cardinality estimation.' ) AS Details ,
                            qs.query_plan ,
                            qs.query_plan_filtered
                    FROM    #dm_exec_query_stats qs
                    WHERE   COALESCE(qs.query_plan_filtered,
                                     CAST(qs.query_plan AS NVARCHAR(MAX))) LIKE '%<PlanAffectingConvert ConvertIssue="Cardinality Estimate" Expression="CONVERT_IMPLICIT%'


				/* Look for missing indexes */
            INSERT  INTO #BlitzResults
                    ( CheckID ,
                      Priority ,
                      FindingsGroup ,
                      Finding ,
                      URL ,
                      Details ,
                      QueryPlan ,
                      QueryPlanFiltered
						  
                    )
                    SELECT  65 AS CheckID ,
                            120 AS Priority ,
                            'Query Plans' AS FindingsGroup ,
                            'Missing Index' AS Finding ,
                            'http://BrentOzar.com/go/missingindex' AS URL ,
                            ( 'One of the top resource-intensive queries may be dramatically improved by adding an index.' ) AS Details ,
                            qs.query_plan ,
                            qs.query_plan_filtered
                    FROM    #dm_exec_query_stats qs
                    WHERE   COALESCE(qs.query_plan_filtered,
                                     CAST(qs.query_plan AS NVARCHAR(MAX))) LIKE '%MissingIndexGroup%'
				
				/* Look for cursors */
            INSERT  INTO #BlitzResults
                    ( CheckID ,
                      Priority ,
                      FindingsGroup ,
                      Finding ,
                      URL ,
                      Details ,
                      QueryPlan ,
                      QueryPlanFiltered
						  
                    )
                    SELECT  66 AS CheckID ,
                            120 AS Priority ,
                            'Query Plans' AS FindingsGroup ,
                            'Cursor' AS Finding ,
                            'http://BrentOzar.com/go/cursor' AS URL ,
                            ( 'One of the top resource-intensive queries is using a cursor.' ) AS Details ,
                            qs.query_plan ,
                            qs.query_plan_filtered
                    FROM    #dm_exec_query_stats qs
                    WHERE   COALESCE(qs.query_plan_filtered,
                                     CAST(qs.query_plan AS NVARCHAR(MAX))) LIKE '%<StmtCursor%'


				/* Look for scalar user-defined functions */
            INSERT  INTO #BlitzResults
                    ( CheckID ,
                      Priority ,
                      FindingsGroup ,
                      Finding ,
                      URL ,
                      Details ,
                      QueryPlan ,
                      QueryPlanFiltered
						  
                    )
                    SELECT  67 AS CheckID ,
                            120 AS Priority ,
                            'Query Plans' AS FindingsGroup ,
                            'Scalar UDFs' AS Finding ,
                            'http://BrentOzar.com/go/functions' AS URL ,
                            ( 'One of the top resource-intensive queries is using a user-defined scalar function that may inhibit parallelism.' ) AS Details ,
                            qs.query_plan ,
                            qs.query_plan_filtered
                    FROM    #dm_exec_query_stats qs
                    WHERE   COALESCE(qs.query_plan_filtered,
                                     CAST(qs.query_plan AS NVARCHAR(MAX))) LIKE '%<UserDefinedFunction%'

        END /* IF @CheckProcedureCache = 1 */

	/*Check for the last good DBCC CHECKDB date */
    CREATE TABLE #DBCCs
        (
          Id INT IDENTITY(1, 1)
                 PRIMARY KEY ,
          ParentObject VARCHAR(255) ,
          Object VARCHAR(255) ,
          Field VARCHAR(255) ,
          Value VARCHAR(255) ,
          DbName SYSNAME NULL
        )
    EXEC sp_MSforeachdb N'USE [?];
							INSERT #DBCCs(ParentObject, Object, Field, Value)
							EXEC (''DBCC DBInfo() With TableResults, NO_INFOMSGS'');
							UPDATE #DBCCs SET DbName = N''?'' WHERE DbName IS NULL;';


    WITH    DB2
              AS ( SELECT   DISTINCT
                            Field ,
                            Value ,
                            DbName
                   FROM     #DBCCs
                   WHERE    Field = 'dbi_dbccLastKnownGood'
                 )
        INSERT  INTO #BlitzResults
                ( CheckID ,
                  Priority ,
                  FindingsGroup ,
                  Finding ,
                  URL ,
                  Details
		                 
                )
                SELECT  68 AS CheckID ,
                        50 AS PRIORITY ,
                        'Reliability' AS FindingsGroup ,
                        'Last good DBCC CHECKDB over 2 weeks old' AS Finding ,
                        'http://BrentOzar.com/go/checkdb' AS URL ,
                        'Database [' + DB2.DbName + ']'
                        + CASE DB2.Value
                            WHEN '1900-01-01 00:00:00.000'
                            THEN ' never had a successful DBCC CHECKDB.'
                            ELSE ' last had a successful DBCC CHECKDB run on '
                                 + DB2.Value + '.'
                          END
                        + ' This check should be run regularly to catch any database corruption as soon as possible.'
                        + ' Note: you can restore a backup of a busy production database to a test server and run DBCC CHECKDB '
                        + ' against that to minimize impact. If you do that, you can ignore this warning.' AS Details
                FROM    DB2
                WHERE   CAST(DB2.Value AS DATETIME) < DATEADD(DD, -14,
                                                              CURRENT_TIMESTAMP)



/*Check for high VLF count: this will omit any database snapshots*/
    IF @@VERSION LIKE 'Microsoft SQL Server 2012%' 
        BEGIN
            CREATE TABLE #LogInfo2012
                (
                  recoveryunitid INT ,
                  FileID SMALLINT ,
                  FileSize BIGINT ,
                  StartOffset BIGINT ,
                  FSeqNo BIGINT ,
                  [Status] TINYINT ,
                  Parity TINYINT ,
                  CreateLSN NUMERIC(38)
                );
            EXEC sp_MSforeachdb N'USE [?];    
	INSERT INTO #LogInfo2012 
	EXEC sp_executesql N''DBCC LogInfo() WITH NO_INFOMSGS'';      
	IF    @@ROWCOUNT > 50            
		BEGIN
			INSERT  INTO #BlitzResults                        
			( CheckID                          
			,Priority                          
			,FindingsGroup                          
			,Finding                          
			,URL                          
			,Details)                  
			SELECT      69                              
			,100                              
			,''Performance''                              
			,''High VLF Count''                              
			,''http://BrentOzar.com/go/vlf ''                              
			,''The ['' + DB_NAME() + ''] database has '' +  CAST(COUNT(*) as VARCHAR(20)) + '' virtual log files (VLFs). This may be slowing down startup, restores, and even inserts/updates/deletes.''  
			FROM #LogInfo2012
			WHERE EXISTS (SELECT name FROM master.sys.databases 
							WHERE source_database_id is null) ;            
			END                       
			TRUNCATE TABLE #LogInfo2012;'
            DROP TABLE #LogInfo2012;
        END
    IF @@VERSION NOT LIKE 'Microsoft SQL Server 2012%' 
        BEGIN
            CREATE TABLE #LogInfo
                (
                  FileID SMALLINT ,
                  FileSize BIGINT ,
                  StartOffset BIGINT ,
                  FSeqNo BIGINT ,
                  [Status] TINYINT ,
                  Parity TINYINT ,
                  CreateLSN NUMERIC(38)
                );
            EXEC sp_MSforeachdb N'USE [?];    
	INSERT INTO #LogInfo 
	EXEC sp_executesql N''DBCC LogInfo() WITH NO_INFOMSGS'';      
	IF    @@ROWCOUNT > 50            
		BEGIN
			INSERT  INTO #BlitzResults                        
			( CheckID                          
			,Priority                          
			,FindingsGroup                          
			,Finding                          
			,URL                          
			,Details)                  
			SELECT      69                              
			,100                              
			,''Performance''                              
			,''High VLF Count''                              
			,''http://BrentOzar.com/go/vlf''                              
			,''The ['' + DB_NAME() + ''] database has '' +  CAST(COUNT(*) as VARCHAR(20)) + '' virtual log files (VLFs). This may be slowing down startup, restores, and even inserts/updates/deletes.''  
			FROM #LogInfo
			WHERE EXISTS (SELECT name FROM master.sys.databases 
							WHERE source_database_id is null);            
			END                       
			TRUNCATE TABLE #LogInfo;'
            DROP TABLE #LogInfo;
        END
	
/*Verify that the servername is set */
	
    IF @@SERVERNAME IS NULL 
        BEGIN
            INSERT  INTO #BlitzResults
                    ( CheckID ,
                      Priority ,
                      FindingsGroup ,
                      Finding ,
                      URL ,
                      Details
                    )
                    SELECT  70 AS CheckID ,
                            200 AS Priority ,
                            'Configuration' AS FindingsGroup ,
                            '@@Servername not set' AS Finding ,
                            'http://BrentOzar.com/go/servername' AS URL ,
                            '@@Servername variable is null. Correct by executing "sp_addserver ''<LocalServerName>'', local"' AS Details
        END;


/*Check for non-aligned indexes in partioned databases*/
    CREATE TABLE #partdb
        (
          dbname VARCHAR(100) ,
          objectname VARCHAR(200) ,
          type_desc VARCHAR(50)
        )
    EXEC dbo.sp_MSforeachdb 'USE [?]; insert into #partdb(dbname, objectname, type_desc)
SELECT distinct db_name(database_id) as DBName,o.name Object_Name,
ds.type_desc
 FROM sys.objects AS o
      JOIN sys.indexes AS i
  ON o.object_id = i.object_id 
JOIN sys.data_spaces ds on ds.data_space_id = i.data_space_id
  LEFT OUTER JOIN 
  sys.dm_db_index_usage_stats AS s    
 ON i.object_id = s.object_id   
  AND i.index_id = s.index_id
  WHERE  o.type = ''u''
 -- Clustered and Non-Clustered indexes
   AND i.type IN (1, 2) 
AND o.name in 
	(
SELECT a.name from 
    (SELECT ob.name, ds.type_desc from sys.objects ob JOIN sys.indexes ind on ind.object_id = ob.object_id join sys.data_spaces ds on ds.data_space_id = ind.data_space_id
		GROUP BY ob.name, ds.type_desc ) a group by a.name having COUNT (*) > 1
	)'
	
    INSERT  INTO #BlitzResults
            ( CheckID ,
              Priority ,
              FindingsGroup ,
              Finding ,
              URL ,
              Details
            )
            SELECT DISTINCT
                    72 AS CheckId ,
                    100 AS Priority ,
                    'Performance' AS FindingsGroup ,
                    'The partioned database ' + dbname
                    + ' may have non-aligned indexes' AS Finding ,
                    'http://BrentOzar.com/go/aligned' AS URL ,
                    'Having non-aligned indexes on partitioned tables may cause inefficient query plans and CPU pressure' AS Details
            FROM    #partdb
            WHERE   dbname IS NOT	NULL
    DROP TABLE #partdb

/*Check to see if a failsafe operator has been configured*/

    DECLARE @AlertInfo TABLE
        (
          FailSafeOperator NVARCHAR(255) ,
          NotificationMethod INT ,
          ForwardingServer NVARCHAR(255) ,
          ForwardingSeverity INT ,
          PagerToTemplate NVARCHAR(255) ,
          PagerCCTemplate NVARCHAR(255) ,
          PagerSubjectTemplate NVARCHAR(255) ,
          PagerSendSubjectOnly NVARCHAR(255) ,
          ForwardAlways INT
        )

    INSERT  INTO @AlertInfo
            EXEC [master].[dbo].[sp_MSgetalertinfo] @includeaddresses = 0
    INSERT  INTO #BlitzResults
            ( CheckID ,
              Priority ,
              FindingsGroup ,
              Finding ,
              URL ,
              Details
                
            )
            SELECT  73 AS CheckID ,
                    50 AS Priority ,
                    'Reliability' AS FindingsGroup ,
                    'No failsafe operator configured' AS Finding ,
                    'http://BrentOzar.com/go/failsafe' AS URL ,
                    ( 'No failsafe operator is configured on this server.  This is a good idea just in-case there are issues with the [msdb] database that prevents alerting.' ) AS Details
            FROM    @AlertInfo
            WHERE   FailSafeOperator IS NULL;

/*Identify globally enabled trace flags*/
    IF OBJECT_ID('tempdb..#TraceStatus') IS NOT NULL 
        DROP TABLE #TraceStatus;
    CREATE TABLE #TraceStatus
        (
          TraceFlag VARCHAR(10) ,
          status BIT ,
          Global BIT ,
          Session BIT
        );

    INSERT  INTO #TraceStatus
            EXEC ( ' DBCC TRACESTATUS(-1) WITH NO_INFOMSGS'
                )

    INSERT  INTO #BlitzResults
            ( CheckID ,
              Priority ,
              FindingsGroup ,
              Finding ,
              URL ,
              Details
            )
            SELECT  74 AS CheckID ,
                    200 AS Priority ,
                    'Global Trace Flag' AS FindingsGroup ,
                    'TraceFlag On' AS Finding ,
                    'http://www.BrentOzar.com/go/traceflags/' AS URL ,
                    'Trace flag ' + T.TraceFlag + ' is enabled globally.' ASDetails
            FROM    #TraceStatus T

/*Check for transaction log file larger than data file */

    INSERT  INTO #BlitzResults
            ( CheckID ,
              Priority ,
              FindingsGroup ,
              Finding ,
              URL ,
              Details
            )
            SELECT  75 AS CheckId ,
                    50 AS Priority ,
                    'Reliability' AS FindingsGroup ,
                    'Transaction Log Larger than Data File' AS Finding ,
                    'http://BrentOzar.com/go/biglog' AS URL ,
                    'The database [' + DB_NAME(a.database_id)
                    + '] has a transaction log file larger than a data file. This may indicate that transaction log backups are not being performed or not performed often enough.' AS Details
            FROM    sys.master_files a
            WHERE   a.type = 1
                    AND a.size > 125000 /* Size is measured in pages here, so this gets us log files over 1GB. */
                    AND a.size > ( SELECT   SUM(b.size)
                                   FROM     sys.master_files b
                                   WHERE    a.database_id = b.database_id
                                            AND b.type = 0
                                 )
                    AND a.database_id IN ( SELECT   database_id
                                           FROM     sys.databases
                                           WHERE    source_database_id IS NULL )

/*Check for collation conflicts between user databases and tempdb */
    INSERT  INTO #BlitzResults
            ( CheckID ,
              Priority ,
              FindingsGroup ,
              Finding ,
              URL ,
              Details
            )
            SELECT  76 AS CheckId ,
                    50 AS Priority ,
                    'Reliability' AS FindingsGroup ,
                    'Collation for ' + name
                    + ' different than tempdb collation' AS Finding ,
                    'http://BrentOzar.com/go/collate' AS URL ,
                    'Collation differences between user databases and tempdb can cause conflicts especially when comparing string values' AS Details
            FROM    sys.databases
            WHERE   name NOT IN ( 'master', 'model', 'msdb' )
                    AND collation_name <> ( SELECT  collation_name
                                            FROM    sys.databases
                                            WHERE   name = 'tempdb'
                                          )

    INSERT  INTO #BlitzResults
            ( CheckID ,
              Priority ,
              FindingsGroup ,
              Finding ,
              URL ,
              Details
            )
            SELECT  77 AS CheckId ,
                    50 AS Priority ,
                    'Reliability' AS FindingsGroup ,
                    'Database Snapshot Online' AS Finding ,
                    'http://BrentOzar.com/go/snapshot' AS URL ,
                    'Database [' + dSnap.[name] + '] is a snapshot of ['
                    + dOriginal.[name]
                    + ']. Make sure you have enough drive space to maintain the snapshot as the original database grows.' AS Details
            FROM    sys.databases dSnap
                    INNER JOIN sys.databases dOriginal ON dSnap.source_database_id = dOriginal.database_id

    INSERT  INTO #BlitzResults
            ( CheckID ,
              Priority ,
              FindingsGroup ,
              Finding ,
              URL ,
              Details
            )
            SELECT  79 AS CheckId ,
                    100 AS Priority ,
                    'Performance' AS FindingsGroup ,
                    'Shrink Database Job' AS Finding ,
                    'http://BrentOzar.com/go/autoshrink' AS URL ,
                    'In the [' + j.[name] + '] job, step [' + step.[step_name]
                    + '] has SHRINKDATABASE or SHRINKFILE, which may be causing database fragmentation.' AS Details
            FROM    msdb.dbo.sysjobs j
                    INNER JOIN msdb.dbo.sysjobsteps step ON j.job_id = step.job_id
            WHERE   step.command LIKE N'%SHRINKDATABASE%'
                    OR step.command LIKE N'%SHRINKFILE%'

    EXEC dbo.sp_MSforeachdb 'USE [?]; INSERT INTO #BlitzResults (CheckID, Priority, FindingsGroup, Finding, URL, Details) SELECT DISTINCT 80, 50, ''Reliability'', ''Max File Size Set'', ''http://BrentOzar.com/go/maxsize'', (''The ['' + DB_NAME() + ''] database file '' + name + '' has a max file size set to '' + CAST(CAST(max_size AS BIGINT) * 8 / 1024 AS VARCHAR(100)) + ''MB. If it runs out of space, the database will stop working even though there may be drive space available.'') FROM sys.database_files WHERE max_size <> 268435456 AND max_size <> -1';

    INSERT  INTO #BlitzResults
            ( CheckID ,
              Priority ,
              FindingsGroup ,
              Finding ,
              URL ,
              Details
            )
            SELECT  81 AS CheckID ,
                    200 AS Priority ,
                    'Non-Active Server Config' AS FindingsGroup ,
                    cr.name AS Finding ,
                    'http://www.BrentOzar.com/blitz/sp_configure/' AS URL ,
                    ( 'This sp_configure option isn''t running under its set value.  Its set value is '
                      + CAST(cr.[Value] AS VARCHAR(100))
                      + ' and its running value is '
                      + CAST(cr.value_in_use AS VARCHAR(100))
                      + '. When someone does a RECONFIGURE or restarts the instance, this setting will start taking effect.' ) AS Details
            FROM    sys.configurations cr
            WHERE   cr.value <> cr.value_in_use;


    IF EXISTS ( SELECT  *
                FROM    sys.all_objects
                WHERE   name = 'dm_server_services' ) 
        SET @StringToExecute = 'INSERT INTO #BlitzResults (CheckID, Priority, FindingsGroup, Finding, URL, Details)
        SELECT  83 AS CheckID ,
                250 AS Priority ,
                ''Server Info'' AS FindingsGroup ,
                ''Services'' AS Finding ,
                '''' AS URL ,
                N''Service: '' + servicename + N'' runs under service account '' + service_account + N''. Last startup time: '' + COALESCE(CAST(CAST(last_startup_time AS DATETIME) AS VARCHAR(50)), ''not shown.'') + ''. Startup type: '' + startup_type_desc + N'', currently '' + status_desc + ''.'' 
                FROM sys.dm_server_services;'
    EXECUTE(@StringToExecute);


/* Check 84 - SQL Server 2012 */
    IF EXISTS ( SELECT  *
                FROM    sys.all_objects o
                        INNER JOIN sys.all_columns c ON o.object_id = c.object_id
                WHERE   o.name = 'dm_os_sys_info'
                        AND c.name = 'physical_memory_kb' ) 
        BEGIN
            SET @StringToExecute = 'INSERT INTO #BlitzResults (CheckID, Priority, FindingsGroup, Finding, URL, Details)
        SELECT  84 AS CheckID ,
                250 AS Priority ,
                ''Server Info'' AS FindingsGroup ,
                ''Hardware'' AS Finding ,
                '''' AS URL ,
                ''Logical processors: '' + CAST(cpu_count AS VARCHAR(50)) + ''. Physical memory: '' + CAST( CAST(ROUND((physical_memory_kb / 1024.0 / 1024), 1) AS INT) AS VARCHAR(50)) + ''GB.''
		FROM sys.dm_os_sys_info';
            EXECUTE(@StringToExecute);
        END

/* Check 84 - SQL Server 2008 */
    IF EXISTS ( SELECT  *
                FROM    sys.all_objects o
                        INNER JOIN sys.all_columns c ON o.object_id = c.object_id
                WHERE   o.name = 'dm_os_sys_info'
                        AND c.name = 'physical_memory_in_bytes' ) 
        BEGIN
            SET @StringToExecute = 'INSERT INTO #BlitzResults (CheckID, Priority, FindingsGroup, Finding, URL, Details)
        SELECT  84 AS CheckID ,
                250 AS Priority ,
                ''Server Info'' AS FindingsGroup ,
                ''Hardware'' AS Finding ,
                '''' AS URL ,
                ''Logical processors: '' + CAST(cpu_count AS VARCHAR(50)) + ''. Physical memory: '' + CAST( CAST(ROUND((physical_memory_in_bytes / 1024.0 / 1024 / 1024), 1) AS INT) AS VARCHAR(50)) + ''GB.''
		FROM sys.dm_os_sys_info';
            EXECUTE(@StringToExecute);
        END


    INSERT  INTO #BlitzResults
            ( CheckID ,
              Priority ,
              FindingsGroup ,
              Finding ,
              URL ,
              Details
            )
            SELECT  85 AS CheckID ,
                    250 AS Priority ,
                    'Server Info' AS FindingsGroup ,
                    'SQL Server Service' AS Finding ,
                    '' AS URL ,
                    N'Version: '
                    + CAST(SERVERPROPERTY('productversion') AS NVARCHAR(100))
                    + N'. Patch Level: '
                    + CAST(SERVERPROPERTY('productlevel') AS NVARCHAR(100))
                    + N'. Edition: '
                    + CAST(SERVERPROPERTY('edition') AS VARCHAR(100))
                    + N'. AlwaysOn Enabled: '
                    + CAST(COALESCE(SERVERPROPERTY('IsHadrEnabled'), 0) AS VARCHAR(100))
                    + N'. AlwaysOn Mgr Status: '
                    + CAST(COALESCE(SERVERPROPERTY('HadrManagerStatus'), 0) AS VARCHAR(100))
	

    INSERT  INTO #BlitzResults
            ( CheckID ,
              Priority ,
              FindingsGroup ,
              Finding ,
              URL ,
              Details
            )
    VALUES  ( -1 ,
              255 ,
              'Thanks!' ,
              'From Brent Ozar Unlimited' ,
              'http://www.BrentOzar.com/blitz/' ,
              'Thanks from the Brent Ozar Unlimited team.  We hope you found this tool useful, and if you need help relieving your SQL Server pains, email us at Help@BrentOzar.com.'
            );

    SET @Version = 16;
    INSERT  INTO #BlitzResults
            ( CheckID ,
              Priority ,
              FindingsGroup ,
              Finding ,
              URL ,
              Details
		            
            )
    VALUES  ( -1 ,
              0 ,
              'sp_Blitz v16 Dec 13 2012' ,
              'From Brent Ozar Unlimited' ,
              'http://www.BrentOzar.com/blitz/' ,
              'Thanks from the Brent Ozar Unlimited team.  We hope you found this tool useful, and if you need help relieving your SQL Server pains, email us at Help@BrentOzar.com.'
		            
            );



    IF @OutputType = 'COUNT' 
        BEGIN
            SELECT  COUNT(*) AS Warnings
            FROM    #BlitzResults
        END
    ELSE 
        BEGIN
            SELECT  [Priority] ,
                    [FindingsGroup] ,
                    [Finding] ,
                    [URL] ,
                    [Details] ,
                    [QueryPlan] ,
                    [QueryPlanFiltered] ,
                    CheckID
            FROM    #BlitzResults
            ORDER BY Priority ,
                    FindingsGroup ,
                    Finding ,
                    Details;
        END
  
    DROP TABLE #BlitzResults;


    IF @OutputProcedureCache = 1 
        SELECT TOP 20
                total_worker_time / execution_count AS AvgCPU ,
                total_worker_time AS TotalCPU ,
                CAST(ROUND(100.00 * total_worker_time
                           / ( SELECT   SUM(total_worker_time)
                               FROM     sys.dm_exec_query_stats
                             ), 2) AS MONEY) AS PercentCPU ,
                total_elapsed_time / execution_count AS AvgDuration ,
                total_elapsed_time AS TotalDuration ,
                CAST(ROUND(100.00 * total_elapsed_time
                           / ( SELECT   SUM(total_elapsed_time)
                               FROM     sys.dm_exec_query_stats
                             ), 2) AS MONEY) AS PercentDuration ,
                total_logical_reads / execution_count AS AvgReads ,
                total_logical_reads AS TotalReads ,
                CAST(ROUND(100.00 * total_logical_reads
                           / ( SELECT   SUM(total_logical_reads)
                               FROM     sys.dm_exec_query_stats
                             ), 2) AS MONEY) AS PercentReads ,
                execution_count ,
                CAST(ROUND(100.00 * execution_count
                           / ( SELECT   SUM(execution_count)
                               FROM     sys.dm_exec_query_stats
                             ), 2) AS MONEY) AS PercentExecutions ,
                CASE WHEN DATEDIFF(mi, creation_time, qs.last_execution_time) = 0
                     THEN 0
                     ELSE CAST(( 1.00 * execution_count / DATEDIFF(mi,
                                                              creation_time,
                                                              qs.last_execution_time) ) AS MONEY)
                END AS executions_per_minute ,
                qs.creation_time AS plan_creation_time ,
                qs.last_execution_time ,
                text ,
                text_filtered ,
                query_plan ,
                query_plan_filtered ,
                sql_handle ,
                query_hash ,
                plan_handle ,
                query_plan_hash
        FROM    #dm_exec_query_stats qs
        ORDER BY CASE UPPER(@CheckProcedureCacheFilter)
                   WHEN 'CPU' THEN total_worker_time
                   WHEN 'READS' THEN total_logical_reads
                   WHEN 'EXECCOUNT' THEN execution_count
                   WHEN 'DURATION' THEN total_elapsed_time
                   ELSE total_worker_time
                 END DESC
    SET NOCOUNT OFF;



GO
/****** Object:  StoredProcedure [dbo].[sp_WhoIsActive]    Script Date: 27/10/2015 09:31:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

/***********************************
Who Is Active? v.8.40 (2009-03-25)
(C) 2007-2009, Adam Machanic
	amachanic@gmail.com
***********************************/
CREATE PROC [dbo].[sp_WhoIsActive]
(
	--Set to 0 to get information about all active SPIDs
	--Set to a specific SPID to get information only about that SPID
	@SPID SMALLINT = 0,

	--Show your own SPID?
	@SHOW_OWN_SPID BIT = 0,

	--If 1, gets the full stored procedure or running batch, when available
	--If 0, gets only the actual statement that is currently running in the batch or procedure
	@GET_FULL_INNER_TEXT BIT = 0,

	--Get associated query plans for running tasks, if available
	@GET_PLANS BIT = 1,

	--Get the associated outer ad hoc query or stored procedure call, if available
	@GET_OUTER_COMMAND BIT = 0,

	--Enables pulling sleeping SPIDs w/ open transactions,
	--in addition to transaction log write info and transaction duration
	@GET_TRANSACTION_INFO BIT = 0,

	--Gets associated locks for each request, aggregated in an XML format
	@GET_LOCKS BIT = 0,

	--Get average time for past runs of an active query
	--(based on the combination of plan handle, sql handle, and offset)
	@GET_AVG_TIME BIT = 0,
	
	--Pull deltas on various metrics
	--Interval in seconds to wait before doing the second data pull
	@DELTA_INTERVAL TINYINT = 0,

	--Column by which to sort output. Valid choices:
		--session_id, physical_io, reads, physical_reads, writes, tempdb_writes,
		--tempdb_current, CPU, context_switches, used_memory, physical_io_delta, 
		--reads_delta, physical_reads_delta, writes_delta, tempdb_writes_delta, 
		--tempdb_current_delta, CPU_delta, context_switches_delta, used_memory_delta, 
		--threads, tran_start_time, open_tran_count, blocking_session_id, percent_complete, 
		--host_name, login_name, database_name, start_time
	@SORT_COLUMN sysname = '[start_time]',

	--Sort direction. Valid choices are ASC or DESC
	@SORT_COLUMN_DIRECTION VARCHAR(4) = 'DESC',

	--Formats some of the output columns in a more "human readable" form
	@FORMAT_OUTPUT BIT = 1,

	--List of desired output columns, in desired order
	--Note that the final output will be the intersection of all enabled features and all 
	--columns in the list. Therefore, only columns associated with enabled features will 
	--actually appear in the output. Likewise, removing columns from this list may effectively
	--disable features, even if they are turned on
	--
	--Each element in this list must be one of the valid output column names. Names must be
	--delimited by square brackets. White space, formatting, and additional characters are
	--allowed, as long as the list contains exact matches of delimited valid column names.
	@OUTPUT_COLUMN_LIST VARCHAR(8000) = '',
	
	--If set to a non-blank value, the script will attempt to insert into the specified 
	--destination table. Please note that the script will not verify that the table exists, 
	--or that it has the correct schema, before doing the insert.
	--Table can be specified in one, two, or three-part format
	@DESTINATION_TABLE VARCHAR(4000) = '',

	--If set to 1, no data collection will happen and no result set will be returned; instead,
	--a CREATE TABLE statement will be returned via the @SCHEMA parameter, which will match 
	--the schema of the result set that would be returned by using the same collection of the
	--rest of the parameters. The CREATE TABLE statement will have a placeholder token of 
	--<table_name> in place of an actual table name.
	@RETURN_SCHEMA BIT = 0,
	@SCHEMA VARCHAR(MAX) = NULL OUTPUT
)
/*
OUTPUT COLUMNS
--------------
[session_id] [smallint] NOT NULL
	Session ID (a.k.a. SPID)

Formatted:		[dd hh:mm:ss.mss] [varchar](15) NULL
Non-Formatted:	<not returned>
	For an active request, time the query has been running
	For a sleeping session, time the session has been connected

Formatted:		[dd hh:mm:ss.mss (avg)] [varchar](15) NULL
Non-Formatted:	[avg_elapsed_time] [int] NULL
	(Requires @GET_AVG_TIME option)
	How much time has the active portion of the query taken in the past, on average?
	Note: This column's name becomes [avg_elapsed_time] in non-formatted mode

Formatted:		[physical_io] [varchar](27) NULL
Non-Formatted:	[physical_io] [int] NULL
	Shows the number of physical I/Os, for active requests

Formatted:		[reads] [varchar](27) NOT NULL
Non-Formatted:	[reads] [bigint] NOT NULL
	For an active request, number of reads done for the current query
	For a sleeping session, total number of reads done over the lifetime of the session

Formatted:		[physical_reads] [varchar](27) NOT NULL
Non-Formatted:	[physical_reads] [bigint] NOT NULL
	For an active request, number of physical reads done for the current query
	For a sleeping session, total number of physical reads done over the lifetime of the session

Formatted:		[writes] [varchar](27) NOT NULL
Non-Formatted:	[writes] [bigint] NOT NULL
	For an active request, number of writes done for the current query
	For a sleeping session, total number of writes done over the lifetime of the session

Formatted:		[tempdb_writes] [varchar](27) NOT NULL
Non-Formatted:	[tempdb_writes] [bigint] NOT NULL
	For an active request, number of TempDB writes done for the current query
	For a sleeping session, total number of TempDB writes done over the lifetime of the session

Formatted:		[tempdb_current] [varchar](27) NOT NULL
Non-Formatted:	[tempdb_current] [bigint] NOT NULL
	For an active request, number of TempDB pages currently allocated for the query
	For a sleeping session, number of TempDB pages currently allocated for the session

Formatted:		[CPU] [varchar](27) NOT NULL
Non-Formatted:	[CPU] [int] NOT NULL
	For an active request, total CPU time consumed by the current query
	For a sleeping session, total CPU time consumed over the lifetime of the session

Formatted:		[context_switches] [varchar](27) NULL
Non-Formatted:	[context_switches] [int] NULL
	Shows the number of context switches, for active requests

Formatted:		[used_memory] [varchar](27) NOT NULL
Non-Formatted:	[used_memory] [int] NOT NULL
	For an active request, total memory consumption for the current query
	For a sleeping session, total current memory consumption

Formatted:		[physical_io_delta] [varchar](27) NULL
Non-Formatted:	[physical_io_delta] [int] NULL
	(Requires @DELTA_INTERVAL option)
	Difference between the number of physical I/Os reported on the first and second collections. 
	If the request started after the first collection, the value will be NULL

Formatted:		[reads_delta] [varchar](27) NULL
Non-Formatted:	[reads_delta] [bigint] NULL
	(Requires @DELTA_INTERVAL option)
	Difference between the number of reads reported on the first and second collections. 
	If the request started after the first collection, the value will be NULL

Formatted:		[physical_reads_delta] [varchar](27) NULL
Non-Formatted:	[physical_reads_delta] [bigint] NULL
	(Requires @DELTA_INTERVAL option)
	Difference between the number of physical reads reported on the first and second collections. 
	If the request started after the first collection, the value will be NULL

Formatted:		[writes_delta] [varchar](27) NULL
Non-Formatted:	[writes_delta] [bigint] NULL
	(Requires @DELTA_INTERVAL option)
	Difference between the number of writes reported on the first and second collections. 
	If the request started after the first collection, the value will be NULL

Formatted:		[tempdb_writes_delta] [varchar](27) NULL
Non-Formatted:	[tempdb_writes_delta] [bigint] NULL
	(Requires @DELTA_INTERVAL option)
	Difference between the number of TempDB writes reported on the first and second collections. 
	If the request started after the first collection, the value will be NULL

Formatted:		[tempdb_current_delta] [varchar](27) NULL
Non-Formatted:	[tempdb_current_delta] [bigint] NULL
	(Requires @DELTA_INTERVAL option)
	Difference between the number of allocated TempDB pages reported on the first and second collections. 
	If the request started after the first collection, the value will be NULL

Formatted:		[CPU_delta] [varchar](27) NULL
Non-Formatted:	[CPU_delta] [int] NULL
	(Requires @DELTA_INTERVAL option)
	Difference between the CPU time reported on the first and second collections. 
	If the request started after the first collection, the value will be NULL

Formatted:		[context_switches_delta] [varchar](27) NULL
Non-Formatted:	[context_switches_delta] [int] NULL
	(Requires @DELTA_INTERVAL option)
	Difference between the context switches count reported on the first and second collections
	If the request started after the first collection, the value will be NULL

Formatted:		[used_memory_delta] [varchar](27) NULL
Non-Formatted:	[used_memory_delta] [int] NULL
	Difference between the memory usage reported on the first and second collections
	If the request started after the first collection, the value will be NULL

Formatted/Non:	[threads] [smallint] NULL
	Number of worker threads currently allocated, for active requests

Formatted/Non:	[status] [varchar](30) NOT NULL
	Activity status for the session (running, sleeping, etc)
	
Formatted/Non:	[wait_info] [varchar](4000) NULL
	Aggregates wait information, in the following format:
		(Ax: Bms/Cms/Dms)E
	A is the number of waiting threads currently waiting on resource type E
	If only one thread is waiting, its wait time will be shown, in milliseconds
	If two threads are waiting, each of their wait times will be shown, in milliseconds
	If three or more threads are waiting, the minimum, average, and maximum wait times will be shown
	If more than one thread is waiting on the same type and the wait times are equal, only one number will be shown
	
	If wait type E is a page latch wait and the page is of a "special" type (e.g. PFS, GAM, SGAM), the page type will be identified.
	
Formatted/Non:	[locks] [xml] NULL
	(Requires @GET_LOCKS option)
	Aggregates lock information, in XML format.
	The lock XML includes the lock mode, locked object, and aggregates the number of requests. 
	Attempts are made to identify locked objects by name

Formatted/Non:	[tran_start_time] [datetime] NULL
	(Requires @GET_TRANSACTION_INFO option)
	Date and time that the first transaction opened by a session caused a transaction log write to occur

Formatted/Non:	[tran_log_writes] [varchar](4000) NULL
	(Requires @GET_TRANSACTION_INFO option)
	Aggregates transaction log write information, in the following format:
	A:B
	A is a database that has been touched by an active transaction
	B is the number of log writes that have been made in the database as a result of the transaction
	
Formatted/Non:	[open_tran_count] [int] NULL
	(Requires @GET_TRANSACTION_INFO option)
	Shows the number of open transactions the session has open

Formatted:		[sql_command] [xml] NULL
Non-Formatted:	[sql_command] [varchar](max) NULL
	(Requires @GET_OUTER_COMMAND option)
	Shows the "outer" SQL command, i.e. the text of the batch or RPC sent to the server, if available

Formatted:		[sql_text] [xml] NULL
Non-Formatted:	[sql_text] [varchar](max) NULL
	Shows the SQL text for active requests or the last statement executed
	for sleeping sessions, if available in either case.
	If @GET_FULL_INNER_TEXT option is set, shows the full text of the batch.
	Otherwise, shows only the active statement within the batch.

Formatted/Non:	[query_plan] [xml] NULL
	(Requires @GET_PLANS option)
	Shows the query plan for the request, if available.
	If the plan is locked, a special timeout message will be sent, in the following format:
		<timeout_exceeded />

Formatted/Non:	[blocking_session_id] [int] NULL
	When applicable, shows the blocking SPID

Formatted/Non:	[percent_complete] [real] NULL
	When applicable, shows the percent complete (e.g. for backups, restores, and some rollbacks)

Formatted/Non:	[host_name] [varchar](128) NOT NULL
	Shows the host name for the connection

Formatted/Non:	[login_name] [varchar](128) NOT NULL
	Shows the login name for the connection

Formatted/Non:	[database_name] [varchar](128) NULL
	Shows the connected database

Formatted/Non:	[start_time] [datetime] NOT NULL
	For active requests, shows the time the request started
	For sleeping sessions, shows the time the connection was made
	
Formatted/Non:	[request_id] [int] NULL
	For active requests, shows the request_id
	Should be 0 unless MARS is being used

Formatted/Non:	[collection_time] [datetime] NOT NULL
	Time that this script's final SELECT ran
*/
AS
BEGIN
	SET NOCOUNT ON; 
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	IF
		@SPID IS NULL
		OR @SHOW_OWN_SPID IS NULL
		OR @GET_FULL_INNER_TEXT IS NULL
		OR @GET_PLANS IS NULL
		OR @GET_OUTER_COMMAND IS NULL
		OR @GET_TRANSACTION_INFO IS NULL
		OR @GET_LOCKS IS NULL
		OR @GET_AVG_TIME IS NULL
		OR @DELTA_INTERVAL IS NULL
		OR @SORT_COLUMN IS NULL
		OR @SORT_COLUMN_DIRECTION IS NULL
		OR @FORMAT_OUTPUT IS NULL
		OR @OUTPUT_COLUMN_LIST IS NULL
		OR @RETURN_SCHEMA IS NULL
		OR @DESTINATION_TABLE IS NULL
	BEGIN;
		RAISERROR('Input parameters cannot be NULL', 16, 1);
		RETURN;
	END;

	IF
		@SORT_COLUMN NOT IN
		(
			'[session_id]',
			'[physical_io]',
			'[reads]',
			'[physical_reads]',
			'[writes]',
			'[tempdb_writes]',
			'[tempdb_current]',
			'[CPU]',
			'[context_switches]',
			'[used_memory]',
			'[physical_io_delta]',
			'[reads_delta]',
			'[physical_reads_delta]',
			'[writes_delta]',
			'[tempdb_writes_delta]',
			'[tempdb_current_delta]',
			'[CPU_delta]',
			'[context_switches_delta]',
			'[used_memory_delta]',
			'[threads]',
			'[tran_start_time]',
			'[open_tran_count]',
			'[blocking_session_id]',
			'[percent_complete]',
			'[host_name]',
			'[login_name]',
			'[database_name]',
			'[start_time]'
		)
	BEGIN;
		RAISERROR('Invalid column passed to @SORT_COLUMN', 16, 1, @SORT_COLUMN);
		RETURN;
	END;

	IF @SORT_COLUMN_DIRECTION NOT IN ('ASC', 'DESC')
	BEGIN;
		RAISERROR('Valid values for @SORT_DIRECTION are: ASC and DESC', 16, 1);
		RETURN;
	END;

	SET @OUTPUT_COLUMN_LIST = 
		STUFF
		(
			(
				SELECT 
					',' + x.column_name AS [text()]
				FROM
				(
					SELECT '[session_id]' AS column_name, 1 AS default_order
					UNION ALL 
					SELECT '[dd hh:mm:ss.mss]', 2
					WHERE
						@FORMAT_OUTPUT = 1
					UNION ALL 
					SELECT '[dd hh:mm:ss.mss (avg)]', 3
					WHERE 
						@FORMAT_OUTPUT = 1
						AND @GET_AVG_TIME = 1
					UNION ALL 
					SELECT '[avg_elapsed_time]', 4
					WHERE 
						@FORMAT_OUTPUT = 0
						AND @GET_AVG_TIME = 1
					UNION ALL 
					SELECT '[physical_io]', 5
					UNION ALL 
					SELECT '[reads]', 6
					UNION ALL 
					SELECT '[physical_reads]', 7
					UNION ALL 
					SELECT '[writes]', 8
					UNION ALL 
					SELECT '[tempdb_writes]', 9
					UNION ALL 
					SELECT '[tempdb_current]', 10
					UNION ALL 
					SELECT '[CPU]', 11
					UNION ALL 
					SELECT '[context_switches]', 12
					UNION ALL 
					SELECT '[used_memory]', 13
					UNION ALL 
					SELECT '[physical_io_delta]', 14
					WHERE
						@DELTA_INTERVAL > 0	
					UNION ALL 
					SELECT '[reads_delta]', 15
					WHERE
						@DELTA_INTERVAL > 0
					UNION ALL 
					SELECT '[physical_reads_delta]', 16
					WHERE
						@DELTA_INTERVAL > 0
					UNION ALL 
					SELECT '[writes_delta]', 17
					WHERE
						@DELTA_INTERVAL > 0
					UNION ALL 
					SELECT '[tempdb_writes_delta]', 18
					WHERE
						@DELTA_INTERVAL > 0
					UNION ALL 
					SELECT '[tempdb_current_delta]', 19
					WHERE
						@DELTA_INTERVAL > 0
					UNION ALL 
					SELECT '[CPU_delta]', 20
					WHERE
						@DELTA_INTERVAL > 0
					UNION ALL 
					SELECT '[context_switches_delta]', 21
					WHERE
						@DELTA_INTERVAL > 0
					UNION ALL 
					SELECT '[used_memory_delta]', 22
					WHERE
						@DELTA_INTERVAL > 0
					UNION ALL 
					SELECT '[threads]', 23
					UNION ALL 
					SELECT '[status]', 24
					UNION ALL 
					SELECT '[wait_info]', 25
					UNION ALL 
					SELECT '[locks]', 26
					WHERE
						@GET_LOCKS = 1
					UNION ALL 
					SELECT '[tran_start_time]', 27
					WHERE
						@GET_TRANSACTION_INFO = 1
					UNION ALL 
					SELECT '[tran_log_writes]', 28
					WHERE
						@GET_TRANSACTION_INFO = 1
					UNION ALL 
					SELECT '[open_tran_count]', 29
					WHERE
						@GET_TRANSACTION_INFO = 1
					UNION ALL 
					SELECT '[sql_command]', 30
					WHERE
						@GET_OUTER_COMMAND = 1
					UNION ALL 
					SELECT '[sql_text]', 31
					UNION ALL 
					SELECT '[query_plan]', 32
					WHERE
						@GET_PLANS = 1
					UNION ALL 
					SELECT '[blocking_session_id]', 33
					UNION ALL 
					SELECT '[percent_complete]', 34
					UNION ALL 
					SELECT '[host_name]', 35
					UNION ALL 
					SELECT '[login_name]', 36
					UNION ALL 
					SELECT '[database_name]', 37
					UNION ALL 
					SELECT '[start_time]', 38
					UNION ALL 
					SELECT '[request_id]', 39
					UNION ALL 
					SELECT '[collection_time]', 40
				) x
				WHERE
					CHARINDEX(x.column_name, @OUTPUT_COLUMN_LIST) > 0
					OR RTRIM(@OUTPUT_COLUMN_LIST) = ''
				ORDER BY
					CASE 
						WHEN @OUTPUT_COLUMN_LIST = '' THEN x.default_order
						ELSE CHARINDEX(x.column_name, @OUTPUT_COLUMN_LIST)
					END
				FOR XML PATH('')
			),
			1,
			1,
			''
		);
	
	IF COALESCE(RTRIM(@OUTPUT_COLUMN_LIST), '') = ''
	BEGIN
		RAISERROR('No valid column matches found in @OUTPUT_COLUMN_LIST or no columns remain due to selected options.', 16, 1);
		RETURN;
	END;
	
	IF @DESTINATION_TABLE <> ''
	BEGIN
		SET @DESTINATION_TABLE = 
			--database
			COALESCE(QUOTENAME(PARSENAME(@DESTINATION_TABLE, 3)) + '.', '') +
			--schema
			COALESCE(QUOTENAME(PARSENAME(@DESTINATION_TABLE, 2)) + '.', '') +
			--table
			COALESCE(QUOTENAME(PARSENAME(@DESTINATION_TABLE, 1)), '');
			
		IF COALESCE(RTRIM(@DESTINATION_TABLE), '') = ''
		BEGIN
			RAISERROR('Destination table not properly formatted.', 16, 1);
			RETURN;
		END;
	END;

	CREATE TABLE #sessions
	(
		recursion SMALLINT NOT NULL,
		session_id SMALLINT NOT NULL,
		request_id INT NULL,
		session_number INT NOT NULL,
		elapsed_time INT NOT NULL,
		avg_elapsed_time INT NULL,
		physical_io INT NULL,
		reads BIGINT NOT NULL,
		physical_reads BIGINT NOT NULL,
		writes BIGINT NOT NULL,
		tempdb_writes BIGINT NOT NULL,
		tempdb_current BIGINT NOT NULL,
		CPU INT NOT NULL,
		context_switches INT NULL,
		used_memory INT NOT NULL, 
		threads SMALLINT NULL,
		status VARCHAR(30) NOT NULL,
		wait_info VARCHAR(4000) NULL,
		locks XML NULL,
		tran_start_time DATETIME NULL,
		tran_log_writes VARCHAR(4000) NULL,
		open_tran_count INT NULL,
		sql_command XML NULL,
		sql_handle VARBINARY(64) NULL,
		statement_start_offset INT NULL,
		statement_end_offset INT NULL,
		sql_text XML NULL,
		plan_handle VARBINARY(64) NULL,
		query_plan XML NULL,
		blocking_session_id SMALLINT NULL,
		percent_complete REAL NULL,
		host_name VARCHAR(128) NOT NULL,
		login_name VARCHAR(128) NOT NULL,
		database_name VARCHAR(128) NULL,
		start_time DATETIME NOT NULL,
		last_request_start_time DATETIME NOT NULL
	);

	IF @RETURN_SCHEMA = 0
	BEGIN;
		--Disable unnecessary autostats on the table
		CREATE STATISTICS s_session_id ON #sessions (session_id)
		WITH SAMPLE 0 ROWS, NORECOMPUTE;
		CREATE STATISTICS s_request_id ON #sessions (request_id)
		WITH SAMPLE 0 ROWS, NORECOMPUTE;
		CREATE STATISTICS s_session_number ON #sessions (session_number)
		WITH SAMPLE 0 ROWS, NORECOMPUTE;
		CREATE STATISTICS s_status ON #sessions (status)
		WITH SAMPLE 0 ROWS, NORECOMPUTE;
		CREATE STATISTICS s_start_time ON #sessions (start_time)
		WITH SAMPLE 0 ROWS, NORECOMPUTE;
		CREATE STATISTICS s_last_request_start_time ON #sessions (last_request_start_time)
		WITH SAMPLE 0 ROWS, NORECOMPUTE;
		CREATE STATISTICS s_recursion ON #sessions (recursion)
		WITH SAMPLE 0 ROWS, NORECOMPUTE;

		DECLARE @recursion SMALLINT;
		SET @recursion = 
			CASE @DELTA_INTERVAL
				WHEN 0 THEN 1
				ELSE -1
			END;

		--Used for the delta pull
		REDO:;
		
		IF 
			@GET_LOCKS = 1 
			AND @recursion = 1
			AND @OUTPUT_COLUMN_LIST LIKE '%|[locks|]%' ESCAPE '|'
		BEGIN;
			SELECT
				y.resource_type,
				y.db_name,
				y.object_id,
				y.file_id,
				y.page_type,
				y.hobt_id,
				y.allocation_unit_id,
				y.index_id,
				y.schema_id,
				y.principal_id,
				y.request_mode,
				y.request_status,
				y.session_id,
				y.resource_description,
				y.request_count,
				COALESCE(r.request_id, -1) AS request_id,
				COALESCE(r.start_time, s.last_request_start_time) AS start_time,
				CONVERT(sysname, NULL) AS object_name,
				CONVERT(sysname, NULL) AS index_name,
				CONVERT(sysname, NULL) AS schema_name,
				CONVERT(sysname, NULL) AS principal_name
			INTO #locks
			FROM
			(
				SELECT
					x.resource_type,
					x.db_name,
					x.object_id,
					x.file_id,
					CASE
						WHEN x.page_no = 1 OR x.page_no % 8088 = 0 THEN 'PFS'
						WHEN x.page_no = 2 OR x.page_no % 511232 = 0 THEN 'GAM'
						WHEN x.page_no = 3 OR x.page_no % 511233 = 0 THEN 'SGAM'
						WHEN x.page_no = 6 OR x.page_no % 511238 = 0 THEN 'DCM'
						WHEN x.page_no = 7 OR x.page_no % 511239 = 0 THEN 'BCM'
						WHEN x.page_no IS NOT NULL THEN '*'
						ELSE NULL
					END AS page_type,
					x.hobt_id,
					x.allocation_unit_id,
					x.index_id,
					x.schema_id,
					x.principal_id,
					x.request_mode,
					x.request_status,
					x.session_id,
					x.request_id,
					CASE
						WHEN COALESCE(x.object_id, x.file_id, x.hobt_id, x.allocation_unit_id, x.index_id, x.schema_id, x.principal_id) IS NULL THEN NULLIF(resource_description, '')
						ELSE NULL
					END AS resource_description,
					COUNT(*) AS request_count
				FROM
				(
					SELECT
						tl.resource_type + 
							CASE 
								WHEN tl.resource_subtype = '' THEN ''
								ELSE '.' + tl.resource_subtype 
							END AS resource_type,
						COALESCE(DB_NAME(tl.resource_database_id), '(null)') AS db_name,
						CONVERT 
						(
							INT,
							CASE 
								WHEN tl.resource_type = 'OBJECT' THEN tl.resource_associated_entity_id
								WHEN tl.resource_description LIKE '%object_id = %' THEN 
									(
										SELECT
											SUBSTRING
											(
												tl.resource_description, 
												(CHARINDEX(p.pattern, tl.resource_description) + DATALENGTH(p.pattern)), 
												COALESCE
												(
													NULLIF
													(
														CHARINDEX(',', tl.resource_description, CHARINDEX(p.pattern, tl.resource_description) + DATALENGTH(p.pattern)), 
														0
													), 
													DATALENGTH(tl.resource_description)+1
												) - (CHARINDEX(p.pattern, tl.resource_description) + DATALENGTH(p.pattern))
											)
										FROM (SELECT 'object_id = ' AS pattern) p
									)
								ELSE NULL
							END
						) AS object_id,
						CONVERT
						(
							INT,
							CASE 
								WHEN tl.resource_type = 'FILE' THEN CONVERT(INT, tl.resource_description) 
								WHEN tl.resource_type IN ('PAGE', 'EXTENT', 'RID') THEN LEFT(tl.resource_description, CHARINDEX(':', tl.resource_description)-1)
								ELSE NULL
							END 
						) AS file_id,
						CONVERT
						(
							INT,
							CASE
								WHEN tl.resource_type IN ('PAGE', 'EXTENT', 'RID') THEN 
									SUBSTRING
									(
										tl.resource_description, 
										CHARINDEX(':', tl.resource_description) + 1, 
										COALESCE
										(
											NULLIF
											(
												CHARINDEX(':', tl.resource_description, CHARINDEX(':', tl.resource_description) + 1), 
												0
											), 
											DATALENGTH(tl.resource_description)+1
										) - (CHARINDEX(':', tl.resource_description) + 1)
									)
								ELSE NULL
							END 
						) AS page_no,
						CASE 
							WHEN tl.resource_type IN ('PAGE', 'KEY', 'RID', 'HOBT') THEN tl.resource_associated_entity_id
							ELSE NULL
						END AS hobt_id,
						CASE 
							WHEN tl.resource_type = 'ALLOCATION_UNIT' THEN tl.resource_associated_entity_id
							ELSE NULL
						END AS allocation_unit_id,
						CONVERT
						(
							INT,
							CASE
								WHEN
									/*TODO: Deal with server principals*/ 
									tl.resource_subtype <> 'SERVER_PRINCIPAL' 
									AND tl.resource_description LIKE '%index_id or stats_id = %' THEN
									(
										SELECT
											SUBSTRING
											(
												tl.resource_description, 
												(CHARINDEX(p.pattern, tl.resource_description) + DATALENGTH(p.pattern)), 
												COALESCE
												(
													NULLIF
													(
														CHARINDEX(',', tl.resource_description, CHARINDEX(p.pattern, tl.resource_description) + DATALENGTH(p.pattern)), 
														0
													), 
													DATALENGTH(tl.resource_description)+1
												) - (CHARINDEX(p.pattern, tl.resource_description) + DATALENGTH(p.pattern))
											)
										FROM (SELECT 'index_id or stats_id = ' AS pattern) p
									)
								ELSE NULL
							END 
						) AS index_id,
						CONVERT
						(
							INT,
							CASE
								WHEN tl.resource_description LIKE '%schema_id = %' THEN
									(
										SELECT
											SUBSTRING
											(
												tl.resource_description, 
												(CHARINDEX(p.pattern, tl.resource_description) + DATALENGTH(p.pattern)), 
												COALESCE
												(
													NULLIF
													(
														CHARINDEX(',', tl.resource_description, CHARINDEX(p.pattern, tl.resource_description) + DATALENGTH(p.pattern)), 
														0
													), 
													DATALENGTH(tl.resource_description)+1
												) - (CHARINDEX(p.pattern, tl.resource_description) + DATALENGTH(p.pattern))
											)
										FROM (SELECT 'schema_id = ' AS pattern) p
									)
								ELSE NULL
							END 
						) AS schema_id,
						CONVERT
						(
							INT,
							CASE
								WHEN tl.resource_description LIKE '%principal_id = %' THEN
									(
										SELECT
											SUBSTRING
											(
												tl.resource_description, 
												(CHARINDEX(p.pattern, tl.resource_description) + DATALENGTH(p.pattern)), 
												COALESCE
												(
													NULLIF
													(
														CHARINDEX(',', tl.resource_description, CHARINDEX(p.pattern, tl.resource_description) + DATALENGTH(p.pattern)), 
														0
													), 
													DATALENGTH(tl.resource_description)+1
												) - (CHARINDEX(p.pattern, tl.resource_description) + DATALENGTH(p.pattern))
											)
										FROM (SELECT 'principal_id = ' AS pattern) p
									)
								ELSE NULL
							END
						) AS principal_id,
						tl.request_mode,
						tl.request_status,
						tl.request_session_id AS session_id,
						tl.request_request_id AS request_id,
										
						/*TODO: Applocks, other resource_descriptions*/
						RTRIM(tl.resource_description) AS resource_description,
						tl.resource_associated_entity_id
						/*********************************************/
					FROM sys.dm_tran_locks tl
					WHERE
						(
							@SPID = 0
							OR tl.request_session_id = @SPID
						)
						AND
						(
							@SHOW_OWN_SPID = 1
							OR tl.request_session_id <> @@SPID
						)
				) x
				GROUP BY
					x.resource_type,
					x.db_name,
					x.object_id,
					x.file_id,
					CASE
						WHEN x.page_no = 1 OR x.page_no % 8088 = 0 THEN 'PFS'
						WHEN x.page_no = 2 OR x.page_no % 511232 = 0 THEN 'GAM'
						WHEN x.page_no = 3 OR x.page_no % 511233 = 0 THEN 'SGAM'
						WHEN x.page_no = 6 OR x.page_no % 511238 = 0 THEN 'DCM'
						WHEN x.page_no = 7 OR x.page_no % 511239 = 0 THEN 'BCM'
						WHEN x.page_no IS NOT NULL THEN '*'
						ELSE NULL
					END,
					x.hobt_id,
					x.allocation_unit_id,
					x.index_id,
					x.schema_id,
					x.principal_id,
					x.request_mode,
					x.request_status,
					x.session_id,
					x.request_id,
					CASE
						WHEN COALESCE(x.object_id, x.file_id, x.hobt_id, x.allocation_unit_id, x.index_id, x.schema_id, x.principal_id) IS NULL THEN NULLIF(resource_description, '')
						ELSE NULL
					END
			) y
			JOIN sys.dm_exec_sessions s ON
				y.session_id = s.session_id
			LEFT OUTER JOIN sys.dm_exec_requests r ON
				s.session_id = r.session_id
				AND y.request_id = r.request_id;
			
			--Disable unnecessary autostats on the table
			CREATE STATISTICS s_db_name ON #locks (db_name)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_object_id ON #locks (object_id)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_hobt_id ON #locks (hobt_id)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_allocation_unit_id ON #locks (allocation_unit_id)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_index_id ON #locks (index_id)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_schema_id ON #locks (schema_id)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_principal_id ON #locks (principal_id)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_request_id ON #locks (request_id)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_start_time ON #locks (start_time)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_resource_type ON #locks (resource_type)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_object_name ON #locks (object_name)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_schema_name ON #locks (schema_name)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_page_type ON #locks (page_type)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_request_mode ON #locks (request_mode)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_request_status ON #locks (request_status)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_resource_description ON #locks (resource_description)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_index_name ON #locks (index_name)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
			CREATE STATISTICS s_principal_name ON #locks (principal_name)
			WITH SAMPLE 0 ROWS, NORECOMPUTE;
		END;
		
		DECLARE @sql NVARCHAR(MAX);

		SET @sql = CONVERT(NVARCHAR(MAX), '') +
			'SELECT ' +
				'@recursion AS recursion, ' +
				'x.session_id, ' +
				'x.request_id, ' +
				'DENSE_RANK() OVER  ' +
				'( ' +
					'ORDER BY ' +
						'x.session_id ' +
				') AS session_number, ' +
				CASE
					WHEN @OUTPUT_COLUMN_LIST LIKE '%|[dd hh:mm:ss.mss|]%' ESCAPE '|' THEN 'x.elapsed_time '
					ELSE CONVERT(NVARCHAR(MAX), '0 ')
				END + 'AS elapsed_time, ' +
				CASE
					WHEN
						(
							@OUTPUT_COLUMN_LIST LIKE '%|[dd hh:mm:ss.mss (avg)|]%' ESCAPE '|' OR 
							@OUTPUT_COLUMN_LIST LIKE '%|[avg_elapsed_time|]%' ESCAPE '|'
						)
						AND @recursion = 1
							THEN 'x.avg_elapsed_time / 1000 '
					ELSE CONVERT(NVARCHAR(MAX), 'NULL ')
				END + 'AS avg_elapsed_time, ' +
				CASE
					WHEN 
						@OUTPUT_COLUMN_LIST LIKE '%|[physical_io|]%' ESCAPE '|'
						OR @OUTPUT_COLUMN_LIST LIKE '%|[physical_io_delta|]%' ESCAPE '|'
							THEN 'x.physical_io '
					ELSE CONVERT(NVARCHAR(MAX), 'NULL ')
				END + 'AS physical_io, ' +
				CASE
					WHEN 
						@OUTPUT_COLUMN_LIST LIKE '%|[reads|]%' ESCAPE '|'
						OR @OUTPUT_COLUMN_LIST LIKE '%|[reads_delta|]%' ESCAPE '|'
							THEN 'x.reads '
					ELSE CONVERT(NVARCHAR(MAX), '0 ')
				END + 'AS reads, ' +
				CASE
					WHEN 
						@OUTPUT_COLUMN_LIST LIKE '%|[physical_reads|]%' ESCAPE '|'
						OR @OUTPUT_COLUMN_LIST LIKE '%|[physical_reads_delta|]%' ESCAPE '|'
							THEN 'x.physical_reads '
					ELSE CONVERT(NVARCHAR(MAX), '0 ')
				END + 'AS physical_reads, ' +
				CASE
					WHEN 
						@OUTPUT_COLUMN_LIST LIKE '%|[writes|]%' ESCAPE '|'
						OR @OUTPUT_COLUMN_LIST LIKE '%|[writes_delta|]%' ESCAPE '|'
							THEN 'x.writes '
					ELSE CONVERT(NVARCHAR(MAX), '0 ')
				END + 'AS writes, ' +
				CASE
					WHEN 
						@OUTPUT_COLUMN_LIST LIKE '%|[tempdb_writes|]%' ESCAPE '|'
						OR @OUTPUT_COLUMN_LIST LIKE '%|[tempdb_writes_delta|]%' ESCAPE '|'
							THEN 'x.tempdb_writes '
					ELSE CONVERT(NVARCHAR(MAX), '0 ')
				END + 'AS tempdb_writes, ' +
				CASE
					WHEN 
						@OUTPUT_COLUMN_LIST LIKE '%|[tempdb_current|]%' ESCAPE '|'
						OR @OUTPUT_COLUMN_LIST LIKE '%|[tempdb_current_delta|]%' ESCAPE '|'
							THEN 'x.tempdb_current '
					ELSE CONVERT(NVARCHAR(MAX), '0 ')
				END + 'AS tempdb_current, ' +
				CASE
					WHEN 
						@OUTPUT_COLUMN_LIST LIKE '%|[CPU|]%' ESCAPE '|'
						OR @OUTPUT_COLUMN_LIST LIKE '%|[CPU_delta|]%' ESCAPE '|'
							THEN 'x.CPU '
					ELSE CONVERT(NVARCHAR(MAX), '0 ')
				END + 'AS CPU, ' +
				CASE
					WHEN 
						@OUTPUT_COLUMN_LIST LIKE '%|[context_switches|]%' ESCAPE '|'
						OR @OUTPUT_COLUMN_LIST LIKE '%|[context_switches_delta|]%' ESCAPE '|'
							THEN 'x.context_switches '
					ELSE CONVERT(NVARCHAR(MAX), 'NULL ')
				END + 'AS context_switches, ' +
				CASE
					WHEN 
						@OUTPUT_COLUMN_LIST LIKE '%|[used_memory|]%' ESCAPE '|'
						OR @OUTPUT_COLUMN_LIST LIKE '%|[used_memory_delta|]%' ESCAPE '|'
							THEN 'x.used_memory '
					ELSE CONVERT(NVARCHAR(MAX), '0 ')
				END + 'AS used_memory, ' +
				CASE
					WHEN 
						@OUTPUT_COLUMN_LIST LIKE '%|[threads|]%' ESCAPE '|'
						AND @recursion = 1
							THEN 'x.threads '
					ELSE CONVERT(NVARCHAR(MAX), 'NULL ')
				END + 'AS threads, ' +
				CASE
					WHEN 
						@OUTPUT_COLUMN_LIST LIKE '%|[status|]%' ESCAPE '|' 
						AND @recursion = 1
							THEN 'x.status '
					ELSE CONVERT(NVARCHAR(MAX), ''''' ')
				END + 'AS status, ' +
				CASE
					WHEN 
						@OUTPUT_COLUMN_LIST LIKE '%|[wait_info|]%' ESCAPE '|' 
						AND @recursion = 1
							THEN 'x.wait_info '
					ELSE CONVERT(NVARCHAR(MAX), 'NULL ')
				END + 'AS wait_info, ' +
				CASE
					WHEN 
						@OUTPUT_COLUMN_LIST LIKE '%|[tran_start_time|]%' ESCAPE '|' 
						AND @recursion = 1
							THEN 
							'CONVERT ' +
							'( ' +
								'DATETIME, ' +
								'LEFT ' +
								'( ' +
									'x.tran_log_writes, ' +
									'NULLIF(CHARINDEX(CHAR(254), x.tran_log_writes) - 1, -1) ' +
								') ' +
							') '
					ELSE CONVERT(NVARCHAR(MAX), 'NULL ')
				END + 'AS tran_start_time, ' +				
				CASE
					WHEN 
						@OUTPUT_COLUMN_LIST LIKE '%|[tran_log_writes|]%' ESCAPE '|' 
						AND @recursion = 1
							THEN 
							'RIGHT ' +
							'( ' +
								'x.tran_log_writes, ' +
								'LEN(x.tran_log_writes) - CHARINDEX(CHAR(254), x.tran_log_writes) ' +
							') '
					ELSE CONVERT(NVARCHAR(MAX), 'NULL ')
				END + 'AS tran_log_writes, ' +
				CASE
					WHEN 
						@OUTPUT_COLUMN_LIST LIKE '%|[open_tran_count|]%' ESCAPE '|' 
						AND @recursion = 1
							THEN 'x.open_tran_count '
					ELSE CONVERT(NVARCHAR(MAX), 'NULL ')
				END + 'AS open_tran_count, ' + 
				CASE
					WHEN 
						@OUTPUT_COLUMN_LIST LIKE '%|[sql_text|]%' ESCAPE '|' 
						AND @recursion = 1
							THEN 'x.sql_handle '
					ELSE CONVERT(NVARCHAR(MAX), 'NULL ')
				END + 'AS sql_handle, ' +
				CASE
					WHEN 
						@OUTPUT_COLUMN_LIST LIKE '%|[sql_text|]%' ESCAPE '|' 
						AND @recursion = 1
							THEN 'x.statement_start_offset '
					ELSE CONVERT(NVARCHAR(MAX), 'NULL ')
				END + 'AS statement_start_offset, ' +
				CASE
					WHEN 
						@OUTPUT_COLUMN_LIST LIKE '%|[sql_text|]%' ESCAPE '|' 
						AND @recursion = 1
							THEN 'x.statement_end_offset '
					ELSE CONVERT(NVARCHAR(MAX), 'NULL ')
				END + 'AS statement_end_offset, ' +
				'NULL AS sql_text, ' +
				CASE
					WHEN 
						@OUTPUT_COLUMN_LIST LIKE '%|[query_plan|]%' ESCAPE '|' 
						AND @recursion = 1
							THEN 'x.plan_handle '
					ELSE CONVERT(NVARCHAR(MAX), 'NULL ')
				END + 'AS plan_handle, ' +
				CASE
					WHEN 
						@OUTPUT_COLUMN_LIST LIKE '%|[blocking_session_id|]%' ESCAPE '|' 
						AND @recursion = 1
							THEN 'NULLIF(x.blocking_session_id, 0) '
					ELSE CONVERT(NVARCHAR(MAX), 'NULL ')
				END + 'AS blocking_session_id, ' +
				CASE
					WHEN 
						@OUTPUT_COLUMN_LIST LIKE '%|[percent_complete|]%' ESCAPE '|'
						AND @recursion = 1
							THEN 'x.percent_complete '
					ELSE CONVERT(NVARCHAR(MAX), 'NULL ')
				END + 'AS percent_complete, ' +
				CASE
					WHEN 
						@OUTPUT_COLUMN_LIST LIKE '%|[host_name|]%' ESCAPE '|' 
						AND @recursion = 1
							THEN 'x.host_name '
					ELSE CONVERT(NVARCHAR(MAX), ''''' ')
				END + 'AS host_name, ' +
				CASE
					WHEN 
						@OUTPUT_COLUMN_LIST LIKE '%|[login_name|]%' ESCAPE '|' 
						AND @recursion = 1
							THEN 'x.login_name '
					ELSE CONVERT(NVARCHAR(MAX), ''''' ')
				END + 'AS login_name, ' +
				CASE
					WHEN 
						@OUTPUT_COLUMN_LIST LIKE '%|[database_name|]%' ESCAPE '|' 
						AND @recursion = 1
							THEN 'DB_NAME(x.database_id) '
					ELSE CONVERT(NVARCHAR(MAX), 'NULL ')
				END + 'AS database_name, ' +
				'x.start_time, ' +
				'x.last_request_start_time ' +
			'FROM ' +
			'( ' +
				'SELECT ' +
					'y.*, ' +
					'tasks.physical_io, ' +
					'tempdb_info.tempdb_writes, ' +
					'tempdb_info.tempdb_current, ' +
					'tasks.context_switches, ' + 
					'tasks.threads, ' +
					'tasks.wait_info, ' +
					'tasks.blocking_session_id, ' +
					CASE 
						WHEN NOT (@GET_AVG_TIME = 1 AND @recursion = 1) THEN CONVERT(NVARCHAR(MAX), 'CONVERT(INT, NULL) ')
						ELSE 'qs.total_elapsed_time / qs.execution_count '
					END + 'AS avg_elapsed_time ' +
				'FROM ' +
				'( ' +
					'SELECT ' +
						's.session_id, ' +
						'r.request_id, ' +
						--r.total_elapsed_time AS elapsed_time,
						--total_elapsed_time appears to be way off in some cases
						'CASE ' +
							--if there are more than 24 days, return a negative number of seconds rather than
							--positive milliseconds, in order to avoid overflow errors
							'WHEN DATEDIFF(day, COALESCE(r.start_time, s.login_time), GETDATE()) > 24 THEN ' +
								'DATEDIFF(second, GETDATE(), COALESCE(r.start_time, s.login_time)) ' +
							'ELSE DATEDIFF(ms, COALESCE(r.start_time, s.login_time), GETDATE()) ' +
						'END AS elapsed_time, ' +
						'COALESCE(r.logical_reads, s.logical_reads) AS reads, ' +
						'COALESCE(r.reads, s.reads) AS physical_reads, ' +
						'COALESCE(r.writes, s.writes) AS writes, ' +
						'COALESCE(r.CPU_time, s.CPU_time) AS CPU, ' +
						'COALESCE(CONVERT(INT, mg.used_memory_kb / 8192), s.memory_usage) AS used_memory, ' +
						'LOWER(COALESCE(r.status, s.status)) AS status, ' +
						'COALESCE(r.sql_handle, c.most_recent_sql_handle) AS sql_handle, ' +
						'r.statement_start_offset, ' +
						'r.statement_end_offset, ' +
						'r.plan_handle, ' +
						'NULLIF(r.percent_complete, 0) AS percent_complete, ' +
						's.host_name, ' +
						's.login_name, ' +
						'COALESCE(r.start_time, s.login_time) AS start_time, ' +
						's.last_request_start_time, ' +
						'r.transaction_id, ' +
						'COALESCE ' +
						'( ' +
							'r.database_id, ' +
							'( ' +
								CASE 
									WHEN NOT (@GET_TRANSACTION_INFO = 1 AND @recursion = 1) THEN CONVERT(NVARCHAR(MAX), 'CONVERT(INT, NULL) ')
									ELSE 'sp.dbid '
								END +
							') ' +
						') AS database_id, ' +
						CASE 
							WHEN NOT (@GET_TRANSACTION_INFO = 1 AND @recursion = 1) THEN CONVERT(NVARCHAR(MAX), 'CONVERT(INT, NULL) ')
							ELSE 'sp.open_tran_count ' 
						END + 'AS open_tran_count, ' + 
						'( ' +
							CASE 
								WHEN NOT (@GET_TRANSACTION_INFO = 1 AND @recursion = 1) THEN CONVERT(NVARCHAR(MAX), 'CONVERT(VARCHAR(4000), NULL) ')
								ELSE
									'SELECT ' +
										'REPLACE ' +
										'( ' +
											'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
											'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
											'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
												'CONVERT ' +
												'( ' +
													'VARCHAR(MAX), ' +
													'CASE ' +
														'WHEN u_trans.database_id IS NOT NULL THEN ' +
															'CASE u_trans.r ' +
																'WHEN 1 THEN COALESCE(CONVERT(VARCHAR, u_trans.transaction_start_time, 121) + CHAR(254), '''') ' +
																'ELSE '''' ' +
															'END + ' + 
															'COALESCE(DB_NAME(u_trans.database_id), ''(null)'') + '':'' + ' +
															'CONVERT(VARCHAR, u_trans.log_record_count) + ' +
															''','' ' +
														'ELSE ' +
															'''N/A,'' ' +
													'END COLLATE Latin1_General_BIN2 ' +
												'), ' +
												'CHAR(31),''''),CHAR(30),''''),CHAR(29),''''),CHAR(28),''''),CHAR(27),''''),CHAR(26),''''),CHAR(25),''''),CHAR(24),''''),CHAR(23),''''),CHAR(22),''''), ' +
												'CHAR(21),''''),CHAR(20),''''),CHAR(19),''''),CHAR(18),''''),CHAR(17),''''),CHAR(16),''''),CHAR(15),''''),CHAR(14),''''),CHAR(12),''''), ' +											'CHAR(11),''''),CHAR(8),''''),CHAR(7),''''),CHAR(6),''''),CHAR(5),''''),CHAR(4),''''),CHAR(3),''''),CHAR(2),''''),CHAR(1),''''), ' +
											'CHAR(0), ' +
											''''' ' +
										') AS [text()] ' +
									'FROM ' +
									'( ' +
										'SELECT ' +
											'trans.*, ' +
											'ROW_NUMBER() OVER (ORDER BY trans.transaction_start_time DESC) AS r ' +
										'FROM ' +
										'( ' +
											'SELECT ' +
												's_tran.database_id, ' +
												'COALESCE(SUM(s_tran.database_transaction_log_record_count), 0) AS log_record_count, ' +
												'MIN(s_tran.database_transaction_begin_time) AS transaction_start_time ' +
											'FROM sys.dm_tran_database_transactions s_tran ' +
											'LEFT OUTER JOIN sys.dm_tran_session_transactions tst ON ' +
												's_tran.transaction_id = tst.transaction_id ' +
												'AND s_tran.database_id < 32767 ' +
											'WHERE ' +
												's_tran.transaction_id = r.transaction_id ' + 
												'OR ' +
												'( ' +
													'COALESCE(r.request_id, 0) = 0 ' +
													'AND s.session_id = tst.session_id ' +
												') ' +
											'GROUP BY ' +
												's_tran.database_id ' +
										') trans ' +
									') u_trans ' +
									'FOR XML PATH('''') '
							END +
						') AS tran_log_writes ' +
					'FROM sys.dm_exec_sessions s ' +					
					'LEFT OUTER JOIN sys.dm_exec_requests r ON ' + 
						's.session_id = r.session_id ' +
					CASE 
						WHEN NOT (@GET_TRANSACTION_INFO = 1 AND @recursion = 1) THEN CONVERT(NVARCHAR(MAX), '')
						ELSE
						'INNER JOIN ' +
						'(' + 
							'SELECT ' +
								'sp1.spid, ' +
								'sp1.request_id, ' +
								'MIN(sp1.dbid) AS dbid, ' +
								'SUM(sp1.open_tran) AS open_tran_count ' +
							'FROM sys.sysprocesses sp1 ' +
							'GROUP BY ' +
								'sp1.spid, ' +
								'sp1.request_id ' +
						') sp ON ' +
							's.session_id = sp.spid ' +
							'AND COALESCE(NULLIF(r.request_id, -1), 0) = sp.request_id ' + 
							'AND ' +
							'( ' + 
								'r.request_id IS NOT NULL ' +
								'OR sp.open_tran_count > 0 ' +
							') '
					END +
					'LEFT OUTER JOIN sys.dm_exec_connections c ON ' +
						's.session_id = c.session_id ' +
					'LEFT OUTER JOIN sys.dm_exec_query_memory_grants mg ON ' +
						'r.session_id = mg.session_id ' +
						'AND r.request_id = mg.request_id ' +
					'WHERE ' +
						's.host_name IS NOT NULL ' +
						'AND ' +
						'( ' +
							'r.session_id IS NULL ' +
							'OR c.connection_id = r.connection_id ' +
						') ' +
						CASE 
							WHEN @GET_TRANSACTION_INFO = 1 AND @recursion = 1 THEN CONVERT(NVARCHAR(MAX), '')
							ELSE
								'AND r.request_id IS NOT NULL '
						END +
						CASE @SPID
							WHEN 0 THEN CONVERT(NVARCHAR(MAX), '')
							ELSE
								'AND s.session_id = @SPID ' 
						END + 
						CASE @SHOW_OWN_SPID
							WHEN 1 THEN CONVERT(NVARCHAR(MAX), '')
							ELSE
								'AND s.session_id <> @@SPID '
						END +
				') AS y ' +
				'LEFT OUTER JOIN ' +
				'( ' +
					'SELECT ' +
						'session_id, ' +
						'request_id, ' +
						'SUM(tempdb_writes) AS tempdb_writes, ' +
						'SUM(tempdb_current) AS tempdb_current ' +
					'FROM ' +
					'( ' +
						'SELECT ' +
							'tsu.session_id, ' +
							'tsu.request_id, ' +
							'tsu.user_objects_alloc_page_count + ' +
								'tsu.internal_objects_alloc_page_count AS tempdb_writes,' +
							'tsu.user_objects_alloc_page_count + ' +
								'tsu.internal_objects_alloc_page_count - ' +
								'tsu.user_objects_dealloc_page_count - ' +
								'tsu.internal_objects_dealloc_page_count AS tempdb_current ' +
						'FROM sys.dm_db_task_space_usage tsu ' +
						CASE 
							WHEN NOT (@GET_TRANSACTION_INFO = 1 AND @recursion = 1) THEN CONVERT(NVARCHAR(MAX), '')
							ELSE
								'UNION ALL ' +
								'' +
								'SELECT ' +
									'ssu.session_id, ' +
									'NULL AS request_id, ' +
									'ssu.user_objects_alloc_page_count + ' +
										'ssu.internal_objects_alloc_page_count AS tempdb_writes, ' +
									'ssu.user_objects_alloc_page_count + ' +
										'ssu.internal_objects_alloc_page_count - ' +
										'ssu.user_objects_dealloc_page_count - ' +
										'ssu.internal_objects_dealloc_page_count AS tempdb_current ' +
								'FROM sys.dm_db_session_space_usage ssu '
						END +
					') t_info ' +
					'GROUP BY ' +
						'session_id, ' +
						'request_id ' +
				') tempdb_info ON ' +
					'tempdb_info.session_id = y.session_id ' +
					'AND COALESCE(tempdb_info.request_id, -1) = COALESCE(y.request_id, -1) ' +
				'OUTER APPLY ' +
				'( ' +
					'SELECT ' +
						'tasks_final.task_xml.value(''(tasks/physical_io/text())[1]'', ''INT'') AS physical_io, ' +
						'tasks_final.task_xml.value(''(tasks/context_switches/text())[1]'', ''INT'') AS context_switches, ' +
						'tasks_final.task_xml.value(''(tasks/threads/text())[1]'', ''INT'') AS threads, ' +
						'tasks_final.task_xml.value(''(tasks/blocking_session_id/text())[1]'', ''SMALLINT'') AS blocking_session_id, ' +								
						'tasks_final.task_xml.value(''(tasks/text())[1]'', ''VARCHAR(8000)'') AS wait_info ' +
					'FROM ' +
					'( ' +
						'SELECT ' +
							'CONVERT ' +
							'( ' +
								'XML, ' +
								'REPLACE(REPLACE(REPLACE( ' +
									'tasks_raw.task_xml_raw, ''</tasks><tasks>'', ''''), ' +
									'''<waits>'', ''''), ' +
									'''</waits>'', '', '') ' +
							') AS task_xml ' +
						'FROM ' +
						'( ' +
							'SELECT ' +
								'CASE waits.r ' +
									'WHEN 1 THEN waits.physical_io ' +
									'ELSE NULL ' +
								'END AS [physical_io], ' +
								'CASE waits.r ' +
									'WHEN 1 THEN waits.context_switches ' +
									'ELSE NULL ' +
								'END AS [context_switches], ' +
								'CASE waits.r ' +
									'WHEN 1 THEN waits.threads ' +
									'ELSE NULL ' +
								'END AS [threads], ' +
								'CASE waits.r ' +
									'WHEN 1 THEN waits.blocking_session_id ' +
									'ELSE NULL ' +
								'END AS [blocking_session_id], ' +
								'REPLACE ' +
								'( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
									'REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE( ' +
										'CONVERT ' +
										'( ' +
											'VARCHAR(MAX), ' +
											'''('' + ' +
												'CONVERT(VARCHAR, num_waits) + ''x: '' + ' +
												'CASE num_waits ' +
													'WHEN 1 THEN CONVERT(VARCHAR, min_wait_time) + ''ms'' ' +
													'WHEN 2 THEN ' +
														'CASE ' +
															'WHEN min_wait_time <> max_wait_time THEN CONVERT(VARCHAR, min_wait_time) + ''/'' + CONVERT(VARCHAR, max_wait_time) + ''ms'' ' +
															'ELSE CONVERT(VARCHAR, max_wait_time) + ''ms'' ' +
														'END ' +
													'ELSE ' +
														'CASE ' +
															'WHEN min_wait_time <> max_wait_time THEN CONVERT(VARCHAR, min_wait_time) + ''/'' + CONVERT(VARCHAR, avg_wait_time) + ''/'' + CONVERT(VARCHAR, max_wait_time) + ''ms'' ' +
															'ELSE CONVERT(VARCHAR, max_wait_time) + ''ms'' ' +
														'END ' +
												'END + ' +
											''')'' + wait_type COLLATE Latin1_General_BIN2 ' +
										'), ' +
										'CHAR(31),''''),CHAR(30),''''),CHAR(29),''''),CHAR(28),''''),CHAR(27),''''),CHAR(26),''''),CHAR(25),''''),CHAR(24),''''),CHAR(23),''''),CHAR(22),''''), ' +
										'CHAR(21),''''),CHAR(20),''''),CHAR(19),''''),CHAR(18),''''),CHAR(17),''''),CHAR(16),''''),CHAR(15),''''),CHAR(14),''''),CHAR(12),''''), ' +
										'CHAR(11),''''),CHAR(8),''''),CHAR(7),''''),CHAR(6),''''),CHAR(5),''''),CHAR(4),''''),CHAR(3),''''),CHAR(2),''''),CHAR(1),''''), ' +
									'CHAR(0), ' +
									''''' ' +
								') AS [waits] ' +
							'FROM ' +
							'( ' +
								'SELECT ' +
									'w2.*, ' +
									'ROW_NUMBER() OVER (ORDER BY w2.num_waits, w2.wait_type) AS r ' +
								'FROM ' +
								'( ' +
									'SELECT DISTINCT ' +
										'w1.physical_io, ' +
										'w1.context_switches, ' +
										'MAX(w1.num_threads) OVER () AS threads, ' +
										'w1.wait_type, ' +
										'MAX(w1.num_waits) OVER (PARTITION BY w1.wait_type) AS num_waits, ' +
										'w1.min_wait_time, ' +
										'w1.avg_wait_time, ' +
										'w1.max_wait_time, ' +
										'w1.blocking_session_id ' +
									'FROM ' +
									'( ' +
										'SELECT ' +
											'SUM(t.pending_io_count) OVER () AS physical_io, ' +
											'SUM(t.context_switches_count) OVER () AS context_switches, ' +
											'DENSE_RANK() OVER (ORDER BY t.exec_context_id) AS num_threads, ' +
											'wt2.wait_type, ' +
											'CASE ' +
												'WHEN wt2.waiting_task_address IS NOT NULL THEN ' +
													'DENSE_RANK() OVER (PARTITION BY wt2.wait_type ORDER BY wt2.waiting_task_address)  ' +
												'ELSE NULL ' +
											'END AS num_waits, ' +
											'MIN(wt2.wait_duration_ms) OVER (PARTITION BY wt2.wait_type) AS min_wait_time, ' +
											'AVG(wt2.wait_duration_ms) OVER (PARTITION BY wt2.wait_type) AS avg_wait_time, ' +
											'MAX(wt2.wait_duration_ms) OVER (PARTITION BY wt2.wait_type) AS max_wait_time, ' +
											'MAX(wt2.blocking_session_id) OVER () AS blocking_session_id ' +
										'FROM sys.dm_os_tasks t ' +
										'LEFT OUTER JOIN ' +
										'( ' +
											'SELECT ' +
												'wt1.wait_type, ' +
												'wt1.session_id, ' +
												'wt1.waiting_task_address, ' +
												'SUM(wt1.wait_duration_ms) AS wait_duration_ms, ' +
												'MAX(wt1.blocking_session_id) AS blocking_session_id ' +
											'FROM ' +
											'( ' +
												'SELECT DISTINCT ' +
													'wt.wait_type + ' +
														--TODO: What else can be pulled from the resource_description?
														'CASE ' +
															'WHEN wt.wait_type LIKE ''PAGE%LATCH_%'' THEN ' +
																''':'' + ' +
																--database name
																'COALESCE(DB_NAME(CONVERT(INT, LEFT(wt.resource_description, CHARINDEX('':'', wt.resource_description) - 1))), ''(null)'') + ' +
																''':'' + ' +
																--file id
																'SUBSTRING(wt.resource_description, CHARINDEX('':'', wt.resource_description) + 1, LEN(wt.resource_description) - CHARINDEX('':'', REVERSE(wt.resource_description)) - CHARINDEX('':'', wt.resource_description)) + ' +
																--page # for special pages
																'''('' + ' +
																	'CASE ' +
																		'WHEN ' +
																			'CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX('':'', REVERSE(wt.resource_description)) - 1)) = 1 OR ' +
																			'CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX('':'', REVERSE(wt.resource_description)) - 1)) % 8088 = 0 THEN ''PFS'' ' +
																		'WHEN ' +
																			'CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX('':'', REVERSE(wt.resource_description)) - 1)) = 2 OR ' +
																			'CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX('':'', REVERSE(wt.resource_description)) - 1)) % 511232 = 0 THEN ''GAM'' ' +
																		'WHEN ' +
																			'CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX('':'', REVERSE(wt.resource_description)) - 1)) = 3 OR ' +
																			'CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX('':'', REVERSE(wt.resource_description)) - 1)) % 511233 = 0 THEN ''SGAM'' ' +
																		'WHEN ' +
																			'CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX('':'', REVERSE(wt.resource_description)) - 1)) = 6 OR ' +
																			'CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX('':'', REVERSE(wt.resource_description)) - 1)) % 511238 = 0 THEN ''DCM'' ' +
																		'WHEN ' +
																			'CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX('':'', REVERSE(wt.resource_description)) - 1)) = 7 OR ' +
																			'CONVERT(INT, RIGHT(wt.resource_description, CHARINDEX('':'', REVERSE(wt.resource_description)) - 1)) % 511239 = 0 THEN ''BCM'' ' +
																		'ELSE ''*'' ' +
																	'END + ' +
																''')'' ' +
															'ELSE '''' ' + 
														'END AS wait_type, ' + 
													'wt.wait_duration_ms, ' +
													'wt.session_id, ' +
													'wt.waiting_task_address, ' +
													'CASE ' +
														'WHEN wt.blocking_session_id <> wt.session_id THEN wt.blocking_session_id ' +
														'ELSE NULL ' +
													'END AS blocking_session_id ' + 
												'FROM sys.dm_os_waiting_tasks wt ' +
											') wt1 ' +
											'GROUP BY ' +
												'wt1.wait_type, ' +
												'wt1.session_id, ' +
												'wt1.waiting_task_address ' +
										') wt2 ON ' + 
											'wt2.session_id = t.session_id ' +
											'AND wt2.waiting_task_address = t.task_address ' +
										'WHERE ' +
											't.session_id = y.session_id ' +
											'AND t.request_id = y.request_id ' +
									') w1 ' +
								') w2 ' +
							') waits ' +
							'ORDER BY ' +
								'waits.r ' +
							'FOR XML PATH(''tasks'') ' +
						') tasks_raw (task_xml_raw) ' +
					') tasks_final ' +
				') AS tasks ' +
				CASE 
					WHEN NOT (@GET_AVG_TIME = 1 AND @recursion = 1) THEN CONVERT(NVARCHAR(MAX), '')
					ELSE
						'LEFT OUTER JOIN sys.dm_exec_query_stats qs ON ' +
							'qs.sql_handle = y.sql_handle ' + 
							'AND qs.plan_handle = y.plan_handle ' + 
							'AND qs.statement_start_offset = y.statement_start_offset ' +
							'AND qs.statement_end_offset = y.statement_end_offset '
					END + 
			') x; ';

		INSERT #sessions
		(
			recursion,
			session_id,
			request_id,
			session_number,
			elapsed_time,
			avg_elapsed_time,
			physical_io,
			reads,
			physical_reads,
			writes,
			tempdb_writes,
			tempdb_current,
			CPU,
			context_switches,
			used_memory,
			threads,
			status,
			wait_info,
			tran_start_time,
			tran_log_writes,
			open_tran_count,
			sql_handle,
			statement_start_offset,
			statement_end_offset,		
			sql_text,
			plan_handle,
			blocking_session_id,
			percent_complete,
			host_name,
			login_name,
			database_name,
			start_time,
			last_request_start_time
		)
		EXEC sp_executesql 
			@sql,
			N'@recursion SMALLINT, @SPID SMALLINT',
			@recursion, @SPID;

		IF 
			@recursion = 1
			AND @OUTPUT_COLUMN_LIST LIKE '%|[sql_text|]%' ESCAPE '|'
		BEGIN
			DECLARE	
				@sql_handle VARBINARY(64),
				@statement_start_offset INT,
				@statement_end_offset INT;

			DECLARE sql_cursor
			CURSOR LOCAL FORWARD_ONLY DYNAMIC OPTIMISTIC
			FOR 
				SELECT 
					sql_handle,
					statement_start_offset,
					statement_end_offset
				FROM #sessions
				WHERE
					recursion = 1
			FOR UPDATE OF 
				sql_text
			OPTION (KEEPFIXED PLAN);

			OPEN sql_cursor;

			FETCH NEXT FROM sql_cursor
			INTO 
				@sql_handle,
				@statement_start_offset,
				@statement_end_offset;

			--Wait up to 5 ms for the SQL text, then give up
			SET LOCK_TIMEOUT 5;

			WHILE @@FETCH_STATUS = 0
			BEGIN;
				BEGIN TRY;
					UPDATE s
					SET
						s.sql_text =
						(
							SELECT
								REPLACE
								(
									REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
									REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
									REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
										CONVERT
										(
											VARCHAR(MAX),
											'--' + CHAR(13) + CHAR(10) +
											CASE @GET_FULL_INNER_TEXT
												WHEN 1 THEN est.text
												ELSE
													CASE
														WHEN @statement_start_offset > 0 THEN
															SUBSTRING
															(
																CONVERT(VARCHAR(MAX), est.text),
																((@statement_start_offset/2) + 1),
																(
																	CASE
																		WHEN @statement_end_offset = -1 THEN 2147483647
																		ELSE ((@statement_end_offset - @statement_start_offset)/2) + 1
																	END
																)
															)
														ELSE RTRIM(LTRIM(est.text))
													END
											END +
											CHAR(13) + CHAR(10) + '--' COLLATE Latin1_General_BIN2
										),
										CHAR(31),''),CHAR(30),''),CHAR(29),''),CHAR(28),''),CHAR(27),''),CHAR(26),''),CHAR(25),''),CHAR(24),''),CHAR(23),''),CHAR(22),''),
										CHAR(21),''),CHAR(20),''),CHAR(19),''),CHAR(18),''),CHAR(17),''),CHAR(16),''),CHAR(15),''),CHAR(14),''),CHAR(12),''),
										CHAR(11),''),CHAR(8),''),CHAR(7),''),CHAR(6),''),CHAR(5),''),CHAR(4),''),CHAR(3),''),CHAR(2),''),CHAR(1),''),
									CHAR(0),
									''
								) AS [processing-instruction(query)]
							FROM sys.dm_exec_sql_text(@sql_handle) est
							FOR XML PATH(''), TYPE
					)
					FROM #sessions s
					WHERE 
						CURRENT OF sql_cursor
					OPTION (KEEPFIXED PLAN);
				END TRY
				BEGIN CATCH;
					UPDATE s
					SET
						s.sql_text = '<timeout_exceeded />'
					FROM #sessions s
					WHERE 
						CURRENT OF sql_cursor
					OPTION (KEEPFIXED PLAN);
				END CATCH;

				FETCH NEXT FROM sql_cursor
				INTO
					@sql_handle,
					@statement_start_offset,
					@statement_end_offset;
			END;

			--Return this to the default
			SET LOCK_TIMEOUT -1;

			CLOSE sql_cursor;
			DEALLOCATE sql_cursor;
		END;

		IF 
			@GET_OUTER_COMMAND = 1 
			AND @recursion = 1
			AND @OUTPUT_COLUMN_LIST LIKE '%|[sql_command|]%' ESCAPE '|'
		BEGIN;
			DECLARE 
				@session_id INT,
				@start_time DATETIME;

			DECLARE @buffer_results TABLE
			(
				EventType VARCHAR(30),
				Parameters INT,
				EventInfo VARCHAR(4000),
				start_time DATETIME,
				session_number INT IDENTITY(1,1) NOT NULL PRIMARY KEY
			);

			DECLARE buffer_cursor
			CURSOR LOCAL FAST_FORWARD
			FOR 
				SELECT 
					session_id,
					MAX(start_time) AS start_time
				FROM #sessions
				WHERE
					recursion = 1
				GROUP BY
					session_id
				ORDER BY
					session_id
				OPTION (KEEPFIXED PLAN);

			OPEN buffer_cursor;

			FETCH NEXT FROM buffer_cursor
			INTO 
				@session_id,
				@start_time;

			WHILE @@FETCH_STATUS = 0
			BEGIN;
				BEGIN TRY;
					--In SQL Server 2008, DBCC INPUTBUFFER will throw 
					--an exception if the session no longer exists
					INSERT @buffer_results
					(
						EventType,
						Parameters,
						EventInfo
					)
					EXEC sp_executesql
						N'DBCC INPUTBUFFER(@session_id) WITH NO_INFOMSGS;',
						N'@session_id INT',
						@session_id;

					UPDATE br
					SET
						br.start_time = @start_time
					FROM @buffer_results br
					WHERE
						br.session_number = 
						(
							SELECT MAX(br2.session_number)
							FROM @buffer_results br2
						);
				END TRY
				BEGIN CATCH
				END CATCH;

				FETCH NEXT FROM buffer_cursor
				INTO 
					@session_id,
					@start_time;
			END;

			UPDATE s
			SET
				sql_command = 
				(
					SELECT 
						REPLACE
						(
							REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
							REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
							REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
								CONVERT
								(
									VARCHAR(MAX),
									'--' + CHAR(13) + CHAR(10) + br.EventInfo + CHAR(13) + CHAR(10) + '--' COLLATE Latin1_General_BIN2
								),
								CHAR(31),''),CHAR(30),''),CHAR(29),''),CHAR(28),''),CHAR(27),''),CHAR(26),''),CHAR(25),''),CHAR(24),''),CHAR(23),''),CHAR(22),''),
								CHAR(21),''),CHAR(20),''),CHAR(19),''),CHAR(18),''),CHAR(17),''),CHAR(16),''),CHAR(15),''),CHAR(14),''),CHAR(12),''),
								CHAR(11),''),CHAR(8),''),CHAR(7),''),CHAR(6),''),CHAR(5),''),CHAR(4),''),CHAR(3),''),CHAR(2),''),CHAR(1),''),
							CHAR(0),
							''
						) AS [processing-instruction(query)]
					FROM @buffer_results br
					WHERE 
						br.session_number = s.session_number
						AND br.start_time = s.start_time
						AND 
						(
							(
								s.start_time = s.last_request_start_time
								AND EXISTS
								(
									SELECT *
									FROM sys.dm_exec_requests r2
									WHERE
										r2.session_id = s.session_id
										AND r2.request_id = s.request_id
										AND r2.start_time = s.start_time
								)
							)
							OR 
							(
								s.status = 'sleeping'
								AND EXISTS
								(
									SELECT *
									FROM sys.dm_exec_sessions s2
									WHERE
										s2.session_id = s.session_id
										AND s2.last_request_start_time = s.last_request_start_time
								)
							)
						)
					FOR XML PATH(''), TYPE
				)
			FROM #sessions s
			WHERE
				recursion = 1
			OPTION (KEEPFIXED PLAN);

			CLOSE buffer_cursor;
			DEALLOCATE buffer_cursor;
		END;

		IF 
			@GET_PLANS = 1 
			AND @recursion = 1
			AND @OUTPUT_COLUMN_LIST LIKE '%|[query_plan|]%' ESCAPE '|'
		BEGIN;
			DECLARE	@plan_handle VARBINARY(64);

			DECLARE plan_cursor
			CURSOR LOCAL FORWARD_ONLY DYNAMIC OPTIMISTIC
			FOR 
				SELECT 
					plan_handle
				FROM #sessions
				WHERE
					recursion = 1
			FOR UPDATE OF 
				query_plan
			OPTION (KEEPFIXED PLAN);

			OPEN plan_cursor;

			FETCH NEXT FROM plan_cursor
			INTO 
				@plan_handle;

			--Wait up to 5 ms for a query plan, then give up
			SET LOCK_TIMEOUT 5;

			WHILE @@FETCH_STATUS = 0
			BEGIN;
				BEGIN TRY;
					UPDATE s
					SET
						s.query_plan =
						(
							SELECT query_plan
							FROM sys.dm_exec_query_plan(@plan_handle)
						)
					FROM #sessions s
					WHERE 
						CURRENT OF plan_cursor
					OPTION (KEEPFIXED PLAN);
				END TRY
				BEGIN CATCH;
					UPDATE s
					SET
						s.query_plan = '<timeout_exceeded />'
					FROM #sessions s
					WHERE 
						CURRENT OF plan_cursor
					OPTION (KEEPFIXED PLAN);
				END CATCH;

				FETCH NEXT FROM plan_cursor
				INTO
					@plan_handle;
			END;

			--Return this to the default
			SET LOCK_TIMEOUT -1;

			CLOSE plan_cursor;
			DEALLOCATE plan_cursor;
		END;

		IF 
			@GET_LOCKS = 1 
			AND @recursion = 1
			AND @OUTPUT_COLUMN_LIST LIKE '%|[locks|]%' ESCAPE '|'
		BEGIN;
			DECLARE @DB_NAME sysname;

			DECLARE locks_cursor
			CURSOR LOCAL FAST_FORWARD
			FOR 
				SELECT DISTINCT
					db_name
				FROM #locks
				WHERE
					EXISTS
					(
						SELECT *
						FROM #sessions s
						WHERE
							s.session_id = #locks.session_id
							AND recursion = 1
					)
					AND db_name <> '(null)'
				OPTION (KEEPFIXED PLAN);

			OPEN locks_cursor;

			FETCH NEXT  FROM locks_cursor
			INTO @DB_NAME;

			WHILE @@FETCH_STATUS = 0
			BEGIN;
				BEGIN TRY;
					SET @sql = CONVERT(NVARCHAR(MAX), '') +
						'UPDATE l ' +
						'SET ' +
							'object_name = o.name, ' +
							'index_name = i.name, ' +
							'schema_name = s.name, ' +
							'principal_name = dp.name ' +
						'FROM #locks l ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@DB_NAME) + '.sys.allocation_units au ON ' +
							'au.allocation_unit_id = l.allocation_unit_id ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@DB_NAME) + '.sys.partitions p ON ' +
							'p.hobt_id = ' +
								'COALESCE ' +
								'( ' +
									'l.hobt_id, ' +
									'CASE ' +
										'WHEN au.type IN (1, 3) THEN au.container_id ' +
										'ELSE NULL ' +
									'END ' +
								') ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@DB_NAME) + '.sys.partitions p1 ON ' +
							'l.hobt_id IS NULL ' +
							'AND au.type = 2 ' +
							'AND p1.partition_id = au.container_id ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@DB_NAME) + '.sys.objects o ON ' +
							'o.object_id = COALESCE(l.object_id, p.object_id, p1.object_id) ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@DB_NAME) + '.sys.indexes i ON ' +
							'i.object_id = COALESCE(l.object_id, p.object_id, p1.object_id) ' +
							'AND i.index_id = COALESCE(l.index_id, p.index_id, p1.index_id) ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@DB_NAME) + '.sys.schemas s ON ' +
							's.schema_id = COALESCE(l.schema_id, o.schema_id) ' +
						'LEFT OUTER JOIN ' + QUOTENAME(@DB_NAME) + '.sys.database_principals dp ON ' +
							'dp.principal_id = l.principal_id ' +
						'WHERE ' +
							'l.db_name = @DB_NAME ' +
						'OPTION (KEEPFIXED PLAN); ';

					EXEC sp_executesql
						@sql,
						N'@DB_NAME sysname',
						@DB_NAME;
				END TRY
				BEGIN CATCH;
					UPDATE #locks
					SET 
						object_name = '(db_inaccessible)'
					WHERE 
						db_name = @DB_NAME
					OPTION (KEEPFIXED PLAN);
				END CATCH;

				FETCH NEXT  FROM locks_cursor
				INTO @DB_NAME;
			END;

			CLOSE locks_cursor;
			DEALLOCATE locks_cursor;

			CREATE CLUSTERED INDEX IX_SRD ON #locks (session_id, request_id, db_name);

			UPDATE s
			SET 
				s.locks =
				(
					SELECT 
						REPLACE
						(
							REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
							REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
							REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
								CONVERT
								(
									VARCHAR(MAX), 
									l1.db_name COLLATE Latin1_General_BIN2
								),
								CHAR(31),''),CHAR(30),''),CHAR(29),''),CHAR(28),''),CHAR(27),''),CHAR(26),''),CHAR(25),''),CHAR(24),''),CHAR(23),''),CHAR(22),''),
								CHAR(21),''),CHAR(20),''),CHAR(19),''),CHAR(18),''),CHAR(17),''),CHAR(16),''),CHAR(15),''),CHAR(14),''),CHAR(12),''),
								CHAR(11),''),CHAR(8),''),CHAR(7),''),CHAR(6),''),CHAR(5),''),CHAR(4),''),CHAR(3),''),CHAR(2),''),CHAR(1),''),
							CHAR(0),
							''
						) AS [Database/@name],
						(
							SELECT 
								l2.request_mode AS [Lock/@request_mode],
								l2.request_status AS [Lock/@request_status]
							FROM #locks l2
							WHERE 
								l1.session_id = l2.session_id
								AND l1.request_id = l2.request_id
								AND l2.db_name = l1.db_name
								AND l2.resource_type = 'DATABASE'
							FOR XML PATH(''), TYPE
						) AS [Database/Locks],
						(
							SELECT
								COALESCE(l3.object_name, '(null)') AS [Object/@name],
								l3.schema_name AS [Object/@schema_name],
								(
									SELECT
										l4.resource_type AS [Lock/@resource_type],
										l4.page_type AS [Lock/@page_type],
										REPLACE
										(
											REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
											REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
											REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
												CONVERT
												(
													VARCHAR(MAX), 
													l4.index_name COLLATE Latin1_General_BIN2
												),
												CHAR(31),''),CHAR(30),''),CHAR(29),''),CHAR(28),''),CHAR(27),''),CHAR(26),''),CHAR(25),''),CHAR(24),''),CHAR(23),''),CHAR(22),''),
												CHAR(21),''),CHAR(20),''),CHAR(19),''),CHAR(18),''),CHAR(17),''),CHAR(16),''),CHAR(15),''),CHAR(14),''),CHAR(12),''),
												CHAR(11),''),CHAR(8),''),CHAR(7),''),CHAR(6),''),CHAR(5),''),CHAR(4),''),CHAR(3),''),CHAR(2),''),CHAR(1),''),
											CHAR(0),
											''
										) AS [Lock/@index_name],
										REPLACE
										(
											REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
											REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
											REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
												CONVERT
												(
													VARCHAR(MAX), 								
													CASE 
														WHEN l4.object_name IS NULL THEN l4.schema_name
														ELSE NULL
													END COLLATE Latin1_General_BIN2
												),
												CHAR(31),''),CHAR(30),''),CHAR(29),''),CHAR(28),''),CHAR(27),''),CHAR(26),''),CHAR(25),''),CHAR(24),''),CHAR(23),''),CHAR(22),''),
												CHAR(21),''),CHAR(20),''),CHAR(19),''),CHAR(18),''),CHAR(17),''),CHAR(16),''),CHAR(15),''),CHAR(14),''),CHAR(12),''),
												CHAR(11),''),CHAR(8),''),CHAR(7),''),CHAR(6),''),CHAR(5),''),CHAR(4),''),CHAR(3),''),CHAR(2),''),CHAR(1),''),
											CHAR(0),
											''
										) AS [Lock/@schema_name],
										REPLACE
										(
											REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
											REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
											REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
												CONVERT
												(
													VARCHAR(MAX), 								
													l4.principal_name COLLATE Latin1_General_BIN2
												),
												CHAR(31),''),CHAR(30),''),CHAR(29),''),CHAR(28),''),CHAR(27),''),CHAR(26),''),CHAR(25),''),CHAR(24),''),CHAR(23),''),CHAR(22),''),
												CHAR(21),''),CHAR(20),''),CHAR(19),''),CHAR(18),''),CHAR(17),''),CHAR(16),''),CHAR(15),''),CHAR(14),''),CHAR(12),''),
												CHAR(11),''),CHAR(8),''),CHAR(7),''),CHAR(6),''),CHAR(5),''),CHAR(4),''),CHAR(3),''),CHAR(2),''),CHAR(1),''),
											CHAR(0),
											''
										) AS [Lock/@principal_name],
										l4.resource_description AS [Lock/@resource_description],
										l4.request_mode AS [Lock/@request_mode],
										l4.request_status AS [Lock/@request_status],
										SUM(l4.request_count) AS [Lock/@request_count]
									FROM #locks l4
									WHERE 
										l4.session_id = l3.session_id
										AND l4.request_id = l3.request_id
										AND l3.db_name = l4.db_name
										AND COALESCE(l3.object_name, '(null)') = COALESCE(l4.object_name, '(null)')
										AND COALESCE(l3.schema_name, '') = COALESCE(l4.schema_name, '')
										AND l4.resource_type <> 'DATABASE'
									GROUP BY
										l4.resource_type,
										l4.page_type,
										l4.index_name,
										CASE 
											WHEN l4.object_name IS NULL THEN l4.schema_name
											ELSE NULL
										END,
										l4.principal_name,
										l4.resource_description,
										l4.request_mode,
										l4.request_status
									FOR XML PATH(''), TYPE
								) AS [Object/Locks]
							FROM #locks l3
							WHERE 
								l3.session_id = l1.session_id
								AND l3.request_id = l1.request_id
								AND l3.db_name = l1.db_name
								AND l3.resource_type <> 'DATABASE'
							GROUP BY 
								l3.session_id,
								l3.request_id,
								l3.db_name,
								COALESCE(l3.object_name, '(null)'),
								l3.schema_name
							FOR XML PATH(''), TYPE
						) AS [Database/Objects]
					FROM #locks l1
					WHERE
						l1.session_id = s.session_id
						AND l1.request_id = COALESCE(s.request_id, -1)
						AND 
						(
							(
								s.request_id IS NULL 
								AND l1.start_time = s.last_request_start_time
							)
							OR
							(
								s.request_id IS NOT NULL 
								AND l1.start_time = s.start_time
							)
						)
						AND s.recursion = 1
					GROUP BY 
						l1.session_id,
						l1.request_id,
						l1.db_name
					FOR XML PATH(''), TYPE
				)
			FROM #sessions s
			OPTION (KEEPFIXED PLAN);
		END;
		
		IF 
			@DELTA_INTERVAL > 0 
			AND @recursion <> 1
		BEGIN;
			SET @recursion = 1;

			DECLARE @delay_time CHAR(12);
			SET @delay_time = CONVERT(VARCHAR, DATEADD(second, @DELTA_INTERVAL, 0), 114);
			WAITFOR DELAY @delay_time;

			GOTO REDO;
		END;
	END;

	SET @sql = CONVERT(NVARCHAR(MAX), '') +
		CASE
			WHEN 
				@DESTINATION_TABLE <> '' 
				AND @RETURN_SCHEMA = 0 
					THEN 'INSERT ' + @DESTINATION_TABLE + ' '
			ELSE CONVERT(NVARCHAR(MAX), '') 
		END +
		'SELECT ' +
			@OUTPUT_COLUMN_LIST + ' ' +
		CASE @RETURN_SCHEMA
			WHEN 1 THEN 'INTO #session_schema '
			ELSE CONVERT(NVARCHAR(MAX), '')
		END + 
		'FROM ' +
		'( ' +
			'SELECT ' +
				'session_id, ' +
				--[dd hh:mm:ss.mss]
				CASE @FORMAT_OUTPUT
					WHEN 1 THEN
						'CASE ' +
							'WHEN elapsed_time < 0 THEN ' +
								'RIGHT ' +
								'( ' +
									'''00'' + CONVERT(VARCHAR, (-1 * elapsed_time) / 86400), ' +
									'2 ' +
								') + ' +
									'RIGHT ' +
									'( ' +
										'CONVERT(VARCHAR, DATEADD(second, (-1 * elapsed_time), 0), 120), ' +
										'9 ' +
									') + ' +
									'''.000'' ' +
							'ELSE ' +
								'RIGHT ' +
								'( ' +
									'''00'' + CONVERT(VARCHAR, elapsed_time / 86400000), ' +
									'2 ' +
								') + ' +
									'RIGHT ' +
									'( ' +
										'CONVERT(VARCHAR, DATEADD(second, elapsed_time / 1000, 0), 120), ' +
										'9 ' +
									') + ' +
									'''.'' + ' + 
									'RIGHT(''000'' + CONVERT(VARCHAR, elapsed_time % 1000), 3) ' +
						'END AS [dd hh:mm:ss.mss], '
					ELSE
						CONVERT(NVARCHAR(MAX), '')
				END +
				--[dd hh:mm:ss.mss (avg)] / avg_elapsed_time
				CASE @FORMAT_OUTPUT
					WHEN 1 THEN 
						'RIGHT ' +
						'( ' +
							'''00'' + CONVERT(VARCHAR, avg_elapsed_time / 86400000), ' +
							'2 ' +
						') + ' +
							'RIGHT ' +
							'( ' +
								'CONVERT(VARCHAR, DATEADD(second, avg_elapsed_time / 1000, 0), 120), ' +
								'9 ' +
							') + ' +
							'''.'' + ' +
							'RIGHT(''000'' + CONVERT(VARCHAR, avg_elapsed_time % 1000), 3) AS [dd hh:mm:ss.mss (avg)], '
					ELSE
						CONVERT(NVARCHAR(MAX), 'avg_elapsed_time, ')
				END +
				--physical_io
				CASE @FORMAT_OUTPUT
					WHEN 1 THEN 'LTRIM(LEFT(CONVERT(CHAR(30), CONVERT(MONEY, physical_io), 1), 27)) AS '
					ELSE CONVERT(NVARCHAR(MAX), '')
				END + 'physical_io, ' +
				--reads
				CASE @FORMAT_OUTPUT
					WHEN 1 THEN 'LTRIM(LEFT(CONVERT(CHAR(30), CONVERT(MONEY, reads), 1), 27)) AS '
					ELSE CONVERT(NVARCHAR(MAX), '')
				END + 'reads, ' +
				--physical_reads
				CASE @FORMAT_OUTPUT
					WHEN 1 THEN 'LTRIM(LEFT(CONVERT(CHAR(30), CONVERT(MONEY, physical_reads), 1), 27)) AS '
					ELSE CONVERT(NVARCHAR(MAX), '')
				END + 'physical_reads, ' +
				--writes
				CASE @FORMAT_OUTPUT
					WHEN 1 THEN 'LTRIM(LEFT(CONVERT(CHAR(30), CONVERT(MONEY, writes), 1), 27)) AS '
					ELSE CONVERT(NVARCHAR(MAX), '')
				END + 'writes, ' +
				--tempdb_writes
				CASE @FORMAT_OUTPUT
					WHEN 1 THEN 'LTRIM(LEFT(CONVERT(CHAR(30), CONVERT(MONEY, tempdb_writes), 1), 27)) AS '
					ELSE CONVERT(NVARCHAR(MAX), '')
				END + 'tempdb_writes, ' +
				--tempdb_current
				CASE @FORMAT_OUTPUT
					WHEN 1 THEN 'LTRIM(LEFT(CONVERT(CHAR(30), CONVERT(MONEY, tempdb_current), 1), 27)) AS '
					ELSE CONVERT(NVARCHAR(MAX), '')
				END + 'tempdb_current, ' +
				--CPU
				CASE @FORMAT_OUTPUT
					WHEN 1 THEN 'LTRIM(LEFT(CONVERT(CHAR(30), CONVERT(MONEY, CPU), 1), 27)) AS '
					ELSE CONVERT(NVARCHAR(MAX), '')
				END + 'CPU, ' +
				--context_switches
				CASE @FORMAT_OUTPUT
					WHEN 1 THEN 'LTRIM(LEFT(CONVERT(CHAR(30), CONVERT(MONEY, context_switches), 1), 27)) AS '
					ELSE CONVERT(NVARCHAR(MAX), '')
				END + 'context_switches, ' +
				--used_memory
				CASE @FORMAT_OUTPUT
					WHEN 1 THEN 'LTRIM(LEFT(CONVERT(CHAR(30), CONVERT(MONEY, used_memory), 1), 27)) AS '
					ELSE CONVERT(NVARCHAR(MAX), '')
				END + 'used_memory, ' +
				--physical_io_delta			
				'CASE ' +
					'WHEN ' +
						'first_request_start_time = last_request_start_time ' + 
						'AND num_events = 2 ' +
						'AND physical_io_delta >= 0 ' +
							'THEN ' +
							CASE @FORMAT_OUTPUT
								WHEN 1 THEN 'LTRIM(LEFT(CONVERT(CHAR(30), CONVERT(MONEY, physical_io_delta), 1), 27)) ' 
								ELSE CONVERT(NVARCHAR(MAX), 'physical_io_delta ')
							END +
					'ELSE NULL ' +
				'END AS physical_io_delta, ' +
				--reads_delta
				'CASE ' +
					'WHEN ' +
						'first_request_start_time = last_request_start_time ' + 
						'AND num_events = 2 ' +
						'AND reads_delta >= 0 ' +
							'THEN ' +
							CASE @FORMAT_OUTPUT
								WHEN 1 THEN 'LTRIM(LEFT(CONVERT(CHAR(30), CONVERT(MONEY, reads_delta), 1), 27)) '
								ELSE CONVERT(NVARCHAR(MAX), 'reads_delta ')
							END +
					'ELSE NULL ' +
				'END AS reads_delta, ' +
				--physical_reads_delta
				'CASE ' +
					'WHEN ' +
						'first_request_start_time = last_request_start_time ' + 
						'AND num_events = 2 ' +
						'AND physical_reads_delta >= 0 ' +
							'THEN ' +
							CASE @FORMAT_OUTPUT
								WHEN 1 THEN 'LTRIM(LEFT(CONVERT(CHAR(30), CONVERT(MONEY, physical_reads_delta), 1), 27)) '
								ELSE CONVERT(NVARCHAR(MAX), 'physical_reads_delta ')
							END + 
					'ELSE NULL ' +
				'END AS physical_reads_delta, ' +
				--writes_delta
				'CASE ' +
					'WHEN ' +
						'first_request_start_time = last_request_start_time ' + 
						'AND num_events = 2 ' +
						'AND writes_delta >= 0 ' +
							'THEN ' +
							CASE @FORMAT_OUTPUT
								WHEN 1 THEN 'LTRIM(LEFT(CONVERT(CHAR(30), CONVERT(MONEY, writes_delta), 1), 27)) '
								ELSE CONVERT(NVARCHAR(MAX), 'writes_delta ')
							END + 
					'ELSE NULL ' +
				'END AS writes_delta, ' +
				--tempdb_writes_delta
				'CASE ' +
					'WHEN ' +
						'first_request_start_time = last_request_start_time ' + 
						'AND num_events = 2 ' +
						'AND tempdb_writes_delta >= 0 ' +
							'THEN ' +
							CASE @FORMAT_OUTPUT
								WHEN 1 THEN 'LTRIM(LEFT(CONVERT(CHAR(30), CONVERT(MONEY, tempdb_writes_delta), 1), 27)) '
								ELSE CONVERT(NVARCHAR(MAX), 'tempdb_writes_delta ')
							END + 
					'ELSE NULL ' +
				'END AS tempdb_writes_delta, ' +
				--tempdb_current_delta
				--this is the only one that can (legitimately) go negative 
				'CASE ' +
					'WHEN ' +
						'first_request_start_time = last_request_start_time ' + 
						'AND num_events = 2 ' +
							'THEN ' +
							CASE @FORMAT_OUTPUT
								WHEN 1 THEN 'LTRIM(LEFT(CONVERT(CHAR(30), CONVERT(MONEY, tempdb_current_delta), 1), 27)) '
								ELSE CONVERT(NVARCHAR(MAX), 'tempdb_current_delta ')
							END + 
					'ELSE NULL ' +
				'END AS tempdb_current_delta, ' +
				--CPU_delta
				'CASE ' +
					'WHEN ' +
						'first_request_start_time = last_request_start_time ' + 
						'AND num_events = 2 ' +
						'AND CPU_delta >= 0 ' +
							'THEN ' +
							CASE @FORMAT_OUTPUT
								WHEN 1 THEN 'LTRIM(LEFT(CONVERT(CHAR(30), CONVERT(MONEY, CPU_delta), 1), 27)) '
								ELSE CONVERT(NVARCHAR(MAX), 'CPU_delta ')
							END + 
					'ELSE NULL ' +
				'END AS CPU_delta, ' +
				--context_switches_delta
				'CASE ' +
					'WHEN ' +
						'first_request_start_time = last_request_start_time ' + 
						'AND num_events = 2 ' +
						'AND context_switches_delta >= 0 ' +
							'THEN ' +
							CASE @FORMAT_OUTPUT
								WHEN 1 THEN 'LTRIM(LEFT(CONVERT(CHAR(30), CONVERT(MONEY, context_switches_delta), 1), 27)) '
								ELSE CONVERT(NVARCHAR(MAX), 'context_switches_delta ')
							END + 
					'ELSE NULL ' +
				'END AS context_switches_delta, ' +
				--used_memory_delta
				'CASE ' +
					'WHEN ' +
						'first_request_start_time = last_request_start_time ' + 
						'AND num_events = 2 ' +
						'AND used_memory_delta >= 0 ' +
							'THEN ' +
							CASE @FORMAT_OUTPUT
								WHEN 1 THEN 'LTRIM(LEFT(CONVERT(CHAR(30), CONVERT(MONEY, used_memory_delta), 1), 27)) '
								ELSE CONVERT(NVARCHAR(MAX), 'used_memory_delta ')
							END + 
					'ELSE NULL ' +
				'END AS used_memory_delta, ' +			
				'threads, ' +
				'status, ' +
				'LEFT(wait_info, LEN(wait_info) - 1) AS wait_info, ' +
				'locks, ' +
				'tran_start_time, ' +
				'LEFT(tran_log_writes, LEN(tran_log_writes) - 1) AS tran_log_writes, ' +
				'open_tran_count, ' +
				--sql_command
				CASE @FORMAT_OUTPUT 
					WHEN 0 THEN 'REPLACE(REPLACE(CONVERT(VARCHAR(MAX), sql_command), ''<?query --''+CHAR(13)+CHAR(10), ''''), CHAR(13)+CHAR(10)+''--?>'', '''') AS '
					ELSE CONVERT(NVARCHAR(MAX), '')
				END + 'sql_command, ' +
				--sql_text
				CASE @FORMAT_OUTPUT 
					WHEN 0 THEN 'REPLACE(REPLACE(CONVERT(VARCHAR(MAX), sql_text), ''<?query --''+CHAR(13)+CHAR(10), ''''), CHAR(13)+CHAR(10)+''--?>'', '''') AS '
					ELSE CONVERT(NVARCHAR(MAX), '')
				END + 'sql_text, ' +
				'query_plan, ' +
				'blocking_session_id, ' +
				'percent_complete, ' +
				'host_name, ' +
				'login_name, ' +
				'database_name, ' +
				'start_time, ' +
				'request_id, ' +
				'GETDATE() AS collection_time ' +
			'FROM ' +
			'( ' + 
				'SELECT TOP(2147483647) ' +
					'*, ' +
					'MAX(physical_io * recursion) OVER (PARTITION BY session_id, request_id) + ' +
						'MIN(physical_io * recursion) OVER (PARTITION BY session_id, request_id) AS physical_io_delta, ' +
					'MAX(reads * recursion) OVER (PARTITION BY session_id, request_id) + ' +
						'MIN(reads * recursion) OVER (PARTITION BY session_id, request_id) AS reads_delta, ' +
					'MAX(physical_reads * recursion) OVER (PARTITION BY session_id, request_id) + ' +
						'MIN(physical_reads * recursion) OVER (PARTITION BY session_id, request_id) AS physical_reads_delta, ' +
					'MAX(writes * recursion) OVER (PARTITION BY session_id, request_id) + ' +
						'MIN(writes * recursion) OVER (PARTITION BY session_id, request_id) AS writes_delta, ' +
					'MAX(tempdb_writes * recursion) OVER (PARTITION BY session_id, request_id) + ' +
						'MIN(tempdb_writes * recursion) OVER (PARTITION BY session_id, request_id) AS tempdb_writes_delta, ' +
					'MAX(tempdb_current * recursion) OVER (PARTITION BY session_id, request_id) + ' +
						'MIN(tempdb_current * recursion) OVER (PARTITION BY session_id, request_id) AS tempdb_current_delta, ' +
					'MAX(CPU * recursion) OVER (PARTITION BY session_id, request_id) + ' +
						'MIN(CPU * recursion) OVER (PARTITION BY session_id, request_id) AS CPU_delta, ' +
					'MAX(context_switches * recursion) OVER (PARTITION BY session_id, request_id) + ' +
						'MIN(context_switches * recursion) OVER (PARTITION BY session_id, request_id) AS context_switches_delta, ' +
					'MAX(used_memory * recursion) OVER (PARTITION BY session_id, request_id) + ' +
						'MIN(used_memory * recursion) OVER (PARTITION BY session_id, request_id) AS used_memory_delta, ' +
					'MIN(last_request_start_time) OVER (PARTITION BY session_id, request_id) AS first_request_start_time, ' +
					'COUNT(*) OVER (PARTITION BY session_id, request_id) AS num_events ' +
				'FROM #sessions s1 ' +
				'ORDER BY ' +
					@SORT_COLUMN + ' ' +
					@SORT_COLUMN_DIRECTION + ' ' +
			') s ' +
			'WHERE ' +
				's.recursion = 1 ' +
		') x ' +
		'OPTION (KEEPFIXED PLAN); ' +
		'' +
		CASE @RETURN_SCHEMA
			WHEN 1 THEN 
				'SET @SCHEMA = ' +
					'''CREATE TABLE <table_name> ( '' + ' + 
						'STUFF ' +
						'( ' +
							'( ' +
								'SELECT ' +
									''','' + ' +
									'QUOTENAME(COLUMN_NAME) + '' '' + ' +
									'DATA_TYPE + ' + 
									'CASE DATA_TYPE ' +
										'WHEN ''varchar'' THEN ''('' + COALESCE(NULLIF(CONVERT(VARCHAR, CHARACTER_MAXIMUM_LENGTH), ''-1''), ''max'') + '') '' ' +
										'ELSE '' '' ' +
									'END + ' +
									'CASE IS_NULLABLE ' +
										'WHEN ''NO'' THEN ''NOT '' ' +
										'ELSE '''' ' +
									'END + ''NULL'' AS [text()] ' +
								'FROM tempdb.INFORMATION_SCHEMA.COLUMNS ' +
								'WHERE ' +
									'TABLE_NAME = OBJECT_NAME(OBJECT_ID(''tempdb..#session_schema''), 2) ' +
									'ORDER BY ' +
										'ORDINAL_POSITION ' +
								'FOR XML PATH('''') ' +
							'), + ' +
							'1, ' +
							'1, ' +
							''''' ' +
						') + ' +
					''')''; ' 
			ELSE CONVERT(NVARCHAR(MAX), '')
		END;

	EXEC sp_executesql
		@sql,
		N'@SORT_COLUMN sysname, @SORT_COLUMN_DIRECTION VARCHAR(4), @OUTPUT_COLUMN_LIST VARCHAR(8000), @SCHEMA VARCHAR(MAX) OUTPUT',
		@SORT_COLUMN, @SORT_COLUMN_DIRECTION, @OUTPUT_COLUMN_LIST, @SCHEMA OUTPUT;
END;



GO
/****** Object:  StoredProcedure [dbo].[sp_WriteTextFile]    Script Date: 27/10/2015 09:31:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_WriteTextFile]
(
 @fileName VARCHAR(1000),
 @text VARCHAR(MAX),
 @append BIT = 0
)
AS
DECLARE
 @fileSystemObject INT,
 @textStream INT,
 @returnValue INT,
 --variables for error handling
 @errorStatus varchar(512),
 @errorDescription varchar(512)

--attempt to create the FileSystemObject
EXEC @returnValue = sp_OACreate "Scripting.FileSystemObject", @fileSystemObject OUTPUT, 1

--check for errors
IF @returnValue <> 0 GOTO errorHandler

--determine whether to append this data to the text file or to create a new file, overwriting any existing data
IF @append = 1
BEGIN
 EXEC @returnValue = sp_OAMethod @fileSystemObject,"opentextfile", @textStream OUTPUT, @fileName, 8
 --check for errors
 IF @returnValue <> 0 GOTO errorHandler
END
ELSE
BEGIN
 EXEC @returnValue = sp_OAMethod @fileSystemObject,"createtextfile", @textStream OUTPUT, @fileName, -1
 --check for errors
 IF @returnValue <> 0 GOTO errorHandler
END

EXEC @returnValue = sp_OAMethod @textStream, "write", null, @text
--check for errors
IF @returnValue <> 0 GOTO errorHandler

EXEC @returnValue = sp_OAMethod @textStream,"close"
--check for errors
IF @returnValue <> 0 GOTO errorHandler

--clean up
EXEC sp_OADestroy @textStream
EXEC sp_OADestroy @fileSystemObject

return 0

errorHandler:
 --get error
 EXEC sp_OAGetErrorInfo null, @errorStatus OUTPUT, @errorDescription OUTPUT
 --raise error
 RAISERROR(@errorDescription,16,1)
 --clean up
 EXEC sp_OADestroy @textStream
 EXEC sp_OADestroy @fileSystemObject

 return 1


GO
/****** Object:  StoredProcedure [dbo].[spWriteStringToFile]    Script Date: 27/10/2015 09:31:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[spWriteStringToFile]
(
@String Varchar(max), --8000 in SQL Server 2000
@Path VARCHAR(255),
@Filename VARCHAR(100)

--
)
AS
DECLARE  @objFileSystem int
        ,@objTextStream int,
              @objErrorObject int,
              @strErrorMessage Varchar(1000),
           @Command varchar(1000),
           @hr int,
              @fileAndPath varchar(80)

set nocount on

select @strErrorMessage='opening the File System Object'
EXECUTE @hr = sp_OACreate  'Scripting.FileSystemObject' , @objFileSystem OUT

Select @FileAndPath=@path+'\'+@filename
if @HR=0 Select @objErrorObject=@objFileSystem , @strErrorMessage='Creating file "'+@FileAndPath+'"'
if @HR=0 execute @hr = sp_OAMethod   @objFileSystem   , 'CreateTextFile'
       , @objTextStream OUT, @FileAndPath,2,True

if @HR=0 Select @objErrorObject=@objTextStream, 
       @strErrorMessage='writing to the file "'+@FileAndPath+'"'
if @HR=0 execute @hr = sp_OAMethod  @objTextStream, 'opentextfile', Null, @String
--EXEC @returnValue = sp_OAMethod @fileSystemObject,կpentextfileԬ @textStream OUTPUT, @fileName, 8


if @HR=0 Select @objErrorObject=@objTextStream, @strErrorMessage='closing the file "'+@FileAndPath+'"'
if @HR=0 execute @hr = sp_OAMethod  @objTextStream, 'Close'

if @hr<>0
       begin
       Declare 
              @Source varchar(255),
              @Description Varchar(255),
              @Helpfile Varchar(255),
              @HelpID int
       
       EXECUTE sp_OAGetErrorInfo  @objErrorObject, 
              @source output,@Description output,@Helpfile output,@HelpID output
       Select @strErrorMessage='Error whilst '
                     +coalesce(@strErrorMessage,'doing something')
                     +', '+coalesce(@Description,'')
       raiserror (@strErrorMessage,16,1)
       end
EXECUTE  sp_OADestroy @objTextStream
EXECUTE sp_OADestroy @objTextStream





GO
/****** Object:  StoredProcedure [dbo].[TableSize]    Script Date: 27/10/2015 09:31:01 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER OFF
GO
CREATE  PROCEDURE [dbo].[TableSize] @db varchar(50)='system'
AS


/* Simon D'Morias ammended August 2005 to run in any database from the system db
Also corrected problem whith table names including spaces
*/

	SET NOCOUNT ON
	
	DECLARE @ObjectName sysname, @Owner sysname
	DECLARE @cmd varchar(1000)

	CREATE TABLE #TempInfo (
		[Name] sysname,
		[rows] bigint NULL,
		reserved varchar(20) NULL,
		data varchar(20) NULL,
		index_size varchar(20) NULL,
		unused varchar(20) NULL
		
	)
	
	CREATE TABLE #TableList (
		TABLE_QUALIFIER sysname,
		TABLE_OWNER sysname,
		TABLE_NAME sysname,
		TABLE_TYPE varchar(32),
		REMARKS varchar(254)
	)
	SET @cmd = 'EXEC ['+@db+'].dbo.sp_tables'
	INSERT #TableList EXEC (@cmd)
	
	DECLARE cCursor CURSOR LOCAL FOR
	SELECT TABLE_NAME, TABLE_OWNER
	FROM #TableList (NOLOCK)
	WHERE TABLE_TYPE = 'TABLE'
	
	OPEN cCursor
	
	FETCH NEXT FROM cCursor
	INTO @ObjectName, @Owner
	WHILE @@FETCH_STATUS = 0
	BEGIN
		BEGIN TRY
			SET @cmd = 'EXEC ['+@db+'].dbo.sp_spaceused '''+@Owner+'.'+@objectname+''''
			INSERT #TempInfo EXEC (@cmd)
		END TRY
		BEGIN CATCH
			PRINT @cmd
		END CATCH
	
		FETCH NEXT FROM cCursor INTO @ObjectName, @Owner
	END
	

	CLOSE cCursor
	DEALLOCATE cCursor
	
	SELECT [Name], [rows],
		CAST(REPLACE(reserved, ' KB', '') AS int) AS [reserved_kb],
		CAST(REPLACE(data, ' KB', '') AS int) AS [Data_kb],
		CAST(REPLACE(index_size, ' KB', '') AS int) AS [index_size_kb],
		CAST(REPLACE(unused, ' KB', '') AS int) AS [unused_kb],
		(CAST(REPLACE(reserved, ' KB', '') AS int) - CAST(REPLACE(unused, ' KB', '') AS int)) AS [size_kb]
	FROM #TempInfo
	WHERE [rows] IS NOT NULL
	ORDER BY CAST(REPLACE(data, ' KB', '') AS int) DESC
	
	DROP TABLE #TableList
	DROP TABLE #TempInfo



GO
/****** Object:  StoredProcedure [dbo].[test]    Script Date: 27/10/2015 09:31:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[test]
AS
SELECT  3478 GO

GO
/****** Object:  StoredProcedure [dbo].[test2]    Script Date: 27/10/2015 09:31:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[test2]
AS
SELECT 1

GO
/****** Object:  StoredProcedure [dbo].[usp_Cubic_LoginAndUserMappings]    Script Date: 27/10/2015 09:31:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




create procedure [dbo].[usp_Cubic_LoginAndUserMappings]

as

IF OBJECT_ID(N'tempdb..#results', 'U') IS NOT NULL 
	DROP TABLE #results;

CREATE TABLE #results(
	LoginName sysname
	,LoginType nvarchar(60)
	,DatabaseName sysname NULL
	,DatabaseUserName sysname NULL
	,[db owner] sysname NULL
	,[access admin] sysname NULL
	,[security admin] sysname NULL
	,[ddl admin] sysname NULL
	,[data reader] sysname NULL
	,[data writer] sysname NULL
	,[deny datareader] sysname NULL
	,[deny datawriter] sysname NULL
	,[backup operator] sysname NULL
	);

EXEC sp_MSforeachdb '
USE [?];
INSERT INTO #results
	SELECT
		sp.name AS LoginName
		,sp.type_desc AS LoginType
		,DB_NAME() AS DatabaseName
		,dp.name AS DatabaseUserName
		,CASE r.name WHEN ''db_owner'' THEN ''Yes'' ELSE ''-'' END AS db_owner
		,CASE r.name WHEN ''db_accessadmin'' THEN ''Yes'' ELSE ''-'' END AS db_accessadmin
		,CASE r.name WHEN ''db_securityadmin'' THEN ''Yes'' ELSE ''-'' END AS db_securityadmin
		,CASE r.name WHEN ''db_ddladmin'' THEN ''Yes'' ELSE ''-'' END AS db_ddladmin
		,CASE r.name WHEN ''db_datareader'' THEN ''Yes'' ELSE ''-'' END AS db_datareader
		,CASE r.name WHEN ''db_datawriter'' THEN ''Yes'' ELSE ''-'' END AS db_datawriter
		,CASE r.name WHEN ''db_denydatareader'' THEN ''Yes'' ELSE ''-'' END AS db_denydatareader
		,CASE r.name WHEN ''db_denydatawriter'' THEN ''Yes'' ELSE ''-'' END AS db_denydatawriter
		,CASE r.name WHEN ''db_backupoperator'' THEN ''Yes'' ELSE ''-'' END AS db_backupoperator
	FROM sys.server_principals sp
	LEFT JOIN sys.database_principals dp ON
		dp.sid = sp.sid
	LEFT JOIN sys.database_role_members drm ON
		drm.member_principal_id = dp.principal_id
	LEFT JOIN sys.database_principals r ON
		r.principal_id = drm.role_principal_id
	WHERE r.name IS NOT NULL;'

CREATE TABLE #LoginsUsersRoles(
	LoginName sysname
	,LoginType nvarchar(60)
	,DatabaseName sysname NULL
	,DatabaseUserName sysname NULL
	,[db owner] sysname NULL
	,[access admin] sysname NULL
	,[security admin] sysname NULL
	,[ddl admin] sysname NULL
	,[data reader] sysname NULL
	,[data writer] sysname NULL
	,[deny datareader] sysname NULL
	,[deny datawriter] sysname NULL
	,[backup operator] sysname NULL
	);

insert into #LoginsUsersRoles (
LoginName, LoginType, DatabaseName, DatabaseUserName,
[db owner], [access admin], [security admin], [ddl admin], [data reader],
[data writer], [deny datareader], [deny datawriter], [backup operator]
)
select distinct LoginName, LoginType, DatabaseName, DatabaseUserName,
'-', '-', '-', '-', '-', '-', '-', '-', '-'
from #results

update l
set l.[db owner] = 'Yes'
from #LoginsUsersRoles l, #Results r
where l.DatabaseName = r.DatabaseName
and l.DatabaseUserName = r.DatabaseUserName
and r.[db owner] = 'Yes'

update l
set l.[access admin] = 'Yes'
from #LoginsUsersRoles l, #Results r
where l.DatabaseName = r.DatabaseName
and l.DatabaseUserName = r.DatabaseUserName
and r.[access admin] = 'Yes'

update l
set l.[security admin] = 'Yes'
from #LoginsUsersRoles l, #Results r
where l.DatabaseName = r.DatabaseName
and l.DatabaseUserName = r.DatabaseUserName
and r.[security admin] = 'Yes'

update l
set l.[ddl admin] = 'Yes'
from #LoginsUsersRoles l, #Results r
where l.DatabaseName = r.DatabaseName
and l.DatabaseUserName = r.DatabaseUserName
and r.[ddl admin] = 'Yes'

update l
set l.[data reader] = 'Yes'
from #LoginsUsersRoles l, #Results r
where l.DatabaseName = r.DatabaseName
and l.DatabaseUserName = r.DatabaseUserName
and r.[data reader] = 'Yes'

update l
set l.[data writer] = 'Yes'
from #LoginsUsersRoles l, #Results r
where l.DatabaseName = r.DatabaseName
and l.DatabaseUserName = r.DatabaseUserName
and r.[data writer] = 'Yes'

update l
set l.[deny datareader] = 'Yes'
from #LoginsUsersRoles l, #Results r
where l.DatabaseName = r.DatabaseName
and l.DatabaseUserName = r.DatabaseUserName
and r.[deny datareader] = 'Yes'

update l
set l.[deny datawriter] = 'Yes'
from #LoginsUsersRoles l, #Results r
where l.DatabaseName = r.DatabaseName
and l.DatabaseUserName = r.DatabaseUserName
and r.[deny datawriter] = 'Yes'

update l
set l.[backup operator] = 'Yes'
from #LoginsUsersRoles l, #Results r
where l.DatabaseName = r.DatabaseName
and l.DatabaseUserName = r.DatabaseUserName
and r.[backup operator] = 'Yes'

-- ------------------------------------------------------------------
-- logins & permissions
-- ------------------------------------------------------------------
select * from #LoginsUsersRoles
order by LoginName, LoginType, DatabaseName, DatabaseUserName
-- ------------------------------------------------------------------

IF OBJECT_ID(N'tempdb..#LoginsUsersRoles', 'U') IS NOT NULL 
	DROP TABLE #LoginsUsersRoles;

IF OBJECT_ID(N'tempdb..#results', 'U') IS NOT NULL 
	DROP TABLE #results;
GO
/****** Object:  StoredProcedure [dbo].[Usp_dba_Audit_ArchiveFile]    Script Date: 27/10/2015 09:31:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO







CREATE PROCEDURE [dbo].[Usp_dba_Audit_ArchiveFile]
AS

SET NOCOUNT ON

Exec sp_configure 'xp_cmdshell',1
Reconfigure with override


DECLARE @Filename VARCHAR(256)
DECLARE @Sql VARCHAR(1024)
DECLARE @Command VARCHAR(1024)
DECLARE @SourceFolder VARCHAR(256)
DECLARE @DestinationFolder VARCHAR(256)

BEGIN TRY

SET @Filename = (select TOP 1 filename from Auditrace where active = 'N' and Processed = 'Y') 

SET @DestinationFolder = (' "I:\FAE_SQLBKP01\profiler\Archive\"')

IF @filename IS NOT NULL

---- Enable xp_cmdshell needs enabled to copy the files


SELECT @Sql = 'EXEC master.sys.xp_cmdshell  ''Move' +' "'+ @filename + '.trc" ' + @DestinationFolder + ''''
-- SELECT @Sql = '''Move' +' "'+ @filename + '.trc" ' + @DestinationFolder + ''''

PRINT @Sql  -- Copy the file to the archive folder

EXEC (@Sql)  

---- Disable xp_cmdshell again

Exec sp_configure 'xp_cmdshell',0
Reconfigure with override

END TRY

BEGIN CATCH

SELECT @@ERROR

PRINT 'THERE WAS NO FILE TO MOVE TO THE ARCHIVE FOLDER'

END CATCH





GO
/****** Object:  StoredProcedure [dbo].[Usp_dba_Audit_ResultLoad]    Script Date: 27/10/2015 09:31:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




CREATE PROCEDURE [dbo].[Usp_dba_Audit_ResultLoad]
AS

SET NOCOUNT ON

DECLARE @filename VARCHAR(256)

SET @filename = (select TOP 1 filename from Auditrace where active = 'N' and Processed = 'N')

IF @filename IS NOT NULL

INSERT [dbo].[AuditResults]

SELECT     [EventClass]
           ,[TextData]
           ,[HostName]
           ,[ApplicationName]
           ,[LoginName]
           ,[SPID]
           ,[StartTime]
           ,[DatabaseName]
           ,[ServerName]
           ,[ObjectID]
           ,[ObjectType]
           ,[ObjectName]
           ,[Permissions]
           ,[ColumnPermissions]
           ,[RoleName]
           ,[BinaryData]

FROM ::fn_trace_gettable(@filename + '.trc',0) 
WHERE DatabaseName not in ('model','tempdb','System')



Update Auditrace
SET [Processed] = 'Y'
WHERE [Filename] = @filename








GO
/****** Object:  StoredProcedure [dbo].[Usp_dba_Audit_Start]    Script Date: 27/10/2015 09:31:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE  [dbo].[Usp_dba_Audit_Start]
				
				@filename nvarchar(256)
				
AS

/*
Created by Mervyn Coburn 16/02/2010 to Start an Audit Trace at a path specified with and appended date and time.

This has been tested on SQL2008 Version 10.0.1600 onwards

-- e.g. With Parameter Exec [dbo].[Usp_dba_Audit] 'F:\SQL_Backup_Mount_01\MSSQL$db_dwh_prd_01\Profiler\DWAudit'

N.B. -- This stored proc may generate an error 19067/19059 if executed within 30 seconds of the first execute 
as the create new trace procedure will believe there is still the same file name specified existing, this should
not normally be an issue as it is unlikely you would wish to run the audit trace more than once.

'F:\SQL_Backup_Mount_01\MSSQL$db_dwh_prd_01\Profiler\DWAudit' the filename will have a date and time appended

select @filename = 'F:\SQL_Backup_Mount_01\MSSQL$db_dwh_prd_01\Profiler\DWAudit' + '_' + @DatenTimestring

StoredProcedure [dbo].[Usp_dba_Audit] Script Date: 16/02/2010

-- Create a trace file with the date n time appended

use the following to start, stop and close the trace
(must stop a trace before it can be closed. Must be closed before you can access the file)
exec sp_trace_setstatus TRACEID, 1 --start trace
exec sp_trace_setstatus 2, 0 --stop trace
exec sp_trace_setstatus 2, 2 --close trace

select * from ::fn_trace_getinfo(null)
go

select * from dbo.Auditrace


*/

declare @DatenTimestring varchar(50)
declare @DayOfMonth as varchar(20)
declare @MonthOfYear as varchar(20)
declare @Year as varchar(20)
declare @Hour as varchar(20)
declare @Minute as varchar(20)
declare @Second as varchar(20)
declare @errorcnt int
declare @Tracefileinpath varchar(50)
declare @Dated date
declare @timed time
declare @TraceID int
declare @maxfilesize bigint
declare @msg varchar(1024)
-- declare @filename nvarchar(256)

set @maxfilesize = 100
set @DayOfMonth =(select RIGHT('0' + Cast(DATEPART(dd, getdate())AS Varchar(2)),2)) 
set @MonthOfYear =(select RIGHT('0' + Cast(DATEPART(mm, getdate())AS Varchar(2)),2))
set @Year=(select DATEPART(yyyy, getdate())) -- Year will always be 4 digits
set @Hour=(select RIGHT('0' + Cast(DATEPART(hh, getdate())AS Varchar(2)),2)) 
set @Minute=(select RIGHT('0' + Cast(DATEPART(mi, getdate())AS Varchar(2)),2))
set @Second=(select RIGHT('0' + Cast(DATEPART(ss, getdate())AS Varchar(2)),2)) 
set @DatenTimestring = @DayOfMonth + '_' + @MonthOfYear + '_' + @Year + '_' + @Hour + '_' +  @Minute + '_' + @Second
set @maxfilesize = 100

-- select @filename = 'F:\SQL_Backup_Mount_01\MSSQL$db_dwh_prd_01\Profiler\DWAudit' + '_' + @DatenTimestring
select @filename = @filename + '_' + @DatenTimestring

-- select @filename

If @filename = (select top 1 value from ::fn_trace_getinfo(null) -- find out if trace filename already exists
where property = 2 order by traceid desc)


-- if @TraceID = 0 
-- if @TraceID is null

Begin

select @Msg "The filename for the Trace already Exists"

Print @Msg 
goto error

End

exec sp_trace_create @TraceID output,0,@filename,@maxfilesize, NULL 
if @TraceID = 0 or @Traceid IS NULL
-- if (@errorcnt != 0) or @TraceID = 0 or @Traceid IS NULL
goto error

-- Set the events

declare @on bit
set @on = 1
--
exec sp_trace_setevent @TraceID, 46, 1, @on   -- Object:Created
exec sp_trace_setevent @TraceID, 46, 8, @on
exec sp_trace_setevent @TraceID, 46, 10, @on
exec sp_trace_setevent @TraceID, 46, 11, @on
exec sp_trace_setevent @TraceID, 46, 14, @on
exec sp_trace_setevent @TraceID, 46, 19, @on
exec sp_trace_setevent @TraceID, 46, 22, @on
exec sp_trace_setevent @TraceID, 46, 26, @on
exec sp_trace_setevent @TraceID, 46, 28, @on
exec sp_trace_setevent @TraceID, 46, 34, @on
exec sp_trace_setevent @TraceID, 46, 35, @on
exec sp_trace_setevent @TraceID, 46, 38, @on
exec sp_trace_setevent @TraceID, 46, 44, @on
--
exec sp_trace_setevent @TraceID, 47, 1, @on  -- Object:Deleted
exec sp_trace_setevent @TraceID, 47, 8, @on
exec sp_trace_setevent @TraceID, 47, 10, @on
exec sp_trace_setevent @TraceID, 47, 11, @on
exec sp_trace_setevent @TraceID, 47, 14, @on
exec sp_trace_setevent @TraceID, 47, 19, @on
exec sp_trace_setevent @TraceID, 47, 22, @on
exec sp_trace_setevent @TraceID, 47, 26, @on
exec sp_trace_setevent @TraceID, 47, 28, @on
exec sp_trace_setevent @TraceID, 47, 34, @on
exec sp_trace_setevent @TraceID, 47, 35, @on
exec sp_trace_setevent @TraceID, 47, 38, @on
exec sp_trace_setevent @TraceID, 47, 44, @on
--
exec sp_trace_setevent @TraceID, 164, 1, @on -- Object:Altered
exec sp_trace_setevent @TraceID, 164, 8, @on
exec sp_trace_setevent @TraceID, 164, 10, @on
exec sp_trace_setevent @TraceID, 164, 11, @on
exec sp_trace_setevent @TraceID, 164, 14, @on
exec sp_trace_setevent @TraceID, 164, 19, @on
exec sp_trace_setevent @TraceID, 164, 22, @on
exec sp_trace_setevent @TraceID, 164, 26, @on
exec sp_trace_setevent @TraceID, 164, 28, @on
exec sp_trace_setevent @TraceID, 164, 34, @on
exec sp_trace_setevent @TraceID, 164, 35, @on
exec sp_trace_setevent @TraceID, 164, 38, @on
exec sp_trace_setevent @TraceID, 164, 44, @on
--
exec sp_trace_setevent @TraceID, 20, 1, @on -- Audit Login Failed
exec sp_trace_setevent @TraceID, 20, 8, @on
exec sp_trace_setevent @TraceID, 20, 10, @on
exec sp_trace_setevent @TraceID, 20, 11, @on
exec sp_trace_setevent @TraceID, 20, 14, @on
exec sp_trace_setevent @TraceID, 20, 19, @on
exec sp_trace_setevent @TraceID, 20, 22, @on
exec sp_trace_setevent @TraceID, 20, 26, @on
exec sp_trace_setevent @TraceID, 20, 28, @on
exec sp_trace_setevent @TraceID, 20, 34, @on
exec sp_trace_setevent @TraceID, 20, 35, @on
exec sp_trace_setevent @TraceID, 20, 38, @on
exec sp_trace_setevent @TraceID, 20, 44, @on
--
exec sp_trace_setevent @TraceID, 102, 1, @on -- Audit Database Scope GRANT, DENY, REVOKE 
exec sp_trace_setevent @TraceID, 102, 8, @on
exec sp_trace_setevent @TraceID, 102, 10, @on
exec sp_trace_setevent @TraceID, 102, 11, @on
exec sp_trace_setevent @TraceID, 102, 14, @on
exec sp_trace_setevent @TraceID, 102, 19, @on
exec sp_trace_setevent @TraceID, 102, 22, @on
exec sp_trace_setevent @TraceID, 102, 26, @on
exec sp_trace_setevent @TraceID, 102, 28, @on
exec sp_trace_setevent @TraceID, 102, 34, @on
exec sp_trace_setevent @TraceID, 102, 35, @on
exec sp_trace_setevent @TraceID, 102, 38, @on
exec sp_trace_setevent @TraceID, 102, 44, @on
--
exec sp_trace_setevent @TraceID, 103, 1, @on -- Audit Object GRANT, DENY, REVOKE Event
exec sp_trace_setevent @TraceID, 103, 8, @on
exec sp_trace_setevent @TraceID, 103, 10, @on
exec sp_trace_setevent @TraceID, 103, 11, @on
exec sp_trace_setevent @TraceID, 103, 14, @on
exec sp_trace_setevent @TraceID, 103, 19, @on
exec sp_trace_setevent @TraceID, 103, 22, @on
exec sp_trace_setevent @TraceID, 103, 26, @on
exec sp_trace_setevent @TraceID, 103, 28, @on
exec sp_trace_setevent @TraceID, 103, 34, @on
exec sp_trace_setevent @TraceID, 103, 35, @on
exec sp_trace_setevent @TraceID, 103, 38, @on
exec sp_trace_setevent @TraceID, 103, 44, @on
--
exec sp_trace_setevent @TraceID, 104, 1, @on -- Audit AddLogin Event SQL Server Login
exec sp_trace_setevent @TraceID, 104, 8, @on
exec sp_trace_setevent @TraceID, 104, 10, @on
exec sp_trace_setevent @TraceID, 104, 11, @on
exec sp_trace_setevent @TraceID, 104, 14, @on
exec sp_trace_setevent @TraceID, 104, 19, @on
exec sp_trace_setevent @TraceID, 104, 22, @on
exec sp_trace_setevent @TraceID, 104, 26, @on
exec sp_trace_setevent @TraceID, 104, 28, @on
exec sp_trace_setevent @TraceID, 104, 34, @on
exec sp_trace_setevent @TraceID, 104, 35, @on
exec sp_trace_setevent @TraceID, 104, 38, @on
exec sp_trace_setevent @TraceID, 104, 44, @on
--
exec sp_trace_setevent @TraceID, 105, 1, @on -- Audit Login Event Windows Login
exec sp_trace_setevent @TraceID, 105, 8, @on
exec sp_trace_setevent @TraceID, 105, 10, @on
exec sp_trace_setevent @TraceID, 105, 11, @on
exec sp_trace_setevent @TraceID, 105, 14, @on
exec sp_trace_setevent @TraceID, 105, 19, @on
exec sp_trace_setevent @TraceID, 105, 22, @on
exec sp_trace_setevent @TraceID, 105, 26, @on
exec sp_trace_setevent @TraceID, 105, 28, @on
exec sp_trace_setevent @TraceID, 105, 34, @on
exec sp_trace_setevent @TraceID, 105, 35, @on
exec sp_trace_setevent @TraceID, 105, 38, @on
exec sp_trace_setevent @TraceID, 105, 44, @on
--
exec sp_trace_setevent @TraceID, 106, 1, @on -- Audit Login Change Property Event e.g.  Password or Defaultdb
exec sp_trace_setevent @TraceID, 106, 8, @on
exec sp_trace_setevent @TraceID, 106, 10, @on
exec sp_trace_setevent @TraceID, 106, 11, @on
exec sp_trace_setevent @TraceID, 106, 14, @on
exec sp_trace_setevent @TraceID, 106, 19, @on
exec sp_trace_setevent @TraceID, 106, 22, @on
exec sp_trace_setevent @TraceID, 106, 26, @on
exec sp_trace_setevent @TraceID, 106, 28, @on
exec sp_trace_setevent @TraceID, 106, 34, @on
exec sp_trace_setevent @TraceID, 106, 35, @on
exec sp_trace_setevent @TraceID, 106, 38, @on
exec sp_trace_setevent @TraceID, 106, 44, @on
--
exec sp_trace_setevent @TraceID, 108, 1, @on -- Audit Add Login to Server Role Event
exec sp_trace_setevent @TraceID, 108, 8, @on
exec sp_trace_setevent @TraceID, 108, 10, @on
exec sp_trace_setevent @TraceID, 108, 11, @on
exec sp_trace_setevent @TraceID, 108, 14, @on
exec sp_trace_setevent @TraceID, 108, 19, @on
exec sp_trace_setevent @TraceID, 108, 22, @on
exec sp_trace_setevent @TraceID, 108, 26, @on
exec sp_trace_setevent @TraceID, 108, 28, @on
exec sp_trace_setevent @TraceID, 108, 34, @on
exec sp_trace_setevent @TraceID, 108, 35, @on
exec sp_trace_setevent @TraceID, 108, 38, @on
exec sp_trace_setevent @TraceID, 108, 44, @on
--
exec sp_trace_setevent @TraceID, 109, 1, @on -- Audit Add DB User Event
exec sp_trace_setevent @TraceID, 109, 8, @on
exec sp_trace_setevent @TraceID, 109, 10, @on
exec sp_trace_setevent @TraceID, 109, 11, @on
exec sp_trace_setevent @TraceID, 109, 14, @on
exec sp_trace_setevent @TraceID, 109, 19, @on
exec sp_trace_setevent @TraceID, 109, 22, @on
exec sp_trace_setevent @TraceID, 109, 26, @on
exec sp_trace_setevent @TraceID, 109, 28, @on
exec sp_trace_setevent @TraceID, 109, 34, @on
exec sp_trace_setevent @TraceID, 109, 35, @on
exec sp_trace_setevent @TraceID, 109, 38, @on
exec sp_trace_setevent @TraceID, 109, 44, @on
--
exec sp_trace_setevent @TraceID, 110, 1, @on -- Audit Add Member to DB Role Event
exec sp_trace_setevent @TraceID, 110, 8, @on
exec sp_trace_setevent @TraceID, 110, 10, @on
exec sp_trace_setevent @TraceID, 110, 11, @on
exec sp_trace_setevent @TraceID, 110, 14, @on
exec sp_trace_setevent @TraceID, 110, 19, @on
exec sp_trace_setevent @TraceID, 110, 22, @on
exec sp_trace_setevent @TraceID, 110, 26, @on
exec sp_trace_setevent @TraceID, 110, 28, @on
exec sp_trace_setevent @TraceID, 110, 34, @on
exec sp_trace_setevent @TraceID, 110, 35, @on
exec sp_trace_setevent @TraceID, 110, 38, @on
exec sp_trace_setevent @TraceID, 110, 44, @on
--
exec sp_trace_setevent @TraceID, 111, 1, @on -- Audit Add Role Event
exec sp_trace_setevent @TraceID, 111, 8, @on
exec sp_trace_setevent @TraceID, 111, 10, @on
exec sp_trace_setevent @TraceID, 111, 11, @on
exec sp_trace_setevent @TraceID, 111, 14, @on
exec sp_trace_setevent @TraceID, 111, 19, @on
exec sp_trace_setevent @TraceID, 111, 22, @on
exec sp_trace_setevent @TraceID, 111, 26, @on
exec sp_trace_setevent @TraceID, 111, 28, @on
exec sp_trace_setevent @TraceID, 111, 34, @on
exec sp_trace_setevent @TraceID, 111, 35, @on
exec sp_trace_setevent @TraceID, 111, 38, @on
exec sp_trace_setevent @TraceID, 111, 44, @on
--
exec sp_trace_setevent @TraceID, 113, 1, @on -- Audit Statement Permission Event
exec sp_trace_setevent @TraceID, 113, 8, @on
exec sp_trace_setevent @TraceID, 113, 10, @on
exec sp_trace_setevent @TraceID, 113, 11, @on
exec sp_trace_setevent @TraceID, 113, 14, @on
exec sp_trace_setevent @TraceID, 113, 19, @on
exec sp_trace_setevent @TraceID, 113, 22, @on
exec sp_trace_setevent @TraceID, 113, 26, @on
exec sp_trace_setevent @TraceID, 113, 28, @on
exec sp_trace_setevent @TraceID, 113, 34, @on
exec sp_trace_setevent @TraceID, 113, 35, @on
exec sp_trace_setevent @TraceID, 113, 38, @on
exec sp_trace_setevent @TraceID, 113, 44, @on
--
exec sp_trace_setevent @TraceID, 115, 1, @on -- Audit Backup/Restore Event
exec sp_trace_setevent @TraceID, 115, 8, @on
exec sp_trace_setevent @TraceID, 115, 10, @on
exec sp_trace_setevent @TraceID, 115, 11, @on
exec sp_trace_setevent @TraceID, 115, 14, @on
exec sp_trace_setevent @TraceID, 115, 19, @on
exec sp_trace_setevent @TraceID, 115, 22, @on
exec sp_trace_setevent @TraceID, 115, 26, @on
exec sp_trace_setevent @TraceID, 115, 28, @on
exec sp_trace_setevent @TraceID, 115, 34, @on
exec sp_trace_setevent @TraceID, 115, 35, @on
exec sp_trace_setevent @TraceID, 115, 38, @on
exec sp_trace_setevent @TraceID, 115, 44, @on
--
exec sp_trace_setevent @TraceID, 116, 1, @on -- Audit DBCC Event
exec sp_trace_setevent @TraceID, 116, 8, @on
exec sp_trace_setevent @TraceID, 116, 10, @on
exec sp_trace_setevent @TraceID, 116, 11, @on
exec sp_trace_setevent @TraceID, 116, 14, @on
exec sp_trace_setevent @TraceID, 116, 19, @on
exec sp_trace_setevent @TraceID, 116, 22, @on
exec sp_trace_setevent @TraceID, 116, 26, @on
exec sp_trace_setevent @TraceID, 116, 28, @on
exec sp_trace_setevent @TraceID, 116, 34, @on
exec sp_trace_setevent @TraceID, 116, 35, @on
exec sp_trace_setevent @TraceID, 116, 38, @on
exec sp_trace_setevent @TraceID, 116, 44, @on
--
exec sp_trace_setevent @TraceID, 117, 1, @on -- Audit Change Audit Event
exec sp_trace_setevent @TraceID, 117, 8, @on
exec sp_trace_setevent @TraceID, 117, 10, @on
exec sp_trace_setevent @TraceID, 117, 11, @on
exec sp_trace_setevent @TraceID, 117, 14, @on
exec sp_trace_setevent @TraceID, 117, 19, @on
exec sp_trace_setevent @TraceID, 117, 22, @on
exec sp_trace_setevent @TraceID, 117, 26, @on
exec sp_trace_setevent @TraceID, 117, 28, @on
exec sp_trace_setevent @TraceID, 117, 34, @on
exec sp_trace_setevent @TraceID, 117, 35, @on
exec sp_trace_setevent @TraceID, 117, 38, @on
exec sp_trace_setevent @TraceID, 117, 44, @on
--
exec sp_trace_setevent @TraceID, 118, 1, @on -- Audit Object Derived Permission Event when Create / Alter / Drop object commands used
exec sp_trace_setevent @TraceID, 118, 8, @on
exec sp_trace_setevent @TraceID, 118, 10, @on
exec sp_trace_setevent @TraceID, 118, 11, @on
exec sp_trace_setevent @TraceID, 118, 14, @on
exec sp_trace_setevent @TraceID, 118, 19, @on
exec sp_trace_setevent @TraceID, 118, 22, @on
exec sp_trace_setevent @TraceID, 118, 26, @on
exec sp_trace_setevent @TraceID, 118, 28, @on
exec sp_trace_setevent @TraceID, 118, 34, @on
exec sp_trace_setevent @TraceID, 118, 35, @on
exec sp_trace_setevent @TraceID, 118, 38, @on
exec sp_trace_setevent @TraceID, 118, 44, @on
--
exec sp_trace_setevent @TraceID, 128, 1, @on -- Audit Database Management Event e.g. create alter drop db
exec sp_trace_setevent @TraceID, 128, 8, @on
exec sp_trace_setevent @TraceID, 128, 10, @on
exec sp_trace_setevent @TraceID, 128, 11, @on
exec sp_trace_setevent @TraceID, 128, 14, @on
exec sp_trace_setevent @TraceID, 128, 19, @on
exec sp_trace_setevent @TraceID, 128, 22, @on
exec sp_trace_setevent @TraceID, 128, 26, @on
exec sp_trace_setevent @TraceID, 128, 28, @on
exec sp_trace_setevent @TraceID, 128, 34, @on
exec sp_trace_setevent @TraceID, 128, 35, @on
exec sp_trace_setevent @TraceID, 128, 38, @on
exec sp_trace_setevent @TraceID, 128, 44, @on
--
exec sp_trace_setevent @TraceID, 129, 1, @on -- Audit Database Object Management Event e.g. create schemas
exec sp_trace_setevent @TraceID, 129, 8, @on
exec sp_trace_setevent @TraceID, 129, 10, @on
exec sp_trace_setevent @TraceID, 129, 11, @on
exec sp_trace_setevent @TraceID, 129, 14, @on
exec sp_trace_setevent @TraceID, 129, 19, @on
exec sp_trace_setevent @TraceID, 129, 22, @on
exec sp_trace_setevent @TraceID, 129, 26, @on
exec sp_trace_setevent @TraceID, 129, 28, @on
exec sp_trace_setevent @TraceID, 129, 34, @on
exec sp_trace_setevent @TraceID, 129, 35, @on
exec sp_trace_setevent @TraceID, 129, 38, @on
exec sp_trace_setevent @TraceID, 129, 44, @on
--
exec sp_trace_setevent @TraceID, 130, 1, @on -- Audit Database Principal e.g. users created or altered
exec sp_trace_setevent @TraceID, 130, 8, @on
exec sp_trace_setevent @TraceID, 130, 10, @on
exec sp_trace_setevent @TraceID, 130, 11, @on
exec sp_trace_setevent @TraceID, 130, 14, @on
exec sp_trace_setevent @TraceID, 130, 19, @on
exec sp_trace_setevent @TraceID, 130, 22, @on
exec sp_trace_setevent @TraceID, 130, 26, @on
exec sp_trace_setevent @TraceID, 130, 28, @on
exec sp_trace_setevent @TraceID, 130, 34, @on
exec sp_trace_setevent @TraceID, 130, 35, @on
exec sp_trace_setevent @TraceID, 130, 38, @on
exec sp_trace_setevent @TraceID, 130, 44, @on
--
exec sp_trace_setevent @TraceID, 131, 1, @on -- Audit Schema Object Management Event e.g. When server objects created or deleted
exec sp_trace_setevent @TraceID, 131, 8, @on
exec sp_trace_setevent @TraceID, 131, 10, @on
exec sp_trace_setevent @TraceID, 131, 11, @on
exec sp_trace_setevent @TraceID, 131, 14, @on
exec sp_trace_setevent @TraceID, 131, 19, @on
exec sp_trace_setevent @TraceID, 131, 22, @on
exec sp_trace_setevent @TraceID, 131, 26, @on
exec sp_trace_setevent @TraceID, 131, 28, @on
exec sp_trace_setevent @TraceID, 131, 34, @on
exec sp_trace_setevent @TraceID, 131, 35, @on
exec sp_trace_setevent @TraceID, 131, 38, @on
exec sp_trace_setevent @TraceID, 131, 44, @on
--
exec sp_trace_setevent @TraceID, 132, 1, @on -- Audit Server Principal Impersonation Event e.g. execute as login
exec sp_trace_setevent @TraceID, 132, 8, @on
exec sp_trace_setevent @TraceID, 132, 10, @on
exec sp_trace_setevent @TraceID, 132, 11, @on
exec sp_trace_setevent @TraceID, 132, 14, @on
exec sp_trace_setevent @TraceID, 132, 19, @on
exec sp_trace_setevent @TraceID, 132, 22, @on
exec sp_trace_setevent @TraceID, 132, 26, @on
exec sp_trace_setevent @TraceID, 132, 28, @on
exec sp_trace_setevent @TraceID, 132, 34, @on
exec sp_trace_setevent @TraceID, 132, 35, @on
exec sp_trace_setevent @TraceID, 132, 38, @on
exec sp_trace_setevent @TraceID, 132, 44, @on
--
exec sp_trace_setevent @TraceID, 133, 1, @on -- Audit Database Principal Impersonation Event e.g. execute as user
exec sp_trace_setevent @TraceID, 133, 8, @on
exec sp_trace_setevent @TraceID, 133, 10, @on
exec sp_trace_setevent @TraceID, 133, 11, @on
exec sp_trace_setevent @TraceID, 133, 14, @on
exec sp_trace_setevent @TraceID, 133, 19, @on
exec sp_trace_setevent @TraceID, 133, 22, @on
exec sp_trace_setevent @TraceID, 133, 26, @on
exec sp_trace_setevent @TraceID, 133, 28, @on
exec sp_trace_setevent @TraceID, 133, 34, @on
exec sp_trace_setevent @TraceID, 133, 35, @on
exec sp_trace_setevent @TraceID, 133, 38, @on
exec sp_trace_setevent @TraceID, 133, 44, @on
--
exec sp_trace_setevent @TraceID, 134, 1, @on -- Audit Server Object Take Ownership Event
exec sp_trace_setevent @TraceID, 134, 8, @on
exec sp_trace_setevent @TraceID, 134, 10, @on
exec sp_trace_setevent @TraceID, 134, 11, @on
exec sp_trace_setevent @TraceID, 134, 14, @on
exec sp_trace_setevent @TraceID, 134, 19, @on
exec sp_trace_setevent @TraceID, 134, 22, @on
exec sp_trace_setevent @TraceID, 134, 26, @on
exec sp_trace_setevent @TraceID, 134, 28, @on
exec sp_trace_setevent @TraceID, 134, 34, @on
exec sp_trace_setevent @TraceID, 134, 35, @on
exec sp_trace_setevent @TraceID, 134, 38, @on
exec sp_trace_setevent @TraceID, 134, 44, @on
--
exec sp_trace_setevent @TraceID, 135, 1, @on -- Audit Database Object Take Ownership Event
exec sp_trace_setevent @TraceID, 135, 8, @on
exec sp_trace_setevent @TraceID, 135, 10, @on
exec sp_trace_setevent @TraceID, 135, 11, @on
exec sp_trace_setevent @TraceID, 135, 14, @on
exec sp_trace_setevent @TraceID, 135, 19, @on
exec sp_trace_setevent @TraceID, 135, 22, @on
exec sp_trace_setevent @TraceID, 135, 26, @on
exec sp_trace_setevent @TraceID, 135, 28, @on
exec sp_trace_setevent @TraceID, 135, 34, @on
exec sp_trace_setevent @TraceID, 135, 35, @on
exec sp_trace_setevent @TraceID, 135, 38, @on
exec sp_trace_setevent @TraceID, 135, 44, @on
--
exec sp_trace_setevent @TraceID, 153, 1, @on -- Audit Schema Object Take Ownership Event
exec sp_trace_setevent @TraceID, 153, 8, @on
exec sp_trace_setevent @TraceID, 153, 10, @on
exec sp_trace_setevent @TraceID, 153, 11, @on
exec sp_trace_setevent @TraceID, 153, 14, @on
exec sp_trace_setevent @TraceID, 153, 19, @on
exec sp_trace_setevent @TraceID, 153, 22, @on
exec sp_trace_setevent @TraceID, 153, 26, @on
exec sp_trace_setevent @TraceID, 153, 28, @on
exec sp_trace_setevent @TraceID, 153, 34, @on
exec sp_trace_setevent @TraceID, 153, 35, @on
exec sp_trace_setevent @TraceID, 153, 38, @on
exec sp_trace_setevent @TraceID, 153, 44, @on
--
exec sp_trace_setevent @TraceID, 160, 1, @on -- Audit Service Broker Message Undeliverable
exec sp_trace_setevent @TraceID, 160, 8, @on
exec sp_trace_setevent @TraceID, 160, 10, @on
exec sp_trace_setevent @TraceID, 160, 11, @on
exec sp_trace_setevent @TraceID, 160, 14, @on
exec sp_trace_setevent @TraceID, 160, 19, @on
exec sp_trace_setevent @TraceID, 160, 22, @on
exec sp_trace_setevent @TraceID, 160, 26, @on
exec sp_trace_setevent @TraceID, 160, 28, @on
exec sp_trace_setevent @TraceID, 160, 34, @on
exec sp_trace_setevent @TraceID, 160, 35, @on
exec sp_trace_setevent @TraceID, 160, 38, @on
exec sp_trace_setevent @TraceID, 160, 44, @on
--
exec sp_trace_setevent @TraceID, 161, 1, @on -- Audit Service Broker Message Corrupted
exec sp_trace_setevent @TraceID, 161, 8, @on
exec sp_trace_setevent @TraceID, 161, 10, @on
exec sp_trace_setevent @TraceID, 161, 11, @on
exec sp_trace_setevent @TraceID, 161, 14, @on
exec sp_trace_setevent @TraceID, 161, 19, @on
exec sp_trace_setevent @TraceID, 161, 22, @on
exec sp_trace_setevent @TraceID, 161, 26, @on
exec sp_trace_setevent @TraceID, 161, 28, @on
exec sp_trace_setevent @TraceID, 161, 34, @on
exec sp_trace_setevent @TraceID, 161, 35, @on
exec sp_trace_setevent @TraceID, 161, 38, @on
exec sp_trace_setevent @TraceID, 161, 44, @on
--
exec sp_trace_setevent @TraceID, 164, 1, @on -- Audit Object:Altered e.g. when Database Object Altered
exec sp_trace_setevent @TraceID, 164, 8, @on
exec sp_trace_setevent @TraceID, 164, 10, @on
exec sp_trace_setevent @TraceID, 164, 11, @on
exec sp_trace_setevent @TraceID, 164, 14, @on
exec sp_trace_setevent @TraceID, 164, 19, @on
exec sp_trace_setevent @TraceID, 164, 22, @on
exec sp_trace_setevent @TraceID, 164, 26, @on
exec sp_trace_setevent @TraceID, 164, 28, @on
exec sp_trace_setevent @TraceID, 164, 34, @on
exec sp_trace_setevent @TraceID, 164, 35, @on
exec sp_trace_setevent @TraceID, 164, 38, @on
exec sp_trace_setevent @TraceID, 164, 44, @on
--
exec sp_trace_setevent @TraceID, 165, 1, @on -- Performance statistics when compiled query plan has been cached or recompiled 
exec sp_trace_setevent @TraceID, 165, 8, @on
exec sp_trace_setevent @TraceID, 165, 10, @on
exec sp_trace_setevent @TraceID, 165, 11, @on
exec sp_trace_setevent @TraceID, 165, 14, @on
exec sp_trace_setevent @TraceID, 165, 19, @on
exec sp_trace_setevent @TraceID, 165, 22, @on
exec sp_trace_setevent @TraceID, 165, 26, @on
exec sp_trace_setevent @TraceID, 165, 28, @on
exec sp_trace_setevent @TraceID, 165, 34, @on
exec sp_trace_setevent @TraceID, 165, 35, @on
exec sp_trace_setevent @TraceID, 165, 38, @on
exec sp_trace_setevent @TraceID, 165, 44, @on
--
exec sp_trace_setevent @TraceID, 170, 1, @on -- Audit Server Scope GDR Event e.g. Creating a Login
exec sp_trace_setevent @TraceID, 170, 8, @on
exec sp_trace_setevent @TraceID, 170, 10, @on
exec sp_trace_setevent @TraceID, 170, 11, @on
exec sp_trace_setevent @TraceID, 170, 14, @on
exec sp_trace_setevent @TraceID, 170, 19, @on
exec sp_trace_setevent @TraceID, 170, 22, @on
exec sp_trace_setevent @TraceID, 170, 26, @on
exec sp_trace_setevent @TraceID, 170, 28, @on
exec sp_trace_setevent @TraceID, 170, 34, @on
exec sp_trace_setevent @TraceID, 170, 35, @on
exec sp_trace_setevent @TraceID, 170, 38, @on
exec sp_trace_setevent @TraceID, 170, 44, @on
--
exec sp_trace_setevent @TraceID, 171, 1, @on -- Audit Server Object GDR Event
exec sp_trace_setevent @TraceID, 171, 8, @on
exec sp_trace_setevent @TraceID, 171, 10, @on
exec sp_trace_setevent @TraceID, 171, 11, @on
exec sp_trace_setevent @TraceID, 171, 14, @on
exec sp_trace_setevent @TraceID, 171, 19, @on
exec sp_trace_setevent @TraceID, 171, 22, @on
exec sp_trace_setevent @TraceID, 171, 26, @on
exec sp_trace_setevent @TraceID, 171, 28, @on
exec sp_trace_setevent @TraceID, 171, 34, @on
exec sp_trace_setevent @TraceID, 171, 35, @on
exec sp_trace_setevent @TraceID, 171, 38, @on
exec sp_trace_setevent @TraceID, 171, 44, @on
--
exec sp_trace_setevent @TraceID, 172, 1, @on -- Audit Database Object GDR Event
exec sp_trace_setevent @TraceID, 172, 8, @on
exec sp_trace_setevent @TraceID, 172, 10, @on
exec sp_trace_setevent @TraceID, 172, 11, @on
exec sp_trace_setevent @TraceID, 172, 14, @on
exec sp_trace_setevent @TraceID, 172, 19, @on
exec sp_trace_setevent @TraceID, 172, 22, @on
exec sp_trace_setevent @TraceID, 172, 26, @on
exec sp_trace_setevent @TraceID, 172, 28, @on
exec sp_trace_setevent @TraceID, 172, 34, @on
exec sp_trace_setevent @TraceID, 172, 35, @on
exec sp_trace_setevent @TraceID, 172, 38, @on
exec sp_trace_setevent @TraceID, 172, 44, @on
--
exec sp_trace_setevent @TraceID, 173, 1, @on -- Audit Server Operation Event e.g. altering settings
exec sp_trace_setevent @TraceID, 173, 8, @on
exec sp_trace_setevent @TraceID, 173, 10, @on
exec sp_trace_setevent @TraceID, 173, 11, @on
exec sp_trace_setevent @TraceID, 173, 14, @on
exec sp_trace_setevent @TraceID, 173, 19, @on
exec sp_trace_setevent @TraceID, 173, 22, @on
exec sp_trace_setevent @TraceID, 173, 26, @on
exec sp_trace_setevent @TraceID, 173, 28, @on
exec sp_trace_setevent @TraceID, 173, 34, @on
exec sp_trace_setevent @TraceID, 173, 35, @on
exec sp_trace_setevent @TraceID, 173, 38, @on
exec sp_trace_setevent @TraceID, 173, 44, @on
--
exec sp_trace_setevent @TraceID, 175, 1, @on -- Audit Server Alter Trace Event
exec sp_trace_setevent @TraceID, 175, 8, @on
exec sp_trace_setevent @TraceID, 175, 10, @on
exec sp_trace_setevent @TraceID, 175, 11, @on
exec sp_trace_setevent @TraceID, 175, 14, @on
exec sp_trace_setevent @TraceID, 175, 19, @on
exec sp_trace_setevent @TraceID, 175, 22, @on
exec sp_trace_setevent @TraceID, 175, 26, @on
exec sp_trace_setevent @TraceID, 175, 28, @on
exec sp_trace_setevent @TraceID, 175, 34, @on
exec sp_trace_setevent @TraceID, 175, 35, @on
exec sp_trace_setevent @TraceID, 175, 38, @on
exec sp_trace_setevent @TraceID, 175, 44, @on
--
exec sp_trace_setevent @TraceID, 176, 1, @on -- Audit Server Object Management Event
exec sp_trace_setevent @TraceID, 176, 8, @on
exec sp_trace_setevent @TraceID, 176, 10, @on
exec sp_trace_setevent @TraceID, 176, 11, @on
exec sp_trace_setevent @TraceID, 176, 14, @on
exec sp_trace_setevent @TraceID, 176, 19, @on
exec sp_trace_setevent @TraceID, 176, 22, @on
exec sp_trace_setevent @TraceID, 176, 26, @on
exec sp_trace_setevent @TraceID, 176, 28, @on
exec sp_trace_setevent @TraceID, 176, 34, @on
exec sp_trace_setevent @TraceID, 176, 35, @on
exec sp_trace_setevent @TraceID, 176, 38, @on
exec sp_trace_setevent @TraceID, 176, 44, @on
--
exec sp_trace_setevent @TraceID, 177, 1, @on -- Audit Server Principal Management Event
exec sp_trace_setevent @TraceID, 177, 8, @on
exec sp_trace_setevent @TraceID, 177, 10, @on
exec sp_trace_setevent @TraceID, 177, 11, @on
exec sp_trace_setevent @TraceID, 177, 14, @on
exec sp_trace_setevent @TraceID, 177, 19, @on
exec sp_trace_setevent @TraceID, 177, 22, @on
exec sp_trace_setevent @TraceID, 177, 26, @on
exec sp_trace_setevent @TraceID, 177, 28, @on
exec sp_trace_setevent @TraceID, 177, 34, @on
exec sp_trace_setevent @TraceID, 177, 35, @on
exec sp_trace_setevent @TraceID, 177, 38, @on
exec sp_trace_setevent @TraceID, 177, 44, @on
--
exec sp_trace_setevent @TraceID, 187, 1, @on -- Rollback Tran starting
exec sp_trace_setevent @TraceID, 187, 8, @on
exec sp_trace_setevent @TraceID, 187, 10, @on
exec sp_trace_setevent @TraceID, 187, 11, @on
exec sp_trace_setevent @TraceID, 187, 14, @on
exec sp_trace_setevent @TraceID, 187, 19, @on
exec sp_trace_setevent @TraceID, 187, 22, @on
exec sp_trace_setevent @TraceID, 187, 26, @on
exec sp_trace_setevent @TraceID, 187, 28, @on
exec sp_trace_setevent @TraceID, 187, 34, @on
exec sp_trace_setevent @TraceID, 187, 35, @on
exec sp_trace_setevent @TraceID, 187, 38, @on
exec sp_trace_setevent @TraceID, 187, 44, @on
--
exec sp_trace_setevent @TraceID, 189, 1, @on -- Audit Lock Timeout
exec sp_trace_setevent @TraceID, 189, 8, @on
exec sp_trace_setevent @TraceID, 189, 10, @on
exec sp_trace_setevent @TraceID, 189, 11, @on
exec sp_trace_setevent @TraceID, 189, 14, @on
exec sp_trace_setevent @TraceID, 189, 19, @on
exec sp_trace_setevent @TraceID, 189, 22, @on
exec sp_trace_setevent @TraceID, 189, 26, @on
exec sp_trace_setevent @TraceID, 189, 28, @on
exec sp_trace_setevent @TraceID, 189, 34, @on
exec sp_trace_setevent @TraceID, 189, 35, @on
exec sp_trace_setevent @TraceID, 189, 38, @on
exec sp_trace_setevent @TraceID, 189, 44, @on

-- Set the trace status to start
exec sp_trace_setstatus @TraceID, 1

-- display trace id for future references
select TraceID=@TraceID

-- Insert Audit Details to table

INSERT [System].[dbo].[Auditrace]
select @TraceID,@filename,'Y',GETDATE(),'N'

IF @@ERROR > 0 

goto error

goto finish


error: 

select @Msg "The filename for the Trace already Exists or there has been a problem creating the trace rerun after 30 seconds"

Print @Msg 

-- select @errorcnt = @@ERROR
-- select @errorcnt

-- Cannot create a new trace because the trace file path is found in the existing traces.

finish:










GO
/****** Object:  StoredProcedure [dbo].[Usp_dba_Audit_Stop]    Script Date: 27/10/2015 09:31:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



-- DROP PROCEDURE  [dbo].[Usp_dba_Audit_Stop]
CREATE PROCEDURE  [dbo].[Usp_dba_Audit_Stop]
				
AS

/*
Created by Mervyn Coburn 16/02/2010 to Stop an Audit Trace that has been added via the Usp_dba_Audit procedure
with an entry in the [System].[dbo].[Auditrace] table.

This has been tested on SQL2008 Version 10.0.1600 onwards

-- e.g. Exec [dbo].[Usp_dba_Audit_Stop]

Works in conjuction with StoredProcedure [dbo].[Usp_dba_Audit] Script Date: 16/02/2010

use the following to start, stop and close the trace
(must stop a trace before it can be closed. Must be closed before you can access the file)
exec sp_trace_setstatus TRACEID, 1 --start trace
exec sp_trace_setstatus 2, 0 --stop trace
exec sp_trace_setstatus 2, 2 --close trace

-- see if any traces are currently running trace id 1 is the default trace.

select * from ::fn_trace_getinfo(null)
go

*/

declare @Rowid int
declare @Traceid int
declare @Filename nvarchar(256)
declare @Active as char(1)
declare @Dated as datetime
declare @errorcnt int
declare @finishnotrun varchar(256)

select @Traceid = (select TOP 1 Traceid from [System].[dbo].[Auditrace] where Active = 'Y' and Traceid is not null and Traceid > 1 order by Rowid desc)

Delete [System].[dbo].[Auditrace]
where Traceid = 0 -- There has been a problem creating this record in the table delete as no traces can run as 0.

WHILE @Traceid > 1 and @Traceid <> ''
	BEGIN

set @Traceid = (select TOP 1 Traceid from [System].[dbo].[Auditrace] where Active = 'Y' and Traceid is not null and Traceid > 1 order by Rowid desc)

IF @Traceid = '' or @Traceid is null or @Traceid < 2
goto finish

exec sp_trace_setstatus @Traceid, 0 --stop trace
exec sp_trace_setstatus @Traceid, 2 --close trace

Update [System].[dbo].[Auditrace]
set Active = 'N' 
Where Traceid = @Traceid

   
    END
    


if (@errorcnt != 0) goto error

goto finish

error: 
select ErrorCode=@errorcnt

finish:







GO
/****** Object:  StoredProcedure [dbo].[usp_help_revlogin]    Script Date: 27/10/2015 09:31:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [dbo].[usp_help_revlogin] @login_name sysname = NULL AS

-- don't run on SQL Server 2000 as that needs a different version of hex & main stored proc
-- See  (http://support.microsoft.com/kb/918992/ ) How to transfer the logins and the passwords between instances of SQL Server 2005 

DECLARE @name sysname
DECLARE @type varchar (1)
DECLARE @hasaccess int
DECLARE @denylogin int
DECLARE @is_disabled int
DECLARE @PWD_varbinary  varbinary (256)
DECLARE @PWD_string  varchar (514)
DECLARE @SID_varbinary varbinary (85)
DECLARE @SID_string varchar (514)
DECLARE @tmpstr  varchar (1024)
DECLARE @is_policy_checked varchar (3)
DECLARE @is_expiration_checked varchar (3)

DECLARE @defaultdb sysname
 
IF (@login_name IS NULL)
  DECLARE login_curs CURSOR FOR

      SELECT p.sid, p.name, p.type, p.is_disabled, p.default_database_name, l.hasaccess, l.denylogin FROM 
sys.server_principals p LEFT JOIN sys.syslogins l
      ON ( l.name = p.name ) WHERE p.type IN ( 'S', 'G', 'U' ) AND p.name <> 'sa'
ELSE
  DECLARE login_curs CURSOR FOR


      SELECT p.sid, p.name, p.type, p.is_disabled, p.default_database_name, l.hasaccess, l.denylogin FROM 
sys.server_principals p LEFT JOIN sys.syslogins l
      ON ( l.name = p.name ) WHERE p.type IN ( 'S', 'G', 'U' ) AND p.name = @login_name
OPEN login_curs

FETCH NEXT FROM login_curs INTO @SID_varbinary, @name, @type, @is_disabled, @defaultdb, @hasaccess, @denylogin
IF (@@fetch_status = -1)
BEGIN
  PRINT 'No login(s) found.'
  CLOSE login_curs
  DEALLOCATE login_curs
  RETURN -1
END
SET @tmpstr = '/* sp_help_revlogin script '
PRINT @tmpstr
SET @tmpstr = '** Generated ' + CONVERT (varchar, GETDATE()) + ' on ' + @@SERVERNAME + ' */'
PRINT @tmpstr
PRINT ''
WHILE (@@fetch_status <> -1)
BEGIN
  IF (@@fetch_status <> -2)
  BEGIN
    PRINT ''
    SET @tmpstr = '-- Login: ' + @name
    PRINT @tmpstr
    IF (@type IN ( 'G', 'U'))
    BEGIN -- NT authenticated account/group

      SET @tmpstr = 'CREATE LOGIN ' + QUOTENAME( @name ) + ' FROM WINDOWS WITH DEFAULT_DATABASE = [' + @defaultdb + ']'
    END
    ELSE BEGIN -- SQL Server authentication
        -- obtain password and sid
            SET @PWD_varbinary = CAST( LOGINPROPERTY( @name, 'PasswordHash' ) AS varbinary (256) )
        EXEC usp_hexadecimal @PWD_varbinary, @PWD_string OUT
        EXEC usp_hexadecimal @SID_varbinary,@SID_string OUT
 
        -- obtain password policy state
        SELECT @is_policy_checked = CASE is_policy_checked WHEN 1 THEN 'ON' WHEN 0 THEN 'OFF' ELSE NULL END FROM sys.sql_logins WHERE name = @name
        SELECT @is_expiration_checked = CASE is_expiration_checked WHEN 1 THEN 'ON' WHEN 0 THEN 'OFF' ELSE NULL END FROM sys.sql_logins WHERE name = @name
 
            SET @tmpstr = 'CREATE LOGIN ' + QUOTENAME( @name ) + ' WITH PASSWORD = ' + @PWD_string + ' HASHED, SID = ' + @SID_string + ', DEFAULT_DATABASE = [' + @defaultdb + ']'

        IF ( @is_policy_checked IS NOT NULL )
        BEGIN
          SET @tmpstr = @tmpstr + ', CHECK_POLICY = ' + @is_policy_checked
        END
        IF ( @is_expiration_checked IS NOT NULL )
        BEGIN
          SET @tmpstr = @tmpstr + ', CHECK_EXPIRATION = ' + @is_expiration_checked
        END
    END
    IF (@denylogin = 1)
    BEGIN -- login is denied access
      SET @tmpstr = @tmpstr + '; DENY CONNECT SQL TO ' + QUOTENAME( @name )
    END
    ELSE IF (@hasaccess = 0)
    BEGIN -- login exists but does not have access
      SET @tmpstr = @tmpstr + '; REVOKE CONNECT SQL TO ' + QUOTENAME( @name )
    END
    IF (@is_disabled = 1)
    BEGIN -- login is disabled
      SET @tmpstr = @tmpstr + '; ALTER LOGIN ' + QUOTENAME( @name ) + ' DISABLE'
    END
    PRINT @tmpstr
  END

  FETCH NEXT FROM login_curs INTO @SID_varbinary, @name, @type, @is_disabled, @defaultdb, @hasaccess, @denylogin
   END
CLOSE login_curs
DEALLOCATE login_curs
RETURN 0


GO
/****** Object:  StoredProcedure [dbo].[usp_hexadecimal]    Script Date: 27/10/2015 09:31:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE PROCEDURE [dbo].[usp_hexadecimal]
	@binvalue varbinary(256),
	@hexvalue varchar (514) OUTPUT
AS
BEGIN
	SET NOCOUNT ON
	DECLARE @charvalue varchar (514)
	DECLARE @i int
	DECLARE @length int
	DECLARE @hexstring char(16)

	SELECT @charvalue = '0x'
	SELECT @i = 1
	SELECT @length = DATALENGTH (@binvalue)
	SELECT @hexstring = '0123456789ABCDEF'

	DECLARE @tempint int
	DECLARE @firstint int
	DECLARE @secondint int
	WHILE (@i <= @length)
	BEGIN
		SELECT @tempint = CONVERT(int, SUBSTRING(@binvalue,@i,1))
		SELECT @firstint = FLOOR(@tempint/16)
		SELECT @secondint = @tempint - (@firstint*16)
		SELECT @charvalue = @charvalue +
		SUBSTRING(@hexstring, @firstint+1, 1) +
		SUBSTRING(@hexstring, @secondint+1, 1)
		SELECT @i = @i + 1
	END

	SELECT @hexvalue = @charvalue
END


GO
/****** Object:  UserDefinedFunction [dbo].[GetJobName]    Script Date: 27/10/2015 09:31:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[GetJobName](@ProgramName varchar(255))
RETURNS VARCHAR(100)
AS
BEGIN
DECLARE @JobID varchar(100), @NewJobID varchar(100)
SET @JobID = SUBSTRING(@ProgramName,30,34)

SELECT @NewJobID = 'Job: '+name from msdb..sysjobs where job_id = SUBSTRING(@JobID, 9, 2)+
	SUBSTRING(@JobID, 7, 2)+
	SUBSTRING(@JobID, 5, 2)+
	SUBSTRING(@JobID, 3, 2)+'-'+
	SUBSTRING(@JobID, 13, 2)+
	SUBSTRING(@JobID, 11, 2)+'-'+
	SUBSTRING(@JobID, 17, 2)+
	SUBSTRING(@JobID, 15, 2)+'-'+
	SUBSTRING(@JobID, 19, 4)+'-'+
	SUBSTRING(@JobID, 23, 12)
RETURN REPLACE(@NewJobID,'Stats Processing - ','')
END



GO
/****** Object:  Table [dbo].[ActivityTable]    Script Date: 27/10/2015 09:31:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[ActivityTable](
	[RowNumber] [int] IDENTITY(0,1) NOT NULL,
	[EventClass] [int] NULL,
	[TextData] [ntext] NULL,
	[ApplicationName] [nvarchar](128) NULL,
	[NTUserName] [nvarchar](128) NULL,
	[LoginName] [nvarchar](128) NULL,
	[Duration] [bigint] NULL,
	[ClientProcessID] [int] NULL,
	[SPID] [int] NULL,
	[StartTime] [datetime] NULL,
	[EndTime] [datetime] NULL,
	[BinaryData] [image] NULL,
	[BigintData1] [bigint] NULL,
	[DatabaseID] [int] NULL,
	[DatabaseName] [nvarchar](128) NULL,
	[EventSequence] [bigint] NULL,
	[GroupID] [int] NULL,
	[HostName] [nvarchar](128) NULL,
	[IntegerData2] [int] NULL,
	[IsSystem] [int] NULL,
	[LoginSid] [image] NULL,
	[Mode] [int] NULL,
	[NTDomainName] [nvarchar](128) NULL,
	[ObjectID] [int] NULL,
	[ObjectID2] [bigint] NULL,
	[OwnerID] [int] NULL,
	[RequestID] [int] NULL,
	[ServerName] [nvarchar](128) NULL,
	[SessionLoginName] [nvarchar](128) NULL,
	[TransactionID] [bigint] NULL,
	[Type] [int] NULL,
	[Error] [int] NULL,
	[EventSubClass] [int] NULL,
	[State] [int] NULL,
	[Success] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[RowNumber] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[Audit]    Script Date: 27/10/2015 09:31:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Audit](
	[CreatedDateTime] [smalldatetime] NOT NULL,
	[SequenceNumber] [int] NOT NULL,
	[Succeeded] [bit] NULL,
	[SessionID] [smallint] NULL,
	[DatabaseID] [smallint] NULL,
	[ObjectID] [int] NULL,
	[Class_Type] [varchar](2) NULL,
	[ServerPrincipalName] [varchar](100) NULL,
	[DatabaseName] [varchar](20) NULL,
	[SchemaName] [varchar](20) NULL,
	[ObjectName] [varchar](50) NULL,
	[ExecutedStatement] [nvarchar](4000) NULL,
PRIMARY KEY CLUSTERED 
(
	[CreatedDateTime] ASC,
	[SequenceNumber] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Auditrace]    Script Date: 27/10/2015 09:31:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Auditrace](
	[Rowid] [int] IDENTITY(1,1) NOT NULL,
	[Traceid] [int] NULL,
	[Filename] [nvarchar](256) NULL,
	[Active] [char](1) NULL,
	[Dated] [datetime] NULL,
	[Processed] [char](1) NULL,
 CONSTRAINT [PK_Auditrace] PRIMARY KEY CLUSTERED 
(
	[Rowid] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[AuditResults]    Script Date: 27/10/2015 09:31:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[AuditResults](
	[RowNumber] [int] IDENTITY(0,1) NOT NULL,
	[EventClass] [int] NULL,
	[TextData] [ntext] NULL,
	[HostName] [nvarchar](128) NULL,
	[ApplicationName] [nvarchar](128) NULL,
	[LoginName] [nvarchar](128) NULL,
	[SPID] [int] NULL,
	[StartTime] [datetime] NULL,
	[DatabaseName] [nvarchar](128) NULL,
	[ServerName] [nvarchar](128) NULL,
	[ObjectID] [int] NULL,
	[ObjectType] [int] NULL,
	[ObjectName] [nvarchar](128) NULL,
	[Permissions] [bigint] NULL,
	[ColumnPermissions] [int] NULL,
	[RoleName] [nvarchar](128) NULL,
	[BinaryData] [image] NULL,
PRIMARY KEY CLUSTERED 
(
	[RowNumber] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
/****** Object:  Table [dbo].[CommandLog]    Script Date: 27/10/2015 09:31:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[CommandLog](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[DatabaseName] [sysname] NULL,
	[SchemaName] [sysname] NULL,
	[ObjectName] [sysname] NULL,
	[ObjectType] [char](2) NULL,
	[IndexName] [sysname] NULL,
	[IndexType] [tinyint] NULL,
	[StatisticsName] [sysname] NULL,
	[PartitionNumber] [int] NULL,
	[ExtendedInfo] [xml] NULL,
	[Command] [nvarchar](max) NOT NULL,
	[CommandType] [nvarchar](60) NOT NULL,
	[StartTime] [datetime] NOT NULL,
	[EndTime] [datetime] NULL,
	[ErrorNumber] [int] NULL,
	[ErrorMessage] [nvarchar](max) NULL,
 CONSTRAINT [PK_CommandLog] PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[dba_indexDefragLog]    Script Date: 27/10/2015 09:31:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[dba_indexDefragLog](
	[indexDefrag_id] [int] IDENTITY(1,1) NOT NULL,
	[databaseID] [int] NOT NULL,
	[databaseName] [nvarchar](128) NOT NULL,
	[objectID] [int] NOT NULL,
	[objectName] [nvarchar](128) NOT NULL,
	[indexID] [int] NOT NULL,
	[indexName] [nvarchar](128) NOT NULL,
	[partitionNumber] [smallint] NOT NULL,
	[fragmentation] [float] NOT NULL,
	[page_count] [int] NOT NULL,
	[dateTimeStart] [datetime] NOT NULL,
	[durationSeconds] [int] NOT NULL,
 CONSTRAINT [PK_indexDefragLog] PRIMARY KEY CLUSTERED 
(
	[indexDefrag_id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[DBMaint]    Script Date: 27/10/2015 09:31:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[DBMaint](
	[name] [varchar](100) NOT NULL,
	[status] [int] NULL,
	[issystem] [int] NULL,
	[isuser] [int] NULL,
	[Fullbackup] [int] NULL,
	[Diffbackup] [int] NULL,
	[Tranbackup] [int] NULL,
	[dbcc] [int] NULL,
	[reindex] [int] NULL,
	[indexdefrag] [int] NULL,
	[stats] [int] NULL,
	[notes] [varchar](1000) NULL,
 CONSTRAINT [PK__DBMaint__03317E3D] PRIMARY KEY CLUSTERED 
(
	[name] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = ON, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[ErrorLog]    Script Date: 27/10/2015 09:31:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ErrorLog](
	[LogDate] [datetime] NULL,
	[ProcessInfo] [varchar](50) NULL,
	[Error] [varchar](7000) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[EventLog]    Script Date: 27/10/2015 09:31:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[EventLog](
	[ID] [int] NOT NULL,
	[Log] [varchar](500) NULL,
	[Source] [varchar](100) NULL,
	[Type] [varchar](50) NULL,
	[Server] [varchar](50) NULL,
	[Date] [datetime] NULL,
	[Error] [int] NULL,
	[Other] [varchar](100) NULL,
	[Message] [varchar](5000) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[FragmentationLevels]    Script Date: 27/10/2015 09:31:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[FragmentationLevels](
	[ServerName] [char](255) NULL,
	[DatabaseName] [char](255) NULL,
	[TableName] [char](255) NULL,
	[IndexName] [char](255) NULL,
	[CountPages] [int] NULL,
	[CountRows] [int] NULL,
	[MinRecSize] [int] NULL,
	[MaxRecSize] [int] NULL,
	[AvgRecSize] [int] NULL,
	[ForRecCount] [int] NULL,
	[Extents] [int] NULL,
	[AvgFreeBytes] [int] NULL,
	[AvgPageDensity] [int] NULL,
	[ScanDensity] [decimal](18, 0) NULL,
	[BestCount] [int] NULL,
	[ActualCount] [int] NULL,
	[LogicalFrag] [decimal](18, 0) NULL,
	[ExtentFrag] [decimal](18, 0) NULL,
	[DateTime] [datetime] NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Job_Failures]    Script Date: 27/10/2015 09:31:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[Job_Failures](
	[Job_ID] [varchar](100) NULL,
	[Server] [varchar](50) NULL,
	[JobName] [varchar](100) NULL,
	[Step_ID] [smallint] NULL,
	[run_time] [smalldatetime] NULL,
	[running] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[JobAnalysis]    Script Date: 27/10/2015 09:31:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[JobAnalysis](
	[server] [nvarchar](50) NOT NULL,
	[jobname] [nvarchar](255) NOT NULL,
	[runstatus] [char](11) NOT NULL,
	[rundatetime] [datetime] NOT NULL,
	[dayofweek] [char](9) NOT NULL,
	[runtime] [char](8) NOT NULL,
	[duration_int] [int] NOT NULL,
	[duration_txt] [char](8) NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[PartitionLog]    Script Date: 27/10/2015 09:31:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[PartitionLog](
	[ID] [bigint] IDENTITY(1,1) NOT NULL,
	[EntryDate] [datetime] NULL,
	[ObjectID] [bigint] NULL,
	[DateRangeSwitchedInt] [int] NULL,
	[DateRangeSwitchedDate] [smalldatetime] NULL,
	[RowCountSwitched] [bigint] NULL,
	[Success] [bit] NULL,
	[Comments] [varchar](500) NULL,
PRIMARY KEY CLUSTERED 
(
	[ID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[PhysicalStats]    Script Date: 27/10/2015 09:31:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[PhysicalStats](
	[EntryDate] [datetime] NOT NULL,
	[database_id] [smallint] NULL,
	[object_id] [int] NULL,
	[index_id] [int] NULL,
	[partition_number] [int] NULL,
	[index_type_desc] [nvarchar](60) NULL,
	[alloc_unit_type_desc] [nvarchar](60) NULL,
	[index_depth] [tinyint] NULL,
	[index_level] [tinyint] NULL,
	[avg_fragmentation_in_percent] [float] NULL,
	[fragment_count] [bigint] NULL,
	[avg_fragment_size_in_pages] [float] NULL,
	[page_count] [bigint] NULL,
	[avg_page_space_used_in_percent] [float] NULL,
	[record_count] [bigint] NULL,
	[ghost_record_count] [bigint] NULL,
	[version_ghost_record_count] [bigint] NULL,
	[min_record_size_in_bytes] [int] NULL,
	[max_record_size_in_bytes] [int] NULL,
	[avg_record_size_in_bytes] [float] NULL,
	[forwarded_record_count] [bigint] NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[ReindexHistory]    Script Date: 27/10/2015 09:31:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[ReindexHistory](
	[DB] [varchar](100) NOT NULL,
	[TableName] [varchar](100) NOT NULL,
	[Index] [varchar](255) NULL,
	[Type] [int] NULL,
	[Clustered] [int] NOT NULL,
	[StartDateTime] [datetime] NOT NULL,
	[Seconds] [int] NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[SSISLog]    Script Date: 27/10/2015 09:31:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING OFF
GO
CREATE TABLE [dbo].[SSISLog](
	[EventID] [int] IDENTITY(1,1) NOT NULL,
	[EventType] [varchar](20) NOT NULL,
	[PackageName] [varchar](50) NOT NULL,
	[TaskName] [varchar](50) NOT NULL,
	[EventCode] [int] NULL,
	[EventDescription] [varchar](1000) NULL,
	[PackageDuration] [int] NULL,
	[ContainerDuration] [int] NULL,
	[InsertCount] [int] NULL,
	[UpdateCount] [int] NULL,
	[DeleteCount] [int] NULL,
	[Host] [varchar](50) NULL,
	[EventDate] [datetime] NULL
) ON [PRIMARY]
SET ANSI_PADDING ON
ALTER TABLE [dbo].[SSISLog] ADD [importpath] [varchar](100) NULL
 CONSTRAINT [PK_SSISLog] PRIMARY KEY CLUSTERED 
(
	[EventID] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[Table_1]    Script Date: 27/10/2015 09:31:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[Table_1](
	[test] [nchar](10) NULL
) ON [PRIMARY]

GO
/****** Object:  Table [dbo].[TableSizeLog]    Script Date: 27/10/2015 09:31:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[TableSizeLog](
	[DB] [varchar](100) NOT NULL,
	[DateTime] [datetime] NOT NULL,
	[TableName] [varchar](100) NOT NULL,
	[Rows] [bigint] NOT NULL,
	[Reserved_kb] [bigint] NOT NULL,
	[Data_kb] [bigint] NOT NULL,
	[Index_size_kb] [bigint] NOT NULL,
	[Unused_kb] [bigint] NOT NULL,
	[Size_kb] [bigint] NOT NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[UptimeHistory]    Script Date: 27/10/2015 09:31:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[UptimeHistory](
	[ID] [int] IDENTITY(2,1) NOT NULL,
	[LastPoll] [datetime] NULL,
	[ServerStarted] [datetime] NULL,
	[Type] [varchar](50) NULL,
	[AffectedSystem] [varchar](50) NULL
) ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
/****** Object:  Table [dbo].[WhoIsActive_20130503]    Script Date: 27/10/2015 09:31:01 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_PADDING ON
GO
CREATE TABLE [dbo].[WhoIsActive_20130503](
	[session_id] [smallint] NOT NULL,
	[dd hh:mm:ss.mss] [varchar](15) NULL,
	[physical_io] [varchar](27) NULL,
	[reads] [varchar](27) NULL,
	[physical_reads] [varchar](27) NULL,
	[writes] [varchar](27) NULL,
	[tempdb_writes] [varchar](27) NULL,
	[tempdb_current] [varchar](27) NULL,
	[CPU] [varchar](27) NULL,
	[context_switches] [varchar](27) NULL,
	[used_memory] [varchar](27) NULL,
	[threads] [smallint] NULL,
	[status] [varchar](30) NOT NULL,
	[wait_info] [varchar](4000) NULL,
	[tran_start_time] [datetime] NULL,
	[tran_log_writes] [varchar](4000) NULL,
	[open_tran_count] [int] NULL,
	[sql_command] [xml] NULL,
	[sql_text] [xml] NULL,
	[query_plan] [xml] NULL,
	[blocking_session_id] [smallint] NULL,
	[percent_complete] [real] NULL,
	[host_name] [varchar](128) NOT NULL,
	[login_name] [varchar](128) NOT NULL,
	[database_name] [varchar](128) NULL,
	[start_time] [datetime] NOT NULL,
	[request_id] [int] NULL,
	[collection_time] [datetime] NOT NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]

GO
SET ANSI_PADDING OFF
GO
ALTER TABLE [dbo].[Auditrace] ADD  CONSTRAINT [DF_Auditrace_Active]  DEFAULT ('Y') FOR [Active]
GO
ALTER TABLE [dbo].[Auditrace] ADD  CONSTRAINT [DF_Auditrace_Dated]  DEFAULT (getdate()) FOR [Dated]
GO
