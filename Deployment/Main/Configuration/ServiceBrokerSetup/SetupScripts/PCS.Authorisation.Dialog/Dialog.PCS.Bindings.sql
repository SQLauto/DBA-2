/*
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
*/

/****** Object:  RemoteServiceBinding [http://tfl.gov.uk/Ft/Pare/Authorisation/Bindings/Dre/Pare]    Script Date: 11/11/2015 10:15:38 ******/
CREATE REMOTE SERVICE BINDING [http://tfl.gov.uk/Ft/Pare/Authorisation/Bindings/Dre/Pare]  
	TO SERVICE N'http://tfl.gov.uk/Ft/Pare/Authorisation/Service/Dre/Pare'  
	WITH USER = [PareDialogUser] ,  ANONYMOUS = OFF 

/****** Object:  RemoteServiceBinding [http://tfl.gov.uk/Ft/Pare/Authorisation/Bindings/Idra/Pare]    Script Date: 11/11/2015 10:15:46 ******/
CREATE REMOTE SERVICE BINDING [http://tfl.gov.uk/Ft/Pare/Authorisation/Bindings/Idra/Pare]  
	TO SERVICE N'http://tfl.gov.uk/Ft/Pare/Authorisation/Service/Idra/Pare'  
	WITH USER = [PareDialogUser] ,  ANONYMOUS = OFF 

/****** Object:  RemoteServiceBinding [http://tfl.gov.uk/Ft/Pare/Authorisation/Bindings/Se/Pare]    Script Date: 11/11/2015 10:15:52 ******/
CREATE REMOTE SERVICE BINDING [http://tfl.gov.uk/Ft/Pare/Authorisation/Bindings/Se/Pare]  
	TO SERVICE N'http://tfl.gov.uk/Ft/Pare/Authorisation/Service/Se/Pare'  
	WITH USER = [PareDialogUser] ,  ANONYMOUS = OFF 

/****** Object:  RemoteServiceBinding [http://tfl.gov.uk/Ft/Pare/DirectPayment/Bindings/Pare]    Script Date: 11/11/2015 10:16:03 ******/
CREATE REMOTE SERVICE BINDING [http://tfl.gov.uk/Ft/Pare/DirectPayment/Bindings/Pare]  
	TO SERVICE N'http://tfl.gov.uk/Ft/Pare/DirectPayment/Service/Pare'  
	WITH USER = [PareDialogUser] ,  ANONYMOUS = OFF 

/****** Object:  RemoteServiceBinding [http://tfl.gov.uk/Ft/Pare/StatusList/Bindings/Pare]    Script Date: 11/11/2015 10:16:12 ******/
CREATE REMOTE SERVICE BINDING [http://tfl.gov.uk/Ft/Pare/StatusList/Bindings/Pare]  
	TO SERVICE N'http://tfl.gov.uk/Ft/Pare/StatusList/Service/Pare'  
	WITH USER = [PareDialogUser] ,  ANONYMOUS = OFF 

