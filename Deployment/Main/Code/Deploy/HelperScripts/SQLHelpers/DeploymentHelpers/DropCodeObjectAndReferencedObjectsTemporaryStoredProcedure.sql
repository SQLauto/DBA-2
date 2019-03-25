create proc #DropCodeObjectAndReferencedObjects
	@schemaName varchar(128),
	@codeObjectName varchar(128)
as
begin
	if @schemaName is null or @codeObjectName is null
	begin
		raiserror('#DropCodeObjectAndReferencedObjects procedure was called with one or more null arguments', 16, 1)
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
			and o.name = @codeObjectName
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

		insert into @referencingEntitiesToDrop (EntityName, SchemaName, DependencyLevel, ReferencingId, TypeToDelete)
		select
			@codeObjectName,
			@schemaName,
			99999,
			so.object_Id,
			so.[type]
		from
			sys.objects so 
		inner join sys.schemas sc on
			so.schema_id = sc.schema_id
		where
			so.name = @codeObjectName
		and sc.name = @schemaName

		--drop views, procs, functions, and triggers in order
		declare @minId int = 1
		declare @maxRecordId int  = (select count(Id) from @referencingEntitiesToDrop)
		declare @sql varchar(max) = ''
		declare @schemaNameOfInterest varchar(128) = ''
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
				set @sql = 'drop procedure [' + @schemaNameOfInterest + '].[' + @entityNameOfInterest + ']'
				exec(@sql)
			end

			--function
			if (@typeToDelete = 'FN' or @typeToDelete = 'IF' or @typeToDelete = 'TF' or @typeToDelete = 'FS' or @typeToDelete = 'FT')
			begin
				set @sql = 'drop function [' + @schemaNameOfInterest +  '].['  + @entityNameOfInterest + ']'
				exec(@sql)
			end
	
			--view
			if (@typeToDelete = 'V')
			begin
				set @sql = 'drop view [' + @schemaNameOfInterest + '].[' + @entityNameOfInterest + ']'
				exec(@sql)
			end

			--trigger
				if (@typeToDelete = 'TR')
			begin
				set @sql = 'drop trigger [' + @schemaNameOfInterest +  '].['  + @entityNameOfInterest + ']'
				exec(@sql)
			end

			--check constraint or default constraint
			if (@typeToDelete = 'C' or @typeToDelete = 'D')
			begin
				set @sql = (select 'alter table ' + sc.name + '.' + t.name + ' drop constraint ' + so.name  
							from 
								sys.objects so
							inner join sys.schemas sco on
								sco.schema_id = so.schema_id
							inner join sys.tables t on 
								t.object_id = so.parent_object_id
							inner join sys.schemas sc on 
								sc.schema_id = t.schema_id
							where
								so.name = @entityNameOfInterest and
								sco.name = @schemaNameOfInterest)
				exec(@sql)
			end	

			set @maxRecordId = @maxRecordId - 1
		end
	end

go

