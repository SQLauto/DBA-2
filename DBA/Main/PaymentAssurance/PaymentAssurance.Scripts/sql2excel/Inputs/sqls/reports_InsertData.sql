SET NOCOUNT ON;

INSERT  INTO [assurance].[reports] ([filename], [query])
OUTPUT  (Inserted.ID)
VALUES (@filename, @querytext);