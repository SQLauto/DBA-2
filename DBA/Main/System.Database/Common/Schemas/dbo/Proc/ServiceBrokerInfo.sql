EXEC #CreateDummyStoredProcedureIfNotExists 'dbo', 'ServiceBrokerInfo'
GO

ALTER PROCEDURE [dbo].[ServiceBrokerInfo] @ResultSetType VARCHAR(20)
AS
set transaction isolation level read uncommitted;
--USED WITH SCOM 2012 TO RETURN SERVICE BROKER QUEUE INFO

IF EXISTS(SELECT 1 FROM SYS.DATABASES WHERE NAME = 'PARE')
BEGIN

	--RETURNS ALL QUEUES THAT ARE NOT 
	IF @ResultSetType = 'DISCOVERY'
	BEGIN
		SELECT
			name
		FROM
			PARE.sys.service_queues
		WHERE
			is_ms_shipped = 0
	END

	--RETURNS QUEUE COUNTS
	IF @ResultSetType = 'QUEUES'
	BEGIN
		SELECT 
			q.name,p.rows
		FROM
			PARE.sys.objects AS o 
			JOIN PARE.sys.partitions AS p ON p.object_id = o.object_id 
			JOIN PARE.sys.objects AS q ON o.parent_object_id = q.object_id 
		WHERE
			p.index_id = 1 
			AND
			q.is_ms_shipped = 0
		UNION ALL --USING UNION ALL TO AVOID SORTING
		SELECT
			o.name,p.rows 
		FROM
			PARE.sys.objects AS o 
			JOIN PARE.sys.partitions AS p ON p.object_id = o.object_id 
		WHERE
			o.name = 'sysxmitqueue'
		UNION ALL
		SELECT
			o.name, p.rows
		FROM
			PARE.sys.objects AS o 
			JOIN PARE.sys.partitions AS p ON p.object_id = o.object_id 
		WHERE
			o.name = 'sysdesend'
	END

	--RETURNS CONFIG OF QUEUES
	IF @ResultSetType = 'CONFIG'
	BEGIN
		SELECT
			object_id,
			name ,
			is_activation_enabled,
			is_receive_enabled,
			is_enqueue_enabled
		FROM
			PARE.sys.service_queues
		WHERE
			is_ms_shipped = 0
	END
END
ELSE
BEGIN
	--RETURNS NULL IF NOT APPLICABLE
	SELECT NULL
END

GO
