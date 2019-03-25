SET NOCOUNT ON;
declare @filename varchar(100)=!DBVARIABLE_filename!
UPDATE [assurance].[reports]
   SET [isenabled] = 0
 WHERE filename=@filename
 AND [isenabled] = 1

