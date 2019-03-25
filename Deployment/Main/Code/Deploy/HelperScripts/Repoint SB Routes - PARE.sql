USE [PARE]
GO
ALTER ROUTE [http://tfl.gov.uk/Ft/Pare/Authorisation/Routes/Dre/Pcs] WITH ADDRESS = 'tcp://<PCS_IP_ADDRESS>:4022'
ALTER ROUTE [http://tfl.gov.uk/Ft/Pare/Authorisation/Routes/Idra/Pcs] WITH ADDRESS = 'tcp://<PCS_IP_ADDRESS>:4022'
ALTER ROUTE [http://tfl.gov.uk/Ft/Pare/Authorisation/Routes/Se/Pcs] WITH ADDRESS = 'tcp://<PCS_IP_ADDRESS>:4022'
ALTER ROUTE [http://tfl.gov.uk/Ft/Pare/DirectPayment/Routes/Pcs] WITH ADDRESS = 'tcp://<PCS_IP_ADDRESS>:4022'
ALTER ROUTE [http://tfl.gov.uk/Ft/Pare/StatusList/Routes/Pcs] WITH ADDRESS = 'tcp:// <PCS_IP_ADDRESS>:4022'
GO
