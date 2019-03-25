GO

-- nothing to validate as patches are non-breaking
DECLARE @isValid BIT = 1;
INSERT INTO deployment.PatchingPreValidationError(IsValid, ValidationMessage) VALUES (@isValid, 'Nothing to check')
