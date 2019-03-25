OPEN MASTER KEY DECRYPTION BY PASSWORD = 'fae123FAE'
CREATE CERTIFICATE [PareNotificationDialogCertPublic]
	AUTHORIZATION PareEmailNotificationDialogUser FROM FILE = 'd:\SSB Certs Pare Notifications\PareNotificationDialogCert_Pub.cert';
GO

CREATE CERTIFICATE [EmailNotificationDialogCertPrivate]
	AUTHORIZATION TargetEmailNotificationDialogUser
	FROM FILE = 'd:\SSB Certs Pare Notifications\EmailNotificationsDialogCert_Pub.cert'
	WITH PRIVATE KEY (FILE = 'd:\SSB Certs Pare Notifications\EmailNotificationsDialogCert_Pri.cert',
	DECRYPTION BY PASSWORD = 'fae123FAE');
GO