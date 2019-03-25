
GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

declare @tableExists bit = 0
exec #tableExists 'capture', 'WaitStats',  @tableExists out
if (@tableExists = 0)
begin
	insert into deployment.PatchingLevelDeterminationResult (IsAtPatchLevelWhichWasTested) values(@tableExists)
end
else
begin
	declare @columnExists bit = 0
	exec #ColumnExists 'capture', 'WaitStats', 'AvgSig_S', @columnExists out
	insert into deployment.PatchingLevelDeterminationResult (IsAtPatchLevelWhichWasTested) values(@columnExists)
end





