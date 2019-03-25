
GO


if not exists(select 1 from sys.schemas s where s.name = 'maint')
begin
    exec('create schema maint');
end

if not exists(select 1 from sys.schemas s where s.name = 'support')
begin
    exec('create schema support');
end


go

