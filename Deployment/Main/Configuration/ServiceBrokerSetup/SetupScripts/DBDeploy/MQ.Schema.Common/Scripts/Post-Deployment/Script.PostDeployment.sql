/*
Post-Deployment Script Template							
--------------------------------------------------------------------------------------
 This file contains SQL statements that will be appended to the build script.		
 Use SQLCMD syntax to include a file in the post-deployment script.			
 Example:      :r .\myfile.sql								
 Use SQLCMD syntax to reference a variable in the post-deployment script.		
 Example:      :setvar TableName MyTable							
               SELECT * FROM [$(TableName)]					
--------------------------------------------------------------------------------------
*/

:r .\AddBaseData.sql
GO

print 'Execute ModifyDirectPaymentConfirmationRequestSchema.sql'
:r .\..\Patching\Cycle031\ModifyDirectPaymentConfirmationRequestSchema.sql
GO
print 'Execute ModifyAuthorisationResponseSchema.sql'
:r .\..\Patching\Cycle031\ModifyAuthorisationResponseSchema.sql
GO
print 'Execute ModifyAccountVerificationResponseSchema.sql'
:r .\..\Patching\Cycle031\ModifyAccountVerificationResponseSchema.sql
GO