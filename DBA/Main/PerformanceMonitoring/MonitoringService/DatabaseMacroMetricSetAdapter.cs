using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Dto;

namespace MonitoringService
{
    public class DatabaseMacroMetricSetAdapter
    {
        public DatabaseMacroMetricSetNormalised Convert(DatabaseMacroMetricSetBasic metricsBasic)
        {
            DatabaseMacroMetricSetNormalised normalised = CreateAndMapLiterals(metricsBasic);
            normalised = Convert(metricsBasic, normalised);

            return normalised;
        }

        public DatabaseMacroMetricSetNormalised Convert(DatabaseMacroMetricSetBasic metricsBasic, DatabaseMacroMetricSetNormalised normalised)
        {
            long maxTotalIops = metricsBasic.Metrics.Max(x => x.TotalIops);
            long maxTotalNumberOfExecutions = metricsBasic.Metrics.Max(x => x.TotalNumberOfExecutions);
            long maxTotalWorkerTimeSeconds = metricsBasic.Metrics.Max(x => x.TotalWorkerTimeSeconds);
            long maxTotalPhysicalReads = metricsBasic.Metrics.Max(x => x.TotalPhysicalReads);
            long maxTotalLogicalWrites = metricsBasic.Metrics.Max(x => x.TotalLogicalWrites);
            long maxTotalLogicalReads = metricsBasic.Metrics.Max(x => x.TotalLogicalReads);
            long maxTotalElapsedTimeSecond = metricsBasic.Metrics.Max(x => x.TotalElapsedTimeSecond);
            long maxLongestRunningTimeSecond = metricsBasic.Metrics.Max(x => x.LongestRunningTimeSecond);
            long maxAverageIopsPerCall = metricsBasic.Metrics.Max(x => x.AverageIopsPerCall);
            long maxAverageElapsedTimeMilliSeconds = metricsBasic.Metrics.Max(x => x.AverageElapsedTimeMilliSeconds);
            long maxAverageNumberOfExecutionsPerSproc = metricsBasic.Metrics.Max(x => x.AverageNumberOfExecutionsPerSproc);
            long maxAverageIopsPerSproc = metricsBasic.Metrics.Max(x => x.AverageIopsPerSproc);

            foreach (var metric in metricsBasic.Metrics)
            {
                var normalisedMetric = new DatabaseMacroMetricNormalised { DatabaseName = metric.DatabaseName };
                normalisedMetric.TotalIops = new NormalisedMetric
                {
                    MetricValue = metric.TotalIops,
                    NormalisedValue = metric.TotalIops == maxTotalIops ? 100 : ((double) metric.TotalIops)/maxTotalIops * 100
                };

                normalisedMetric.TotalNumberOfExecutions = new NormalisedMetric
                {
                    MetricValue = metric.TotalNumberOfExecutions,
                    NormalisedValue = metric.TotalNumberOfExecutions== maxTotalNumberOfExecutions ? 100 : ((double) metric.TotalNumberOfExecutions)/maxTotalNumberOfExecutions * 100
                };

                normalisedMetric.TotalWorkerTimeSeconds = new NormalisedMetric
                {
                    MetricValue = metric.TotalWorkerTimeSeconds,
                    NormalisedValue = metric.TotalWorkerTimeSeconds== maxTotalWorkerTimeSeconds ? 100 : ((double) metric.TotalWorkerTimeSeconds)/maxTotalWorkerTimeSeconds * 100
                };

                normalisedMetric.TotalPhysicalReads = new NormalisedMetric
                {
                    MetricValue = metric.TotalPhysicalReads,
                    NormalisedValue = metric.TotalPhysicalReads== maxTotalPhysicalReads ? 100 : ((double) metric.TotalPhysicalReads)/maxTotalPhysicalReads * 100
                };

                normalisedMetric.TotalLogicalWrites = new NormalisedMetric
                {
                    MetricValue = metric.TotalLogicalWrites,
                    NormalisedValue = metric.TotalLogicalWrites== maxTotalLogicalWrites ? 100 : ((double) metric.TotalLogicalWrites)/maxTotalLogicalWrites * 100
                };

                normalisedMetric.TotalLogicalReads = new NormalisedMetric
                {
                    MetricValue = metric.TotalLogicalReads,
                    NormalisedValue = metric.TotalLogicalReads== maxTotalLogicalReads ? 100 : ((double) metric.TotalLogicalReads)/maxTotalLogicalReads * 100
                };

                normalisedMetric.TotalElapsedTimeSecond = new NormalisedMetric
                {
                    MetricValue = metric.TotalElapsedTimeSecond,
                    NormalisedValue = metric.TotalElapsedTimeSecond== maxTotalElapsedTimeSecond ? 100 : ((double) metric.TotalElapsedTimeSecond)/maxTotalElapsedTimeSecond * 100
                };

                normalisedMetric.LongestRunningTimeSecond = new NormalisedMetric
                {
                    MetricValue = metric.LongestRunningTimeSecond,
                    NormalisedValue = metric.LongestRunningTimeSecond== maxLongestRunningTimeSecond ? 100 : ((double) metric.LongestRunningTimeSecond)/maxLongestRunningTimeSecond * 100
                };

                normalisedMetric.AverageIopsPerCall = new NormalisedMetric
                {
                    MetricValue = metric.AverageIopsPerCall,
                    NormalisedValue = metric.AverageIopsPerCall== maxAverageIopsPerCall ? 100 : ((double) metric.AverageIopsPerCall)/maxAverageIopsPerCall * 100
                };

                normalisedMetric.AverageElapsedTimeMilliSeconds = new NormalisedMetric
                {
                    MetricValue = metric.AverageElapsedTimeMilliSeconds,
                    NormalisedValue = metric.AverageElapsedTimeMilliSeconds== maxAverageElapsedTimeMilliSeconds ? 100 : ((double) metric.AverageElapsedTimeMilliSeconds)/maxAverageElapsedTimeMilliSeconds * 100
                };

                normalisedMetric.AverageNumberOfExecutionsPerSproc = new NormalisedMetric
                {
                    MetricValue = metric.AverageNumberOfExecutionsPerSproc,
                    NormalisedValue = metric.AverageNumberOfExecutionsPerSproc== maxAverageNumberOfExecutionsPerSproc ? 100 : ((double) metric.AverageNumberOfExecutionsPerSproc)/maxAverageNumberOfExecutionsPerSproc * 100
                };

                normalisedMetric.AverageIopsPerSproc = new NormalisedMetric
                {
                    MetricValue = metric.AverageIopsPerSproc,
                    NormalisedValue = metric.AverageIopsPerSproc== maxAverageIopsPerSproc ? 100 : ((double) metric.AverageIopsPerSproc)/maxAverageIopsPerSproc * 100
                };

                normalised.Metrics.Add(normalisedMetric);
            }

            return normalised;
        }


