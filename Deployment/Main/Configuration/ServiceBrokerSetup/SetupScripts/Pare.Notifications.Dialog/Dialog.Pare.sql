--:error $(errorLogPath)\ErrorPareNotificationsDialog.txt
GO

--drop routes
IF EXISTS (select * from sys.routes where name = 'http://tfl.gov.uk/Ft/Notification/Routes/Email')
	DROP ROUTE [http://tfl.gov.uk/Ft/Notification/Routes/Email]

--drop bindings
IF EXISTS (select * from sys.remote_service_bindings where name = 'http://tfl.gov.uk/Ft/Notification/Bindings/Email')
	DROP REMOTE SERVICE BINDING [http://tfl.gov.uk/Ft/Notification/Bindings/Email]

-- drop certs
IF EXISTS (select 1 FROM sys.certificates WHERE [name] = 'PareNotificationDialogCertPrivate')
	DROP CERTIFICATE [PareNotificationDialogCertPrivate]

IF EXISTS (select 1 FROM sys.certificates WHERE [name] = 'EmailNotificationDialogCertPublic')
	DROP CERTIFICATE [EmailNotificationDialogCertPublic]

-- master key
IF NOT EXISTS (select 1 from sys.symmetric_keys where name like '%DatabaseMasterKey%') 
	CREATE MASTER KEY ENCRYPTION  BY PASSWORD = 'fae123FAE'
GO

-- users
IF NOT EXISTS (SELECT * FROM sysusers WHERE [name] = 'PareEmailNotificationDialogUser')
	CREATE USER [PareEmailNotificationDialogUser]
    WITHOUT LOGIN;
GO
IF NOT EXISTS (SELECT * FROM sysusers WHERE [name] = 'TargetEmailNotificationDialogUser')
	CREATE USER [TargetEmailNotificationDialogUser]
    WITHOUT LOGIN;
GO

-- debug
--:setvar scriptpath "D:\Deploy\ServiceBrokerSetup\DBDeploy"

:r $(scriptPath)\Pare.Notifications.Dialog\Dialog.Pare.Certs.sql

:r $(scriptPath)\Pare.Notifications.Dialog\Dialog.Pare.Bindings.sql

:r $(scriptPath)\Pare.Notifications.Dialog\Dialog.Pare.Routes.sql

--:r D:\Deploy\ServiceBrokerSetup\DBDeploy\Pare.Notifications.Dialog\Dialog.Pare.Permissions.sql