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

IF 'Dev' = '$(Environment)'
	BEGIN
		:r .\Script.PostDeployment.Dev.sql
	END
ELSE IF 'TSRig' = '$(Environment)'
	BEGIN
		:r .\Script.PostDeployment.TSRig.sql
	END
ELSE IF 'CubicAcc' = '$(Environment)'
	BEGIN
		:r .\Script.PostDeployment.CubicAcc.sql
	END
ELSE IF 'CubicInt' = '$(Environment)'
	BEGIN
		:r .\Script.PostDeployment.CubicInt.sql
	END
ELSE IF 'TestRig' = '$(Environment)'
	BEGIN
		:r .\Script.PostDeployment.TestRig.sql
	END
ELSE IF 'PreProd' = '$(Environment)'
	BEGIN
		:r .\Script.PostDeployment.Preprod.sql
	END
ELSE IF 'SiteA' = '$(Environment)'
	BEGIN
		:r .\Script.PostDeployment.SiteA.sql
	END
ELSE IF 'DevInt' = '$(Environment)'
	BEGIN
		:r .\Script.PostDeployment.DevInt.sql
	END
ELSE IF 'DevIntPerf' = '$(Environment)'
	BEGIN
		:r .\Script.PostDeployment.DevIntPerf.sql
	END
ELSE IF 'DevIntPerf' = '$(Environment)'
	BEGIN
		:r .\Script.PostDeployment.Simulator.sql
	END

-- =============================================
-- Remove pre-production/test stored procedures
-- =============================================
IF '$(Environment)' NOT IN ('Dev', 'TSRig', 'TestRig', 'Preprod', 'DevInt', 'DevIntPerf')
	BEGIN
		IF EXISTS (SELECT * FROM sysobjects WHERE id = object_id(N'[dbo].[SsbEmptyServiceBrokerQueues]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
		BEGIN
			DROP PROCEDURE [dbo].[SsbEmptyServiceBrokerQueues]
		END
	END

exec [dbo].[CreateEventNotificationForDirectPayment]