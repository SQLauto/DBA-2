/* 
Script Name: 1b_Travelstore_create_new_travel_weeklycappingstate_table.sql

TO BE RUN in Travelstore Database on VINS001 

   This will create "_new" tables for travel and archive schemas 

*/ 

USE Travelstore 

GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[travel].[WeeklyCappingState_NEW]') AND type in (N'U'))
BEGIN
CREATE TABLE [travel].[WeeklyCappingState_NEW](
	[TravelDay] [smallint] NOT NULL,
	[TravelTokenId] [bigint] NOT NULL,
	[CumulativeDailyBestValue] [int] NULL,
	[DailyBestValue] [int] NULL,
	[BestWeeklyCapId] [int] NULL,
	[DailyTotalFareChargedSoFar] [int] NULL,
	[DailyCounterBestRunningTotal] [int] NULL,
	[WeeklyCounterState] [varchar](1000) NULL,
	[Stage2RecalculationCacheState] [varchar](max) NULL,
 CONSTRAINT [PK_WeeklyCappingState_TravelTokenID_TravelDay_NEW] PRIMARY KEY CLUSTERED 
(
	[TravelTokenId] ASC,
	[TravelDay] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PS_WeeklyCappingState]([TravelDay])
) ON [PS_WeeklyCappingState]([TravelDay])
END
GO

