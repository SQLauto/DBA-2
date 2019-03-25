-- drop endpoint 
IF EXISTS (select 1 FROM sys.endpoints WHERE [name] = 'PcsEndpoint')
	DROP ENDPOINT [PcsEndpoint]
GO

-- drop certs
IF EXISTS (select 1 FROM sys.certificates WHERE [name] = 'PcsEndpointCertPrivate')
	DROP CERTIFICATE [PcsEndpointCertPrivate]
GO

IF EXISTS (select 1 FROM sys.certificates WHERE [name] = 'PareEndpointCertPublic')
	DROP CERTIFICATE [PareEndpointCertPublic]
GO

-- master key
IF NOT EXISTS (select 1 from sys.symmetric_keys where name like '%DatabaseMasterKey%')
	CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'fae123FAE';
GO

-- logins
IF NOT EXISTS (SELECT * FROM syslogins  WHERE [name] = 'PareEndpointLogin')
	CREATE LOGIN [PareEndpointLogin] WITH PASSWORD = 'hDfuixt gSyFo0{@fdjk kkrmsFT7_&#$!~<nfrvsboymhn|'
GO

IF NOT EXISTS (SELECT * FROM syslogins  WHERE [name] = 'PcsEndpointLogin')
	CREATE LOGIN [PcsEndpointLogin] WITH PASSWORD = 'hDfuixt gSyFo0{@fdjk kkrmsFT7_&#$!~<nfrvsboymhn|'
GO

--users
IF NOT EXISTS (SELECT * FROM sysusers WHERE [name] = 'PcsEndpointUser')
	CREATE USER [PcsEndpointUser] FOR LOGIN PcsEndpointLogin;
GO
IF NOT EXISTS (SELECT * FROM sysusers WHERE [name] = 'PareEndpointUser')
	CREATE USER [PareEndpointUser] FOR LOGIN PareEndpointLogin;
GO

-- Set from calling script
--:setvar path "D:\DBDeploy\PCS.Authorisation.Transport\"

:r $(path)\PCS.Authorisations.Transport\Transport.Pcs.Certs.sql

:r $(path)\PCS.Authorisations.Transport\Transport.Pcs.Endpoint.sql




