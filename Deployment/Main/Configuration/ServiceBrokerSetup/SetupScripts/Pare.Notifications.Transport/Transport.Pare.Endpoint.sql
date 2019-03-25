USE [master]
GO

-- Preprod, and devint have pare and pcs on the same instance, as such there is no explicit pare endpoint configured
-- (existing routes use LOCAL). To make notifications work we have to set it up explicitly
--IF '$(Environment)' IN ('PreProd', 'DevIntPerf')
BEGIN	
	IF NOT EXISTS (SELECT 1 FROM sys.endpoints WHERE name = 'PareEndPoint')
	BEGIN
		Print 'Creating pare endpoint'
		CREATE ENDPOINT [PareEndpoint] 
		STATE=STARTED
		AS TCP 
		(
			LISTENER_PORT = 4022
		)
		FOR SERVICE_BROKER 
		(
			AUTHENTICATION = CERTIFICATE [PareEndpointCertPrivate],
			ENCRYPTION = DISABLED
		)
	END
END

print 'Setting Endpoint permissions...'
GRANT CONNECT ON ENDPOINT::PareEndpoint to EmailNotificationEndpointLogin;
