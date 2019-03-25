using System.Management.Automation.Runspaces;
using Deployment.Common;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace TFL.PowerShell.Logging.Tests
{
    [TestClass]
    public class HostIoInterceptorTests
    {
        [TestMethod]
        public void TestPausesAndResumesLoggingForSingleLog()
        {
            using (var runspace = RunspaceFactory.CreateRunspace())
            {
                runspace.Open();

                var runSpaceId = runspace.InstanceId;

                var inteceptor = HostIoInterceptor.Instance;
                inteceptor.AttachProxyRunspace(runspace);

                var log1 = new LogFile(@"C:\Temp\Log1.log", runspaceId: runSpaceId);
                var log2 = new LogFile(@"C:\Temp\Log2.log", runspaceId: runSpaceId);

                inteceptor.AddSubscriber(runSpaceId, log1);
                inteceptor.AddSubscriber(runSpaceId, log2);

                Assert.IsFalse(log1.Paused);
                Assert.IsFalse(log2.Paused);

                inteceptor.SuspendLogging(new[] { log1 });

                Assert.IsTrue(log1.Paused);
                Assert.IsFalse(log2.Paused);

                inteceptor.ResumeLogging(new[] { log1 });

                Assert.IsFalse(log1.Paused);
                Assert.IsFalse(log2.Paused);

                inteceptor.RemoveSubscribers(new[] { log1,log2 });

                Assert.IsTrue(inteceptor.Subscribers.CountEqualTo(0));
            }
        }

        [TestMethod]
        public void TestPausesAndResumesLoggingForMultipleLogs()
        {
            using (var runspace = RunspaceFactory.CreateRunspace())
            {
                runspace.Open();

                var runSpaceId = runspace.InstanceId;

                var inteceptor = HostIoInterceptor.Instance;
                inteceptor.AttachProxyRunspace(runspace);

                var log1 = new LogFile(@"C:\Temp\Log1.log", runspaceId: runSpaceId);
                var log2 = new LogFile(@"C:\Temp\Log2.log", runspaceId: runSpaceId);

                inteceptor.AddSubscriber(runSpaceId, log1);
                inteceptor.AddSubscriber(runSpaceId, log2);

                Assert.IsFalse(log1.Paused);
                Assert.IsFalse(log2.Paused);

                inteceptor.SuspendLogging(new[] { log1, log2 });

                Assert.IsTrue(log1.Paused);
                Assert.IsTrue(log2.Paused);

                inteceptor.ResumeLogging(new[] { log1, log2 });

                Assert.IsFalse(log1.Paused);
                Assert.IsFalse(log2.Paused);
            }
        }

        [TestMethod]
        public void TestRegistrationAcrossTwoRunspaces()
        {
            using (var primaryRunspace = RunspaceFactory.CreateRunspace())
            {
                primaryRunspace.Open();

                var runSpaceId = primaryRunspace.InstanceId;

                var inteceptor = HostIoInterceptor.Instance;
                inteceptor.AttachProxyRunspace(primaryRunspace);

                var summaryLog = new LogFile(@"C:\Temp\Summary.log", runspaceId: runSpaceId);

                inteceptor.AddSubscriber(runSpaceId, summaryLog);

                using (var secondaryRunspace = RunspaceFactory.CreateRunspace())
                {
                    secondaryRunspace.Open();

                    var machineRunspaceId = secondaryRunspace.InstanceId;

                    var machineLog1 = new LogFile(@"C:\Temp\Machine1.log", runspaceId: machineRunspaceId);
                    var machineLog2 = new LogFile(@"C:\Temp\Machine2.log", runspaceId: machineRunspaceId);

                    inteceptor.AttachProxyRunspace(secondaryRunspace);
                    Assert.IsFalse(inteceptor.IsRunspaceLogRegistered(machineRunspaceId, summaryLog.Path));
                    //register same summary log with secondary runspace too
                    //to mimic this in register, we create a new logfile with same path for new runspace
                    var secondarySummary = new LogFile(summaryLog.Path, runspaceId: machineRunspaceId);
                    inteceptor.AddSubscriber(machineRunspaceId, secondarySummary);
                    inteceptor.AddSubscriber(runSpaceId, machineLog1);

                    Assert.IsFalse(secondarySummary.Paused);
                    Assert.IsFalse(machineLog1.Paused);

                    inteceptor.AttachProxyRunspace(primaryRunspace);
                    Assert.IsFalse(summaryLog.Paused);

                    inteceptor.AttachProxyRunspace(secondaryRunspace);

                    inteceptor.SuspendLogging(new[] { secondarySummary });

                    Assert.IsTrue(secondarySummary.Paused);
                    Assert.IsFalse(machineLog1.Paused);
                    inteceptor.AttachProxyRunspace(primaryRunspace);

                    Assert.IsFalse(summaryLog.Paused);

                    inteceptor.AttachProxyRunspace(secondaryRunspace);

                    inteceptor.RemoveSubscribers(new[] { machineLog1 });
                    inteceptor.AddSubscriber(runSpaceId, machineLog2);

                    Assert.IsTrue(inteceptor.Subscribers.CountEqualTo(2));
                }
            }
        }
    }
}