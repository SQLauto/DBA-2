create procedure #SynonymExists
	@schemaName varchar(128),
	@synonymName varchar(128),
	@synonymExists bit out
as
begin
	set @synonymExists = 0
	if exists (select 1 from sys.synonyms sy
				inner join sys.schemas sc on
					sy.schema_id = sc.schema_id 
				where sy.name = @synonymName
				and sc.name = @schemaName)
	begin
		set @synonymExists = 1
	end
				
end

;


go

