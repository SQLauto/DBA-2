EXEC #CreateDummyStoredProcedureIfNotExists 'capture', 'WhoIsActiveData'
GO

ALTER PROC [capture].[WhoIsActiveData]
AS
BEGIN
	RETRY:		 
	SET ANSI_WARNINGS OFF
 
	DECLARE @destination_table VARCHAR(4000) ;
	DECLARE @startdate INT 
	DECLARE @ErrMsg varchar(max)
	SET @startdate=CONVERT(VARCHAR, GETDATE(), 112)
	SET @destination_table = 'WhoIsActive_' + CONVERT(VARCHAR, GETDATE(), 112) ;
	DECLARE @sql varchar(4000)

	BEGIN TRY
	IF OBJECT_ID(@destination_table,'U') IS  NULL
	BEGIN

	DECLARE @schema VARCHAR(4000) ;
	DECLARE @renametablename  VARCHAR(4000);

	EXEC dbo.sp_WhoIsActive
	@get_transaction_info = 1,
	@get_plans = 1,
	@get_outer_command = 1,
	@find_block_leaders = 1,
	@get_locks=1,
	@RETURN_SCHEMA = 1,
	@SCHEMA = @schema OUTPUT ;

	SET @schema = REPLACE(@schema, '<table_name> (','<table_name> (id int identity(1,1) PRIMARY KEY,' ) ;
	SET @schema = REPLACE(@schema, '<table_name>', @destination_table) ;


	EXEC(@schema) ;
	END 

	DECLARE
  
		@msg NVARCHAR(1000) ;

	SET @destination_table = 'Baselinedata.dbo.WhoIsActive_' + CONVERT(VARCHAR, GETDATE(), 112) ;

	DECLARE @numberOfRuns INT ;
	SET @numberOfRuns = 100 ;

	WHILE @startdate = CAST(CONVERT(VARCHAR, GETDATE(), 112) as int)
		BEGIN;
			EXEC dbo.sp_WhoIsActive @get_transaction_info = 1, @get_plans = 1,@get_outer_command = 1,
				@find_block_leaders = 1,@get_locks=1, @DESTINATION_TABLE = @destination_table ;

			SET @sql = 'DELETE FROM '+@destination_table+ ' where id >=' + cast((@@IDENTITY-1000) as varchar)
					+ ' and (database_name=''BaselineData'' '
					+' or cast(sql_text as varchar(max)) like ''%sp_server_diagnostics%'')'
			PRINT(@sql)
			EXEC(@sql)

			SET @numberOfRuns = @numberOfRuns - 1 ;

        
			IF  @startdate <= CAST(CONVERT(VARCHAR, GETDATE(), 112) as int)
				BEGIN
                           
					WAITFOR DELAY '00:00:10'
				END
			ELSE
				BEGIN
					SET @msg = CONVERT(CHAR(19), GETDATE(), 121) + ': ' + 'Done.'
                
				END

	END 
	END TRY
	BEGIN CATCH
	
		 SET @ErrMsg = ERROR_MESSAGE()
		 PRINT @ErrMsg
		 --rename the existing table as in existing table column additional_info does not exist
		 if(@ErrMsg like 'An explicit value for the identity column in table%' or @ErrMsg like '%Column name or number of supplied values does not match table definition%')
		 BEGIN
			SET @renametablename='old_' + replace(@destination_table,'Baselinedata.dbo.','')
			EXEC sp_rename @destination_table, @renametablename; 
			GOTO RETRY
         END
	END CATCH
END


GO