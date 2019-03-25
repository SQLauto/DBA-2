create proc #PartitionSchemeExists
	@PartitionSchemeName varchar(128),
	@PartitionSchemeExists bit out
as
begin
	if @PartitionSchemeName is null
	begin
		raiserror('#PartitionSchemeExists procedure was called with one or more null arguments', 16, 1)
	end

	set @PartitionSchemeExists = 0
	if exists(SELECT 1 FROM sys.partition_Schemes p WHERE p.name = @PartitionSchemeName)
	begin
		set @PartitionSchemeExists = 1
	end
end


go





