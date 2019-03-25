SET NOCOUNT ON;

SELECT   FILENAME,
         QUERY
FROM     [assurance].[reports]
WHERE    isenabled = 1
ORDER BY FILENAME ASC;