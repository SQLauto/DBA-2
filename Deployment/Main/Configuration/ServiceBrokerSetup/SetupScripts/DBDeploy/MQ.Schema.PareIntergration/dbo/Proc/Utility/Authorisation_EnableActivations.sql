CREATE PROCEDURE [dbo].[Authorisation_EnableActivations]
AS
	ALTER QUEUE [http://tfl.gov.uk/Ft/Pare/Authorisation/Queue/Dre/Pare] WITH STATUS = ON;
	ALTER QUEUE [http://tfl.gov.uk/Ft/Pare/Authorisation/Queue/Dre/Pare]
	WITH ACTIVATION
	(
		STATUS = ON,
		PROCEDURE_NAME = [Authorisation_ActivationDRE],
		MAX_QUEUE_READERS = 10,
		EXECUTE AS OWNER
	);

	ALTER QUEUE [http://tfl.gov.uk/Ft/Pare/Authorisation/Queue/Idra/Pare] WITH STATUS = ON;
	ALTER QUEUE [http://tfl.gov.uk/Ft/Pare/Authorisation/Queue/Idra/Pare]
	WITH ACTIVATION
	(
		STATUS = ON,
		PROCEDURE_NAME = [Authorisation_ActivationIDRA],
		MAX_QUEUE_READERS = 10,
		EXECUTE AS OWNER
	);

	ALTER QUEUE [http://tfl.gov.uk/Ft/Pare/Authorisation/Queue/Se/Pare] WITH STATUS = ON;
	ALTER QUEUE [http://tfl.gov.uk/Ft/Pare/Authorisation/Queue/Se/Pare]
	WITH ACTIVATION
	(
		STATUS = ON,
		PROCEDURE_NAME = [Authorisation_ActivationSe],
		MAX_QUEUE_READERS = 10,
		EXECUTE AS OWNER
	);
