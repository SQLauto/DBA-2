IF EXISTS( SELECT * FROM sys.server_event_sessions WHERE name='Errors') 
DROP EVENT SESSION [Errors] ON SERVER 
GO 
CREATE EVENT SESSION [Errors] ON SERVER 
ADD EVENT sqlserver.error_reported(
    ACTION(sqlserver.client_app_name,sqlserver.client_connection_id,sqlserver.client_hostname,sqlserver.database_id,sqlserver.query_hash,sqlserver.session_id,sqlserver.sql_text,sqlserver.tsql_frame,sqlserver.tsql_stack)
    WHERE ([package0].[equal_boolean]([sqlserver].[is_system],(0)) AND [package0].[greater_than_int64]([severity],(15)))) 
ADD TARGET package0.event_file(SET filename=N'$(driveletter):\TFL\Logs\SqlExtendedEvents\SqlExtendedEvents')
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=ON)
GO

ALTER EVENT SESSION [Errors]  
ON SERVER  
STATE = start;