go

--nothing to validate as patches are non-breaking
declare @isValid bit = 1;
insert into deployment.PatchingPreValidationError(IsValid, ValidationMessage) Values(@isValid, 'Table authorisation.InvalidMessage nothing to check')

go

