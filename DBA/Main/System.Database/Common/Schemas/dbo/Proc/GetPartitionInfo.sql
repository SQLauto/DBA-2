EXEC #CreateDummyStoredProcedureIfNotExists 'dbo', 'GetPartitionInfo'
GO
ALTER PROCEDURE [dbo].[GetPartitionInfo] @ObjectName varchar(255)
AS
	set transaction isolation level read uncommitted;
	
select partition_id, SDS.name [FileGroup], partition_number, [value] [Range], P.rows [Rows]
	from sys.indexes I 
		LEFT JOIN sys.partition_schemes PS ON I.Data_Space_ID = PS.data_space_id
		LEFT JOIN sys.partition_functions PF ON PF.function_id = PS.Function_ID
		LEFT JOIN sys.partition_range_values RV ON RV.function_id = PF.function_id
		LEFT JOIN sys.partitions P	ON P.Partition_number = RV.boundary_id AND p.index_id = I.index_id
		LEFT JOIN sys.destination_data_spaces DS ON DS.destination_id = P.Partition_Number AND DS.partition_scheme_id = PS.data_space_id
		LEFT JOIN sys.data_spaces SDS ON SDS.data_space_id = DS.data_space_id
	WHERE I.object_id = object_id(@ObjectName) 
		AND P.object_id = object_id(@ObjectName)
		order by partition_number

GO
