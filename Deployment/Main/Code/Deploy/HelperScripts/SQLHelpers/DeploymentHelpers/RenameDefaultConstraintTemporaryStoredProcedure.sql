create proc #RenameDefaultConstraint
/* 
	This is written so it will not fail unless parameters are null -> which should be found in testing. as it is a tidying up process
	this is not a reason to fail a release
*/
	@schemaName varchar(128),
	@tableName varchar(128),
	@columnName varchar(128),
	@constraintNameToBe varchar(128)
as
begin
	if (@schemaName is null or @tableName is null or @columnName is null or @constraintNameToBe is null)
	begin
		raiserror('#RenameDefaultConstraint procedure was called with one or more null arguments', 16, 1)
	end

	if not exists (select 1 from sys.objects where name = @constraintNameToBe)
	begin
		declare @currentConstraintName varchar(128)
		set @currentConstraintName = (select dc.name from sys.tables st
											inner join sys.schemas sc on
												st.schema_id = sc.schema_id
											inner join sys.columns co on
												st.object_id = co.object_id
											inner join sys.default_constraints dc on
												dc.parent_object_id = st.object_id
											and dc.parent_column_id = co.column_id
											where 
												st.name = @tableName
											and sc.name = @schemaName
											and co.name = @columnName)

		if (@currentConstraintName is null)
		begin
			set @currentConstraintName = 
									(select i.name from sys.tables st
										inner join sys.schemas sc on
											st.schema_id = sc.schema_id
										inner join sys.indexes i on 
											i.object_id = st.object_id
										inner join sys.index_columns ic on
											i.object_id = ic.object_id
										and i.index_id = ic.index_id
										inner join sys.columns co on
											co.column_id = ic.column_id
										and co.object_id = ic.object_id
										where 
											st.name = @tableName
										and sc.name = @schemaName
										and co.name = @columnName
										and i.is_unique_constraint = 1
										)
		end

		if (@currentConstraintName is not null)
		begin
			declare @constraintToRename varchar(128) = @schemaName + '.' + @currentConstraintName
			declare @message varchar(max) = '(' + @constraintToRename + ')'
			exec #SpRenameWrapper @constraintToRename, @constraintNameToBe, 'OBJECT', @message
		end
	end
end


go


