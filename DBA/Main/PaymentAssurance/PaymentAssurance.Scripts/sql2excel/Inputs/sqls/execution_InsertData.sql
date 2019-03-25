SET NOCOUNT ON;

INSERT INTO [assurance].[execution] ([started])
OUTPUT  (Inserted.ID)
VALUES (@starteddate);