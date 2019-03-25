--:error $(errorLogPath)\ErrorNotificationsTransport.txt
GO

-- master key
IF NOT EXISTS (select 1 from sys.symmetric_keys where name like '%DatabaseMasterKey%') 
	CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'fae123FAE';
GO

-- logins
IF NOT EXISTS (SELECT * FROM syslogins  WHERE [name] = 'PareNotificationEndpointLogin')
	CREATE LOGIN [PareNotificationEndpointLogin] WITH PASSWORD = 'hDfuixt gSyFo0{@fdjk kkrmsFT7_&#$!~<nfrvsboymhn|'
GO

IF NOT EXISTS (SELECT * FROM syslogins  WHERE [name] = 'EmailNotificationEndpointLogin')
	CREATE LOGIN [EmailNotificationEndpointLogin] WITH PASSWORD = 'hDfuixt gSyFo0{@fdjk kkrmsFT7_&#$!~<nfrvsboymhn|'
GO

--users
IF NOT EXISTS (SELECT * FROM sysusers WHERE [name] = 'EmailNotificationEndpointUser')
	CREATE USER [EmailNotificationEndpointUser] FOR LOGIN EmailNotificationEndpointLogin;
GO
IF NOT EXISTS (SELECT * FROM sysusers WHERE [name] = 'PareNotificationEndpointUser')
	CREATE USER [PareNotificationEndpointUser] FOR LOGIN PareNotificationEndpointLogin;
GO



-- Import certificates
print '  running Notifications.Notifications.Transport\Transport.Email.Certs.sql'
:r $(scriptPath)\Notifications.Notifications.Transport\Transport.Email.Certs.sql


-- Create endpoint
print '  running Notifications.Notifications.Transport\Transport.Email.Endpoint.sql'
:r $(scriptPath)\Notifications.Notifications.Transport\Transport.Email.Endpoint.sql




