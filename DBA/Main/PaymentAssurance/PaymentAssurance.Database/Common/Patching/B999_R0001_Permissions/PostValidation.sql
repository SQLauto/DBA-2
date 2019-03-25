go
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
go

declare @exists bit = 1
declare @message varchar(150) = 'This is valid'

-- Logins
IF NOT EXISTS (select * from sys.server_principals where ([name] = N'$(PaymentAssuranceServiceAccount)') and ([type] = 'U'))
BEGIN
	set @exists = 0
	set @message = 'Server User $(PaymentAssuranceServiceAccount) was expected to exist and it does not.'
END

USE $(DatabaseName)

IF NOT EXISTS (select * from sys.database_principals where ([name] = N'$(PaymentAssuranceServiceAccount)') and ([type] = 'U'))
BEGIN
	set @exists = 0
	set @message = 'Database User $(PaymentAssuranceServiceAccount) was expected to exist and it does not.'
END


insert into deployment.PatchingPostValidationError(IsValid, ValidationMessage) Values(@exists, @message)

GO

