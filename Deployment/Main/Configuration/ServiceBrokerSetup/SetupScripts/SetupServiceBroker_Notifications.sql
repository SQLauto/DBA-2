
-- CLEAN ENV SETUP


-- Manually copy 2 SSB Certificate folders to D:
/*
"Copy SSB Certs and SSB Certs Pare Notifications folders to the D drive of the DB1 and DB2
 – Certificates location $/Deployment/Main/Configuration/ServiceBrokerSetup"
*/

:setvar path "D:\Baseline\1.ServiceBrokerSetup"
:setvar scriptpath "D:\Baseline\1.ServiceBrokerSetup"
:setvar PareEndpoint "TCP://TS-DB1:4022"

:connect .\inst3

USE [master]
GO

print 'Running Notifications.Notifications.Transport\Transport.Email.sql'
GO
:r $(scriptPath)\Notifications.Notifications.Transport\Transport.Email.sql
GO


--CREATE DATABASE [Notification]
--GO

USE [Notification]
GO

print 'Running Notifications.Notifications.Dialog\Dialog.Notifications.sql'
GO
:r $(scriptPath)\Notifications.Notifications.Dialog\Dialog.Notifications.sql
GO

--ALTER DATABASE [Notifications] SET ENABLE_BROKER

/*
Enable Service Broker on the following databases by right clicking properties -> Options ->Service broker -> Broker Enabled = True
TS-DB1\INST2.Pare 
TS-DB2\INST2.PCS
TS-DB1\INST3.Notifications
*/

/*
If you’re receiving the error
An exception occurred while enqueueing a message in the target queue. 
Error: 15581 State: 7. Please create a master key in the database or open the master key in the session
 before performing this operation
To fix this you’d need to run this statement
*/
--alter [master] key add encryption by service master key
