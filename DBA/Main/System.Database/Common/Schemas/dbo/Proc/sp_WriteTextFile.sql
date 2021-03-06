EXEC #CreateDummyStoredProcedureIfNotExists 'dbo', 'sp_WriteTextFile'
GO

ALTER PROCEDURE [dbo].[sp_WriteTextFile]
(
 @fileName VARCHAR(1000),
 @text VARCHAR(MAX),
 @append BIT = 0
)
AS
DECLARE
 @fileSystemObject INT,
 @textStream INT,
 @returnValue INT,
 --variables for error handling
 @errorStatus varchar(512),
 @errorDescription varchar(512)

--attempt to create the FileSystemObject
EXEC @returnValue = sp_OACreate "Scripting.FileSystemObject", @fileSystemObject OUTPUT, 1

--check for errors
IF @returnValue <> 0 GOTO errorHandler

--determine whether to append this data to the text file or to create a new file, overwriting any existing data
IF @append = 1
BEGIN
 EXEC @returnValue = sp_OAMethod @fileSystemObject,"opentextfile", @textStream OUTPUT, @fileName, 8
 --check for errors
 IF @returnValue <> 0 GOTO errorHandler
END
ELSE
BEGIN
 EXEC @returnValue = sp_OAMethod @fileSystemObject,"createtextfile", @textStream OUTPUT, @fileName, -1
 --check for errors
 IF @returnValue <> 0 GOTO errorHandler
END

EXEC @returnValue = sp_OAMethod @textStream, "write", null, @text
--check for errors
IF @returnValue <> 0 GOTO errorHandler

EXEC @returnValue = sp_OAMethod @textStream,"close"
--check for errors
IF @returnValue <> 0 GOTO errorHandler

--clean up
EXEC sp_OADestroy @textStream
EXEC sp_OADestroy @fileSystemObject

return 0

errorHandler:
 --get error
 EXEC sp_OAGetErrorInfo null, @errorStatus OUTPUT, @errorDescription OUTPUT
 --raise error
 RAISERROR(@errorDescription,16,1)
 --clean up
 EXEC sp_OADestroy @textStream
 EXEC sp_OADestroy @fileSystemObject

 return 1

GO
