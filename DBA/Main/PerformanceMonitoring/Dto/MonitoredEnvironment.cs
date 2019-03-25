using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Dto
{
    public class MonitoredEnvironment
    {
        public MonitoredEnvironment()
        {
            Databases = new List<string>();
        }
        public string EnvironmentName { get; set; }
        public List<string> Databases { get; set; } 
    }

}
