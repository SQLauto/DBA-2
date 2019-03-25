create proc #ForeignKeyExists
	@foreignKeyName varchar(128),
	@foreignKeyExists bit out
as
begin
	if @foreignKeyName is null
	begin
		raiserror('#ForeignKeyExists procedure was called with one or more null arguments', 16, 1)
	end

	set @foreignKeyExists = 0
	if exists(select 1 from sys.foreign_keys fk 
		where fk.name =  @foreignKeyName)
	begin
		set @foreignKeyExists = 1
	end
end


go

