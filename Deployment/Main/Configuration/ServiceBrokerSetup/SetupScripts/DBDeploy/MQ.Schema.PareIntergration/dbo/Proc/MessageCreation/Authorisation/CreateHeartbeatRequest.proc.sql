CREATE PROCEDURE [dbo].[CreateHeartbeatRequest]
	@HeartbeatId bigint,
	@SentDateTime datetimeoffset,
	@Message xml output
AS

	SET @Message = (
		SELECT
			@HeartbeatId as 'HeartbeatId',
			@SentDateTime as 'SentDateTime'
			FOR XML PATH(''), ROOT('HeartbeatRequest'), elements xsinil
	);

RETURN 0