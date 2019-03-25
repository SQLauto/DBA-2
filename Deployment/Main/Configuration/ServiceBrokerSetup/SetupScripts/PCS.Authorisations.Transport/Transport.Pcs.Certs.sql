OPEN MASTER KEY DECRYPTION BY PASSWORD = 'fae123FAE'
CREATE CERTIFICATE [PcsEndpointCertPrivate]
	FROM FILE = 'D:\SSB Certs\PcsEndPointCert_Pub.cert'
	WITH PRIVATE KEY (FILE = 'D:\SSB Certs\PcsEndPointCert_Pri.cert',
	DECRYPTION BY PASSWORD = 'fae123FAE');
GO

CREATE CERTIFICATE [PareEndpointCertPublic]
	AUTHORIZATION PcsEndpointUser
	FROM FILE = 'D:\SSB Certs\PareEndpointCert_Pub.cert';
GO