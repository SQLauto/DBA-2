SET NOCOUNT ON;
declare @executionid int=!DBVARIABLE_executionid!
declare @iserror bit=!DBVARIABLE_iserror!
declare @finisheddate datetime=!DBVARIABLE_finisheddate!

UPDATE [assurance].[execution]
   SET [finished] = @finisheddate
      ,[iserror] = @iserror
 WHERE ID=@executionID