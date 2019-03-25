/*

	This script adds a new column (that was added in R86 drop 5) to the unique constraint on the table apportionment.OperatorApportionment
	TFS Bug number 155168

	NOTE: No rollback script required as this is a forward-only script
*/

use [RAE]

BEGIN TRY

	IF EXISTS(SELECT * 
		FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
		WHERE CONSTRAINT_NAME='UK_OperatorId_Origin_Destination_ApportionmentNodeSequenceId_Percent' )
	BEGIN
		BEGIN TRANSACTION;

		ALTER TABLE [apportionment].[OperatorApportionment] 
		DROP CONSTRAINT [UK_OperatorId_Origin_Destination_ApportionmentNodeSequenceId_Percent]
	
		ALTER TABLE [apportionment].[OperatorApportionment] ADD  CONSTRAINT [UC_OperatorId_Origin_Destination_ARANPointSequenceId_Percent_JANPointSequenceId] UNIQUE NONCLUSTERED 
		(
			[OperatorId] ASC,
			[Origin] ASC,
			[Destination] ASC,
			[Mode] ASC,
			[ARANPointSequenceId] ASC,
			[Percentage] ASC,
			[JANPointSequenceId] ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

		COMMIT TRANSACTION;
	END

END TRY 
BEGIN CATCH 
  IF (@@TRANCOUNT > 0)
   BEGIN
      ROLLBACK;
      THROW;
   END 
    SELECT
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_SEVERITY() AS ErrorSeverity,
        ERROR_STATE() AS ErrorState,
        ERROR_PROCEDURE() AS ErrorProcedure,
        ERROR_LINE() AS ErrorLine,
        ERROR_MESSAGE() AS ErrorMessage
END CATCH

use [RAE_CPC]

BEGIN TRY
	
	IF EXISTS(SELECT * 
		FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS
		WHERE CONSTRAINT_NAME='UK_OperatorId_Origin_Destination_ApportionmentNodeSequenceId_Percent' )
	BEGIN
		BEGIN TRANSACTION;

		ALTER TABLE [apportionment].[OperatorApportionment] 
		DROP CONSTRAINT [UK_OperatorId_Origin_Destination_ApportionmentNodeSequenceId_Percent]
	
		ALTER TABLE [apportionment].[OperatorApportionment] ADD  CONSTRAINT [UC_OperatorId_Origin_Destination_ARANPointSequenceId_Percent_JANPointSequenceId] UNIQUE NONCLUSTERED 
		(
			[OperatorId] ASC,
			[Origin] ASC,
			[Destination] ASC,
			[Mode] ASC,
			[ARANPointSequenceId] ASC,
			[Percentage] ASC,
			[JANPointSequenceId] ASC
		)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]

		COMMIT TRANSACTION;
	END

END TRY 
BEGIN CATCH 
  IF (@@TRANCOUNT > 0)
   BEGIN
      ROLLBACK;
      THROW;
   END 
    SELECT
        ERROR_NUMBER() AS ErrorNumber,
        ERROR_SEVERITY() AS ErrorSeverity,
        ERROR_STATE() AS ErrorState,
        ERROR_PROCEDURE() AS ErrorProcedure,
        ERROR_LINE() AS ErrorLine,
        ERROR_MESSAGE() AS ErrorMessage
END CATCH
