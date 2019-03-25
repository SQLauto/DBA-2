go
select 'Create schema'
go
--run script
:r $(scriptPath)\Patching\SchemaDefinitions\deployment.sql
go

select 'PatchingScriptRun Table'
go
--run script
:r $(scriptPath)\Patching\Scripts\Schemas\Deployment\Tables\PatchingScriptsRun.sql
go
select 'PatchingLog Table'
--run script
:r $(scriptPath)\Patching\Scripts\Schemas\Deployment\Tables\PatchingLog.sql
go
select 'PatchingPreValidationError Table'
go
--run script
:r $(scriptPath)\Patching\Scripts\Schemas\Deployment\Tables\PatchingPreValidationError.sql
go
select 'PatchingPostValidationError Table'
go
--run script
:r $(scriptPath)\Patching\Scripts\Schemas\Deployment\Tables\PatchingPostValidationError.sql
go
select 'PatchLevelDeterminationResult Table'
go
--run script
:r $(scriptPath)\Patching\Scripts\Schemas\Deployment\Tables\PatchLevelDeterminationResult.sql
go
select 'Deployment.DropConstraintPatchingScriptsRun_UniqueNameConstraint'
go
--run script
:r $(scriptPath)\Patching\Scripts\Patches\DropConstraintPatchingScriptsRun_UniqueNameConstraint.sql
go
go
select 'DropOldStoredProcedures.sql'
go
--run script
:r $(scriptPath)\Patching\Scripts\Patches\DropOldStoredProcedures.sql
go
select 'DropOldTables.sql'
go
--run script
:r $(scriptPath)\Patching\Scripts\Patches\DropOldTables.sql
go
select 'PatchingScriptRunIdSetToBeIdentityColumn.sql'
go
--run script
:r $(scriptPath)\Patching\Scripts\Patches\PatchingScriptRunIdSetToBeIdentityColumn.sql
go
--run script
:r $(scriptPath)\Patching\Scripts\Patches\PreValidationColumnRename.sql
go
--redeploy all code artifacts: views, functions, sprocs, triggers
select 'RedeployAll code artifacts'
go
--run script
:r $(scriptPath)\Patching\Scripts\Schemas\Deployment\Programmability\RedeployAllCodeArtifacts.sql
go