--GRANT CONNECT TO [FAELab\ZsvcPare]
--GO
USE [$(DatabaseName)]

-- allow RECEIVE from the notification service queue
GRANT RECEIVE ON [dbo].[http://tfl.gov.uk/Ft/Pare/Queue/Pare_Notification] TO [FAE\zsvcPare]


-- allow VIEW DEFINITION right on the notification service
GRANT VIEW DEFINITION ON SERVICE::[http://tfl.gov.uk/Ft/Pare/Service/Pare_Notification] TO [FAE\zsvcPare]


-- allow REFRENCES right on the notification queue schema
GRANT REFERENCES ON SCHEMA::dbo TO [FAE\zsvcPare]
