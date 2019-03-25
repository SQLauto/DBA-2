USE [PCS]
GO

/****** Object:  ServiceQueue [http://tfl.gov.uk/Ft/Pare/Authorisation/Queue/Dre/Pcs]    Script Date: 11/11/2015 11:04:22 ******/
CREATE QUEUE [dbo].[http://tfl.gov.uk/Ft/Pare/Authorisation/Queue/Dre/Pcs] WITH STATUS = ON , RETENTION = OFF , ACTIVATION (  STATUS = ON , PROCEDURE_NAME = [dbo].[PcsMockAuthorisationDreActivation] , MAX_QUEUE_READERS = 10 , EXECUTE AS OWNER  ), POISON_MESSAGE_HANDLING (STATUS = ON)  ON [PRIMARY] 

/****** Object:  ServiceQueue [http://tfl.gov.uk/Ft/Pare/Authorisation/Queue/Idra/Pcs]    Script Date: 11/11/2015 11:04:30 ******/
CREATE QUEUE [dbo].[http://tfl.gov.uk/Ft/Pare/Authorisation/Queue/Idra/Pcs] WITH STATUS = ON , RETENTION = OFF , ACTIVATION (  STATUS = ON , PROCEDURE_NAME = [dbo].[PcsMockAuthorisationIdraActivation] , MAX_QUEUE_READERS = 10 , EXECUTE AS OWNER  ), POISON_MESSAGE_HANDLING (STATUS = ON)  ON [PRIMARY] 

/****** Object:  ServiceQueue [http://tfl.gov.uk/Ft/Pare/Authorisation/Queue/Se/Pcs]    Script Date: 11/11/2015 11:04:36 ******/
CREATE QUEUE [dbo].[http://tfl.gov.uk/Ft/Pare/Authorisation/Queue/Se/Pcs] WITH STATUS = ON , RETENTION = OFF , ACTIVATION (  STATUS = ON , PROCEDURE_NAME = [dbo].[PcsMockAuthorisationSeActivation] , MAX_QUEUE_READERS = 10 , EXECUTE AS OWNER  ), POISON_MESSAGE_HANDLING (STATUS = ON)  ON [PRIMARY] 

/****** Object:  ServiceQueue [http://tfl.gov.uk/Ft/Pare/DirectPayment/Queue/Pcs]    Script Date: 11/11/2015 11:04:48 ******/
CREATE QUEUE [dbo].[http://tfl.gov.uk/Ft/Pare/DirectPayment/Queue/Pcs] WITH STATUS = ON , RETENTION = OFF , POISON_MESSAGE_HANDLING (STATUS = ON)  ON [PRIMARY] 

/****** Object:  ServiceQueue [http://tfl.gov.uk/Ft/Pare/StatusList/Queue/Pcs]    Script Date: 11/11/2015 11:05:04 ******/
CREATE QUEUE [dbo].[http://tfl.gov.uk/Ft/Pare/StatusList/Queue/Pcs] WITH STATUS = ON , RETENTION = OFF , ACTIVATION (  STATUS = ON , PROCEDURE_NAME = [dbo].[PcsMockStatusListActivation] , MAX_QUEUE_READERS = 10 , EXECUTE AS OWNER  ), POISON_MESSAGE_HANDLING (STATUS = ON)  ON [PRIMARY] 

