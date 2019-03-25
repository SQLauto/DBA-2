create proc #IndexExists
	@indexName varchar(128),
	@indexExists bit out
as
begin
	if @indexName is null
	begin
		raiserror('#IndexExists procedure was called with one or more null arguments', 16, 1)
	end

	set @indexExists = 0
	if exists(select 1 from sys.indexes idx
					where idx.name = @indexName)
	begin
		set @indexExists = 1
	end
	
end


go


