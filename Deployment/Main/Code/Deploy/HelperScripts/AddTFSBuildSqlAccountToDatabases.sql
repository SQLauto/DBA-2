:connect ts-db1\inst1

USE [master]
GO
if not exists (select 1 from sys.syslogins where name = 'TFSBuild')
begin
	CREATE LOGIN [TFSBuild] WITH PASSWORD=N'LMTF$Bu1ld', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
end
GO
ALTER LOGIN [tfsbuild] ENABLE
GO
ALTER SERVER ROLE [sysadmin] ADD MEMBER [TFSBuild]
GO

:connect ts-db1\inst2

USE [master]
GO
if not exists (select 1 from sys.syslogins where name = 'TFSBuild')
begin
	CREATE LOGIN [TFSBuild] WITH PASSWORD=N'LMTF$Bu1ld', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
end
GO
ALTER LOGIN [tfsbuild] ENABLE
GO
ALTER SERVER ROLE [sysadmin] ADD MEMBER [TFSBuild]
GO

:connect ts-db1\inst3

USE [master]
GO
if not exists (select 1 from sys.syslogins where name = 'TFSBuild')
begin
	CREATE LOGIN [TFSBuild] WITH PASSWORD=N'LMTF$Bu1ld', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
end
GO
ALTER LOGIN [tfsbuild] ENABLE
GO
ALTER SERVER ROLE [sysadmin] ADD MEMBER [TFSBuild]
GO

:connect ts-db2\inst1

USE [master]
GO
if not exists (select 1 from sys.syslogins where name = 'TFSBuild')
begin
	CREATE LOGIN [TFSBuild] WITH PASSWORD=N'LMTF$Bu1ld', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
end
GO
ALTER LOGIN [tfsbuild] ENABLE
GO
ALTER SERVER ROLE [sysadmin] ADD MEMBER [TFSBuild]
GO


:connect ts-db2\inst2

USE [master]
GO
if not exists (select 1 from sys.syslogins where name = 'TFSBuild')
begin
	CREATE LOGIN [TFSBuild] WITH PASSWORD=N'LMTF$Bu1ld', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
end
GO
ALTER LOGIN [tfsbuild] ENABLE
GO
ALTER SERVER ROLE [sysadmin] ADD MEMBER [TFSBuild]
GO


:connect ts-db2\inst3

USE [master]
GO
if not exists (select 1 from sys.syslogins where name = 'TFSBuild')
begin
	CREATE LOGIN [TFSBuild] WITH PASSWORD=N'LMTF$Bu1ld', DEFAULT_DATABASE=[master], CHECK_EXPIRATION=OFF, CHECK_POLICY=OFF
end
GO
ALTER LOGIN [tfsbuild] ENABLE
GO
ALTER SERVER ROLE [sysadmin] ADD MEMBER [TFSBuild]
GO

