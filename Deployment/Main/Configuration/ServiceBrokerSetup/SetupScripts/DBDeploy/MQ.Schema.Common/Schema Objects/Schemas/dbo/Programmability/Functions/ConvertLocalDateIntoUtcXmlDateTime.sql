CREATE FUNCTION [dbo].[ConvertLocalDateIntoUtcXmlDateTime]
	(@datetime datetime2)
RETURNS VARCHAR(200)
AS
BEGIN
	DECLARE @offset INT;
	--Add an offset onto the local datetime. Note that this won't
	--work correctly if the status list instruction was created on
	--on the other side of the UTC/BST switch. It's assumed that this
	--will be fixed by story 3270 which removes datetime2's and replaces
	--then with the datetimeoffset data type.
	SELECT @offset = DATEDIFF(HH,GETUTCDATE(),GETDATE());

	--Until the correct transactiondate is added to IDRA this will use the datetime min val which will underflow in BST.
	--Fudge this for now
	IF DATEDIFF(HH, '0001-01-01 00:00:00', @datetime) <= @offset
		SET @offset = 0;
	
	DECLARE @sign CHAR = '+';
	IF @offset < 0 SET @sign = '-';  
	
	return convert(varchar(200), @datetime, 126) + @sign + right('00'+ convert(varchar(2), @offset), 2) + ':00';
END
GO