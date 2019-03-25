create proc #TableExistsWithCount
	@schemaName varchar(128),
	@tableName varchar(128),
	@count bigint,
	@tableExists bit out
as
begin
	if @schemaName is null or @tableName is null or @count is null
	begin
		raiserror('#TableExistsWithCount procedure was called with one or more null arguments', 16, 1)
	end

	DECLARE @RowCount INT, @SQL NVARCHAR(1000)
	
	set @tableExists = 0
	if exists(select 1 from sys.tables t 
			  inner join sys.schemas sc on
				t.schema_id = sc.schema_id
				where 
					t.name = @tableName and
					sc.name = @schemaName) 
	   
				
	begin
		SELECT @SQL = N'SELECT @RowCount = COUNT(1) from ' +@schemaName+'.' +@tableName
		EXEC sp_executesql @SQL, N'@RowCount INT OUTPUT', @RowCount OUTPUT
		
		
		if @RowCount=@count
		begin
			set @tableExists=1 
		end
		
	end
	

end


go


