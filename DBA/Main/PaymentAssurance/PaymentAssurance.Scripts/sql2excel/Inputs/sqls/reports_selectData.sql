SET NOCOUNT ON;

select TOP 1 ID,QUERY from [assurance].[reports] 
WHERE [filename]=@filename
AND isenabled=1
ORDER by created desc;