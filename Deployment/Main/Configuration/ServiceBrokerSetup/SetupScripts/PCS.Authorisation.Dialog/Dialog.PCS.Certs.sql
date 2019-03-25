/*   from PARE
OPEN MASTER KEY DECRYPTION BY PASSWORD = 'fae123FAE'

CREATE CERTIFICATE [PcsDialogCertPublic]
	AUTHORIZATION PcsDialogUser FROM FILE = 'd:\SSB Certs\PcsDialogCert_Pub.cert';

CREATE CERTIFICATE [PareDialogCertPrivate]
	AUTHORIZATION PareDialogUser
	FROM FILE = 'd:\SSB Certs\PareDialogCert_Pub.cert'
	WITH PRIVATE KEY (FILE = 'd:\SSB Certs\PareDialogCert_Pri.cert',
	DECRYPTION BY PASSWORD = 'fae123FAE');
*/

OPEN MASTER KEY DECRYPTION BY PASSWORD = 'fae123FAE'

CREATE CERTIFICATE [PareDialogCertPublic]
	AUTHORIZATION PareDialogUser FROM FILE = 'd:\SSB Certs\PareDialogCert_Pub.cert';

CREATE CERTIFICATE [PcsDialogCertPrivate]
	AUTHORIZATION PcsDialogUser
	FROM FILE = 'd:\SSB Certs\PcsDialogCert_Pub.cert'
	WITH PRIVATE KEY (FILE = 'd:\SSB Certs\PcsDialogCert_Pri.cert',
	DECRYPTION BY PASSWORD = 'fae123FAE');