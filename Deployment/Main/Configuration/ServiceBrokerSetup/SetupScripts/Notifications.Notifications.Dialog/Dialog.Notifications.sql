--:error $(errorLogPath)\ErrorNotificationsDialog.txt
GO

--drop routes
IF EXISTS (select * from sys.routes where name = 'http://tfl.gov.uk/Ft/Pare/CustomerNotification/Routes/Pare')
	DROP ROUTE [http://tfl.gov.uk/Ft/Pare/CustomerNotification/Routes/Pare]

--drop bindings
IF EXISTS (select * from sys.remote_service_bindings where name = 'http://tfl.gov.uk/Ft/Pare/CustomerNotification/Bindings/Pare')
	DROP REMOTE SERVICE BINDING [http://tfl.gov.uk/Ft/Pare/CustomerNotification/Bindings/Pare]

-- drop certs
IF EXISTS (select 1 FROM sys.certificates WHERE [name] = 'EmailNotificationDialogCertPrivate')
	DROP CERTIFICATE [EmailNotificationDialogCertPrivate]
	
IF EXISTS (select 1 FROM sys.certificates WHERE [name] = 'PareNotificationDialogCertPublic')
	DROP CERTIFICATE [PareNotificationDialogCertPublic]	

-- create master key
IF NOT EXISTS (select 1 from sys.symmetric_keys where name like '%DatabaseMasterKey%')
	CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'fae123FAE'
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

:r $(scriptPath)\Notifications.Notifications.Dialog\Dialog.Notifications.Certs.sql

:r $(scriptPath)\Notifications.Notifications.Dialog\Dialog.Notifications.Bindings.sql

:r $(scriptPath)\Notifications.Notifications.Dialog\Dialog.Notifications.Routes.sql

--:r $(scriptPath)\Notifications.Notifications.Dialog\Dialog.Notifications.Permissions.sql