USE [PCS]
GO

/****** Object:  MessageType [http://tfl.gov.uk/Ft/Pare/Authorisation/Message/AccountVerification/Request]    Script Date: 11/11/2015 11:08:37 ******/
CREATE MESSAGE TYPE [http://tfl.gov.uk/Ft/Pare/Authorisation/Message/AccountVerification/Request] VALIDATION = VALID_XML WITH SCHEMA COLLECTION [dbo].[http://tfl.gov.uk/Ft/Pare/Authorisation/Schema/AccountVerification/Request/v1]

/****** Object:  MessageType [http://tfl.gov.uk/Ft/Pare/Authorisation/Message/AccountVerification/Response]    Script Date: 11/11/2015 11:08:42 ******/
CREATE MESSAGE TYPE [http://tfl.gov.uk/Ft/Pare/Authorisation/Message/AccountVerification/Response] VALIDATION = WELL_FORMED_XML

/****** Object:  MessageType [http://tfl.gov.uk/Ft/Pare/Authorisation/Message/Authorisation/Request]    Script Date: 11/11/2015 11:08:48 ******/
CREATE MESSAGE TYPE [http://tfl.gov.uk/Ft/Pare/Authorisation/Message/Authorisation/Request] VALIDATION = VALID_XML WITH SCHEMA COLLECTION [dbo].[http://tfl.gov.uk/Ft/Pare/Authorisation/Schema/Authorisation/Request/v1]

/****** Object:  MessageType [http://tfl.gov.uk/Ft/Pare/Authorisation/Message/Authorisation/Response]    Script Date: 11/11/2015 11:08:54 ******/
CREATE MESSAGE TYPE [http://tfl.gov.uk/Ft/Pare/Authorisation/Message/Authorisation/Response] VALIDATION = WELL_FORMED_XML

/****** Object:  MessageType [http://tfl.gov.uk/Ft/Pare/Authorisation/Message/AuthorisationReversal/Request]    Script Date: 11/11/2015 11:09:04 ******/
CREATE MESSAGE TYPE [http://tfl.gov.uk/Ft/Pare/Authorisation/Message/AuthorisationReversal/Request] VALIDATION = VALID_XML WITH SCHEMA COLLECTION [dbo].[http://tfl.gov.uk/Ft/Pare/Authorisation/Schema/AuthorisationReversal/Request/v1]

/****** Object:  MessageType [http://tfl.gov.uk/Ft/Pare/Authorisation/Message/AuthorisationReversal/Response]    Script Date: 11/11/2015 11:09:12 ******/
CREATE MESSAGE TYPE [http://tfl.gov.uk/Ft/Pare/Authorisation/Message/AuthorisationReversal/Response] VALIDATION = WELL_FORMED_XML

/****** Object:  MessageType [http://tfl.gov.uk/Ft/Pare/Authorisation/Message/Heartbeat/Request]    Script Date: 11/11/2015 11:09:20 ******/
CREATE MESSAGE TYPE [http://tfl.gov.uk/Ft/Pare/Authorisation/Message/Heartbeat/Request] VALIDATION = VALID_XML WITH SCHEMA COLLECTION [dbo].[http://tfl.gov.uk/Ft/Pare/Authorisation/Schema/Heartbeat/Request/v1]

/****** Object:  MessageType [http://tfl.gov.uk/Ft/Pare/Authorisation/Message/Heartbeat/Response]    Script Date: 11/11/2015 11:09:26 ******/
CREATE MESSAGE TYPE [http://tfl.gov.uk/Ft/Pare/Authorisation/Message/Heartbeat/Response] VALIDATION = WELL_FORMED_XML

/****** Object:  MessageType [http://tfl.gov.uk/Ft/Pare/DirectPayment/Message/Confirmation/Request]    Script Date: 11/11/2015 11:09:32 ******/
CREATE MESSAGE TYPE [http://tfl.gov.uk/Ft/Pare/DirectPayment/Message/Confirmation/Request] VALIDATION = WELL_FORMED_XML

/****** Object:  MessageType [http://tfl.gov.uk/Ft/Pare/DirectPayment/Message/Confirmation/Response]    Script Date: 11/11/2015 11:09:38 ******/
CREATE MESSAGE TYPE [http://tfl.gov.uk/Ft/Pare/DirectPayment/Message/Confirmation/Response] VALIDATION = VALID_XML WITH SCHEMA COLLECTION [dbo].[http://tfl.gov.uk/Ft/Pare/DirectPayment/Schema/Confirmation/Response/]

/****** Object:  MessageType [http://tfl.gov.uk/Ft/Pare/StatusList/Message/StatusListUpdate/DeltaDistributionConfirmation]    Script Date: 11/11/2015 11:09:46 ******/
CREATE MESSAGE TYPE [http://tfl.gov.uk/Ft/Pare/StatusList/Message/StatusListUpdate/DeltaDistributionConfirmation] VALIDATION = WELL_FORMED_XML

/****** Object:  MessageType [http://tfl.gov.uk/Ft/Pare/StatusList/Message/StatusListUpdate/Request]    Script Date: 11/11/2015 11:09:56 ******/
CREATE MESSAGE TYPE [http://tfl.gov.uk/Ft/Pare/StatusList/Message/StatusListUpdate/Request] VALIDATION = VALID_XML WITH SCHEMA COLLECTION [dbo].[http://tfl.gov.uk/Ft/Pare/StatusList/Schema/StatusListUpdate/Request/v0.1]

/****** Object:  MessageType [http://tfl.gov.uk/Ft/Pare/StatusList/Message/StatusListUpdate/Response]    Script Date: 11/11/2015 11:10:18 ******/
CREATE MESSAGE TYPE [http://tfl.gov.uk/Ft/Pare/StatusList/Message/StatusListUpdate/Response] VALIDATION = WELL_FORMED_XML