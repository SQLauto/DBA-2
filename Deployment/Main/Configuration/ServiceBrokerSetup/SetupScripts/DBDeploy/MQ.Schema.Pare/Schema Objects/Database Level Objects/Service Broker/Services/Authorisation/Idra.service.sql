CREATE SERVICE [http://tfl.gov.uk/Ft/Pare/Authorisation/Service/Idra/Pare]
	ON QUEUE [dbo].[http://tfl.gov.uk/Ft/Pare/Authorisation/Queue/Idra/Pare]
	( 
	    [http://tfl.gov.uk/Ft/Pare/Authorisation/Contract/Pare],
		[http://tfl.gov.uk/Ft/Pare/Authorisation/Contract/Pcs]
	)