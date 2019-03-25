--drop routes
IF EXISTS (select * from sys.routes where name = 'http://tfl.gov.uk/Ft/Pare/Authorisation/Routes/Dre/Pare')
	DROP ROUTE [http://tfl.gov.uk/Ft/Pare/Authorisation/Routes/Dre/Pare]
IF EXISTS (select * from sys.routes where name = 'http://tfl.gov.uk/Ft/Pare/Authorisation/Routes/Idra/Pare')
	DROP ROUTE [http://tfl.gov.uk/Ft/Pare/Authorisation/Routes/Idra/Pare]
IF EXISTS (select * from sys.routes where name = 'http://tfl.gov.uk/Ft/Pare/Authorisation/Routes/Se/Pare')
	DROP ROUTE [http://tfl.gov.uk/Ft/Pare/Authorisation/Routes/Se/Pare]
IF EXISTS (select * from sys.routes where name = 'http://tfl.gov.uk/Ft/Pare/DirectPayment/Routes/Pare')
	DROP ROUTE [http://tfl.gov.uk/Ft/Pare/DirectPayment/Routes/Pare]
IF EXISTS (select * from sys.routes where name = 'http://tfl.gov.uk/Ft/Pare/StatusList/Routes/Pare')
	DROP ROUTE [http://tfl.gov.uk/Ft/Pare/StatusList/Routes/Pare]
GO

--drop bindings
IF EXISTS (select * from sys.remote_service_bindings where name = 'http://tfl.gov.uk/Ft/Pare/Authorisation/Bindings/Dre/Pare')
	DROP REMOTE SERVICE BINDING [http://tfl.gov.uk/Ft/Pare/Authorisation/Bindings/Dre/Pare]
IF EXISTS (select * from sys.remote_service_bindings where name = 'http://tfl.gov.uk/Ft/Pare/Authorisation/Bindings/Idra/Pare')
	DROP REMOTE SERVICE BINDING [http://tfl.gov.uk/Ft/Pare/Authorisation/Bindings/Idra/Pare]
IF EXISTS (select * from sys.remote_service_bindings where name = 'http://tfl.gov.uk/Ft/Pare/Authorisation/Bindings/Se/Pare')
	DROP REMOTE SERVICE BINDING [http://tfl.gov.uk/Ft/Pare/Authorisation/Bindings/Se/Pare]
IF EXISTS (select * from sys.remote_service_bindings where name = 'http://tfl.gov.uk/Ft/Pare/DirectPayment/Bindings/Pare')
	DROP REMOTE SERVICE BINDING [http://tfl.gov.uk/Ft/Pare/DirectPayment/Bindings/Pare]
IF EXISTS (select * from sys.remote_service_bindings where name = 'http://tfl.gov.uk/Ft/Pare/StatusList/Bindings/Pare')
	DROP REMOTE SERVICE BINDING [http://tfl.gov.uk/Ft/Pare/StatusList/Bindings/Pare]
GO

-- drop certs
IF EXISTS (select 1 FROM sys.certificates WHERE [name] = 'PcsDialogCertPrivate')
	DROP CERTIFICATE [PcsDialogCertPrivate]

IF EXISTS (select 1 FROM sys.certificates WHERE [name] = 'PareDialogCertPublic')
	DROP CERTIFICATE [PareDialogCertPublic]

-- master key
IF NOT EXISTS (select 1 from sys.symmetric_keys where name like '%DatabaseMasterKey%') 
	CREATE MASTER KEY ENCRYPTION  BY PASSWORD = 'fae123FAE'
GO

-- users
IF NOT EXISTS (SELECT * FROM sysusers WHERE [name] = 'PareDialogUser')
	CREATE USER [PareDialogUser]
    WITHOUT LOGIN;
GO
IF NOT EXISTS (SELECT * FROM sysusers WHERE [name] = 'PcsDialogUser')
	CREATE USER [PcsDialogUser]
    WITHOUT LOGIN;
GO

--:setvar scriptpath "D:\Baseline\1.ServiceBrokerSetup"
--:setvar PcsEndpoint "TCP://10.33.50.128:4024"

print '    running Pare.Authorisation.Dialog\Dialog.PCS.Certs.sql'
:r $(scriptPath)\Pare.Authorisation.Dialog\Dialog.PCS.Certs.sql

print '    running Pare.Authorisation.Dialog\Dialog.PCS.Bindings.sql'
:r $(scriptPath)\Pare.Authorisation.Dialog\Dialog.PCS.Bindings.sql

print '    running Pare.Authorisation.Dialog\Dialog.PCS.Routes.sql'
:r $(scriptPath)\Pare.Authorisation.Dialog\Dialog.PCS.Routes.sql

print '    running Pare.Authorisation.Dialog\Dialog.PCS.Permissions.sql'
:r $(scriptPath)\Pare.Authorisation.Dialog\Dialog.PCS.Permissions.sql
