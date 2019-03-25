
GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

declare @exists bit;
exec #TableTypeExists 'maint', 'RestoreDatabaseMappings', @exists out;

if (@exists = 0)
begin
	CREATE TYPE [maint].[RestoreDatabaseMappings] AS TABLE(
	[AsIsMapping] [varchar](248) NOT NULL,
	[ToBeMapping] [varchar](248) NOT NULL
	)
end

