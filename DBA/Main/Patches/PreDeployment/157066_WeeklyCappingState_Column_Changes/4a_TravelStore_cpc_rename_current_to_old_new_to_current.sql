/* 
This script should be run on VINS001 Travelstore_CPC

!!! This should only be run after the _New table has been synced after the system has been shutdown !!!

*/

USE Travelstore_CPC

GO

BEGIN TRY
       BEGIN TRANSACTION

			IF EXISTS( SELECT 1 from sysobjects where name = 'WeeklyCappingState_OLD' and OBJECT_SCHEMA_NAME(id) = 'travel')
				Raiserror('!!!! WeeklyCappingState_OLD table already exists which means this script has alreday been run. Please discuss with TFL DBA !!!!',16,1)
              EXEC sp_rename N'Travel.WeeklyCappingState.PK_WeeklyCappingState_TravelTokenID_TravelDay', N'PK_WeeklyCappingState_TravelTokenID_TravelDay_OLD', N'INDEX';   
              EXEC sp_rename N'Travel.WeeklyCappingState', N'WeeklyCappingState_OLD';   
              EXEC sp_rename N'Travel.WeeklyCappingState_NEW.PK_WeeklyCappingState_TravelTokenID_TravelDay_NEW', N'PK_WeeklyCappingState_TravelTokenID_TravelDay', N'INDEX';   
              EXEC sp_rename N'Travel.WeeklyCappingState_NEW', N'WeeklyCappingState';   							

       COMMIT TRANSACTION

END TRY
BEGIN CATCH

       IF @@TRANCOUNT>0
              ROLLBACK;

       THROW

END CATCH ;
