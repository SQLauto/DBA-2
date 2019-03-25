-- drop endpoint
IF EXISTS (select 1 FROM sys.endpoints WHERE [name] = 'PareEndpoint')
	DROP ENDPOINT [PareEndpoint]
GO

-- drop certs
IF EXISTS (select 1 FROM sys.certificates WHERE [name] = 'PareEndpointCertPrivate')
	DROP CERTIFICATE [PareEndpointCertPrivate]
GO

IF EXISTS (select 1 FROM sys.certificates WHERE [name] = 'PcsEndpointCertPublic')
	DROP CERTIFICATE [PcsEndpointCertPublic]
GO

-- master key
IF NOT EXISTS (select 1 from sys.symmetric_keys where name like '%DatabaseMasterKey%') 
	CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'fae123FAE';
GO

-- logins
IF NOT EXISTS (SELECT * FROM syslogins  WHERE [name] = 'PareEndpointLogin')
	CREATE LOGIN PareEndpointLogin WITH PASSWORD = 'awoxuJgktd{bco1zfdcbjoRsmsFT7_&#$!~<nj|amvov_R%d'
GO

IF NOT EXISTS (SELECT * FROM syslogins  WHERE [name] = 'PcsEndpointLogin')
	CREATE LOGIN PcsEndpointLogin WITH PASSWORD = '@c|txup|8tw.+fkkRwArutqwmsFT7_&#$!~<?g=w+zoJooa!'
GO

-- users
IF NOT EXISTS (SELECT * FROM sysusers WHERE [name] = 'PareEndpointUser')
	CREATE USER [PareEndpointUser] FOR LOGIN PareEndpointLogin
GO
IF NOT EXISTS (SELECT * FROM sysusers WHERE [name] = 'PcsEndpointUser')
	CREATE USER [PcsEndpointUser] FOR LOGIN PcsEndpointLogin;
GO

--:setvar path "D:\Deploy\ServiceBrokerSetup"

:r $(scriptPath)\Pare.Authorisation.Transport\Transport.Pare.Certs.sql

:r $(scriptPath)\Pare.Authorisation.Transport\Transport.Pare.Endpoint.sql
