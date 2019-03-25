/*
-- Runs for TJS and TJS CPC database.

-- Applies a patch to sproc travel.GetExpiryDateByUniqueTokenId
-- which:
-- 1. When no data is found, sproc now returns Null value rather than DbNull
*/

USE TJS;
GO

ALTER PROCEDURE travel.GetExpiryDateByUniqueTokenId
(
	@UniqueTokenId BIGINT
)
AS
BEGIN
	SELECT 
	(SELECT TOP 1
        t.[ExpiryDate]
    FROM
        travel.TapVersion t
	WHERE
		t.[UniqueTokenId] = @UniqueTokenId
	ORDER BY
		t.[UniqueTokenId], t.[TravelDay], t.[Version] ASC) AS ExpiryDate
END
GO

USE TJS_CPC;
GO

ALTER PROCEDURE travel.GetExpiryDateByUniqueTokenId
(
	@UniqueTokenId BIGINT
)
AS
BEGIN
	SELECT 
	(SELECT TOP 1
        t.[ExpiryDate]
    FROM
        travel.TapVersion t
	WHERE
		t.[UniqueTokenId] = @UniqueTokenId
	ORDER BY
		t.[UniqueTokenId], t.[TravelDay], t.[Version] ASC) AS ExpiryDate
END
GO
