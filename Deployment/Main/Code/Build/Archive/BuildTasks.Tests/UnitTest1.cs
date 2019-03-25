using System;
using System.Text;
using System.Collections.Generic;
using System.Linq;
using System.Activities;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using System.Workflow.Runtime;
using System.Workflow.Runtime.Hosting;



namespace BuildTasks.Tests
{
   

    [TestClass]
    public class UnitTest1
    {
        private LabManager.Details testLabManDetails;
        ManualWorkflowSchedulerService schedSvc = null;
        WorkflowRuntime runtime = null;

        private TestContext testContextInstance;

        /// <summary>
        ///Gets or sets the test context which provides
        ///information about and functionality for the current test run.
        ///</summary>
        public TestContext TestContext
        {
            get
            {
                return testContextInstance;
            }
            set
            {
                testContextInstance = value;
            }
        }

        // Use TestInitialize to run code before running each test 
        [TestInitialize()]
        public void TestInitialize()
        {
            schedSvc = new ManualWorkflowSchedulerService();
            runtime = new WorkflowRuntime();
            runtime.AddService(schedSvc);

            testLabManDetails = new LabManager.Details();
            testLabManDetails.Organisation = "Fares And Ticketing";
            testLabManDetails.Password = "Password";
            testLabManDetails.Server = "10.107.200.4";
            testLabManDetails.TargetWorkspace = "NightlyBuild";
            testLabManDetails.Workspace = "TFSWorkspace";
            testLabManDetails.UserName = "TFSBuild";
        }
 
        // Use TestCleanup to run code after each test has run
        [TestCleanup()]
        public void TestCleanup() 
        {
            if (runtime != null && runtime.IsStarted)
                runtime.StopRuntime();
            
            if (runtime != null)
                runtime.Dispose();

        }


        [TestMethod]
        public void TestGetRigFromConfiguration()
        {

            Dictionary<string, object> results = null;
            Exception ex = null;
            
            runtime.WorkflowCompleted += delegate(
              object sender, WorkflowCompletedEventArgs wce)
            {
                results = wce.OutputParameters;
            };

            Dictionary<string, object> wfParams = new Dictionary<string, object>();
            wfParams.Add("ConfigurationName", "Running FAE Single Server Infra Rig");
            wfParams.Add("ServerDetails", testLabManDetails);

            WorkflowInstance instance = runtime.CreateWorkflow(
              typeof(LabManager.GetRigFromConfiguration), wfParams);
            instance.Start();

            ManualWorkflowSchedulerService man =
              runtime.GetService<ManualWorkflowSchedulerService>();
            man.RunWorkflow(instance.InstanceId);

            //the workflow is done, now we can test the outputs
            Assert.IsNotNull(results, "No results found");
                       
        }
    }
}
