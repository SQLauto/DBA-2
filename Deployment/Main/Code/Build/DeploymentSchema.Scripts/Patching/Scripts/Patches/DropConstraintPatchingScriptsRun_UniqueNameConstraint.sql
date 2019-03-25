go
if exists (select 1 from sys.objects where name = 'PatchingScriptsRun_UniqueNameConstraint')
begin
       alter table deployment.PatchingScriptsRun drop constraint PatchingScriptsRun_UniqueNameConstraint
end

go