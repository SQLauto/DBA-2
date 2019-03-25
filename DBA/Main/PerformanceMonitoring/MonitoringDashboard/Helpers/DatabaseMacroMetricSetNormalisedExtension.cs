using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using Dto;
using MonitoringDashboard.Models;

namespace MonitoringDashboard.Helpers
{
    public static class DatabaseMacroMetricSetNormalisedExtension
    {
        public static RadarChartSet ToRadarChartSet(this DatabaseMacroMetricSetNormalised databaseMacroMetricSet)
        {
            var chartSet = new RadarChartSet();

            foreach (var db in databaseMacroMetricSet.Metrics)
            {
                var dset = new RadarDataset();
                dset.DisplayName = db.DatabaseName;
                dset.RadarPoints.Add(NormalisedMetricConvertor("Total IOPs", db.TotalIops));
                dset.RadarPoints.Add(NormalisedMetricConvertor("Total Num. Execs", db.TotalNumberOfExecutions));
                dset.RadarPoints.Add(NormalisedMetricConvertor("Total Worker Time Seconds", db.TotalWorkerTimeSeconds));
                dset.RadarPoints.Add(NormalisedMetricConvertor("Total Physical Reads", db.TotalPhysicalReads));
                dset.RadarPoints.Add(NormalisedMetricConvertor("Total Logical Writes", db.TotalLogicalWrites));
                dset.RadarPoints.Add(NormalisedMetricConvertor("Total Logical Reads", db.TotalLogicalReads));
                dset.RadarPoints.Add(NormalisedMetricConvertor("Total Elapsed Time (s)", db.TotalElapsedTimeSecond));
                dset.RadarPoints.Add(NormalisedMetricConvertor("Longest Running Time (s)", db.LongestRunningTimeSecond));
                dset.RadarPoints.Add(NormalisedMetricConvertor("Avg. IOPs per call", db.AverageIopsPerCall));
                dset.RadarPoints.Add(NormalisedMetricConvertor("Avg. Elapsed Time (ms)", db.AverageElapsedTimeMilliSeconds));
                dset.RadarPoints.Add(NormalisedMetricConvertor("Avg. Num. Execs per Sproc", db.AverageNumberOfExecutionsPerSproc));
                dset.RadarPoints.Add(NormalisedMetricConvertor("Avg IOPS per sproc", db.AverageIopsPerSproc));

                chartSet.RadarDatasets.Add(dset);
            }

            return chartSet;
        }

        private static RadarPoint NormalisedMetricConvertor(string name, NormalisedMetric metric)
        {
            var point = new RadarPoint
            {
                Name = name,
                Point = metric.NormalisedValue,
                Value = metric.MetricValue
            };

            point.Percentile = (int) Math.Floor(point.Point/10);
            return point;
        }
    }
}