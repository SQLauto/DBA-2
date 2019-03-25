CREATE PROCEDURE [#DatabaseReadCommittedSnapshotEnabled]
(
	@databaseName VARCHAR(128),
	@readCommittedSnapshotEnabled BIT OUT 
)
AS
BEGIN
	IF @databaseName IS NULL
	BEGIN
		raiserror('#DatabaseReadCommittedSnapshotEnabled procedure was called with one or more null arguments', 16, 1)
	END

	SET @readCommittedSnapshotEnabled = 0

	-- check db exists
	IF EXISTS(	SELECT	1 FROM	master.sys.databases WHERE	name = @databaseName )
		BEGIN	
			SELECT	@readCommittedSnapshotEnabled = sys.is_read_committed_snapshot_on 
			FROM	sys.databases sys 
			WHERE	name = @databaseName
		END
	ELSE
		BEGIN;
			THROW 51000, 'The specified database does not exist.', 1; 
		END	
END
GO

