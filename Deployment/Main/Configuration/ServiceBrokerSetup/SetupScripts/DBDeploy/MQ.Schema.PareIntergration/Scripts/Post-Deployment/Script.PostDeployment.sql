/*
PARE Queue Activation
*/
print 'Adding Status list activation...';

ALTER QUEUE [http://tfl.gov.uk/Ft/Pare/StatusList/Queue/Pare] WITH STATUS = ON;
	ALTER QUEUE [http://tfl.gov.uk/Ft/Pare/StatusList/Queue/Pare]
	WITH ACTIVATION
	(
		STATUS = ON,
		PROCEDURE_NAME = [StatusListActivation],
		MAX_QUEUE_READERS = 10,
		EXECUTE AS OWNER
	);

print 'Adding DRE response activation...';

ALTER QUEUE [http://tfl.gov.uk/Ft/Pare/Authorisation/Queue/Dre/Pare] WITH STATUS = ON;
	ALTER QUEUE [http://tfl.gov.uk/Ft/Pare/Authorisation/Queue/Dre/Pare]
	WITH ACTIVATION
	(
		STATUS = ON,
		PROCEDURE_NAME = [Authorisation_ActivationDRE],
		MAX_QUEUE_READERS = 10,
		EXECUTE AS OWNER
	);

print 'Adding IDRA response activation...';

ALTER QUEUE [http://tfl.gov.uk/Ft/Pare/Authorisation/Queue/Idra/Pare] WITH STATUS = ON;
	ALTER QUEUE [http://tfl.gov.uk/Ft/Pare/Authorisation/Queue/Idra/Pare]
	WITH ACTIVATION
	(
		STATUS = ON,
		PROCEDURE_NAME = [Authorisation_ActivationIDRA],
		MAX_QUEUE_READERS = 10,
		EXECUTE AS OWNER
	);

print 'Adding Se response activation...';

ALTER QUEUE [http://tfl.gov.uk/Ft/Pare/Authorisation/Queue/se/Pare] WITH STATUS = ON;
	ALTER QUEUE [http://tfl.gov.uk/Ft/Pare/Authorisation/Queue/se/Pare]
	WITH ACTIVATION
	(
		STATUS = ON,
		PROCEDURE_NAME = [Authorisation_ActivationSE],
		MAX_QUEUE_READERS = 10,
		EXECUTE AS OWNER
	);