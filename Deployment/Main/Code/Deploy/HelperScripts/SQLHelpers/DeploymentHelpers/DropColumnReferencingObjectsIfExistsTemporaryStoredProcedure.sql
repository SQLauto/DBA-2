create proc #DropColumnReferencingObjects
	@schemaName varchar(128),
	@tableName varchar(128),
	@columnName varchar(128)
as
begin
	if @schemaName is null or @tableName is null or @columnName is null
	begin
		raiserror('#DropColumnReferencingObjects procedure was called with one or more null arguments', 16, 1)
	end

	if exists (
				select 1 from sys.tables t
					inner join sys.schemas sc on 
						t.schema_id = sc.schema_id
					inner join sys.columns co on
						t.object_id = co.object_id
					where
						sc.name = @schemaName
					and t.name = @tableName
					and co.Name = @columnName
					)
	begin

		--drop indexes on column
		declare @indexesToDrop table
		(
			Id int identity(1,1),
			IndexName varchar(128) not null,
			IsConstraint bit not null
		)

		insert into @indexesToDrop (IndexName, IsConstraint)
		select 
			ix.Name IndexName,
			ix.is_primary_key | ix.Is_unique_constraint IsConstraint
		from 
			sys.indexes ix 
		inner join sys.tables t on
				t.object_id = ix.object_id
		inner join sys.schemas sc on 
			t.schema_id = sc.schema_id
		inner join sys.index_columns ixc on
			ixc.index_id = ix.index_id
		and ix.object_id = ixc.object_id
		inner join sys.columns c on
			t.object_id = c.object_id
		and c.column_id = ixc.column_id
		where 
			sc.name = @schemaName
		and t.name = @tableName
		and c.name = @columnName

		declare @currentId int = 1
		declare @maxRecordId int  = (select count(Id) from @indexesToDrop)
		declare @sql varchar(max) = ''
		declare @indexName varchar(128)
		declare @isConstraint bit

		while (@currentId <= @maxRecordId)
		begin
			select	
				@indexName = i.IndexName,
				@isConstraint = i.IsConstraint
			from 
				@indexesToDrop i
			where
				i.Id = @currentId

				if (@isConstraint = 1)
				begin
					set @sql = 'alter table ' + @schemaName + '.' + @tableName + ' drop constraint ' + @indexName
				end
				else
				begin
					set @sql = ' drop index ' + @indexName + ' on ' + @schemaName + '.' + @tableName 
				end

				exec (@sql)

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
			
			select 
				orefd.name EntityName,
				sc.name ReferencedSchema,
				o.name ReferencedEntity,
				ed.referenced_id ReferencedId,
				ed.referencing_id ReferencingId,
				0 DependencyLevel
			from 
				sys.sql_dependencies d
			inner join sys.objects o on
				d.referenced_major_id = o.object_id
			inner join sys.objects orefd on
				d.object_id = orefd.object_id
			inner join sys.schemas sc on
				sc.schema_id = o.schema_id
			inner join sys.sql_expression_dependencies ed on 
				ed.referenced_entity_name = o.name
			and ed.referenced_schema_name = sc.name

			inner join sys.columns c on
				c.object_id = d.referenced_major_id
			and c.column_id = d.referenced_minor_id
			where
				o.name = @tableName
			and sc.name = @schemaName
			and c.name = @columnName
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
		set @maxRecordId = (select count(Id) from @referencingEntitiesToDrop)
		set @sql = ''
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
				set @sql = 'drop function [' + @schemaNameOfInterest + '].[' + @entityNameOfInterest + ']'
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
				set @sql = 'drop trigger [' + @schemaNameOfInterest + '].[' + @entityNameOfInterest + ']'
				exec(@sql)
			end

			--check constraint or default constraint
			if (@typeToDelete = 'C' or @typeToDelete = 'D')
			begin
				set @sql = (select 'alter table [' + sc.name + '].[' + t.name + '] drop constraint ' + so.name
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
				print(@sql)
				exec(@sql)
			end	

			set @maxRecordId = @maxRecordId - 1
		end
	end
end

go
