create proc #CertificateExists
	@certificateName varchar(128),
	@exists bit out
as
begin
	if @certificateName is null
	begin
		raiserror('#CertificateExists procedure was called with one or more null arguments', 16, 1)
	end

	set @exists = 0
	if exists(select 1 from sys.certificates where name = @certificateName)
	begin
		set @exists = 1
	end
end

go

