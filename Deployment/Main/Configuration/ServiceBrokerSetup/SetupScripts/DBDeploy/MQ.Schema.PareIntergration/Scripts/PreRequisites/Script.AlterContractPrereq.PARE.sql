

-- This isn't strictly patching but using this model to make it clear that this runs before the dacpac
-- (dacpac pre-deployment scripts don't get committed prior to the compare)
-- the SB Schema Pare/Pcs fails queue updates with a dependency on the sb service so it must be deleted first.

IF EXISTS (select * from sys.services where [name] = 'http://tfl.gov.uk/Ft/Pare/DirectPayment/Service/Pare')
BEGIN
	DROP SERVICE [http://tfl.gov.uk/Ft/Pare/DirectPayment/Service/Pare]
END