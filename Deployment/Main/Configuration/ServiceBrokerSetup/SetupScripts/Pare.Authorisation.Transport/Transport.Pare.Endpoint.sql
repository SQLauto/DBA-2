CREATE ENDPOINT PareEndpoint
AUTHORIZATION PareEndpointLogin
STATE = STARTED 
AS TCP
(
	LISTENER_PORT = 4022
)
FOR SERVICE_BROKER
(
	AUTHENTICATION = CERTIFICATE PareEndPointCertPrivate,
	ENCRYPTION = DISABLED
)
GO

USE [master]
GO
print 'Setting Endpoint permissions...'
GRANT CONNECT ON ENDPOINT::PareEndpoint to PcsEndpointLogin;
