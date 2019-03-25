--DROP DATABASE [PARE]
--GO

-- CLEAN ENV SETUP

-- Manually copy 2 SSB Certificate folders to D:
/*
"Copy SSB Certs and SSB Certs Pare Notifications folders to the D drive of the DB1 and DB2
 – Certificates location $/Deployment/Main/Configuration/ServiceBrokerSetup"
*/

:setvar path "D:\Baseline\1.ServiceBrokerSetup"
:setvar scriptpath "D:\Baseline\1.ServiceBrokerSetup"

:connect .\inst2

/* setting up...
server.ENDPOINT.PareEndpoint
server.LOGINS.PareEndpointLogin			Transport base

master.USERS.PareEndpointUser			Transport base
master.CERTS.PareEndpointCertPrivate

PARE.USERS.PareDialogUser
PARE.CERTS.PareDialogCertPrivate
*/

-- THESE VARY BY ENVIRONMENT 
:setvar PcsEndpoint "TCP://TS-DB2:4022"
:setvar PcsEndpointPort "4022"

:setvar PareEndpoint "TCP://TS-DB1:4022"
:setvar PareEndpointPort "4022"

USE [master]
GO

print 'Running Pare.Authorisation.Transport\Transport.Pare.sql'
GO
:r $(scriptPath)\Pare.Authorisation.Transport\Transport.Pare.sql -- used to be called on master
	-- base		PareEndpointLogin, PareEndpointUser
	-- certs
	-- endpoint
GO

--CREATE DATABASE [PARE]
--GO

USE [PARE]
GO

print 'Running Pare.Authorisation.Dialog\Dialog.Pare.sql'
GO
:r $(scriptPath)\Pare.Authorisation.Dialog\Dialog.Pare.sql
	-- WITH NO Permissions SCRIPT AT THE MOMENT - WHY ARE THERE NO SERVICES?
GO

:setvar NotificationsEndpoint "TCP://TS-DB1:4023"

USE [master]
GO

print 'running Pare.Notifications.Transport\Transport.Pare.sql'
GO
:r $(scriptPath)\Pare.Notifications.Transport\Transport.Pare.sql
GO

USE [PARE]
GO

print 'running Pare.Notifications.Dialog\Dialog.Pare.sql'
GO
:r $(scriptPath)\Pare.Notifications.Dialog\Dialog.Pare.sql   
	-- WITH NO Permissions SCRIPT AT THE MOMENT - WHY ARE THERE NO SERVICES?
GO
