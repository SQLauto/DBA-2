using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Dto
{
    public class DatabaseExecutionMetric
    {
        public string Environment { get; set; }
        public DateTime StartDate { get; set; }
        public DateTime EndDate { get; set; }
        public string DatabaseOfInterest { get; set; }
        public string SqlOfInterest { get; set; }
        public string LatestExecutionPlan { get; set; }
        public long TotalIops { get; set; }
        public long TotalNumberOfExecutions { get; set; }
        public long TotalWorkerTimeSeconds { get; set; }
        public long TotalPhysicalReads { get; set; }
        public long TotalLogicalWrites { get; set; }
        public long TotalLogicalReads { get; set; }
        public long TotalElapsedTimeSeconds { get; set; }
        public long LongestRunningTimeSeconds { get; set; }
        public long AverageIopsPerCall { get; set; }
        public long AverageElapsedTimeMilliSeconds { get; set; }
    }
}
