using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Dto;

namespace MonitoringService
{
    public class BaselineService
    {

        private static ReportService ReportServiceInstance = new ReportService();
        private static Dictionary<BarChartScalarType, ScalarBarChartGenerateData> BarChartGenerators = new Dictionary<BarChartScalarType,ScalarBarChartGenerateData>(); 
        private delegate List<DatabaseScalarValue> ScalarBarChartGenerateData(ReportParametersDto paramDto);


        static BaselineService()
        {
            BarChartGenerators.Add(BarChartScalarType.TotalIops, ReportServiceInstance.TotalIopsGet);
            BarChartGenerators.Add(BarChartScalarType.TotalNumberOfExecutions, ReportServiceInstance.TotalNumberOfExecutionsGet);
            BarChartGenerators.Add(BarChartScalarType.TotalWorkerTimeSeconds, ReportServiceInstance.TotalWorkerTimeGet);
            BarChartGenerators.Add(BarChartScalarType.TotalPhysicalReads, ReportServiceInstance.TotalPhysicalReadsGet);
            BarChartGenerators.Add(BarChartScalarType.TotalLogicalReads, ReportServiceInstance.TotalLogicalReadsGet);
            BarChartGenerators.Add(BarChartScalarType.TotalElapsedTimeSeconds, ReportServiceInstance.TotalElapsedTimeGet);
            BarChartGenerators.Add(BarChartScalarType.LongestRunningTimeSeconds, ReportServiceInstance.LongestRunningQueriesGet);
            BarChartGenerators.Add(BarChartScalarType.AverageIopsPerCall, ReportServiceInstance.AverageIopsPerCallGet);
            BarChartGenerators.Add(BarChartScalarType.AverageElapsedTimeMilliSeconds, ReportServiceInstance.AverageElapsedTimeGet);
            //To Do implement this DAL
            BarChartGenerators.Add(BarChartScalarType.AverageNumberExecutionsPerSproc, ReportServiceInstance.TotalNumberOfExecutionsGet);
            //To Do implement this DAL
            BarChartGenerators.Add(BarChartScalarType.AverageIopsPerSproc, ReportServiceInstance.AverageIopsPerCallGet);
        }

