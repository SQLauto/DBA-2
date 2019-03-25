using System;
using System.Collections.Generic;

namespace Dto
{
    public class DatabaseMacroMetricSetNormalised
    {
        public DatabaseMacroMetricSetNormalised()
        {
            Metrics = new List<DatabaseMacroMetricNormalised>();    
        }

        public DateTimeOffset Start1 { get; set; }
        public DateTimeOffset End1 { get; set; }
        public string EnvironmentName1 { get; set; }
        public int CountMetricsSet1 { get; set; }

        public DateTimeOffset Start2 { get; set; }
        public DateTimeOffset End2 { get; set; }
        public string EnvironmentName2 { get; set; }
        public int CountMetricsSet2 { get; set; }
        public bool Set2Exists { get; set; }

        public List<DatabaseMacroMetricNormalised> Metrics { get; set; }  
    }
}