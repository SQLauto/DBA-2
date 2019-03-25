using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Dto
{
    public class DatabaseMacroMetricSetBasic
    {
        public DatabaseMacroMetricSetBasic()
        {
            Metrics = new List<DatabaseMacroMetricBasic>();    
        }

        public DateTimeOffset Start { get; set; }
        public DateTimeOffset End { get; set; }
        public string EnvironmentName { get; set; }
        public List<DatabaseMacroMetricBasic> Metrics { get; set; } 
    }
}
