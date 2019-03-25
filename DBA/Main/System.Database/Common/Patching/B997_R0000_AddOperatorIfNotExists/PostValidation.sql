

GO

declare @validationMessage varchar(max)
declare @exists bit = 0

if	exists(select 1 from msdb.dbo.sysoperators where name = 'The CE DBA Team')
begin
	set @exists = 1
end

set @validationMessage = 'Operator [The CE DBA Team] was expected to exist and it does not.'
insert into deployment.PatchingPostValidationError(ValidationMessage, IsValid) values (@validationMessage, @exists)
