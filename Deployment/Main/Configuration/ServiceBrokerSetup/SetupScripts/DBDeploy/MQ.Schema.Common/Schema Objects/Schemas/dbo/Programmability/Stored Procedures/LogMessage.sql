CREATE PROCEDURE [dbo].[LogMessage](
    @messageType SYSNAME,
	@messageBody xml)
AS
DECLARE @message as varchar(max)
BEGIN
BEGIN TRY
 IF(Select LogEnabled From LogController) = 1 --Is Logging Enabled
	BEGIN  
		Set @message = 'Message Type: ' + Cast(@messageType as varchar(100)) + ' ' + 'Message Body:- ' +  cast(@messageBody as varchar(max))
		RAISERROR ('%s', 0, 1, @message) WITH LOG 		    
	END
	END TRY
		BEGIN CATCH
		--Nothing to do if we cannot login.
		END CATCH
END
