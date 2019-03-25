USE [PCS]
GO

/****** Object:  ServiceContract [http://tfl.gov.uk/Ft/Pare/Authorisation/Contract/Pare]    Script Date: 11/11/2015 11:07:18 ******/
CREATE CONTRACT [http://tfl.gov.uk/Ft/Pare/Authorisation/Contract/Pare] ([http://tfl.gov.uk/Ft/Pare/Authorisation/Message/AccountVerification/Request] SENT BY INITIATOR,
[http://tfl.gov.uk/Ft/Pare/Authorisation/Message/Authorisation/Request] SENT BY INITIATOR,
[http://tfl.gov.uk/Ft/Pare/Authorisation/Message/AuthorisationReversal/Request] SENT BY INITIATOR,
[http://tfl.gov.uk/Ft/Pare/Authorisation/Message/Heartbeat/Request] SENT BY INITIATOR)

/****** Object:  ServiceContract [http://tfl.gov.uk/Ft/Pare/Authorisation/Contract/Pcs]    Script Date: 11/11/2015 11:07:23 ******/
CREATE CONTRACT [http://tfl.gov.uk/Ft/Pare/Authorisation/Contract/Pcs] ([http://tfl.gov.uk/Ft/Pare/Authorisation/Message/AccountVerification/Response] SENT BY INITIATOR,
[http://tfl.gov.uk/Ft/Pare/Authorisation/Message/Authorisation/Response] SENT BY INITIATOR,
[http://tfl.gov.uk/Ft/Pare/Authorisation/Message/AuthorisationReversal/Response] SENT BY INITIATOR,
[http://tfl.gov.uk/Ft/Pare/Authorisation/Message/Heartbeat/Response] SENT BY INITIATOR)

/****** Object:  ServiceContract [http://tfl.gov.uk/Ft/Pare/DirectPayment/Contract/Pare]    Script Date: 11/11/2015 11:07:31 ******/
CREATE CONTRACT [http://tfl.gov.uk/Ft/Pare/DirectPayment/Contract/Pare] ([http://tfl.gov.uk/Ft/Pare/DirectPayment/Message/Confirmation/Response] SENT BY INITIATOR)

/****** Object:  ServiceContract [http://tfl.gov.uk/Ft/Pare/DirectPayment/Contract/Pcs]    Script Date: 11/11/2015 11:07:37 ******/
CREATE CONTRACT [http://tfl.gov.uk/Ft/Pare/DirectPayment/Contract/Pcs] ([http://tfl.gov.uk/Ft/Pare/DirectPayment/Message/Confirmation/Request] SENT BY INITIATOR)

/****** Object:  ServiceContract [http://tfl.gov.uk/Ft/Pare/StatusList/Contract/Pare]    Script Date: 11/11/2015 11:07:43 ******/
CREATE CONTRACT [http://tfl.gov.uk/Ft/Pare/StatusList/Contract/Pare] ([http://tfl.gov.uk/Ft/Pare/StatusList/Message/StatusListUpdate/Request] SENT BY INITIATOR)

/****** Object:  ServiceContract [http://tfl.gov.uk/Ft/Pare/StatusList/Contract/Pcs]    Script Date: 11/11/2015 11:07:49 ******/
CREATE CONTRACT [http://tfl.gov.uk/Ft/Pare/StatusList/Contract/Pcs] ([http://tfl.gov.uk/Ft/Pare/StatusList/Message/StatusListUpdate/DeltaDistributionConfirmation] SENT BY INITIATOR,
[http://tfl.gov.uk/Ft/Pare/StatusList/Message/StatusListUpdate/Response] SENT BY INITIATOR)

