create procedure #DropSequenceIfExists @schemaName varchar(128), @sequenceName varchar(128)
as
begin
	
	declare @sequenceExists bit
	exec #SequenceExists @schemaName, @sequenceName, @sequenceExists out

	if (@sequenceExists = 1)
	begin
		declare @sql varchar(max) = 'drop sequence [' +  @schemaName + '].[' + @sequenceName + ']'
		exec(@sql)
	end	
end

go

