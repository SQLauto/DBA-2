CREATE PROCEDURE [dbo].[CreateEventNotificationForDirectPayment]	
AS
	IF EXISTS (SELECT 1
    FROM sys.event_notifications
    WHERE name = 'Pare_Event_Notification_DirectPaymentConfirmation')
	BEGIN
		DROP EVENT Notification Pare_Event_Notification_DirectPaymentConfirmation 
		ON QUEUE [dbo].[http://tfl.gov.uk/Ft/Pare/DirectPayment/Queue/Pare] 
	END

	CREATE EVENT NOTIFICATION Pare_Event_Notification_DirectPaymentConfirmation
	ON QUEUE [dbo].[http://tfl.gov.uk/Ft/Pare/DirectPayment/Queue/Pare]
	FOR QUEUE_ACTIVATION
	TO SERVICE 'http://tfl.gov.uk/Ft/Pare/Service/Pare_Notification' , 'current database' 	

RETURN 0
