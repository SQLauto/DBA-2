CREATE PROCEDURE [dbo].[TurnStatusListActivationOn]
	
AS
	ALTER QUEUE [http://tfl.gov.uk/Ft/Pare/StatusList/Queue/Pare] WITH STATUS = ON;
	ALTER QUEUE [http://tfl.gov.uk/Ft/Pare/StatusList/Queue/Pare]
	WITH ACTIVATION
	(
		STATUS = ON,
		PROCEDURE_NAME = [StatusListActivation],
		MAX_QUEUE_READERS = 10,
		EXECUTE AS OWNER
	);

