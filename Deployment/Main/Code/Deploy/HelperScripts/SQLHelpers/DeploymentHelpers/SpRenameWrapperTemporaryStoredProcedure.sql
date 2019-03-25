create procedure #SpRenameWrapper
	@objectName nvarchar(776),
	@newName sysname,
	@objectType varchar(13),
	@message varchar(max) = null
as 
begin
		declare @startMessage varchar(max) = '******** START ******* sp_rename called expect caution'
		if (@message != null)
		begin
			set @startMessage = @startMessage + ' ' + @message
		end
		print @startMessage
		exec sp_rename @objectName, @newName, @objectType;
		print '******** END ******* sp_rename called expect caution'
end


go

