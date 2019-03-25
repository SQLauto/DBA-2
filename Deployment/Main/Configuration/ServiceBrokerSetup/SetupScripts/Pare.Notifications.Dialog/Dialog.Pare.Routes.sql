--Not needed if you're restoring database as the routes are already created
CREATE ROUTE [http://tfl.gov.uk/Ft/Notification/Routes/Email]
	WITH 
		SERVICE_NAME = 	'http://tfl.gov.uk/Ft/Notification/Service/Email',
		ADDRESS = N'$(NotificationsEndpoint)' -- 'TCP://TS-DB1:4023'