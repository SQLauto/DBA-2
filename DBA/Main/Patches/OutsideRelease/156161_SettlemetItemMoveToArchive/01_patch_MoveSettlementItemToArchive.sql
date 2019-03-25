/* Bug number 156151 

This Script should be run in pare on VINS002 and is a prodcution specific script

*/
USE PARE
GO 
BEGIN TRANSACTION
BEGIN TRY 
INSERT archive.settlementitem 
		SELECT * 
		FROM    
		(
			DELETE SI 
			OUTPUT DELETED.*
			FROM dbo.settlementitem SI 
			WHERE SI.travelday = 14116 and settlementid = 958704632
		) AS RowsToMove; 
COMMIT TRANSACTION
END TRY
BEGIN CATCH
	IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION
		;THROW
END CATCH