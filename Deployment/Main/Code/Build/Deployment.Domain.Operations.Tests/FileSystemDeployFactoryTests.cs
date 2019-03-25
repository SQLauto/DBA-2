using System;
using System.Linq;
using Deployment.Common;
using Deployment.Common.Xml;
using Deployment.Domain.Operations.DomainModelFactory;
using Deployment.Domain.Roles;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using MSTestExtensions;

namespace Deployment.Domain.Operations.Tests
{
    [TestClass]
    public class FileSystemDeployFactoryTests : DomainOperationsTestBase
    {
        [TestInitialize]
        public void Setup()
        {
            RoleName = "TFL.FileSystem";
            Body = "<CreateFolder></CreateFolder><CopyItem></CopyItem><RemoveFolder></RemoveFolder>";
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("FileSystem")]
        public void TestValidatesResponsibility()
        {
            var element = GenerateServerRoleXml();

            var factory = new FileSystemDeployFactory("default");

            Assert.IsTrue(factory.IsResponsibleFor(element));
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("FileSystem")]
        public void TestValidatesNonResponsibility()
        {
            RoleName = "Invalid";
            var element = GenerateServerRoleXml();

            var factory = new FileSystemDeployFactory("default");

            Assert.IsFalse(factory.IsResponsibleFor(element));
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("FileSystem")]
        public void TestReadsCreateFolderRole()
        {
            var factory = new FileSystemDeployFactory("default");

            var element = XmlHelper.CreateXElement(@"<ServerRole Name='TFL.FileSystem' Include='Baseline.File.System' Description='Baseline file system' Groups='Always'><CreateFolder TargetPath='\D$\tfl\BaselineTemp' /></ServerRole>");

            var validationResult = new ValidationResult();
            var fileSystemRole = factory.DomainModelCreate(element, ref validationResult);

            Assert.IsTrue(validationResult.Result);
            Assert.IsNotNull(fileSystemRole);
            var role = fileSystemRole as FileSystemDeploy;
            Assert.IsNotNull(role);
            Assert.IsTrue(role.FileSystemRoles.Any());
            var folder = role.FileSystemRoles[0] as FolderDeploy;
            Assert.IsNotNull(folder);
            Assert.AreEqual(DeploymentAction.Install, folder.Action);
            Assert.IsFalse(string.IsNullOrWhiteSpace(folder.TargetPath));
            Assert.IsFalse(string.IsNullOrWhiteSpace(fileSystemRole.Name));
            Assert.IsFalse(string.IsNullOrWhiteSpace(fileSystemRole.Include));
            Assert.IsFalse(string.IsNullOrWhiteSpace(fileSystemRole.Description));
            Assert.IsTrue(fileSystemRole.Configuration.Equals("default", StringComparison.InvariantCultureIgnoreCase));
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("FileSystem")]
        public void TestReadsRemoveFolderRole()
        {
            var factory = new FileSystemDeployFactory("default");

            var element = XmlHelper.CreateXElement(@"<ServerRole Name='TFL.FileSystem' Include='Baseline.File.System' Description='Baseline file system' Groups='Always'><RemoveFolder TargetPath='\D$\tfl\BaselineTemp' /></ServerRole>");

            var validationResult = new ValidationResult();
            var fileSystemRole = factory.DomainModelCreate(element, ref validationResult);

            Assert.IsTrue(validationResult.Result);
            Assert.IsNotNull(fileSystemRole);
            var role = fileSystemRole as FileSystemDeploy;
            Assert.IsNotNull(role);
            Assert.IsTrue(role.FileSystemRoles.Any());
            var folder = role.FileSystemRoles[0] as FolderDeploy;
            Assert.IsNotNull(folder);
            Assert.AreEqual(DeploymentAction.Uninstall, folder.Action);
            Assert.IsFalse(string.IsNullOrWhiteSpace(folder.TargetPath));
            Assert.IsFalse(string.IsNullOrWhiteSpace(fileSystemRole.Name));
            Assert.IsFalse(string.IsNullOrWhiteSpace(fileSystemRole.Include));
            Assert.IsFalse(string.IsNullOrWhiteSpace(fileSystemRole.Description));
            Assert.IsTrue(fileSystemRole.Configuration.Equals("default", StringComparison.InvariantCultureIgnoreCase));
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("FileSystem")]
        public void TestReadsCopyItemRole()
        {
            var factory = new FileSystemDeployFactory("default");

            var element = XmlHelper.CreateXElement(@"<ServerRole Name='TFL.FileSystem' Include='Baseline.File.System' Description='Baseline file system' Groups='Always'><CopyItem Source='Resources\' Target='\D$\tfl\BaselineTemp' Recurse='true' Filter='*.xml' Replace='true' /></ServerRole>");

            var validationResult = new ValidationResult();
            var fileSystemRole = factory.DomainModelCreate(element, ref validationResult);

            Assert.IsTrue(validationResult.Result);
            Assert.IsNotNull(fileSystemRole);
            var role = fileSystemRole as FileSystemDeploy;
            Assert.IsNotNull(role);
            Assert.IsTrue(role.FileSystemRoles.Any());
            var copyItem = role.FileSystemRoles[0] as CopyItem;
            Assert.IsNotNull(copyItem);
            Assert.IsFalse(string.IsNullOrWhiteSpace(copyItem.Target));
            Assert.IsFalse(string.IsNullOrWhiteSpace(copyItem.Source));
            Assert.IsFalse(string.IsNullOrWhiteSpace(copyItem.Filter));
            Assert.IsTrue(copyItem.Recurse);
            Assert.IsTrue(copyItem.Replace);
            Assert.IsFalse(string.IsNullOrWhiteSpace(fileSystemRole.Include));
            Assert.IsFalse(string.IsNullOrWhiteSpace(fileSystemRole.Description));
            Assert.IsTrue(fileSystemRole.Configuration.Equals("default", StringComparison.InvariantCultureIgnoreCase));
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("FileSystem")]
        public void TestReadsMultipleFileSystemRoles()
        {
            var factory = new FileSystemDeployFactory("default");

            var element = XmlHelper.CreateXElement(@"<ServerRole Name='TFL.FileSystem' Include='Baseline.File.System' Description='Baseline file system' Groups='Always'><CreateFolder TargetPath='\D$\tfl\BaselineTemp' /><CopyItem Source='Resources\' Target='\D$\tfl\BaselineTemp' Recurse='true' Filter='*.xml' Replace='true' /><CopyItem Source='Resources\' Target='\D$\tfl\BaselineTemp' Recurse='true' Filter='*.xml' Replace='true' /></ServerRole>");

            var validationResult = new ValidationResult();
            var roles = factory.DomainModelCreate(element, ref validationResult);
            Assert.IsTrue(validationResult.Result);
            var fileSystemDeploy = roles as FileSystemDeploy;
            Assert.IsNotNull(fileSystemDeploy);
            Assert.AreEqual(3, fileSystemDeploy.FileSystemRoles.Count);

            var role0 = fileSystemDeploy.FileSystemRoles[0] as FolderDeploy;
            Assert.IsNotNull(role0);
            var role1 = fileSystemDeploy.FileSystemRoles[1] as CopyItem;
            Assert.IsNotNull(role1);
            var role2 = fileSystemDeploy.FileSystemRoles[2] as CopyItem;
            Assert.IsNotNull(role2);

        }
    }
}