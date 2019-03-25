CREATE FUNCTION [dbo].[ConvertXmlDateTimeBackToLocalTime]
(
	@offsetdate datetimeoffset
)
RETURNS datetime2
AS
BEGIN
	-- Attempt to correct the date back into the local timezone.
	-- It's assumed that this won't be required after story 3270
	-- which removes datetime2's and replaces
	-- then with the datetimeoffset data type.
	declare @utcdatetime datetime2 = convert(datetime2, @offsetdate, 1);
	declare @offsetfromutc int = DATEDIFF(HH,GETUTCDATE(),GETDATE());
	declare @localdatetime datetime2 = DATEADD(hour, (@offsetfromutc), @utcdatetime);
	return @localdatetime
END
