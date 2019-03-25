--drop routes
IF EXISTS (select * from sys.routes where name = 'http://tfl.gov.uk/Ft/Pare/Authorisation/Routes/Dre/Pcs')
	DROP ROUTE [http://tfl.gov.uk/Ft/Pare/Authorisation/Routes/Dre/Pcs]
IF EXISTS (select * from sys.routes where name = 'http://tfl.gov.uk/Ft/Pare/Authorisation/Routes/Idra/Pcs')
	DROP ROUTE [http://tfl.gov.uk/Ft/Pare/Authorisation/Routes/Idra/Pcs]
IF EXISTS (select * from sys.routes where name = 'http://tfl.gov.uk/Ft/Pare/Authorisation/Routes/Se/Pcs')
	DROP ROUTE [http://tfl.gov.uk/Ft/Pare/Authorisation/Routes/Se/Pcs]
IF EXISTS (select * from sys.routes where name = 'http://tfl.gov.uk/Ft/Pare/DirectPayment/Routes/Pcs')
	DROP ROUTE [http://tfl.gov.uk/Ft/Pare/DirectPayment/Routes/Pcs]
IF EXISTS (select * from sys.routes where name = 'http://tfl.gov.uk/Ft/Pare/StatusList/Routes/Pcs')
	DROP ROUTE [http://tfl.gov.uk/Ft/Pare/StatusList/Routes/Pcs]
GO

--drop bindings
IF EXISTS (select * from sys.remote_service_bindings where name = 'http://tfl.gov.uk/Ft/Pare/Authorisation/Bindings/Dre/Pcs')
	DROP REMOTE SERVICE BINDING [http://tfl.gov.uk/Ft/Pare/Authorisation/Bindings/Dre/Pcs]
IF EXISTS (select * from sys.remote_service_bindings where name = 'http://tfl.gov.uk/Ft/Pare/Authorisation/Bindings/Idra/Pcs')
	DROP REMOTE SERVICE BINDING [http://tfl.gov.uk/Ft/Pare/Authorisation/Bindings/Idra/Pcs]
IF EXISTS (select * from sys.remote_service_bindings where name = 'http://tfl.gov.uk/Ft/Pare/Authorisation/Bindings/Se/Pcs')
	DROP REMOTE SERVICE BINDING [http://tfl.gov.uk/Ft/Pare/Authorisation/Bindings/Se/Pcs]
IF EXISTS (select * from sys.remote_service_bindings where name = 'http://tfl.gov.uk/Ft/Pare/DirectPayment/Bindings/Pcs')
	DROP REMOTE SERVICE BINDING [http://tfl.gov.uk/Ft/Pare/DirectPayment/Bindings/Pcs]
IF EXISTS (select * from sys.remote_service_bindings where name = 'http://tfl.gov.uk/Ft/Pare/StatusList/Bindings/Pcs')
	DROP REMOTE SERVICE BINDING [http://tfl.gov.uk/Ft/Pare/StatusList/Bindings/Pcs]
GO

-- drop certs
IF EXISTS (select 1 FROM sys.certificates WHERE [name] = 'PareDialogCertPrivate')
	DROP CERTIFICATE [PareDialogCertPrivate]

IF EXISTS (select 1 FROM sys.certificates WHERE [name] = 'PcsDialogCertPublic')
	DROP CERTIFICATE [PcsDialogCertPublic]

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

print '    running Pare.Authorisation.Dialog\Dialog.Pare.Certs.sql'
:r $(scriptPath)\Pare.Authorisation.Dialog\Dialog.Pare.Certs.sql

print '    running Pare.Authorisation.Dialog\Dialog.Pare.Bindings.sql'
:r $(scriptPath)\Pare.Authorisation.Dialog\Dialog.Pare.Bindings.sql

print '    running Pare.Authorisation.Dialog\Dialog.Pare.Routes.sql'
:r $(scriptPath)\Pare.Authorisation.Dialog\Dialog.Pare.Routes.sql

--print '    running Pare.Authorisation.Dialog\Dialog.Pare.Permissions.sql'
--:r $(scriptPath)\Pare.Authorisation.Dialog\Dialog.Pare.Permissions.sql
