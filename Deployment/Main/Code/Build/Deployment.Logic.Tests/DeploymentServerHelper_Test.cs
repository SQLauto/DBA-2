using System;
using System.Text;
using System.Collections.Generic;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Deployment.Entities;
using Deployment.Entities.Roles;
using Deployment.Logic.Entities;

namespace Deployment.Logic.Tests
{
    [TestClass]
    public class DeploymentServerHelper_Test
    {      
        #region Additional test attributes
        //
        // You can use the following additional attributes as you write your tests:
        //
        // Use ClassInitialize to run code before running the first test in the class
        // [ClassInitialize()]
        // public static void MyClassInitialize(TestContext testContext) { }
        //
        // Use ClassCleanup to run code after all tests in a class have run
        // [ClassCleanup()]
        // public static void MyClassCleanup() { }
        //
        // Use TestInitialize to run code before running each test 
        // [TestInitialize()]
        // public void MyTestInitialize() { }
        //
        // Use TestCleanup to run code after each test has run
        // [TestCleanup()]
        // public void MyTestCleanup() { }
        //
        #endregion

        [TestMethod]
        [TestCategory("Unit")]
        public void GetServersFromString_Test()
        {
            string toCheck = string.Empty;
            List<string> Servers = DeploymentServerHelper.GetServersFromString(toCheck);
            Assert.IsTrue(Servers.Count == 0);


        }

        [TestMethod]
        [TestCategory("Unit")]
        public void AreServersBeingDeployedTo()
        {
            //Checks when looking for machine name
            Machine machine = new Machine();
            machine.Name = "TS-DB1";

            List<string> servers = new List<string>();
            bool willDeploy = DeploymentServerHelper.IsMachineBeingDeployedTo(machine, servers);
            Assert.IsTrue(willDeploy);

            
            servers = null;
            willDeploy = DeploymentServerHelper.IsMachineBeingDeployedTo(machine, servers);
            Assert.IsTrue(willDeploy);

            servers = new List<string>() {"TS-DB1", "TS-DB2"};
            willDeploy = DeploymentServerHelper.IsMachineBeingDeployedTo(machine, servers);
            Assert.IsTrue(willDeploy);

            machine.Name = "ts-db1";
            willDeploy = DeploymentServerHelper.IsMachineBeingDeployedTo(machine, servers);
            Assert.IsTrue(willDeploy);

            machine.Name = "TS-CAS1";
            willDeploy = DeploymentServerHelper.IsMachineBeingDeployedTo(machine, servers);
            Assert.IsFalse(willDeploy);

            servers = new List<string>() {"!TS-DB1"};
            machine.Name = "TS-DB1";
            willDeploy = DeploymentServerHelper.IsMachineBeingDeployedTo(machine, servers);
            Assert.IsFalse(willDeploy);

            //Checks for when looking for machine External IP
            machine.Name = "";
            machine.ExternalIP = "10.107.201.135";

            servers = new List<string>();
            willDeploy = DeploymentServerHelper.IsMachineBeingDeployedTo(machine, servers);
            Assert.IsTrue(willDeploy);

            servers = null;
            willDeploy = DeploymentServerHelper.IsMachineBeingDeployedTo(machine, servers);
            Assert.IsTrue(willDeploy);

            servers = new List<string>() {"10.107.201.135", "10.107.244.111"};
            willDeploy = DeploymentServerHelper.IsMachineBeingDeployedTo(machine, servers);
            Assert.IsTrue(willDeploy);

            machine.ExternalIP = "10.107.222.231";
            willDeploy = DeploymentServerHelper.IsMachineBeingDeployedTo(machine, servers);
            Assert.IsFalse(willDeploy);

            servers = new List<string>() {"!10.107.201.135"};
            machine.ExternalIP = "10.107.201.135";
            willDeploy = DeploymentServerHelper.IsMachineBeingDeployedTo(machine, servers);
            Assert.IsFalse(willDeploy);
        }
    }
}
