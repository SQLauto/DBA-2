create proc #DropTableAndReferencedObjects
	@schemaName varchar(128),
	@tableName varchar(128)
as
begin
	if @schemaName is null or @tableName is null
	begin
		raiserror('#DropTableAndReferencedObjects procedure was called with one or more null arguments', 16, 1)
	end

	if exists (select 1 from sys.tables t 
				inner join sys.schemas sc on 
					t.schema_id = sc.schema_id
				where
					t.name = @tableName
				and sc.name = @schemaName)
	begin

		declare @foreignKeysToDrop table
		(	
			Id int identity(1,1),
			SchemaName varchar(128),
			TableName varchar(128),
			KeyName varchar(128)
		)

		insert into @foreignKeysToDrop (SchemaName, TableName, KeyName)
		select 
			sc.name,
			o.name,
			fk.name
		from 
			sys.foreign_keys fk 
		inner join sys.objects o on
			fk.parent_object_id = o.object_id
		inner join sys.schemas sc on 
			sc.schema_id = o.schema_id
		inner join sys.objects ro on
			ro.object_id = fk.referenced_object_id
		inner join sys.schemas rsc on
			rsc.schema_id = ro.schema_id
		where 
			 ro.name = @tableName
		and rsc.name = @schemaName

		declare @currentId int = 1
		declare @maxRecordId int = (select count(Id) from @foreignKeysToDrop)
		declare @sql varchar(max)
		declare @schemaNameOfInterest varchar(128)
		declare @tableNameOfInterest varchar(128)
		declare @keyName varchar(128)

		while @currentId <= @maxRecordId
		begin

			select
				@schemaNameOfInterest = fkd.SchemaName,
				@tableNameOfInterest = fkd.TableName,
				@keyName = fkd.KeyName
			from
				@foreignKeysToDrop fkd
			where 
				fkd.Id = @currentId

			set @sql = 'alter table ' + @schemaNameOfInterest + '.' + @tableNameOfInterest + ' drop constraint ' + @keyName
			exec(@sql)

			set @currentId = @currentId + 1
		end

		declare @referencingEntitiesToDrop table
		(
			Id int identity(1,1),
			EntityName varchar(128),
			SchemaName varchar(128),
			DependencyLevel int,
			ReferencingId int,
			TypeToDelete varchar(15)
		)
		;

		WITH ObjectDepends(EntityName, ReferencedSchema, ReferencedEntity, ReferencedId, ReferencingId, DependencyLevel)
		AS (
			select EntityName = 
			   case referencing_class
				  when 1 then object_name(referencing_id)
				  when 12 then (select t.name from sys.triggers t 
							   where t.object_id = sed.referencing_id)
				  when 13 then (select st.name from sys.server_triggers st
							   where st.object_id = sed.referencing_id)
			   end
			,referenced_schema_name ReferencedSchema
			,referenced_entity_name ReferencedEntity
			,referenced_id ReferencedId
			,referencing_id ReferencingId
			,0 DependencyLevel 
			from sys.sql_expression_dependencies sed 
			inner join sys.objects o on
				o.object_id = sed.referenced_id
			inner join sys.schemas sc on
				sc.schema_id = o.schema_id
			where
				sc.name = @schemaName
			and o.name = @tableName
		union all
			select EntityName = 
			   case sed.referencing_class
				  when 1 then OBJECT_NAME(sed.referencing_id)
				  when 12 then (select t.name from sys.triggers t 
							   where t.object_id = sed.referencing_id)
				  when 13 then (select st.name from sys.server_triggers st)
			   end
			,sed.referenced_schema_name ReferencedSchema
			,sed.referenced_entity_name ReferencedEntity
			,sed.referenced_id ReferencedId
			,sed.referencing_id ReferencingId
			,DependencyLevel + 1   
			from ObjectDepends o
			inner join sys.sql_expression_dependencies sed on 
			sed.referenced_id = o.ReferencingId
			)


		insert into @referencingEntitiesToDrop (EntityName, SchemaName, DependencyLevel, ReferencingId, TypeToDelete)
		select 
			o.Name,
			coalesce(sc.name, 'dbo'),
			max(od.DependencyLevel) DependencyLevel, 
			od.ReferencingId,
			o.[type]
		from
			ObjectDepends od
		inner join sys.objects o on
			od.ReferencingId = o.object_id
		inner join sys.schemas sc on
			sc.schema_id = o.schema_id
		group by
			o.Name,
			sc.name, 
			od.ReferencingId,
			o.[type]
		order by 
			DependencyLevel

		--drop views, procs, functions, and triggers in order
		declare @minId int = 1
		set @maxRecordId  = (select count(Id) from @referencingEntitiesToDrop)
		set @sql = ''
		set @schemaNameOfInterest = ''
		declare @entityNameOfInterest varchar(128)
		declare @typeToDelete varchar(15)

		while @maxRecordId >= @minId
		begin

			select 
				@schemaNameOfInterest = red.SchemaName,
				@entityNameOfInterest = red.EntityName,
				@typeToDelete = red.TypeToDelete
			from 
				@referencingEntitiesToDrop red
			where
				red.Id = @maxRecordId

			-- proc
			if (@typeToDelete = 'P')
			begin
				set @sql = 'drop procedure ' + @schemaNameOfInterest + '.' + @entityNameOfInterest
				exec(@sql)
			end

			--function
			if (@typeToDelete = 'FN' or @typeToDelete = 'IF' or @typeToDelete = 'TF' or @typeToDelete = 'FS' or @typeToDelete = 'FT')
			begin
				set @sql = 'drop function ' + @schemaNameOfInterest + '.' + @entityNameOfInterest
				exec(@sql)
			end
	
			--view
			if (@typeToDelete = 'V')
			begin
				set @sql = 'drop view ' + @schemaNameOfInterest + '.' + @entityNameOfInterest
				exec(@sql)
			end

			--trigger
				if (@typeToDelete = 'TR')
			begin
				set @sql = 'drop trigger ' + @schemaNameOfInterest + '.' + @entityNameOfInterest
				exec(@sql)
			end

			set @maxRecordId = @maxRecordId - 1
		end

		--finally drop table of interest
		set @sql = 'drop table ' + @schemaName + '.' + @tableName
		exec(@sql)
	end
end


go

