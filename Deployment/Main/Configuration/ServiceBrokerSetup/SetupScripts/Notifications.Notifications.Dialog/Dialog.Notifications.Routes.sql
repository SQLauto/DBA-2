--Not needed if you're restoring database as the routes are already created
CREATE ROUTE [http://tfl.gov.uk/Ft/Pare/CustomerNotification/Routes/Pare]
	WITH 
		SERVICE_NAME = 	'http://tfl.gov.uk/Ft/Pare/CustomerNotification/Service/Pare',
		ADDRESS = N'$(PareEndpoint)'