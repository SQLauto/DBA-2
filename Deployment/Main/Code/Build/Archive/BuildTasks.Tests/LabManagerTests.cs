using System;
using System.Text;
using System.Collections.Generic;
using System.Linq;
using Microsoft.VisualStudio.TestTools.UnitTesting;
//using System.Workflow.Runtime;
//using System.Workflow.Runtime.Hosting;
using System.Activities;
using CustomBuildActivities;
using CustomBuildActivities.CustomType;


namespace BuildTasks.Tests
{
    [TestClass]
    public class LabManagerTests
    {
        private LabManager.Details testLabManDetails;
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

        /// <summary>
        /// Initialise Test
        /// </summary>
        [TestInitialize()]
        public void TestInitialize()
        {
            testLabManDetails = new LabManager.Details();
            testLabManDetails.Organisation = "Fares And Ticketing";
            testLabManDetails.Password = "password";
            testLabManDetails.Server = "10.107.200.4";
            testLabManDetails.TargetWorkspace = "NightlyBuild";
            testLabManDetails.Workspace = "TFSWorkspace";
            testLabManDetails.UserName = "TFSBuild";
        }

        //[TestMethod]
        //public void TestPartitionedBuildGUI()
        //{
        //    PartitionedBuildSettings settings = new PartitionedBuildSettings();
        //    settings.UsePartitionedBuild = true;
        //    using (PartitionedBuildDialog dlg = new PartitionedBuildDialog(settings))
        //    {
        //        dlg.ShowDialog();
        //    }
        //}

        [TestMethod]
        [TestCategory("Config")]
        public void GetRigFromConfigurationTest()
        {
            Dictionary<string, object> input = new Dictionary<string, object>();
            input.Add("ConfigurationName", "Running FAE Single Server Infra Rig");
            input.Add("ServerDetails", testLabManDetails);
            
            WorkflowInvoker invoker = new WorkflowInvoker(new LabManager.GetRigFromConfiguration());

            IDictionary<string, object> output = invoker.Invoke(input);
            
            Assert.IsNotNull(output);
            Rig returnedRig = (Rig)output["Result"];

            Assert.AreEqual<string>("Running FAE Single Server Infra Rig", returnedRig.Name);

            Assert.AreEqual<int>(2, returnedRig.Boxes.Count);
        }

        [TestMethod]
        [TestCategory("Config")]
        public void SerialiseRigFromConfigurationTest()
        {
            Dictionary<string, object> input = new Dictionary<string, object>();
            input.Add("ConfigurationName", "Running FAE Single Server Infra Rig");
            input.Add("ServerDetails", testLabManDetails);

            WorkflowInvoker invoker = new WorkflowInvoker(new LabManager.GetRigFromConfiguration());

            IDictionary<string, object> output = invoker.Invoke(input);

            Assert.IsNotNull(output);
            Rig returnedRig = (Rig)output["Result"];

            Assert.AreEqual<string>("Running FAE Single Server Infra Rig", returnedRig.Name);
            Assert.AreEqual<int>(2, returnedRig.Boxes.Count);

            //Invoke the Serialisation
            invoker = new WorkflowInvoker(new LabManager.SerialiseRig());
            input = new Dictionary<string, object>();

            string serialisedRigFile = System.IO.Path.GetTempFileName();

            input.Add("OutputFilename", serialisedRigFile);
            input.Add("RigToSerialise", returnedRig);

            output = invoker.Invoke(input);

            Assert.IsTrue(System.IO.File.Exists(serialisedRigFile));

            //MCSFG IntraSprint5  20110523
        }

        [TestMethod]
        [TestCategory("Config")]
        public void CloneConfigurationTest()
        {
            string CloneConfigName = "Test Clone " + System.DateTime.Now.ToString();
            Dictionary<string, object> input = new Dictionary<string, object>();
            input.Add("CloneConfigurationName", CloneConfigName);
            input.Add("ServerDetails", testLabManDetails);
            input.Add("SourceConfigurationName", "FAE Single Server Infra Rig");
            input.Add("TargetWorkspace", "TFSWorkspace");

            WorkflowInvoker invoker = new WorkflowInvoker(new LabManager.CloneConfiguration());

            IDictionary<string, object> output = invoker.Invoke(input);

            Assert.IsTrue((int)output["Result"]>0);
        }

        [TestMethod]
        [TestCategory("Config")]
        public void MoveConfigurationTest()
        {
            //First let's clone a configuration (needs to exist before we move it)
            string CloneConfigName = "Test Clone " + System.DateTime.Now.ToString();
            Dictionary<string, object> input = new Dictionary<string, object>();
            input.Add("CloneConfigurationName", CloneConfigName);
            input.Add("ServerDetails", testLabManDetails);
            input.Add("SourceConfigurationName", "FAE Single Server Infra Rig");
            input.Add("TargetWorkspace", "TFSWorkspace");
            

            WorkflowInvoker invoker = new WorkflowInvoker(new LabManager.CloneConfiguration());

            IDictionary<string, object> output = invoker.Invoke(input);
            int resultid = (int)output["Result"];

            Assert.IsTrue(resultid >0);
            
            //Now test the move
            string MovedConfigName = "Test Move " + System.DateTime.Now.ToString();
            input = new Dictionary<string, object>();
            input.Add("SourceConfigurationName", CloneConfigName);
            input.Add("ServerDetails", testLabManDetails);
            input.Add("TargetWorkspace", "NightlyBuild");
            input.Add("TargetConfigurationName", MovedConfigName);


            invoker = new WorkflowInvoker(new LabManager.MoveConfiguration());
            output = invoker.Invoke(input);
        }

        [TestMethod]
        [TestCategory("Config")]
        public void ShutDownConfigurationTest()
        {
            //First let's clone a configuration (needs to exist before we move it)
            string CloneConfigName = "Test Clone " + System.DateTime.Now.ToString();
            Dictionary<string, object> input = new Dictionary<string, object>();
            input.Add("CloneConfigurationName", CloneConfigName);
            input.Add("ServerDetails", testLabManDetails);
            input.Add("SourceConfigurationName", "FAE Single Server Infra Rig");
            input.Add("TargetWorkspace", "TFSWorkspace");


            WorkflowInvoker invoker = new WorkflowInvoker(new LabManager.CloneConfiguration());

            IDictionary<string, object> output = invoker.Invoke(input);
            int resultid = (int)output["Result"];

            Assert.IsTrue(resultid > 0);

            //Test Deploy
            input = new Dictionary<string, object>();
            input.Add("ConfigurationName", CloneConfigName);
            input.Add("ServerDetails", testLabManDetails);
            invoker = new WorkflowInvoker(new LabManager.DeployConfiguration());
            output = invoker.Invoke(input);

            Assert.IsTrue((bool)output["Result"]);         


            //Now test the ShutDown
            input = new Dictionary<string, object>();
            input.Add("ConfigurationName", CloneConfigName);
            input.Add("ServerDetails", testLabManDetails);
            invoker = new WorkflowInvoker(new LabManager.ShutDownConfiguration());
            output = invoker.Invoke(input);

            //Test UnDeploy
            input = new Dictionary<string, object>();
            input.Add("ConfigurationName", CloneConfigName);
            input.Add("ServerDetails", testLabManDetails);
            invoker = new WorkflowInvoker(new LabManager.UnDeployConfiguration());
            output = invoker.Invoke(input);

            Assert.IsTrue((bool)output["Result"]);

        }

    }
}
