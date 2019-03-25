CREATE SERVICE [http://tfl.gov.uk/Ft/Pare/Authorisation/Service/Dre/Pare]
	ON QUEUE [dbo].[http://tfl.gov.uk/Ft/Pare/Authorisation/Queue/Dre/Pare]
	( 
	    [http://tfl.gov.uk/Ft/Pare/Authorisation/Contract/Pare],
		[http://tfl.gov.uk/Ft/Pare/Authorisation/Contract/Pcs]
	)