EXEC #CreateDummyStoredProcedureIfNotExists 'dbo', 'CheckLinkedServer'
GO


ALTER PROCEDURE [dbo].[CheckLinkedServer]
AS
set transaction isolation level read uncommitted;

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
