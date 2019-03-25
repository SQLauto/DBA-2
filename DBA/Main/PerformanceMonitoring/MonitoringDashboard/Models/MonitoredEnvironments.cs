using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using Dto;

namespace MonitoringDashboard.Models
{
    public class MonitoredEnvironments
    {
        public List<MonitoredEnvironment> EnvironmentsOfInterest { get; set; }
    }
}