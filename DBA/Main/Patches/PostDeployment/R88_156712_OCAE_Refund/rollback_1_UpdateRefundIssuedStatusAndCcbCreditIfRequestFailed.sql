/*RUN THIS ON THE VINS003 INSTANCE*/

USE RefundManager
GO

ALTER PROCEDURE [Refunds].[UpdateRefundIssuedStatusAndCcbCreditIfRequestFailed]
(
       @RequestId BIGINT,
       @issuedStatus INT,
       @RequestSeqNo BIGINT
)
AS
BEGIN TRY
	
	DECLARE @PrestigeId BIGINT = -1
	DECLARE @RefundId BIGINT = -1
	DECLARE @RefundAmount int = 0
	DECLARE @FinalBalance int = 0
	DECLARE @RefundSource NVARCHAR(20)
      
	BEGIN TRANSACTION
			
		SELECT @RefundId=id, @RefundAmount=Amount, @PrestigeId=PrestigeId, @RefundSource=Source FROM Refunds.Refund WHERE RequestId = @RequestId

		UPDATE Refunds.Refund 
		SET IssuedStatus = @issuedStatus, 
			RequestSeqNo = @RequestSeqNo, 
			Updated = sysdatetimeoffset() 
		WHERE RequestId = @RequestId

		DECLARE @CurrentBalance int
        SELECT @CurrentBalance = Balance 
		FROM [Refunds].[CardCreditBalance] 
		WHERE ID = (SELECT MAX(ID) FROM [Refunds].[CardCreditBalance] WHERE [PrestigeId] = @prestigeId)
		
		IF @CurrentBalance IS NULL
			SET @CurrentBalance=0
					
		IF @issuedStatus = 1
		BEGIN
			INSERT INTO [Refunds].[CardCreditBalance]([PrestigeId] ,[OysterChargeAdjustmentId] ,[RefundId]  ,[Balance])
			VALUES (@prestigeId ,NULL ,@RefundId , @CurrentBalance + @RefundAmount)

			SET @FinalBalance = @CurrentBalance + @RefundAmount
		END
		ELSE
		BEGIN
			SET @FinalBalance = @CurrentBalance
		END

	COMMIT TRANSACTION

	SELECT @PrestigeId as PrestigeId, @FinalBalance as Balance, @RefundSource as RefundSource
	
END TRY
BEGIN CATCH
   	IF @@TRANCOUNT > 0
		ROLLBACK TRANSACTION;
	
	DECLARE @ErrorNumber INT = ERROR_NUMBER();
	DECLARE @ErrorLine INT = ERROR_LINE();
	DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
	DECLARE @ErrorSeverity INT = ERROR_SEVERITY();
	DECLARE @ErrorState INT = ERROR_STATE();

	SELECT 
		ERROR_NUMBER() AS ErrorNumber,
		ERROR_SEVERITY() AS ErrorSeverity,
		ERROR_STATE() AS ErrorState,
		ERROR_PROCEDURE() AS ErrorProcedure,
		ERROR_LINE() AS ErrorLine,
		ERROR_MESSAGE() AS ErrorMessage;

	RAISERROR(@ErrorMessage, @ErrorSeverity, @ErrorState);

END CATCH
GO