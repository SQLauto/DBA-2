create proc #PartitionFunctionExists
	@PartitionFunctionName varchar(128),
	@PartitionFunctionExists bit out
as
begin
	if @PartitionFunctionName is null
	begin
		raiserror('#IndexExists procedure was called with one or more null arguments', 16, 1)
	end

	set @PartitionFunctionExists = 0
	if exists(SELECT 1 FROM sys.partition_functions p WHERE p.name = @PartitionFunctionName)
	begin
		set @PartitionFunctionExists = 1
	end
end


go



