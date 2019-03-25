using System.Collections.Generic;
using Dto;
using PerformanceMonitoring.BaselineDal;

namespace MonitoringService
{
    public class ReportService
    {
        public List<DatabaseScalarValue> AverageElapsedTimeGet(ReportParametersDto paramDto)
        {
            var dal = new ReportDal();
            var scalars = dal.AverageElapsedTimeGet(paramDto);

            return scalars;
        }

        public List<DatabaseScalarValue> AverageIopsPerCallGet(ReportParametersDto paramDto)
        {
            var dal = new ReportDal();
            var scalars = dal.AverageIopsPerCallGet(paramDto);

            return scalars;
        }

        public List<DatabaseScalarValue> LongestRunningQueriesGet(ReportParametersDto paramDto)
        {
            var dal = new ReportDal();
            var scalars = dal.LongestRunningQueriesGet(paramDto);

            return scalars;
        }

        public List<DatabaseScalarValue> TotalElapsedTimeGet(ReportParametersDto paramDto)
        {
            var dal = new ReportDal();
            var scalars = dal.TotalElapsedTimeGet(paramDto);

            return scalars;
        }

        public List<DatabaseScalarValue> TotalIopsGet(ReportParametersDto paramDto)
        {
            var dal = new ReportDal();
            var scalars = dal.TotalIopsGet(paramDto);

            return scalars;
        }

        public List<DatabaseScalarValue> TotalLogicalReadsGet(ReportParametersDto paramDto)
        {
            var dal = new ReportDal();
            var scalars = dal.TotalLogicalReadsGet(paramDto);

            return scalars;
        }

        public List<DatabaseScalarValue> TotalNumberOfExecutionsGet(ReportParametersDto paramDto)
        {
            var dal = new ReportDal();
            var scalars = dal.TotalNumberOfExecutionsGet(paramDto);

            return scalars;
        }

        public List<DatabaseScalarValue> TotalPhysicalReadsGet(ReportParametersDto paramDto)
        {
            var dal = new ReportDal();
            var scalars = dal.TotalPhysicalReadsGet(paramDto);

            return scalars;
        }

        public List<DatabaseScalarValue> TotalPhysicalWritesGet(ReportParametersDto paramDto)
        {
            var dal = new ReportDal();
            var scalars = dal.TotalPhysicalWritesGet(paramDto);

            return scalars;
        }

        public List<DatabaseScalarValue> TotalWorkerTimeGet(ReportParametersDto paramDto)
        {
            var dal = new ReportDal();
            var scalars = dal.TotalWorkerTimeGet(paramDto);

            return scalars;
        }
    }
}