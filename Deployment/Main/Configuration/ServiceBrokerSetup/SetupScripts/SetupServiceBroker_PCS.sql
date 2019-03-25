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

-- THESE VARY BY ENVIRONMENT 
:setvar PcsEndpointPort "4022"
:setvar PareEndPoint "TCP://TS-DB1:4022"

/*USE [master]
GO

print 'Running PCS.AuthorisationTransport\Transport.PCS.sql'
GO
:r $(scriptPath)\PCS.Authorisations.Transport\Transport.PCS.sql -- used to be called on master
	-- base		PareEndpointLogin, PareEndpointUser
	-- certs
	-- endpoint
GO*/

USE [PCS]
GO

print 'Running PCS.Authorisation.Dialog\Dialog.PCS.sql'
GO
:r $(scriptPath)\PCS.Authorisation.Dialog\Dialog.PCS.sql -- used to be called on PCS

GO