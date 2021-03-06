EXEC #CreateDummyStoredProcedureIfNotExists 'dbo', 'GetAuditData'
GO

ALTER PROCEDURE [dbo].[GetAuditData]
AS

set transaction isolation level read uncommitted;

--GET BACKUP LOCATION
DECLARE @FolderLocation VARCHAR(1000) 
 SET @FolderLocation = (SELECT TOP 1 log_file_path from sys.server_file_audits)

--RAISE ERROR IF BACKUP LOCATION DOES NOT EXIST   
IF @FolderLocation IS NULL
RAISERROR(50005, 10, 1, N'No Audit File Location Found. Check Audit Exists')

--COMPLETE AUDIT LOCATION
SET @FolderLocation = @FolderLocation + '*.sqlaudit'

---AUDIT TABLE CLEANUP--ONLY KEEPING 2 WEEKS
DELETE FROM [Audit]
WHERE [eventtime] < DATEADD(DAY,-14,GETDATE())

--RESEED
IF CAST(GETDATE() AS DATE) <> (SELECT CAST(MAX(EventTime) AS DATE) FROM [System].[dbo].[Audit])
BEGIN
	DBCC CHECKIDENT ([Audit], RESEED, 1)
END

--LOAD DATA
MERGE [Audit] AS Target
USING (SELECT DISTINCT
			[event_time], 
			[action_id], 
			[session_id], 
			[object_id], 
			[class_type], 
			[server_principal_name],
			[database_principal_name], 
			[database_name], 
			[object_name], 
			[statement]
		FROM 
			sys.fn_get_audit_file(@FolderLocation,NULL,NULL)
		WHERE
			event_time >= GETDATE()-1) AS Source 
			ON (Target.[eventtime] = Source.event_time AND
				Target.[objectid] = Source.object_id)
WHEN NOT MATCHED 
	THEN INSERT ([EventTime]			,
				[ActionID]				,
				[SessionID]				,
				[ObjectID]				,
				[ClassType]				,
				[ServerPrincipalName]	,
				[DatabasePrincipalName] ,
				[DatabaseName]			,
				[ObjectName]			,
				[Statement]) 
		VALUES ([event_time], 
				[action_id], 
				[session_id], 
				[object_id], 
				[class_type], 
				[server_principal_name],
				[database_principal_name], 
				[database_name], 
				[object_name], 
				[statement]);
GO
