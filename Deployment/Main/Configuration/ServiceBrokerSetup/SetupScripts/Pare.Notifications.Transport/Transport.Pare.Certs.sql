USE [master]
GO
OPEN MASTER KEY DECRYPTION BY PASSWORD = 'fae123FAE'
-- Preprod, and devint have pare and pcs on the same instance, as such there is no explicit pare endpoint configured
-- (existing routes use LOCAL). To make notifications work we have to set it up explicitly
--IF '$(Environment)' IN ('PreProd', 'DevIntPerf')
BEGIN	
	IF NOT EXISTS (select * from sys.certificates where name = 'PareEndpointCertPrivate')
	BEGIN
		PRINT 'Creating PareEndpointCertPrivate'
		CREATE CERTIFICATE [PareEndpointCertPrivate]
			AUTHORIZATION PareEndpointUser
			FROM FILE = 'd:\SSB Certs\PareEndPointCert_Pub.cert'
			WITH PRIVATE KEY (FILE = 'd:\SSB Certs\PareEndPointCert_Pri.cert',
			DECRYPTION BY PASSWORD = 'fae123FAE');
	END
END

IF NOT EXISTS (select * from sys.certificates where name = 'NotificationsEndPointCertPublic')
BEGIN
	CREATE CERTIFICATE [NotificationsEndPointCertPublic]
		AUTHORIZATION PareEndpointUser 
		FROM FILE = 'd:\SSB Certs Pare Notifications\NotificationsEndPointCert_Pub.cert';
END
