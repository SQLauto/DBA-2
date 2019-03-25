
GO
:r $(deploymentHelpersPath)\DeploymentHelpers.Deploy.sql
GO

-- Views
:R $(scriptPath)\..\Schemas\admin\Views\View_PartitionRanges.sql

-- Table Types
:R $(scriptPath)\..\Schemas\admin\Type\UserDefinedTableTypes\RequiredFile.sql
:R $(scriptPath)\..\Schemas\admin\Type\UserDefinedTableTypes\RequiredPartition.sql

-- Functions
:R $(scriptPath)\..\Schemas\admin\Function\PartitioningGetNextBoundary.sql
:R $(scriptPath)\..\Schemas\admin\Function\PartitioningFormatBoundary.sql
:R $(scriptPath)\..\Schemas\admin\Function\PartitioningGetBoundaryValuesPerFileGroup.sql
:R $(scriptPath)\..\Schemas\admin\Function\PartitioningGetFinalBoundaryValue.sql
:R $(scriptPath)\..\Schemas\admin\Function\PartitioningGetInitialBoundaryValue.sql

-- Procedures
:R $(scriptPath)\..\Schemas\admin\Proc\Partitioning_SplitRange.sql
:R $(scriptPath)\..\Schemas\admin\Proc\Partitioning_Configure.sql
:R $(scriptPath)\..\Schemas\admin\Proc\Partitioning_AddPartitions.sql
:R $(scriptPath)\..\Schemas\admin\Proc\Partitioning_CreatePartitions.sql
:R $(scriptPath)\..\Schemas\admin\Proc\Partitioning_TableCreate.sql
:R $(scriptPath)\..\Schemas\admin\Proc\Partitioning_TableArchiving.sql
:R $(scriptPath)\..\Schemas\admin\Proc\MaintenanceViewsOnPartitionedTables.sql
:R $(scriptPath)\..\Schemas\admin\Proc\PostPartitionValidation.sql
:R $(scriptPath)\..\Schemas\admin\Proc\Partitioning_SplitTable.sql


GO






