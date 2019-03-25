--:error $(errorLogPath)\ErrorPareNotificationsTransport.txt
GO

-- logins
IF NOT EXISTS (SELECT * FROM syslogins  WHERE [name] = 'PareNotificationEndpointLogin')
	CREATE LOGIN PareNotificationEndpointLogin WITH PASSWORD = 'awoxuJgktd{bco1zfdcbjoRsmsFT7_&#$!~<nj|amvov_R%d'
GO

IF NOT EXISTS (SELECT * FROM syslogins  WHERE [name] = 'EmailNotificationEndpointLogin')
	CREATE LOGIN EmailNotificationEndpointLogin WITH PASSWORD = '@c|txup|8tw.+fkkRwArutqwmsFT7_&#$!~<?g=w+zoJooa!'
GO

-- users
IF NOT EXISTS (SELECT * FROM sysusers WHERE [name] = 'PareNotificationEndpointUser')
	CREATE USER [PareNotificationEndpointUser] FOR LOGIN PareNotificationEndpointLogin
GO
IF NOT EXISTS (SELECT * FROM sysusers WHERE [name] = 'EmailNotificationEndpointUser')
	CREATE USER [EmailNotificationEndpointUser] FOR LOGIN EmailNotificationEndpointLogin;
GO


--:setvar scriptPath "D:\Deploy\ServiceBrokerSetup\Pare.Notifications.Transport"

-- Create public certificate for Notifications
:r $(scriptPath)\Pare.Notifications.Transport\Transport.Pare.Certs.sql


-- Create endpoint
:r $(scriptPath)\Pare.Notifications.Transport\Transport.Pare.Endpoint.sql
