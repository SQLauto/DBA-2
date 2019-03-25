if not exists (select 1 from sys.procedures p inner join sys.schemas sc on p.schema_id = sc.schema_id
				where sc.name = 'deployment'and p.name = 'SetScriptAsRun')
begin
	exec ('create proc  deployment.SetScriptAsRun as begin select 1 end;')
end
go
alter procedure [deployment].[SetScriptAsRun]
	@Script NVARCHAR(255)
AS
begin
	SET NOCOUNT ON;
	
	INSERT INTO [deployment].PatchingScriptsRun VALUES (@Script, GETDATE(), SYSTEM_USER)
end
go