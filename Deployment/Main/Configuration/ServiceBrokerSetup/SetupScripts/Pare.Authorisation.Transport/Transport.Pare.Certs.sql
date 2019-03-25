OPEN MASTER KEY DECRYPTION BY PASSWORD = 'fae123FAE'
CREATE CERTIFICATE [PareEndpointCertPrivate]
	FROM FILE = 'D:\SSB Certs\PareEndPointCert_Pub.cert'
	WITH PRIVATE KEY (FILE = 'D:\SSB Certs\PareEndPointCert_Pri.cert',
	DECRYPTION BY PASSWORD = 'fae123FAE');
GO

CREATE CERTIFICATE [PcsEndpointCertPublic]
	AUTHORIZATION PareEndpointUser
	FROM FILE = 'D:\SSB Certs\PcsEndpointCert_Pub.cert';
GO
