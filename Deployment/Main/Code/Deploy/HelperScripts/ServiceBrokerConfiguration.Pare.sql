--- SERVICE BROKER SETUP

select * from sys.transmission_queue
select * from sys.service_queues

select service_broker_guid, * from sys.databases
select * from PARE.sys.routes where [name] like '%Pare%'

select * from PARE.sys.services where [name] like '%Pare%'
select * from PARE.sys.service_queues where [name] like '%Pare%' and is_activation_enabled = 1
select * from PARE.sys.certificates where [name] like '%Pare%' 

select * from master.sys.endpoints where [name] = 'PareEndpoint'
select * from master.sys.certificates where [name] like '%Pare%'
  

-- PARE SYSTEM STATUS
	select AuthorisationStatusId, AuthorisationResultId, * from PARE.dbo.AuthorisationLog
	select * from PARE.dbo.AuthorisationRequest
	select * from PARE.dbo.AuthorisationResponse
	select * from PARE.dbo.InvalidMessage

	select * from PARE.dbo.Heartbeat HB 
		left join PARE.dbo.HeartbeatResponse HBR on HB.id = HBR.HeartbeatId
	order by HB.id desc

	select * from PARE.dbo.EndOfDaySettlementProgress
	select PendingChargeStatusId, * from PARE.dbo.PendingCharge

	select * from PARE.dbo.SsbSessionConversations order by created desc
	
--select * from PARE.dbo.[http://tfl.gov.uk/Ft/Pare/Authorisation/Queue/Dre/Pare]
--select * from PARE.dbo.[http://tfl.gov.uk/Ft/Pare/Authorisation/Queue/Idra/Pare]
--select * from PARE.dbo.[http://tfl.gov.uk/Ft/Pare/Authorisation/Queue/Se/Pare]
