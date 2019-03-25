if not exists (select 1 from sys.procedures p inner join sys.schemas sc on p.schema_id = sc.schema_id
				where sc.name = 'deployment'and p.name = 'GetPatchingPostValidation')
begin
	exec ('create proc  deployment.GetPatchingPostValidation as begin select 1 end;')
end
go
alter procedure deployment.GetPatchingPostValidation
	@isValid bit output,
	@validationResult xml output
as
begin
	set @isValid = 0
	declare @count int = (select count(*) from deployment.PatchingPostValidationError)
	declare @message varchar(max)
	if (@count = 0)
	begin
		set @isValid = 0
		set @message = 'The count of records in deployment.PatchingPostValidationError must be non-zero and it was zero.'
	end
	else
	begin
		set @isValid = (select min(cast(IsValid as int)) IsValid from deployment.PatchingPostValidationError)
		declare @countOfFailures int = (select count(*) from deployment.PatchingPostValidationError where IsValid = 0)
		set @message = 'The count of post validation errors is: ' + cast(@countOfFailures as varchar(10))
	end
	
	declare @t table
	(
		UserMessage varchar(max)
	)
	insert into @t (UserMessage) values(@message)
	
	set @validationResult =  (select root.UserMessage, ValidationMessage, IsValid, CreatedAt  
	from @t as root cross join deployment.PatchingPostValidationError as ValidationError for xml auto, elements) 
	
end

go