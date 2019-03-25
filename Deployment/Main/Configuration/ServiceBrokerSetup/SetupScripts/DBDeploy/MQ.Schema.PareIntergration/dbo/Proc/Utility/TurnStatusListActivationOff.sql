CREATE PROCEDURE [dbo].[TurnStatusListActivationOff]
	
AS
	ALTER QUEUE [http://tfl.gov.uk/Ft/Pare/StatusList/Queue/Pare] WITH STATUS = ON;
	ALTER QUEUE [http://tfl.gov.uk/Ft/Pare/StatusList/Queue/Pare]
	WITH ACTIVATION
	(
		STATUS = OFF
	);