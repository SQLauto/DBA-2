ALTER AUTHORIZATION ON SERVICE::[http://tfl.gov.uk/Ft/Pare/Authorisation/Service/Idra/Pcs] TO PcsDialogUser;
ALTER AUTHORIZATION ON SERVICE::[http://tfl.gov.uk/Ft/Pare/Authorisation/Service/Dre/Pcs] TO PcsDialogUser;
ALTER AUTHORIZATION ON SERVICE::[http://tfl.gov.uk/Ft/Pare/Authorisation/Service/Se/Pcs] TO PcsDialogUser;
ALTER AUTHORIZATION ON SERVICE::[http://tfl.gov.uk/Ft/Pare/StatusList/Service/Pcs] TO PcsDialogUser;
ALTER AUTHORIZATION ON SERVICE::[http://tfl.gov.uk/Ft/Pare/DirectPayment/Service/Pcs] TO PcsDialogUser;

GRANT SEND ON SERVICE::[http://tfl.gov.uk/Ft/Pare/Authorisation/Service/Idra/Pcs] TO PareDialogUser;
GRANT SEND ON SERVICE::[http://tfl.gov.uk/Ft/Pare/Authorisation/Service/Dre/Pcs] TO PareDialogUser;
GRANT SEND ON SERVICE::[http://tfl.gov.uk/Ft/Pare/Authorisation/Service/Se/Pcs] TO PareDialogUser;
GRANT SEND ON SERVICE::[http://tfl.gov.uk/Ft/Pare/StatusList/Service/Pcs] TO PareDialogUser;
GRANT SEND ON SERVICE::[http://tfl.gov.uk/Ft/Pare/DirectPayment/Service/Pcs] TO PareDialogUser;

--For some insane reason SQL Data tools revokes the connect permission on all the users
--that you created. Note that it only does this whilst deploying to SQL 2012, it's OK on 2008.
GRANT CONNECT TO PareDialogUser;
GRANT CONNECT TO PcsDialogUser;