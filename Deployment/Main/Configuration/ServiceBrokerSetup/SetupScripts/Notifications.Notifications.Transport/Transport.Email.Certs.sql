USE [master]
GO
OPEN MASTER KEY DECRYPTION BY PASSWORD = 'fae123FAE'
if not exists (select * from sys.certificates where name = 'PareEndpointCertPublic')
begin
	CREATE CERTIFICATE [PareEndpointCertPublic]
		AUTHORIZATION EmailNotificationEndpointUser 
		FROM FILE = 'd:\SSB Certs Pare Notifications\PareEndPointCert_Pub.cert';
end
GO
	
if not exists (select * from sys.certificates where name = 'NotificationsEndPointCertPrivate')
begin
	CREATE CERTIFICATE [NotificationsEndPointCertPrivate]
		AUTHORIZATION EmailNotificationEndpointUser
		FROM FILE = 'd:\SSB Certs Pare Notifications\NotificationsEndPointCert_Pub.cert'
		WITH PRIVATE KEY (FILE = 'd:\SSB Certs Pare Notifications\NotificationsEndPointCert_Pri.cert',
		DECRYPTION BY PASSWORD = 'fae123FAE');
end
GO
