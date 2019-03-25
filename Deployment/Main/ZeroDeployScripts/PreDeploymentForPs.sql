--pre steps
USE [master]

IF db_id(N'$(DatabaseName)') IS NOT NULL
begin
	ALTER DATABASE [$(DatabaseName)] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE [$(DatabaseName)]
end

IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'fae')
begin
	CREATE LOGIN fae WITH PASSWORD = 'fae', CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
end

IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = N'pare')
begin
	CREATE LOGIN pare WITH PASSWORD = 'pare', CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
end