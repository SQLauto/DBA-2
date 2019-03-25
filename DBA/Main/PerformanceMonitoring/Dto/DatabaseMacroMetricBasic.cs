using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Dto
{
    public class DatabaseMacroMetricBasic
    {
        public string DatabaseName { get; set; }
        public long TotalIops { get; set; }
        public long TotalNumberOfExecutions { get; set; }
        public long TotalWorkerTimeSeconds { get; set; }
        public long TotalPhysicalReads { get; set; }
        public long TotalLogicalWrites { get; set; }
        public long TotalLogicalReads { get; set; }
        public long TotalElapsedTimeSecond { get; set; }
        public long LongestRunningTimeSecond { get; set; }
        public long AverageIopsPerCall { get; set; }
        public long AverageElapsedTimeMilliSeconds { get; set; }
        public long AverageNumberOfExecutionsPerSproc { get; set; }
        public long AverageIopsPerSproc { get; set; }
    }
}
