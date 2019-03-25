using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Dto
{
    public class DatabaseScalarMetricSet
    {
        public DatabaseScalarMetricSet()
        {
            Scalars = new List<DatabaseScalarValue>();
        }

        public DateTimeOffset Start { get; set; }
        public DateTimeOffset End { get; set; }
        public string EnvironmentName { get; set; }
        public string DatabaseName { get; set; }
        public string MetricName { get; set; }
        public List<DatabaseScalarValue> Scalars;
    }
}
