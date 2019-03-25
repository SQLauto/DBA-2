/*  Run 1.  PARE step 1: There is no Service Broker active in the database. Change to a database context that contains a Service Broker.
			Notif Step 2: Could not find stored procedure 'SsbSendOnConversation'.		
*/
/*  Resolution 1
		Restored D:\CubicINT_Migration\PARE backup and Notifications backup
		Ran PARE and Notifications post-deployment fix scripts
*/


:connect .\inst3

PRINT 'Using Notification DB'
PRINT ''
USE [Notification]
GO

PRINT '  Turn off internal activation'
PRINT ''

	ALTER QUEUE [dbo].[http://tfl.gov.uk/Ft/Notification/Queue/Email] WITH STATUS = ON ,
	RETENTION = OFF , ACTIVATION (  STATUS = OFF , PROCEDURE_NAME = [dbo].[Email_Activation] , MAX_QUEUE_READERS = 10 , EXECUTE AS N'dbo'  ), POISON_MESSAGE_HANDLING (STATUS = ON)
	GO

:connect .\inst2

PRINT 'Using PARE DB'
PRINT ''
USE [PARE]
GO

PRINT '  Send a message'
	Declare @ConversationHandle1 UniqueIdentifier
	exec SsbSendOnConversation
		'http://tfl.gov.uk/Ft/Pare/CustomerNotification/Service/Pare',
		'http://tfl.gov.uk/Ft/Notification/Service/Email',
		'http://tfl.gov.uk/Ft/Notification/Contract/Email',
		'http://tfl.gov.uk/Ft/Notification/Message/Email',
		'<Notifications xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
		<Notification>
		<NotificationCode>f8aee325-a6c9-4e94-9b46-bba98c93755a</NotificationCode>
		<SendTo>
		<CardHolder>
		<PanToken>99999999999999999999999</PanToken>
		<PaymentCardExpiryDate>0113</PaymentCardExpiryDate>
		</CardHolder>
		</SendTo>
		<TemplateContentTags>
		<PaymentAmount>9999</PaymentAmount>
		<PaymentTransactionDateTime>2013-11-28T12:11:04.5030783+00:00</PaymentTransactionDateTime>
		<PaymentCardPanToken>12345678912345678912345678</PaymentCardPanToken>
		<PaymentCardExpiryDate>0113</PaymentCardExpiryDate>
		<PaymentCardLast4Digits>1234</PaymentCardLast4Digits>
		<PaymentCardType>Visa</PaymentCardType>
		<DebtAmount>1</DebtAmount>
		<DebtDate>2013-11-29T12:11:04.5030783+00:00</DebtDate>
		<DebtIndicator>Y</DebtIndicator>
		<AuthorisationAmount>2</AuthorisationAmount>
		</TemplateContentTags>
		</Notification>
		</Notifications>',
		@ConversationHandle = @ConversationHandle1 OUT

GO


:connect .\inst3

PRINT 'Using Notification DB'
PRINT ''
USE [Notification]
GO

PRINT '  Check for the message'
        WAITFOR DELAY '00:00:15';
        DECLARE @test int
        SET @test = (SELECT count(*)
        FROM [Notification].[dbo].[http://tfl.gov.uk/Ft/Notification/Queue/Email]
        WHERE  CAST(message_body AS NVARCHAR(MAX)) Like '%<PanToken>99999999999999999999999%')

        -- Remove it (doesnt work )
        --DELETE FROM [Notification].[dbo].[http://tfl.gov.uk/Ft/Notification/Queue/Email]
        --WHERE  CAST(message_body AS NVARCHAR(MAX)) Like '%<PanToken>99999999999999999999999%')

        -- Turn on activation VERY IMPORTANT, missing this will leave the database in a non functional state
        ALTER QUEUE [dbo].[http://tfl.gov.uk/Ft/Notification/Queue/Email] WITH STATUS = ON ,
        RETENTION = OFF , ACTIVATION (  STATUS = ON , PROCEDURE_NAME = [dbo].[Email_Activation] , MAX_QUEUE_READERS = 10 , EXECUTE AS N'dbo'  ), POISON_MESSAGE_HANDLING (STATUS = ON)

        IF @test=0
        THROW 51000, 'Message not found in http://tfl.gov.uk/Ft/Notification/Queue/Email', 1;
