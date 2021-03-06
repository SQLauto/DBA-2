
EXEC #CreateDummyStoredProcedureIfNotExists 'support', 'ErrorLogsOfInterestGet'
GO

alter proc [support].[ErrorLogsOfInterestGet]
	@startDateOfInterest datetime,
	@endDateOfInterest datetime,
	@readErrorLogNotAgentLog bit = 1,
	@fileOfInterestCurrent int = 0,
	@useExcludeList bit = 1
as

set transaction isolation level read uncommitted;

declare @errorLog int = 1
declare @agentLog int = 2
declare @logOfInterest int = @errorLog
if (@readErrorLogNotAgentLog = 0)
begin
	set @logOfInterest = @agentLog
end

declare @SqlErrorLog table
(
	LogDate datetime,
	ProcessInfo varchar(20),
	LogText varchar(max)
)

insert into @SqlErrorLog
 EXEC master.dbo.xp_readerrorlog @fileOfInterestCurrent, @logOfInterest

 delete from @SqlErrorLog where LogDate < @startDateOfInterest
 delete from @SqlErrorLog where LogDate > @endDateOfInterest

 if (@useExcludeList = 0)
 begin
	 select 
		LogDate,
		ProcessInfo,
		LogText
	  from 
		@SqlErrorLog 
	order by 
		LogDate
end
else
begin
	select 
		LogDate,
		ProcessInfo,
		LogText
	  from 
		@SqlErrorLog 
	 where
		LogText not like 'Log was backed up. Database:%'
	and LogText not like 'Database differential changes were backed up. Database:%This is an informational message. No user action is required.'
	and LogText not like 'This instance of SQL Server has been using a process ID of%This is an informational message only; no user action is '
	and LogText not like 'Service Broker login attempt failed with error: ''A previously existing connection with the same peer was detected during connection handshake. This connection lost the arbitration and it will be closed. All traffic will be redirected to the previously existing connection. This is an informational message only. No user action is required. State 80.%'
	and LogText not like 'Configuration option ''show advanced options'' changed from 1 to 1. Run the RECONFIGURE statement to install.'
	and LogText not like 'Configuration option ''xp_cmdshell'' changed from 0 to 1. Run the RECONFIGURE statement to install.'
	and LogText not like '(c) Microsoft Corporation.%'
	and LogText not like 'All rights reserved.%'
	and LogText not like 'Server process ID is%'
	and LogText not like 'System Manufacturer: %'
	and LogText not like 'Authentication mode is%'
	and LogText not like 'Logging SQL Server messages in file%'
	and LogText not like 'The service account is%This is an informational message; no user action is required.'
	and LogText not like 'The error log has been reinitialized. See the previous log for older entries.'
	and LogText not like 'This instance of SQL Server has been using a process ID of%This is an informational message only; no user action is '
	and LogText not like 'Service Broker login attempt failed with error: ''A previously existing connection with the same peer was detected during connection handshake. This connection lost the arbitration and it will be closed. All traffic will be redirected to the previously existing connection. This is an informational message only. No user action is required. State 80.%'
	and LogText not like 'Configuration option ''show advanced options'' changed from 1 to 1. Run the RECONFIGURE statement to install.'
	and LogText not like 'Configuration option ''xp_cmdshell'' changed from 0 to 1. Run the RECONFIGURE statement to install.'
	and LogText not like 'Microsoft SQL Server 2012%'
	order by 
		LogDate
end	 
	

GO
