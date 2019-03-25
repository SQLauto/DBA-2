CREATE REMOTE SERVICE BINDING [http://tfl.gov.uk/Ft/Pare/Authorisation/Bindings/Dre/Pcs]
	TO SERVICE 'http://tfl.gov.uk/Ft/Pare/Authorisation/Service/Dre/Pcs'
	WITH USER = PcsDialogUser;

CREATE REMOTE SERVICE BINDING [http://tfl.gov.uk/Ft/Pare/Authorisation/Bindings/Idra/Pcs]
	TO SERVICE 'http://tfl.gov.uk/Ft/Pare/Authorisation/Service/Idra/Pcs'
	WITH USER = PcsDialogUser;

CREATE REMOTE SERVICE BINDING [http://tfl.gov.uk/Ft/Pare/Authorisation/Bindings/Se/Pcs]
	TO SERVICE 'http://tfl.gov.uk/Ft/Pare/Authorisation/Service/Se/Pcs'
	WITH USER = PcsDialogUser;

CREATE REMOTE SERVICE BINDING [http://tfl.gov.uk/Ft/Pare/DirectPayment/Bindings/Pcs]
	TO SERVICE 'http://tfl.gov.uk/Ft/Pare/DirectPayment/Service/Pcs'
	WITH USER = PcsDialogUser;

CREATE REMOTE SERVICE BINDING [http://tfl.gov.uk/Ft/Pare/StatusList/Bindings/Pcs]
	TO SERVICE 'http://tfl.gov.uk/Ft/Pare/StatusList/Service/Pcs'
	WITH USER = PcsDialogUser;