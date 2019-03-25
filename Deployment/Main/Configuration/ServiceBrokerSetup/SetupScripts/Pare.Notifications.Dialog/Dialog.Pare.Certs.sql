OPEN MASTER KEY DECRYPTION BY PASSWORD = 'fae123FAE'
CREATE CERTIFICATE [EmailNotificationDialogCertPublic]
	AUTHORIZATION TargetEmailNotificationDialogUser FROM FILE = 'd:\SSB Certs Pare Notifications\EmailNotificationsDialogCert_Pub.cert';

CREATE CERTIFICATE [PareNotificationDialogCertPrivate]
	AUTHORIZATION PareEmailNotificationDialogUser
	FROM FILE = 'd:\SSB Certs Pare Notifications\PareNotificationDialogCert_Pub.cert'
	WITH PRIVATE KEY (FILE = 'd:\SSB Certs Pare Notifications\PareNotificationDialogCert_Pri.cert',
	DECRYPTION BY PASSWORD = 'fae123FAE');