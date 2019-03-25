CREATE SERVICE [http://tfl.gov.uk/Ft/Pare/StatusList/Service/Pare]
	ON QUEUE [dbo].[http://tfl.gov.uk/Ft/Pare/StatusList/Queue/Pare]
	( 
	    [http://tfl.gov.uk/Ft/Pare/StatusList/Contract/Pare],
		[http://tfl.gov.uk/Ft/Pare/StatusList/Contract/Pcs]
	)