        public DatabaseExecutionMetric DatabaseExecutionMetricGet(string environment, string startDate, string endDate, string databaseOfInterest, string sqlOfInterest)
        {
            var metric = new DatabaseExecutionMetric
            {
                Environment =  environment,
                StartDate = DateTime.Parse(startDate),
                EndDate = DateTime.Parse(endDate),
                DatabaseOfInterest = databaseOfInterest,
                SqlOfInterest = sqlOfInterest,
                AverageElapsedTimeMilliSeconds = 12,
                AverageIopsPerCall = 497,
                LongestRunningTimeSeconds = 1,
                TotalElapsedTimeSeconds = 3072,
                TotalLogicalReads = 123902316,
                TotalLogicalWrites = 299,
                TotalPhysicalReads = 1647,
                TotalWorkerTimeSeconds = 2369,
                TotalNumberOfExecutions = 248991,
                TotalIops = 123902615,
                LatestExecutionPlan =
                    "<ShowPlanXML xmlns='http://schemas.microsoft.com/sqlserver/2004/07/showplan' Version='1.2' Build='11.0.5058.0'><BatchSequence><Batch><Statements><StmtSimple StatementText='select * from [archive].[PendingCharge]' StatementId='1' StatementCompId='1' StatementType='SELECT' RetrievedFromCache='true' StatementSubTreeCost='5400.76' StatementEstRows='3.86034e+008' StatementOptmLevel='FULL' QueryHash='0xB5507996E012A500' QueryPlanHash='0x305601EBF4171CEB'><StatementSetOptions QUOTED_IDENTIFIER='true' ARITHABORT='true' CONCAT_NULL_YIELDS_NULL='true' ANSI_NULLS='true' ANSI_PADDING='true' ANSI_WARNINGS='true' NUMERIC_ROUNDABORT='false' /><QueryPlan CachedPlanSize='72' CompileTime='35' CompileCPU='3' CompileMemory='808'><MemoryGrantInfo SerialRequiredMemory='0' SerialDesiredMemory='0' /><OptimizerHardwareDependentProperties EstimatedAvailableMemoryGrant='480000' EstimatedPagesCached='960000' EstimatedAvailableDegreeOfParallelism='8' /><RelOp NodeId='0' PhysicalOp='Clustered Index Scan' LogicalOp='Clustered Index Scan' EstimateRows='3.86034e+008' EstimateIO='4976.02' EstimateCPU='424.739' AvgRowSize='148' EstimatedTotalSubtreeCost='5400.76' TableCardinality='3.86034e+008' Parallel='0' Partitioned='1' EstimateRebinds='0' EstimateRewinds='0' EstimatedExecutionMode='Row'><OutputList><ColumnReference Database='[PARE]' Schema='[archive]' Table='[PendingCharge]' Column='SettlementId' /><ColumnReference Database='[PARE]' Schema='[archive]' Table='[PendingCharge]' Column='SettlementBatchId' /><ColumnReference Database='[PARE]' Schema='[archive]' Table='[PendingCharge]' Column='Created' /><ColumnReference Database='[PARE]' Schema='[archive]' Table='[PendingCharge]' Column='Modified' /><ColumnReference Database='[PARE]' Schema='[archive]' Table='[PendingCharge]' Column='TravelTokenId' /><ColumnReference Database='[PARE]' Schema='[archive]' Table='[PendingCharge]' Column='ExpiryDatePartition' /><ColumnReference Database='[PARE]' Schema='[archive]' Table='[PendingCharge]' Column='TravelDay' /><ColumnReference Database='[PARE]' Schema='[archive]' Table='[PendingCharge]' Column='ChargeToCardAmount' /><ColumnReference Database='[PARE]' Schema='[archive]' Table='[PendingCharge]' Column='CreditGivenAmount' /><ColumnReference Database='[PARE]' Schema='[archive]' Table='[PendingCharge]' Column='CreditUsedAmount' /><ColumnReference Database='[PARE]' Schema='[archive]' Table='[PendingCharge]' Column='DelayedSettlementReasonId' /><ColumnReference Database='[PARE]' Schema='[archive]' Table='[PendingCharge]' Column='GoodwillAmount' /><ColumnReference Database='[PARE]' Schema='[archive]' Table='[PendingCharge]' Column='TransactionDate' /><ColumnReference Database='[PARE]' Schema='[archive]' Table='[PendingCharge]' Column='LastTapPaymentCardATC' /><ColumnReference Database='[PARE]' Schema='[archive]' Table='[PendingCharge]' Column='PendingChargeStatusId' /><ColumnReference Database='[PARE]' Schema='[archive]' Table='[PendingCharge]' Column='ChargeTypeId' /><ColumnReference Database='[PARE]' Schema='[archive]' Table='[PendingCharge]' Column='LinkedChargeToCardAmount' /><ColumnReference Database='[PARE]' Schema='[archive]' Table='[PendingCharge]' Column='LinkedSettlementId' /><ColumnReference Database='[PARE]' Schema='[archive]' Table='[PendingCharge]' Column='AVPAuthorisationLogId' /><ColumnReference Database='[PARE]' Schema='[archive]' Table='[PendingCharge]' Column='OriginalAuthorisationLogId' /><ColumnReference Database='[PARE]' Schema='[archive]' Table='[PendingCharge]' Column='TapTimestamp' /><ColumnReference Database='[PARE]' Schema='[archive]' Table='[PendingCharge]' Column='OriginalAuthCode' /><ColumnReference Database='[PARE]' Schema='[archive]' Table='[PendingCharge]' Column='OriginalTraceId' /><ColumnReference Database='[PARE]' Schema='[archive]' Table='[PendingCharge]' Column='OriginalTravelDay' /></OutputList><IndexScan Ordered='0' ForcedIndex='0' ForceScan='0' NoExpandHint='0'><DefinedValues><DefinedValue><ColumnReference Database='[PARE]' Schema='[archive]' Table='[PendingCharge]' Column='SettlementId' /></DefinedValue><DefinedValue><ColumnReference Database='[PARE]' Schema='[archive]' Table='[PendingCharge]' Column='SettlementBatchId' /></DefinedValue><DefinedValue><ColumnReference Database='[PARE]' Schema='[archive]' Table='[PendingCharge]' Column='Created' /></DefinedValue><DefinedValue><ColumnReference Database='[PARE]' Schema='[archive]' Table='[PendingCharge]' Column='Modified' /></DefinedValue><DefinedValue><ColumnReference Database='[PARE]' Schema='[archive]' Table='[PendingCharge]' Column='TravelTokenId' /></DefinedValue><DefinedValue><ColumnReference Database='[PARE]' Schema='[archive]' Table='[PendingCharge]' Column='ExpiryDatePartition' /></DefinedValue><DefinedValue><ColumnReference Database='[PARE]' Schema='[archive]' Table='[PendingCharge]' Column='TravelDay' /></DefinedValue><DefinedValue><ColumnReference Database='[PARE]' Schema='[archive]' Table='[PendingCharge]' Column='ChargeToCardAmount' /></DefinedValue><DefinedValue><ColumnReference Database='[PARE]' Schema='[archive]' Table='[PendingCharge]' Column='CreditGivenAmount' /></DefinedValue><DefinedValue><ColumnReference Database='[PARE]' Schema='[archive]' Table='[PendingCharge]' Column='CreditUsedAmount' /></DefinedValue><DefinedValue><ColumnReference Database='[PARE]' Schema='[archive]' Table='[PendingCharge]' Column='DelayedSettlementReasonId' /></DefinedValue><DefinedValue><ColumnReference Database='[PARE]' Schema='[archive]' Table='[PendingCharge]' Column='GoodwillAmount' /></DefinedValue><DefinedValue><ColumnReference Database='[PARE]' Schema='[archive]' Table='[PendingCharge]' Column='TransactionDate' /></DefinedValue><DefinedValue><ColumnReference Database='[PARE]' Schema='[archive]' Table='[PendingCharge]' Column='LastTapPaymentCardATC' /></DefinedValue><DefinedValue><ColumnReference Database='[PARE]' Schema='[archive]' Table='[PendingCharge]' Column='PendingChargeStatusId' /></DefinedValue><DefinedValue><ColumnReference Database='[PARE]' Schema='[archive]' Table='[PendingCharge]' Column='ChargeTypeId' /></DefinedValue><DefinedValue><ColumnReference Database='[PARE]' Schema='[archive]' Table='[PendingCharge]' Column='LinkedChargeToCardAmount' /></DefinedValue><DefinedValue><ColumnReference Database='[PARE]' Schema='[archive]' Table='[PendingCharge]' Column='LinkedSettlementId' /></DefinedValue><DefinedValue><ColumnReference Database='[PARE]' Schema='[archive]' Table='[PendingCharge]' Column='AVPAuthorisationLogId' /></DefinedValue><DefinedValue><ColumnReference Database='[PARE]' Schema='[archive]' Table='[PendingCharge]' Column='OriginalAuthorisationLogId' /></DefinedValue><DefinedValue><ColumnReference Database='[PARE]' Schema='[archive]' Table='[PendingCharge]' Column='TapTimestamp' /></DefinedValue><DefinedValue><ColumnReference Database='[PARE]' Schema='[archive]' Table='[PendingCharge]' Column='OriginalAuthCode' /></DefinedValue><DefinedValue><ColumnReference Database='[PARE]' Schema='[archive]' Table='[PendingCharge]' Column='OriginalTraceId' /></DefinedValue><DefinedValue><ColumnReference Database='[PARE]' Schema='[archive]' Table='[PendingCharge]' Column='OriginalTravelDay' /></DefinedValue></DefinedValues><Object Database='[PARE]' Schema='[archive]' Table='[PendingCharge]' Index='[PK_PendingCharge]' IndexKind='Clustered' /></IndexScan></RelOp></QueryPlan></StmtSimple></Statements></Batch></BatchSequence></ShowPlanXML>"
            };

            return metric;
        }

