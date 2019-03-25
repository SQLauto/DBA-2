ALTER AUTHORIZATION ON SERVICE::[http://tfl.gov.uk/Ft/Pare/CustomerNotification/Service/Pare] TO PareEmailNotificationDialogUser;

GRANT SEND ON SERVICE::[http://tfl.gov.uk/Ft/Pare/CustomerNotification/Service/Pare] TO TargetEmailNotificationDialogUser;

--For some insane reason SQL Data tools revokes the connect permission on all the users
--that you created. Note that it only does this whilst deploying to SQL 2012, it's OK on 2008.
GRANT CONNECT TO PareEmailNotificationDialogUser;
GRANT CONNECT TO TargetEmailNotificationDialogUser;