EXEC #CreateDummyStoredProcedureIfNotExists 'dbo', 'spWriteStringToFile'
GO

ALTER PROCEDURE [dbo].[spWriteStringToFile]
(
@String Varchar(max), --8000 in SQL Server 2000
@Path VARCHAR(255),
@Filename VARCHAR(100)

--
)
AS
DECLARE  @objFileSystem int
        ,@objTextStream int,
              @objErrorObject int,
              @strErrorMessage Varchar(1000),
           @Command varchar(1000),
           @hr int,
              @fileAndPath varchar(80)

set nocount on

select @strErrorMessage='opening the File System Object'
EXECUTE @hr = sp_OACreate  'Scripting.FileSystemObject' , @objFileSystem OUT

Select @FileAndPath=@path+'\'+@filename
if @HR=0 Select @objErrorObject=@objFileSystem , @strErrorMessage='Creating file "'+@FileAndPath+'"'
if @HR=0 execute @hr = sp_OAMethod   @objFileSystem   , 'CreateTextFile'
       , @objTextStream OUT, @FileAndPath,2,True

if @HR=0 Select @objErrorObject=@objTextStream, 
       @strErrorMessage='writing to the file "'+@FileAndPath+'"'
if @HR=0 execute @hr = sp_OAMethod  @objTextStream, 'opentextfile', Null, @String
--EXEC @returnValue = sp_OAMethod @fileSystemObject,”opentextfile”, @textStream OUTPUT, @fileName, 8


if @HR=0 Select @objErrorObject=@objTextStream, @strErrorMessage='closing the file "'+@FileAndPath+'"'
if @HR=0 execute @hr = sp_OAMethod  @objTextStream, 'Close'

if @hr<>0
       begin
       Declare 
              @Source varchar(255),
              @Description Varchar(255),
              @Helpfile Varchar(255),
              @HelpID int
       
       EXECUTE sp_OAGetErrorInfo  @objErrorObject, 
              @source output,@Description output,@Helpfile output,@HelpID output
       Select @strErrorMessage='Error whilst '
                     +coalesce(@strErrorMessage,'doing something')
                     +', '+coalesce(@Description,'')
       raiserror (@strErrorMessage,16,1)
       end
EXECUTE  sp_OADestroy @objTextStream
EXECUTE sp_OADestroy @objTextStream




GO