        private DatabaseMacroMetricSetNormalised CreateAndMapLiterals(DatabaseMacroMetricSetBasic metricsBasic)
        {
            var normalised = new DatabaseMacroMetricSetNormalised
            {
                End1 = metricsBasic.End,
                Start1 = metricsBasic.Start,
                EnvironmentName1 = metricsBasic.EnvironmentName
            };

            return normalised;
        }

        public DatabaseMacroMetricSetNormalised Convert(DatabaseMacroMetricSetBasic set1, DatabaseMacroMetricSetBasic set2)
        {
            var normalised = new DatabaseMacroMetricSetNormalised
            {
                End1 = set1.End,
                Start1 = set1.Start,
                EnvironmentName1 = set1.EnvironmentName
            };

            var mergedMetrics = new DatabaseMacroMetricSetBasic();
            mergedMetrics.Metrics.AddRange(set1.Metrics);
            normalised.CountMetricsSet1 = set1.Metrics.Count;

            if (set2 != null)
            {
                normalised.End2 = set2.End;
                normalised.Start2 = set2.Start;
                normalised.EnvironmentName2 = set2.EnvironmentName;
                normalised.Set2Exists = true;
                normalised.CountMetricsSet2 = set2.Metrics.Count;

                foreach (var metric in set2.Metrics)
                {
                    metric.DatabaseName = metric.DatabaseName + "~";
                    metric.AverageElapsedTimeMilliSeconds = metric.AverageElapsedTimeMilliSeconds/2;
                    metric.AverageIopsPerCall = metric.AverageIopsPerCall/2;
                    metric.AverageIopsPerSproc = metric.AverageIopsPerSproc/2;
                    metric.AverageNumberOfExecutionsPerSproc = metric.AverageNumberOfExecutionsPerSproc/2;
                    metric.LongestRunningTimeSecond = metric.LongestRunningTimeSecond/2;
                    metric.TotalElapsedTimeSecond = metric.TotalElapsedTimeSecond/2;
                    metric.TotalIops = metric.TotalIops/2;
                    metric.TotalLogicalReads = metric.TotalLogicalReads/2;
                    metric.TotalLogicalWrites = metric.TotalLogicalWrites/2;
                    metric.TotalNumberOfExecutions = metric.TotalNumberOfExecutions/2;
                    metric.TotalPhysicalReads = metric.TotalPhysicalReads/2;
                    metric.TotalWorkerTimeSeconds = metric.TotalWorkerTimeSeconds/2;

                    mergedMetrics.Metrics.Add(metric);
                }
            }
            var normalisedMetrics = Convert(mergedMetrics, normalised);
            return normalisedMetrics;
        }
    }
}
