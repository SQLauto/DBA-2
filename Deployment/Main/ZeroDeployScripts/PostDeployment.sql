USE [Autogration_FAE]
GO

/****** Object:  Synonym [internal].[PareRatingStageSyntheticTap]    Script Date: 30/01/2015 14:11:25 ******/
DROP SYNONYM [internal].[PareRatingStageSyntheticTap]
GO

/****** Object:  Synonym [internal].[PareRatingStageSyntheticTap]    Script Date: 30/01/2015 14:11:25 ******/
CREATE SYNONYM [internal].[PareRatingStageSyntheticTap] FOR [Autogration_PARE].[dbo].[RatingStageSyntheticTap]
GO

USE [Autogration_FAE]
GO

/****** Object:  Synonym [internal].[PareRatingStageTap0]    Script Date: 30/01/2015 14:11:31 ******/
DROP SYNONYM [internal].[PareRatingStageTap0]
GO

/****** Object:  Synonym [internal].[PareRatingStageTap0]    Script Date: 30/01/2015 14:11:31 ******/
CREATE SYNONYM [internal].[PareRatingStageTap0] FOR [Autogration_PARE].[dbo].[RatingStageTap0]
GO

USE [Autogration_FAE]
GO

/****** Object:  Synonym [internal].[PareRatingStageTap1]    Script Date: 30/01/2015 14:11:38 ******/
DROP SYNONYM [internal].[PareRatingStageTap1]
GO

/****** Object:  Synonym [internal].[PareRatingStageTap1]    Script Date: 30/01/2015 14:11:38 ******/
CREATE SYNONYM [internal].[PareRatingStageTap1] FOR [Autogration_PARE].[dbo].[RatingStageTap1]
GO

-- Update fae pipeline caching to minimum
update config.Setting set value='-1' where id in('8F74C930-277D-4DE0-B833-CD3812CE12A2','A70BBBBA-A9D1-4BC5-87CE-7FDBF2F49B0C')
-- Update fae Master data caching to one year old
Update config.Setting set value=left(convert(varchar(25), DATEADD(YEAR, -1, GETDATE()), 120) ,10) where Id = '56FEBD01-629E-4CF0-84DB-E75B6ECAF738' 

USE [Autogration_PARE]
GO

 /****** Object:  Schema [PARE]    Script Date: 30/01/2015 14:12:12 ******/
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'PARE')
BEGIN
	DECLARE @sql VARCHAR(MAX)
	SET @sql = 'CREATE SCHEMA [PARE]'
	EXEC (@sql)
END
GO

USE [Autogration_PARE]
GO

