/*	
	Rolls back the change to the List_To_Table function, causing the function to return a NOT NULL TABLE type.
*/

USE [RefundManager]

IF EXISTS (
			SELECT	1 
			FROM	sysobjects 
			WHERE	name = 'List_to_Table' 
					AND 
					xtype IN (N'TF')		-- table function
)
BEGIN
	DROP FUNCTION [Refunds].[List_to_Table]
END
GO

-- Create the [Refunds].[List_to_Table] function
--IF NOT EXISTS (
--			SELECT	1 
--			FROM	sysobjects 
--			WHERE	name = 'List_to_Table' 
--					AND 
--					xtype IN (N'TF')		-- table function
--)
--BEGIN
	CREATE FUNCTION [Refunds].[List_to_Table] (@list nvarchar(MAX), @delimiter NCHAR(1))
		RETURNS @tbl TABLE (value NVARCHAR(50) NOT NULL) 
	AS
	BEGIN
		DECLARE @pos        INT,
				@nextpos    INT,
				@valuelen   INT

		SELECT @pos = 0, @nextpos = 1

		WHILE @nextpos > 0
		BEGIN
			SELECT @nextpos = charindex(@delimiter, @list, @pos + 1)
			SELECT @valuelen = CASE WHEN @nextpos > 0 THEN @nextpos
									ELSE len(@list) + 1
								END - @pos - 1
			INSERT @tbl (value)
				VALUES (substring(@list, @pos + 1, @valuelen))
			SELECT @pos = @nextpos
		END
		RETURN
	END
--END
GO