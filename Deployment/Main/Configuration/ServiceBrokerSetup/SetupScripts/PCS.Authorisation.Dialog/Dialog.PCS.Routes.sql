/*CREATE ROUTE [http://tfl.gov.uk/Ft/Pare/Authorisation/Routes/Idra/Pcs]
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
*/

/****** Object:  ServiceRoute [http://tfl.gov.uk/Ft/Pare/Authorisation/Routes/Dre/Pare]    Script Date: 11/11/2015 10:19:18 ******/
CREATE ROUTE [http://tfl.gov.uk/Ft/Pare/Authorisation/Routes/Dre/Pare]   
	WITH  SERVICE_NAME  = N'http://tfl.gov.uk/Ft/Pare/Authorisation/Service/Dre/Pare' ,  
	ADDRESS  = N'$(PareEndpoint)'

/****** Object:  ServiceRoute [http://tfl.gov.uk/Ft/Pare/Authorisation/Routes/Idra/Pare]    Script Date: 11/11/2015 10:19:24 ******/
CREATE ROUTE [http://tfl.gov.uk/Ft/Pare/Authorisation/Routes/Idra/Pare]   
	WITH  SERVICE_NAME  = N'http://tfl.gov.uk/Ft/Pare/Authorisation/Service/Idra/Pare' ,  
	ADDRESS  = N'$(PareEndpoint)' 


/****** Object:  ServiceRoute [http://tfl.gov.uk/Ft/Pare/Authorisation/Routes/Se/Pare]    Script Date: 11/11/2015 10:19:31 ******/
CREATE ROUTE [http://tfl.gov.uk/Ft/Pare/Authorisation/Routes/Se/Pare]   
	WITH  SERVICE_NAME  = N'http://tfl.gov.uk/Ft/Pare/Authorisation/Service/Se/Pare' ,  
	ADDRESS  = N'$(PareEndpoint)'

/****** Object:  ServiceRoute [http://tfl.gov.uk/Ft/Pare/DirectPayment/Routes/Pare]    Script Date: 11/11/2015 10:19:38 ******/
CREATE ROUTE [http://tfl.gov.uk/Ft/Pare/DirectPayment/Routes/Pare]   
	WITH  SERVICE_NAME  = N'http://tfl.gov.uk/Ft/Pare/DirectPayment/Service/Pare' ,  
	ADDRESS  = N'$(PareEndpoint)' 

/****** Object:  ServiceRoute [http://tfl.gov.uk/Ft/Pare/StatusList/Routes/Pare]    Script Date: 11/11/2015 10:19:45 ******/
CREATE ROUTE [http://tfl.gov.uk/Ft/Pare/StatusList/Routes/Pare]   
	WITH  SERVICE_NAME  = N'http://tfl.gov.uk/Ft/Pare/StatusList/Service/Pare' ,  
	ADDRESS  = N'$(PareEndpoint)' 


