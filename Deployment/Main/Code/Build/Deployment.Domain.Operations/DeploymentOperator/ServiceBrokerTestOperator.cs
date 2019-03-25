using System;
using System.Data.SqlClient;
using System.Threading;
using Deployment.Common.Helpers;
using Deployment.Common.Logging;
using Deployment.Domain.Roles;

namespace Deployment.Domain.Operations.DeploymentOperator
{
    public class ServiceBrokerTestOperator
    {
        public bool RunTest(ServiceBrokerTest serviceBrokerTest, Machine machine, PostDeployParameters parameters, IDeploymentLogger logger)
        {            // We run the first script on the first server, then the second on the second server.
                     // If no exception is raised the test has passed
            var result = true;

            using (var timer = new PerformanceLogger(logger))
            {
                foreach (var test in serviceBrokerTest.Tests)
                {
                    try
                    {
                        using (var conn = new SqlConnection(DataHelper.GetConnectionString(test.DatabaseServer,
                            test.DatabaseInstance, test.TargetDatabase, test.UserName, test.Password)))
                        {
                            conn.Open();
                            string sql = test.SqlScript.Replace("$TargetDatabase", test.TargetDatabase);
                            using (var command = new SqlCommand(sql, conn))
                            {
                                command.ExecuteNonQuery();
                            }
                        }

                        Thread.Sleep(3000);
                    }
                    catch (Exception ex)
                    {
                        timer.WriteSummary(
                            $"Custom SerivceBroker Test '{serviceBrokerTest.Name}'.", LogResult.Error);
                        logger?.WriteError(ex);
                        result = false;
                        break;
                    }
                }

                timer.WriteSummary(
                    $"Custom SerivceBroker Test '{serviceBrokerTest.Name}'", result ? LogResult.Success : LogResult.Fail);
            }

            return result;
        }
    }
}