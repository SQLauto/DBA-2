
EXEC #CreateDummyViewIfNotExists 'admin', 'View_PartitionRanges'

GO

ALTER VIEW [admin].[View_PartitionRanges]
AS
--http://blogs.msdn.com/b/hanspo/archive/2009/08/21/inside-of-table-and-index-partitioning-in-microsoft-sql-server.aspx
select pf.name as [partition_function],
		ps.name as [partition_scheme],
		prv.boundary_id + cast(pf.boundary_value_on_right as int) as [partition_number],
		case when pf.boundary_value_on_right = 0 then '<=' else '>=' end as [relation],
		prv.value as [boundary_value],
		type_name(pp.system_type_id) as [type],
		fg.name as [filegroup],
		case when ps.name is null then NULL else N'IN USE' end as [status]
		,count(f.file_id) CountOfFiles
		,fg.data_space_id FileGroupDataSpaceId
from sys.partition_functions pf
join sys.partition_range_values prv 
	on prv.function_id = pf.function_id 
	and prv.parameter_id = 1
join sys.partition_parameters pp 
	on pp.function_id = pf.function_id
left join sys.partition_schemes ps 
	on ps.function_id = pf.function_id
left join sys.destination_data_spaces dds
	on dds.partition_scheme_id = ps.data_space_id 
	and dds.destination_id = prv.boundary_id + cast(pf.boundary_value_on_right as int)
left join sys.filegroups fg 
	on fg.data_space_id = dds.data_space_id
left join sys.database_files f 
	on fg.data_space_id = f.data_space_id
group by pf.name,ps.name,pf.boundary_value_on_right,prv.value,prv.boundary_id,pp.system_type_id,fg.name, fg.data_space_id;

GO
 