        public DatabaseScalarMetricSet DatabaseScalarMetricsGet(string environment, DateTime startDate, DateTime endDate, string databaseOfInterest, string value, BarChartScalarType typeOfBarChartToCreate)
        {
            var dto = new ReportParametersDto
            {
                DatabaseName = databaseOfInterest,
                StartDate = startDate,
                EndDate = endDate,
                Enviroment = environment
            };

            ScalarBarChartGenerateData dataGenerator = BarChartGenerators[typeOfBarChartToCreate];
            List<DatabaseScalarValue> scalars = dataGenerator(dto);

            var model = new DatabaseScalarMetricSet
            {
                DatabaseName = dto.DatabaseName,
                EnvironmentName = dto.Enviroment,
                End = dto.EndDate,
                Start = dto.StartDate,
                Scalars = scalars
            };

            return model;
        }

        private DatabaseMacroMetricSetBasic DatabaseMacroMetricSetGet(EnvironmentCriteria criteria)
        {
            var set = new DatabaseMacroMetricSetBasic { EnvironmentName = criteria.EnvironmentName, Start = criteria.Start, End = criteria.End};
            set.Metrics.Add(GetPareMetric());
            set.Metrics.Add(GetFaeMetric());
            //set.Metrics.Add(GetCascMetric());

            return set;

          
        }

