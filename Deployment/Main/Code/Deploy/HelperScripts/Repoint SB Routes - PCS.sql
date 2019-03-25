USE [PCS]
GO
ALTER ROUTE [http://tfl.gov.uk/Ft/Pare/Authorisation/Routes/Dre/Pare] WITH ADDRESS  = N'TCP://<PARE_IP_ADDRESS>:4022' 
ALTER ROUTE [http://tfl.gov.uk/Ft/Pare/Authorisation/Routes/Idra/Pare] WITH ADDRESS  = N'TCP://<PARE_IP_ADDRESS>:4022' 
ALTER ROUTE [http://tfl.gov.uk/Ft/Pare/Authorisation/Routes/Se/Pare] WITH ADDRESS  = N'TCP://<PARE_IP_ADDRESS>:4022' 
ALTER ROUTE [http://tfl.gov.uk/Ft/Pare/DirectPayment/Routes/Pare] WITH ADDRESS  = N'TCP://<PARE_IP_ADDRESS>:4022' 
ALTER ROUTE [http://tfl.gov.uk/Ft/Pare/StatusList/Routes/Dre/Pare] WITH ADDRESS  = N'TCP://<PARE_IP_ADDRESS>:4022' 
GO