/****** Object:  StoredProcedure [PARE].[EmptyStaging]    Script Date: 30/01/2015 14:12:34 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




IF EXISTS(SELECT 1 FROM sys.procedures WHERE Name = 'EmptyStaging')
DROP PROCEDURE [PARE].[EmptyStaging]
GO

CREATE PROCEDURE [PARE].[EmptyStaging]
-- =============================================
-- Author:           Nick Nurock
-- Create date: 16-05-2011
-- Description:      Truncates a specified staging table
-- Parameters: 
--     TableName     Name of the table to truncate
-- =============================================
(
@TableName NVARCHAR(128)
)
AS
BEGIN
       DECLARE @TruncateString NVARCHAR(500)

       if @TableName is null
              print 'Table name cannot be empty'
       else
              begin

              SET @TruncateString='truncate table [dbo].'+@TableName
              EXEC sp_executesql @TruncateString
              end
END


IF NOT EXISTS(SELECT 1 FROM sys.procedures p
       inner join sys.schemas sc on
              p.schema_id = sc.schema_id
WHERE 
    p.name = 'StageDayKeysGet'
       and sc.name = 'pare')
BEGIN
       exec('CREATE PROCEDURE [PARE].[StageDayKeysGet] AS begin select 1 end')
end




GO
USE [Autogration_PARE]
GO

/****** Object:  StoredProcedure [PARE].[StageDayKeysGet]    Script Date: 30/01/2015 14:12:41 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





-- =============================================
-- Author:           Nick Nurock
-- Create date: 16-05-2011
-- Description:      Retuns the distinct DayKeys present in the specified staging table
-- Parameters: 
--     TableName     Name of the table to query
-- =============================================
IF EXISTS(SELECT 1 FROM sys.procedures WHERE Name = 'StageDayKeysGet')
DROP PROCEDURE [PARE].[StageDayKeysGet]
GO

CREATE PROCEDURE [PARE].[StageDayKeysGet]
(
       @TableName NVARCHAR(128)
)
AS
BEGIN
       DECLARE @SelectString NVARCHAR(500)

       if @TableName is null
              print 'Table name cannot be empty'
       else
              SET @SelectString='
                     SELECT DISTINCT 
                                  travelday 
                     FROM   
                                  [dbo].' + @TableName + ' 
                     UNION
                     SELECT DISTINCT 
                                  travelday 
                     FROM   
                                  [dbo].[RatingStageSyntheticTap]

                     ORDER BY 
                                  TravelDay'

              -- We use sp_executesql rather than exec, as it supports parameterised statements,
              --although in this case we have no parameters
              EXEC sp_executesql @SelectString
END





GO
USE [Autogration_PARE]
GO

/****** Object:  StoredProcedure [PARE].[StageSyntheticTapInsert]    Script Date: 30/01/2015 14:12:49 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





-- =============================================
-- Author:           Kofi Sarfo
-- Create date: 30-10-2012
-- Description:      Inserts a synthetic tap into the synthetic taps queue table
-- Parameters: 
--     
-- =============================================
IF EXISTS(SELECT 1 FROM sys.procedures WHERE Name = 'StageSyntheticTapInsert')
DROP PROCEDURE [PARE].[StageSyntheticTapInsert]
GO 

CREATE PROCEDURE [PARE].[StageSyntheticTapInsert]
(
          @SyntheticTapId                bigint
      ,@TapTimestamp              datetimeoffset
      ,@NationalLocationCode      int
      ,@HostDeviceTypeId          tinyint
      ,@TravelTokenId                    bigint
      ,@TravelDay                        smallint
      ,@ValidationTypeId          tinyint
      ,@TrainingFlag              bit
      ,@ReaderId                         int
      ,@BusRouteId                       varchar(8)
      ,@BusDirection              char(1)
      ,@ValidationResultId        tinyint
      ,@PaymentCardATC                   int
      ,@ModeId                                  tinyint
      ,@Synthetic                        bit
      ,@SyntheticATCOffset        smallint
      ,@CounterTapFlag                   tinyint
      ,@InspectionLocation        tinyint
      ,@LocalTimeZone                    tinyint
         ,@ReferenceTapId                bigint
         ,@atcOffset                      int
         ,@BusStopId                     varchar(12)
         ,@BusStopIdStatus               smallint
         ,@TapCreatedInPare       datetimeoffset
         ,@InspectorId                       VARCHAR(25)
         ,@OperatorId                           SMALLINT
         ,@RTDEMVSequenceNumber   BIGINT 
         ,@source                               tinyint
)
AS
BEGIN
       DECLARE @id INT

INSERT INTO [dbo].[RatingStageSyntheticTap]
    (
              [SyntheticTapId]
              ,[TapTimestamp]
              ,[NationalLocationCode]
              ,[HostDeviceTypeId]
              ,[TravelTokenId]
              ,[TravelDay]
              ,[ValidationTypeId]
              ,[TrainingFlag]
              ,[ReaderId]
              ,[BusRouteId]
              ,[BusDirection]
              ,[ValidationResultId]
              ,[PaymentCardATC]
              ,[ModeId]
              ,[Synthetic]
              ,[SyntheticATCOffset]
              ,[CounterTapFlag]
              ,[InspectionLocation]
              ,[LocalTimeZone]
              ,[ReferenceTapId]
              ,[AtcOffset]
              ,[BusStopId]
              ,[BusStopIdStatus]
              ,[TapCreatedInPare]
              ,[InspectorId]
              ,[OperatorId]
              ,[RTDEMVSequenceNumber]
              ,[Source]
       )
       SELECT
                 @SyntheticTapId                
                ,@TapTimestamp           
                ,@NationalLocationCode   
                ,@HostDeviceTypeId       
                ,@TravelTokenId                 
                ,@TravelDay                     
                ,@ValidationTypeId       
                ,@TrainingFlag                  
                ,@ReaderId                      
                ,@BusRouteId                           
                ,@BusDirection                  
                ,@ValidationResultId            
                ,@PaymentCardATC                
                ,@ModeId                               
                ,@Synthetic                     
                ,@SyntheticATCOffset            
                ,@CounterTapFlag                
                ,@InspectionLocation            
                ,@LocalTimeZone                 
                ,@ReferenceTapId                
                ,@atcOffset                     
                ,@BusStopId
                ,@BusStopIdStatus
                ,@TapCreatedInPare
                ,@InspectorId
                ,@OperatorId
                ,@RTDEMVSequenceNumber
                ,@source

       SELECT @id = SCOPE_IDENTITY()
       SELECT @id
END





GO
USE [Autogration_PARE]
GO

/****** Object:  StoredProcedure [PARE].[StageSyntheticTapsBatch]    Script Date: 30/01/2015 14:12:56 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




-- =============================================
-- Author:           Nick Nurock
-- Create date: 16-05-2011
-- Description:      Retuns the distinct DayKeys present in the specified staging table
-- Parameters: 
--     TableName     Name of the table to query
-- =============================================
IF EXISTS(SELECT 1 FROM sys.procedures WHERE Name = 'StageSyntheticTapsBatch')
DROP PROCEDURE [PARE].[StageSyntheticTapsBatch]
GO

CREATE PROCEDURE [PARE].[StageSyntheticTapsBatch]
(
       @TableName NVARCHAR(128)
)
AS
BEGIN
       DECLARE @SelectString NVARCHAR(MAX)

       if @TableName is null
              print 'Table name cannot be empty'
       else
              SET @SelectString=
              '      
              DELETE [dbo].RatingStageSyntheticTap
                     OUTPUT DELETED.[SyntheticTapId] AS [TapId]
                     ,DELETED.TapTimestamp
                     ,DELETED.Created
                     ,DELETED.NationalLocationCode
                     ,DELETED.HostDeviceTypeId
                     ,DELETED.TravelTokenId
                     ,''9999'' /* Expiry Date */
                     ,DELETED.TravelDay
                     ,DELETED.ValidationTypeId
                     ,DELETED.TrainingFlag
                     ,DELETED.ReaderId
                     ,DELETED.Source
                     ,DELETED.BusRouteId
                     ,DELETED.BusDirection
                     ,DELETED.ValidationResultId
                     ,DELETED.PaymentCardATC
                     ,DELETED.ModeId
                     ,DELETED.Synthetic
                     ,DELETED.SyntheticATCOffset
                     ,DELETED.CounterTapFlag
                     ,DELETED.InspectionLocation
                     ,DELETED.LocalTimeZone
                     ,DELETED.BusStopId
                     ,DELETED.BusStopIdStatus
                     ,DELETED.TapCreatedInPare
                     ,DELETED.InspectorId
                     ,DELETED.OperatorId
                     ,DELETED.RTDEMVSequenceNumber
                     INTO 
                     
                     [dbo].[' + @TableName + ']' + 
                     '
                     (
                     [TapId]
                     ,TapTimestamp
                     ,Created
                     ,NationalLocationCode
                     ,HostDeviceTypeId
                     ,TravelTokenId
                     ,[ExpiryDate]
                     ,TravelDay
                     ,ValidationTypeId
                     ,TrainingFlag
                     ,ReaderId
                     ,Source
                     ,BusRouteId
                     ,BusDirection
                     ,ValidationResultId
                     ,PaymentCardATC
                     ,ModeId
                     ,Synthetic
                     ,SyntheticATCOffset
                     ,CounterTapFlag
                     ,InspectionLocation
                     ,LocalTimeZone
                     ,BusStopId
                     ,BusStopIdStatus
                     ,TapCreatedInPare
                     ,InspectorId
                     ,OperatorId
                     ,RTDEMVSequenceNumber
                     )'
                           
              -- We use sp_executesql rather than exec, as it supports parameterised statements,
              --although in this case we have no parameters
              EXEC sp_executesql @SelectString
