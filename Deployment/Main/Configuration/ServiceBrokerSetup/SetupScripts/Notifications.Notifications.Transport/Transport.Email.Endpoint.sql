USE [master]
GO

IF NOT EXISTS (SELECT 1 FROM sys.endpoints WHERE name = 'EmailNotificationEndpoint')
BEGIN
	CREATE ENDPOINT EmailNotificationEndpoint
	AUTHORIZATION EmailNotificationEndpointLogin
	STATE = STARTED 
	AS TCP
	(
		LISTENER_PORT = 4023
	)
	FOR SERVICE_BROKER
	(
		AUTHENTICATION = CERTIFICATE NotificationsEndPointCertPrivate,
		ENCRYPTION = DISABLED
	)
END
GO

print 'Setting Endpoint permissions...'
GRANT CONNECT ON ENDPOINT::EmailNotificationEndpoint to PareNotificationEndpointLogin;
