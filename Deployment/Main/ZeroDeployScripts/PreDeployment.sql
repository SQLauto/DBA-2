--pre steps
USE [master]

IF db_id('Autogration_FAE') IS NOT NULL
begin
	ALTER DATABASE [Autogration_FAE] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE [Autogration_FAE]
end

IF db_id('Autogration_OTFP') IS NOT NULL
begin
	ALTER DATABASE [Autogration_OTFP] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE [Autogration_OTFP]
end

IF db_id('Autogration_PARE') IS NOT NULL
begin
	ALTER DATABASE [Autogration_PARE] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE [Autogration_PARE]
end

IF db_id('Autogration_CSCWebSSO') IS NOT NULL
begin
	ALTER DATABASE [Autogration_CSCWebSSO] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE [Autogration_CSCWebSSO]
end

IF db_id('Autogration_NotificationsExtractRW') IS NOT NULL
begin
	ALTER DATABASE [Autogration_NotificationsExtractRW] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE [Autogration_NotificationsExtractRW]
end

IF db_id('Autogration_NotificationProcessorDb') IS NOT NULL
begin
	ALTER DATABASE [Autogration_NotificationProcessorDb] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE [Autogration_NotificationProcessorDb]
end

IF db_id('Autogration_SDM') IS NOT NULL
begin
	ALTER DATABASE [Autogration_SDM] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE [Autogration_SDM]
end


IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'fae')
begin
	CREATE LOGIN fae WITH PASSWORD = 'fae', CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
end

IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'pare')
begin
	CREATE LOGIN pare WITH PASSWORD = 'pare', CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
end
