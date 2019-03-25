USE [PCS]
GO

/****** Object:  BrokerService [http://tfl.gov.uk/Ft/Pare/Authorisation/Service/Dre/Pcs]    Script Date: 11/11/2015 11:02:55 ******/
CREATE SERVICE [http://tfl.gov.uk/Ft/Pare/Authorisation/Service/Dre/Pcs]  ON QUEUE [dbo].[http://tfl.gov.uk/Ft/Pare/Authorisation/Queue/Dre/Pcs] ([http://tfl.gov.uk/Ft/Pare/Authorisation/Contract/Pare],
[http://tfl.gov.uk/Ft/Pare/Authorisation/Contract/Pcs])

/****** Object:  BrokerService [http://tfl.gov.uk/Ft/Pare/Authorisation/Service/Idra/Pcs]    Script Date: 11/11/2015 11:03:02 ******/
CREATE SERVICE [http://tfl.gov.uk/Ft/Pare/Authorisation/Service/Idra/Pcs]  ON QUEUE [dbo].[http://tfl.gov.uk/Ft/Pare/Authorisation/Queue/Idra/Pcs] ([http://tfl.gov.uk/Ft/Pare/Authorisation/Contract/Pare],
[http://tfl.gov.uk/Ft/Pare/Authorisation/Contract/Pcs])

/****** Object:  BrokerService [http://tfl.gov.uk/Ft/Pare/Authorisation/Service/Se/Pcs]    Script Date: 11/11/2015 11:03:11 ******/
CREATE SERVICE [http://tfl.gov.uk/Ft/Pare/Authorisation/Service/Se/Pcs]  ON QUEUE [dbo].[http://tfl.gov.uk/Ft/Pare/Authorisation/Queue/Se/Pcs] ([http://tfl.gov.uk/Ft/Pare/Authorisation/Contract/Pare],
[http://tfl.gov.uk/Ft/Pare/Authorisation/Contract/Pcs])

/****** Object:  BrokerService [http://tfl.gov.uk/Ft/Pare/DirectPayment/Service/Pcs]    Script Date: 11/11/2015 11:03:18 ******/
CREATE SERVICE [http://tfl.gov.uk/Ft/Pare/DirectPayment/Service/Pcs]  ON QUEUE [dbo].[http://tfl.gov.uk/Ft/Pare/DirectPayment/Queue/Pcs] ([http://tfl.gov.uk/Ft/Pare/DirectPayment/Contract/Pare],
[http://tfl.gov.uk/Ft/Pare/DirectPayment/Contract/Pcs])

/****** Object:  BrokerService [http://tfl.gov.uk/Ft/Pare/StatusList/Service/Pcs]    Script Date: 11/11/2015 11:03:28 ******/
CREATE SERVICE [http://tfl.gov.uk/Ft/Pare/StatusList/Service/Pcs]  ON QUEUE [dbo].[http://tfl.gov.uk/Ft/Pare/StatusList/Queue/Pcs] ([http://tfl.gov.uk/Ft/Pare/StatusList/Contract/Pare],
[http://tfl.gov.uk/Ft/Pare/StatusList/Contract/Pcs])

