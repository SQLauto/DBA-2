CREATE PROCEDURE [dbo].[Authorisation_DisableActivations]
AS
	ALTER QUEUE [http://tfl.gov.uk/Ft/Pare/Authorisation/Queue/Dre/Pare] WITH STATUS = ON;
	ALTER QUEUE [http://tfl.gov.uk/Ft/Pare/Authorisation/Queue/Dre/Pare]
	WITH ACTIVATION
	(
		STATUS = OFF
	);

	ALTER QUEUE [http://tfl.gov.uk/Ft/Pare/Authorisation/Queue/Idra/Pare] WITH STATUS = ON;
	ALTER QUEUE [http://tfl.gov.uk/Ft/Pare/Authorisation/Queue/Idra/Pare]
	WITH ACTIVATION
	(
		STATUS = OFF
	);

	ALTER QUEUE [http://tfl.gov.uk/Ft/Pare/Authorisation/Queue/Se/Pare] WITH STATUS = ON;
	ALTER QUEUE [http://tfl.gov.uk/Ft/Pare/Authorisation/Queue/Se/Pare]
	WITH ACTIVATION
	(
		STATUS = OFF
	);
