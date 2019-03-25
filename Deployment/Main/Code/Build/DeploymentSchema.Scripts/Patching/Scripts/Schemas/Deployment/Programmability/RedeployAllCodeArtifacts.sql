select 'GetPatchingPreValidation.sql'
go
--run script
:r $(scriptPath)\Patching\Scripts\Schemas\Deployment\Programmability\StoredProcedures\GetPatchingPreValidation.sql
go
select 'GetPatchingPostValidation.sql'
go
--run script
:r $(scriptPath)\Patching\Scripts\Schemas\Deployment\Programmability\StoredProcedures\GetPatchingPostValidation.sql
go
select 'GetPatchLevelDeterminationResult.sql'
go
--run script
:r $(scriptPath)\Patching\Scripts\Schemas\Deployment\Programmability\StoredProcedures\GetPatchLevelDeterminationResult.sql
go
select 'PatchingValidationEmpty.sql'
go
--run script
:r $(scriptPath)\Patching\Scripts\Schemas\Deployment\Programmability\StoredProcedures\PatchingValidationEmpty.sql
go
select 'PatchLevelDeterminationResultEmpty.sql'
go
--run script
:r $(scriptPath)\Patching\Scripts\Schemas\Deployment\Programmability\StoredProcedures\PatchLevelDeterminationResultEmpty.sql
go
select 'SetScriptAsRun.sql'
go
--run script
:r $(scriptPath)\Patching\Scripts\Schemas\Deployment\Programmability\StoredProcedures\SetScriptsAsRun.sql
go