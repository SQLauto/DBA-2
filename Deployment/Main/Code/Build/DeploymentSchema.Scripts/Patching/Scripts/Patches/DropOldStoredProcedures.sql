go
if exists (select 1 from sys.procedures p inner join sys.schemas sc on p.schema_id = sc.schema_id 
			where p.name = 'SetScriptAsRun' and sc.name = 'deployment')
begin
	drop procedure deployment.SetScriptAsRun
end
go
if exists (select 1 from sys.procedures p inner join sys.schemas sc on p.schema_id = sc.schema_id 
			where p.name = 'GetVersion' and sc.name = 'deployment')
begin
	drop procedure deployment.GetVersion
end
go
if exists (select 1 from sys.procedures p inner join sys.schemas sc on p.schema_id = sc.schema_id 
			where p.name = 'GetPatchingPreValidation' and sc.name = 'deployment')
begin
	drop procedure deployment.GetPatchingPreValidation
end
go
if exists (select 1 from sys.procedures p inner join sys.schemas sc on p.schema_id = sc.schema_id 
			where p.name = 'HasScriptBeenRun' and sc.name = 'deployment')
begin
	drop procedure deployment.HasScriptBeenRun
end
go