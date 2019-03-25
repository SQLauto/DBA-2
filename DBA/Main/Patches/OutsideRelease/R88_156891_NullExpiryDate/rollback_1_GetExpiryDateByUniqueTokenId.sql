USE TJS;
GO

ALTER PROCEDURE travel.GetExpiryDateByUniqueTokenId
(
	@UniqueTokenId BIGINT
)
AS
BEGIN
    SELECT TOP 1
        t.[ExpiryDate]
    FROM
        travel.TapVersion t
	WHERE
		t.[UniqueTokenId] = @UniqueTokenId
	ORDER BY
		t.[UniqueTokenId], t.[TravelDay], t.[Version] ASC
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
    SELECT TOP 1
        t.[ExpiryDate]
    FROM
        travel.TapVersion t
	WHERE
		t.[UniqueTokenId] = @UniqueTokenId
	ORDER BY
		t.[UniqueTokenId], t.[TravelDay], t.[Version] ASC
END
GO
