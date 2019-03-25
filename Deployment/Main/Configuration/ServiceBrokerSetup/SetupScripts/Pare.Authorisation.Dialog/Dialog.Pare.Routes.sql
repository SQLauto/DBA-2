CREATE ROUTE [http://tfl.gov.uk/Ft/Pare/Authorisation/Routes/Idra/Pcs]
	WITH 
		SERVICE_NAME = 	'http://tfl.gov.uk/Ft/Pare/Authorisation/Service/Idra/Pcs',
		ADDRESS = N'$(PcsEndpoint)'

CREATE ROUTE [http://tfl.gov.uk/Ft/Pare/Authorisation/Routes/Dre/Pcs]
	WITH 
		SERVICE_NAME = 	'http://tfl.gov.uk/Ft/Pare/Authorisation/Service/Dre/Pcs',
		ADDRESS = N'$(PcsEndpoint)'

CREATE ROUTE [http://tfl.gov.uk/Ft/Pare/Authorisation/Routes/Se/Pcs]
	WITH 
		SERVICE_NAME = 	'http://tfl.gov.uk/Ft/Pare/Authorisation/Service/Se/Pcs',
		ADDRESS = N'$(PcsEndpoint)'

CREATE ROUTE [http://tfl.gov.uk/Ft/Pare/DirectPayment/Routes/Pcs]
	WITH 
		SERVICE_NAME = 	'http://tfl.gov.uk/Ft/Pare/DirectPayment/Service/Pcs',
		ADDRESS = N'$(PcsEndpoint)'

CREATE ROUTE [http://tfl.gov.uk/Ft/Pare/StatusList/Routes/Pcs]
	WITH 
		SERVICE_NAME = 	'http://tfl.gov.uk/Ft/Pare/StatusList/Service/Pcs',
		ADDRESS = N'$(PcsEndpoint)'