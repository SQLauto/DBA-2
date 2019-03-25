ALTER AUTHORIZATION ON SERVICE::[http://tfl.gov.uk/Ft/Pare/Authorisation/Service/Idra/Pare] TO PareDialogUser;
ALTER AUTHORIZATION ON SERVICE::[http://tfl.gov.uk/Ft/Pare/Authorisation/Service/Dre/Pare] TO PareDialogUser;
ALTER AUTHORIZATION ON SERVICE::[http://tfl.gov.uk/Ft/Pare/Authorisation/Service/Se/Pare] TO PareDialogUser;
ALTER AUTHORIZATION ON SERVICE::[http://tfl.gov.uk/Ft/Pare/StatusList/Service/Pare] TO PareDialogUser;
ALTER AUTHORIZATION ON SERVICE::[http://tfl.gov.uk/Ft/Pare/DirectPayment/Service/Pare] TO PareDialogUser;

GRANT SEND ON SERVICE::[http://tfl.gov.uk/Ft/Pare/Authorisation/Service/Idra/Pare] TO PcsDialogUser;
GRANT SEND ON SERVICE::[http://tfl.gov.uk/Ft/Pare/Authorisation/Service/Dre/Pare] TO PcsDialogUser;
GRANT SEND ON SERVICE::[http://tfl.gov.uk/Ft/Pare/Authorisation/Service/Se/Pare] TO PcsDialogUser;
GRANT SEND ON SERVICE::[http://tfl.gov.uk/Ft/Pare/StatusList/Service/Pare] TO PcsDialogUser;
GRANT SEND ON SERVICE::[http://tfl.gov.uk/Ft/Pare/DirectPayment/Service/Pare] TO PcsDialogUser;

--For some insane reason SQL Data tools revokes the connect permission on all the users
--that you created. Note that it only does this whilst deploying to SQL 2012, it's OK on 2008.
GRANT CONNECT TO PareDialogUser;
GRANT CONNECT TO PcsDialogUser;