using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace Dto
{
    public class EnvironmentCriteria
    {
        public EnvironmentCriteria()
        {
            DatabasesOfInterest = new List<string>();
        }

        public string EnvironmentName { get; set; }
        public DateTime Start { get; set; }
        public DateTime End { get; set; }
        public List<string> DatabasesOfInterest { get; set; }
    }
}
