SET NOCOUNT ON;
declare @executionid int=!DBVARIABLE_executionid!
declare @reportid int=!DBVARIABLE_reportid!
declare @iserror bit=!DBVARIABLE_iserror!
declare @errormessage varchar(1000)=!DBVARIABLE_errormessage!
declare @createddate datetime=!DBVARIABLE_createddate!

INSERT INTO [assurance].[Results] 
([execution_id],[report_id],[iserror],[errormessage],[created])
VALUES
(@executionid,@reportid,@iserror,@errormessage,@createddate);