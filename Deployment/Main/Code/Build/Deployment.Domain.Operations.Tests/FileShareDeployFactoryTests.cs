using System;
using Deployment.Common;
using Deployment.Domain.Operations.DomainModelFactory;
using Deployment.Domain.Roles;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using MSTestExtensions;

namespace Deployment.Domain.Operations.Tests
{
    [TestClass]
    public class FileShareDeployFactoryTests : DomainOperationsTestBase
    {
        [TestInitialize]
        public void Setup()
        {
            RoleName = "TFL.FileShare";
            Body = "<FileShare></FileShare>";
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("FileShare")]
        public void TestValidatesResponsibility()
        {
            var element = GenerateServerRoleXml();

            var factory = new FileShareDeployFactory("default");

            Assert.IsTrue(factory.IsResponsibleFor(element));
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("FileShare")]
        public void TestValidatesNonResponsibility()
        {
            RoleName = "Invalid";
            var element = GenerateServerRoleXml();

            var factory = new FileShareDeployFactory("default");

            Assert.IsFalse(factory.IsResponsibleFor(element));
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("FileShare")]
        public void TestReadsCommonRole()
        {
            Body = string.Format("<FileShare Name='Test'>{0}</FileShare>", StandardXml);
            var element = GenerateServerRoleXml();
            var factory = new FileShareDeployFactory("default");

            var validationResult = new ValidationResult();
            var role = factory.DomainModelCreate(element, ref validationResult);
            var fileShareDeploy = role as FileShareDeploy;

            Assert.ValidationResult(validationResult, TestContext);
            Assert.IsNotNull(fileShareDeploy);
            Assert.IsTrue(fileShareDeploy.Configuration.Equals("default", StringComparison.InvariantCultureIgnoreCase));
            Assert.IsNotNullOrEmpty(fileShareDeploy.Users);
            Assert.AreEqual(1, fileShareDeploy.Users.Count);
            Assert.AreEqual("DeploymentAccount", fileShareDeploy.Users[0].Name);
            Assert.IsTrue(fileShareDeploy.Users[0].Permissions == FileSharePermission.Change);
            Assert.IsTrue(fileShareDeploy.Users[0].AccountType == FileShareUserAccountType.ServiceAccount);
        }

        private const string StandardXml = @"
            <ShareName>ShareName</ShareName>
            <FolderToShare>D:\TfL\BaselineShare</FolderToShare>
            <FolderPermissions>ReadAndExecute</FolderPermissions>
            <Users>
                <User name='DeploymentAccount' type='ServiceAccount' permissions='Change'/>
            </Users>";
    }
}