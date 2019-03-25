create proc #TableLockEscalationExists
	@schemaName varchar(128),
	@tableName varchar(128),
	@lockEscalationDescription nvarchar(60),
	@tableLockEscalationExists bit out
as
begin
	if @schemaName is null or @tableName is null or @lockEscalationDescription is null
	begin
		raiserror('#TableLockEscalationExists procedure was called with one or more null arguments', 16, 1)
	end

	set @tableLockEscalationExists = 0
	if exists(select 1 from sys.tables t 
			  inner join sys.schemas sc on
				t.schema_id = sc.schema_id
				where 
					t.name = @tableName and
					sc.name = @schemaName and
					t.lock_escalation_desc = @lockEscalationDescription)
	begin
		set @tableLockEscalationExists = 1
	end
end
;


go

