create procedure #XmlSchemaCollectionExists
	@schemaName varchar(128),
	@xmlSchemaCollectionName varchar(128),
	@xmlSchemaCollectionExists bit out
as
begin
	
	set @xmlSchemaCollectionExists = 0
	if exists (select 1 from 
				sys.xml_schema_collections xsc
				inner join sys.schemas sc on	
					sc.Schema_Id = xsc.schema_id
				where
					sc.name = @schemaName
				and xsc.name = @xmlSchemaCollectionName)
	begin
		set @xmlSchemaCollectionExists = 1
	end
end	;

go

