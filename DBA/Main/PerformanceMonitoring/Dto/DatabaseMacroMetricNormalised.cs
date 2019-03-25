using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Dto
{
    public class DatabaseMacroMetricNormalised
    {
        public string DatabaseName { get; set; }
        public NormalisedMetric TotalIops { get; set; }
        public NormalisedMetric TotalNumberOfExecutions { get; set; }
        public NormalisedMetric TotalWorkerTimeSeconds { get; set; }
        public NormalisedMetric TotalPhysicalReads { get; set; }
        public NormalisedMetric TotalLogicalWrites { get; set; }
        public NormalisedMetric TotalLogicalReads { get; set; }
        public NormalisedMetric TotalElapsedTimeSecond { get; set; }
        public NormalisedMetric LongestRunningTimeSecond { get; set; }
        public NormalisedMetric AverageIopsPerCall { get; set; }
        public NormalisedMetric AverageElapsedTimeMilliSeconds { get; set; }
        public NormalisedMetric AverageNumberOfExecutionsPerSproc { get; set; }
        public NormalisedMetric AverageIopsPerSproc { get; set; }
    }
}
