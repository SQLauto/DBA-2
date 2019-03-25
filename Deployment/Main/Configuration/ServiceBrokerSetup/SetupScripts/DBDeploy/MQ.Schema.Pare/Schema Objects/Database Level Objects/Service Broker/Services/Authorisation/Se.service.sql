CREATE SERVICE [http://tfl.gov.uk/Ft/Pare/Authorisation/Service/Se/Pare]
	ON QUEUE [dbo].[http://tfl.gov.uk/Ft/Pare/Authorisation/Queue/Se/Pare]
	( 
	    [http://tfl.gov.uk/Ft/Pare/Authorisation/Contract/Pare],
		[http://tfl.gov.uk/Ft/Pare/Authorisation/Contract/Pcs]
	)