        public DatabaseMacroMetricSetNormalised DatabaseMacroMetricNormalisedSetGet(EnvironmentCriteria criteria1,
            EnvironmentCriteria criteria2 = null)
        {
            DatabaseMacroMetricSetBasic set1 = DatabaseMacroMetricSetGet(criteria1);
            DatabaseMacroMetricSetBasic set2 = null;
            if (criteria2 != null)
            {
                set2 = DatabaseMacroMetricSetGet(criteria2);    
            }


            var adapter = new DatabaseMacroMetricSetAdapter();
            DatabaseMacroMetricSetNormalised normalisedSet = adapter.Convert(set1, set2);

            return normalisedSet;
        }

        private DatabaseMacroMetricBasic GetCascMetric()
        {
            return new DatabaseMacroMetricBasic
            {
                DatabaseName = "CS",
                TotalIops = 84,
                TotalNumberOfExecutions = 21,
                TotalWorkerTimeSeconds = 0,
                TotalPhysicalReads = 0,
                TotalLogicalWrites = 0,
                TotalLogicalReads = 84,
                TotalElapsedTimeSecond = 0,
                LongestRunningTimeSecond = 0,
                AverageIopsPerCall = 4,
                AverageElapsedTimeMilliSeconds = 0,
                AverageNumberOfExecutionsPerSproc = 10,
                AverageIopsPerSproc = 8
            };
        }

        private DatabaseMacroMetricBasic GetFaeMetric()
        {
            return new DatabaseMacroMetricBasic
            {
                DatabaseName = "FAE",
                TotalIops = 4055416114,
                TotalNumberOfExecutions = 315006,
                TotalWorkerTimeSeconds = 100734,
                TotalPhysicalReads = 2007451,
                TotalLogicalWrites = 266141,
                TotalLogicalReads = 4055149973,
                TotalElapsedTimeSecond = 127021,
                LongestRunningTimeSecond = 2911,
                AverageIopsPerCall = 12874,
                AverageElapsedTimeMilliSeconds = 403,
                AverageNumberOfExecutionsPerSproc = 18529,
                AverageIopsPerSproc = 218868
            };
        }

        private DatabaseMacroMetricBasic GetPareMetric()
        {
            return new DatabaseMacroMetricBasic
            {
                DatabaseName = "PARE",
                TotalIops = 9714808506,
                TotalNumberOfExecutions = 676350,
                TotalWorkerTimeSeconds = 33415,
                TotalPhysicalReads = 2529143,
                TotalLogicalWrites = 1297417,
                TotalLogicalReads = 9713511089,
                TotalElapsedTimeSecond = 15009,
                LongestRunningTimeSecond = 125,
                AverageIopsPerCall = 14363,
                AverageElapsedTimeMilliSeconds = 22,
                AverageNumberOfExecutionsPerSproc = 7351,
                AverageIopsPerSproc = 1321562
            };
        }
    }
}
