CREATE PROCEDURE [#DatabaseSnapshotIsolationEnabled]
(
	@databaseName VARCHAR(128),
	@snapshotIsolationEnabled BIT OUT
)
AS
BEGIN
	IF @databaseName IS NULL
	BEGIN
		raiserror('#DatabaseSnapshotIsolationEnabled procedure was called with one or more null arguments', 16, 1)
	END

	SET @snapshotIsolationEnabled = 0

	-- check db exists
	IF EXISTS(	SELECT	1 FROM	master.sys.databases WHERE	name = @databaseName )
		BEGIN	
			SELECT	@snapshotIsolationEnabled = sys.snapshot_isolation_state 
			FROM	sys.databases sys 
			WHERE	name = @databaseName
		END
	ELSE
		BEGIN;
			THROW 51000, 'The specified database does not exist.', 1; 
		END	
END
GO