END




GO
USE [Autogration_PARE]
GO

/****** Object:  StoredProcedure [PARE].[StageTapCountGet]    Script Date: 30/01/2015 14:13:09 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO





-- =============================================
-- Author:           Nick Nurock
-- Create date: 13-05-2011
-- Description:      Returns the count from a specified Staging Table
-- Parameters: 
--     TableName     Name of the table to query
-- =============================================
IF EXISTS(SELECT 1 FROM sys.procedures WHERE Name = 'StageTapCountGet')
DROP PROCEDURE [PARE].[StageTapCountGet] 
GO

CREATE PROCEDURE [PARE].[StageTapCountGet] 
(
@TableName NVARCHAR(128)
)
AS
BEGIN
       DECLARE @SelectString NVARCHAR(500)

       if @TableName is null
              print 'Table name cannot be empty'
       else
       
              SET @SelectString='select count(*) from [dbo].'+@TableName

              -- We use sp_executesql rather than exec, as it supports parameterised statements,
              -- although in this particular case, our query string is not parameterised.
              EXEC sp_executesql @SelectString

END





GO
USE [Autogration_PARE]
GO

/****** Object:  StoredProcedure [PARE].[StageTapForModuloAndDateRangeGet]    Script Date: 30/01/2015 14:13:15 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO




-- =============================================
-- Author:           Nick Nurock
-- Create date: 16-05-2011
-- Description:      Moves all the taps from the specified staging table into the main taps table
--                         and allocates them a BatchId.
-- Parameters: 
--     TableName                  Name of the staging table to query
--  EarlierTravelDay Minimum TravelDay to consider
--  LaterTravelDay         Maximum TravelDay to consider
--  Modulo                        The Modulo result on the TravelTokenId which to filter
--  Divisor                       The divisor operator to use when mod'ing the TravelTokenId
-- =============================================

IF EXISTS(SELECT 1 FROM sys.procedures WHERE Name = 'StageTapForModuloAndDateRangeGet')
DROP PROCEDURE [PARE].[StageTapForModuloAndDateRangeGet]
GO

CREATE PROCEDURE [PARE].[StageTapForModuloAndDateRangeGet]
       (
       @tableName NVARCHAR(128),
       @earlierTravelDay SMALLINT,
       @laterTravelDay SMALLINT,
       @divisor TINYINT,
       @modulo TINYINT
       )
AS

BEGIN
       DECLARE @SelectString NVARCHAR(MAX)

       if @tableName is null
              print 'Table name cannot be empty'
       else
              SET @SelectString='SELECT  TapId, 
                                                              TapTimestamp, 
                                                              Created, 
                                                              NationalLocationCode, 
                                                              HostDeviceTypeId, 
                                                              TravelTokenId,
                                                              ExpiryDate,
                                                              TravelDay,
                                                              ValidationTypeId, 
                                                              TrainingFlag, 
                                                              ReaderId, 
                                                              BusRouteId, 
                                                              BusDirection, 
                                                              ValidationResultId, 
                                                              PaymentCardATC, 
                                                              ModeId, 
                                                              Synthetic, 
                                                              SyntheticATCOffset,
                                                              CounterTapFlag,
                                                              InspectionLocation,
                                                              LocalTimeZone,
                                                              BusStopId,
                                                              BusStopIdStatus,
                                                              TapCreatedInPare,
                                                              InspectorId,
                                                              OperatorId,
                                                              RTDEMVSequenceNumber,
                                                              Source
                                                FROM 
                                                              [dbo].[' + @tableName + '] 
                                                WHERE 
                                                              TravelTokenId % @pDivisor = @pModulo 
                                                AND           TravelDay >= @pEarlierTravelDay 
                                                AND           TravelDay <= @pLaterTravelDay'

              -- We use sp_executesql rather than exec, as it supports parameterised statements,
              EXEC sp_executesql @SelectString, N'@pDivisor TINYINT, @pModulo TINYINT, @pEarlierTravelDay SMALLINT, @pLaterTravelDay SMALLINT', @divisor, @modulo, @earlierTravelDay, @laterTravelDay
END




GO


/****** Update to use service broker on single SQL instance ******/
Use [Autogration_PARE]
IF EXISTS(SELECT 1 FROM sys.services WHERE name = 'http://tfl.gov.uk/Ft/Notification/Service/Email')
DROP SERVICE [http://tfl.gov.uk/Ft/Notification/Service/Email]
GO

IF EXISTS(SELECT * FROM sys.service_queues WHERE name = 'http://tfl.gov.uk/Ft/Notification/Queue/Email')
DROP QUEUE [dbo].[http://tfl.gov.uk/Ft/Notification/Queue/Email]
GO


USE [Autogration_NotificationProcessorDb]
GO

/****** Object:  BrokerService [http://tfl.gov.uk/Ft/Pare/CustomerNotification/Service/Pare]    Script Date: 25/02/2015 13:56:19 ******/
IF EXISTS(SELECT 1 FROM sys.services WHERE name = 'http://tfl.gov.uk/Ft/Pare/CustomerNotification/Service/Pare')
DROP SERVICE [http://tfl.gov.uk/Ft/Pare/CustomerNotification/Service/Pare]
GO


USE [Autogration_NotificationProcessorDb]
GO

/****** Object:  ServiceQueue [dbo].[http://tfl.gov.uk/Ft/Pare/CustomerNotification/Queue/Pare]    Script Date: 25/02/2015 13:56:29 ******/
IF EXISTS(SELECT * FROM sys.service_queues WHERE name = 'http://tfl.gov.uk/Ft/Pare/CustomerNotification/Queue/Pare')
DROP QUEUE [dbo].[http://tfl.gov.uk/Ft/Pare/CustomerNotification/Queue/Pare]
GO


ALTER DATABASE [Autogration_NotificationProcessorDb] SET TRUSTWORTHY ON
ALTER DATABASE [Autogration_PARE] SET TRUSTWORTHY ON


USE [Autogration_PARE]
ALTER MASTER KEY FORCE REGENERATE WITH ENCRYPTION BY PASSWORD = 'fae123FAE'
GO

USE [Autogration_NotificationProcessorDb]
IF (select Count(*) from sys.symmetric_keys where name like '%DatabaseMasterKey%') = 1
BEGIN
	ALTER MASTER KEY FORCE REGENERATE WITH ENCRYPTION BY PASSWORD = 'fae123FAE'
END
ELSE
BEGIN
	CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'fae123FAE'
END
GO

/******Disable new features which aren't tested yet in Autogration ******/

USE [Autogration_FAE]
--Same station leniency enabled for Earth onwards
update config.Setting set Value='true' where SettingTemplateId in (select id from config.SettingTemplate where name='EnableFeatureSameStationLeniency')
--Correction Quotas In Autofill enabled for Earth onwards
update config.Setting set Value='true' where SettingTemplateId in (select id from config.SettingTemplate where name='EnableFeatureCorrectionQuotasInAutofill')
update config.Setting set Value='false' where SettingTemplateId in (select id from config.SettingTemplate where name='EnableFeatureAutofillE')






/****** Sort out Users and Roles ******/

USE Autogration_Pare
GO
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'pare')
CREATE USER [pare] FOR LOGIN [pare] WITH DEFAULT_SCHEMA=[dbo]
GO
ALTER ROLE [db_owner] ADD MEMBER [pare]
GO

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'fae')
CREATE USER [fae] FOR LOGIN [fae] WITH DEFAULT_SCHEMA=[dbo]
GO
ALTER ROLE [db_owner] ADD MEMBER [fae]
GO

USE Autogration_Fae
GO
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'fae')
CREATE USER [fae] FOR LOGIN [fae] WITH DEFAULT_SCHEMA=[dbo]
GO
ALTER ROLE [db_owner] ADD MEMBER [fae]
GO

USE Autogration_CSCWebSSO
GO
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'fae')
CREATE USER [fae] FOR LOGIN [fae] WITH DEFAULT_SCHEMA=[dbo]
GO
ALTER ROLE [db_owner] ADD MEMBER [fae]
GO

USE Autogration_NotificationProcessorDb
GO
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = N'fae')
CREATE USER [fae] FOR LOGIN [fae] WITH DEFAULT_SCHEMA=[dbo]
GO
ALTER ROLE [db_owner] ADD MEMBER [fae]
GO