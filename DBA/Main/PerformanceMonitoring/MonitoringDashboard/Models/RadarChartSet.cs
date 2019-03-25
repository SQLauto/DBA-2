using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace MonitoringDashboard.Models
{
    public class RadarChartSet
    {
        public RadarChartSet()
        {
            RadarDatasets = new List<RadarDataset>();    
        }

        public List<RadarDataset> RadarDatasets { get; set; } 
    }

    public class RadarDataset
    {
        public RadarDataset()
        {
            RadarPoints = new List<RadarPoint>();    
        }

        public string DisplayName { get; set; }
        public List<RadarPoint> RadarPoints { get; set; } 
    }

    public class RadarPoint
    {
        public string Name { get; set; }
        public double Point { get; set; }
        public long Value { get; set; }
        public int Percentile { get; set; }
    }
}