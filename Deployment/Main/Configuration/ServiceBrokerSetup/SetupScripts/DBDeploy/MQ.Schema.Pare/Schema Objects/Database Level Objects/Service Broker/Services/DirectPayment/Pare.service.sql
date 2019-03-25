CREATE SERVICE [http://tfl.gov.uk/Ft/Pare/DirectPayment/Service/Pare]
	ON QUEUE [dbo].[http://tfl.gov.uk/Ft/Pare/DirectPayment/Queue/Pare]
	( 
	    [http://tfl.gov.uk/Ft/Pare/DirectPayment/Contract/Pare],
		[http://tfl.gov.uk/Ft/Pare/DirectPayment/Contract/Pcs]
	)
