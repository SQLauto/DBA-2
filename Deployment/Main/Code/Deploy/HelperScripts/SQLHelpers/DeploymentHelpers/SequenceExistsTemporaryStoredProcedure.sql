create proc #SequenceExists
	@schemaName varchar(128),
	@sequenceName varchar(128),
	@sequenceExists bit out
as
begin
	if @schemaName is null or @sequenceName is null
	begin
		raiserror('#SequenceExists procedure was called with one or more null arguments', 16, 1)
	end

	set @sequenceExists = 0
	if exists(select 1 from sys.sequences s 
			  inner join sys.schemas sc on
				s.schema_id = sc.schema_id
				where 
					s.name = @sequenceName and
					sc.name = @schemaName)
	begin
		set @sequenceExists = 1
	end
end


go


