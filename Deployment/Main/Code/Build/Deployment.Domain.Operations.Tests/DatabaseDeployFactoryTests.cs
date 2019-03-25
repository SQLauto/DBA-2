using System;
using System.Xml.Linq;
using Deployment.Common;
using Deployment.Common.Xml;
using Deployment.Domain.Operations.DomainModelFactory;
using Deployment.Domain.Roles;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using MSTestExtensions;

namespace Deployment.Domain.Operations.Tests
{
    [TestClass]
    public class DatabaseDeployFactoryTests : DomainOperationsTestBase
    {

        [TestInitialize]
        public void Setup()
        {
            RoleName = "FromConfig";
            Body = "<Test></Test>";
            BaseRoleString = @"<DatabaseRole xmlns='{0}' Name='{1}' Include='Include' Description='Description' Groups='{2}' {3}>{4}</DatabaseRole>";
        }


        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("DatabaseDeploy")]
        public void TestValidatesResponsibility()
        {
            var element = GenerateServerRoleXml();

            var factory = new DatabaseDeployFactory("default");

            Assert.IsTrue(factory.IsResponsibleFor(element));
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("DatabaseDeploy")]
        public void TestValidatesNonResponsibility()
        {
            var invalidServerRole = string.Format(
                @"<ServerRole xmlns='{0}' Name='Tfl.FileSystem' Include='Baseline.File.System' Description='Baseline file system' Groups='Always' ><CreateFolder TargetPath='\D$\tfl\BaselineTemp' /></ServerRole > ", Namespaces.CommonRole.XmlNamespace);

            var element = XmlHelper.CreateXElement(invalidServerRole);

            var factory = new DatabaseDeployFactory("default");

            Assert.IsFalse(factory.IsResponsibleFor(element));
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("DatabaseDeploy")]
        public void TestReadsCommonRole()
        {
            var factory = new DatabaseDeployFactory("default");

            Body = CommonXml;
            var element = GenerateServerRoleXml();

            var validationResult = new ValidationResult();
            var baseRole = factory.DomainModelCreate(element, ref validationResult);

            AssertValidationResult(validationResult, () => Assert.IsTrue(validationResult.Result));
            Assert.IsNotNull(baseRole);

            var databaseDeploy = baseRole as DatabaseDeploy;
            Assert.IsNotNull(databaseDeploy);
            Assert.IsTrue(databaseDeploy.Configuration.Equals("default", StringComparison.InvariantCultureIgnoreCase));
            Assert.IsFalse(string.IsNullOrWhiteSpace(databaseDeploy.DatabaseInstance));

            Assert.IsFalse(string.IsNullOrWhiteSpace(databaseDeploy.Name));
            Assert.IsFalse(string.IsNullOrWhiteSpace(databaseDeploy.Include));
            Assert.IsFalse(string.IsNullOrWhiteSpace(databaseDeploy.Description));

            Assert.IsTrue(string.IsNullOrWhiteSpace(databaseDeploy.BaselineDeployment));
            Assert.IsFalse(string.IsNullOrWhiteSpace(databaseDeploy.PatchLevelDeterminationScript));
            Assert.IsTrue(string.IsNullOrWhiteSpace(databaseDeploy.FolderPath));
            Assert.IsTrue(string.IsNullOrWhiteSpace(databaseDeploy.PatchDeployment));
            Assert.IsFalse(string.IsNullOrWhiteSpace(databaseDeploy.PatchFolderFormatStartsWith));
            Assert.IsFalse(string.IsNullOrWhiteSpace(databaseDeploy.PatchDeploymentFolder));
            Assert.IsTrue(string.IsNullOrWhiteSpace(databaseDeploy.PostDeployment));
            Assert.IsFalse(string.IsNullOrWhiteSpace(databaseDeploy.PostValidationScript));
            Assert.IsTrue(string.IsNullOrWhiteSpace(databaseDeploy.PreDeployment));
            Assert.IsFalse(string.IsNullOrWhiteSpace(databaseDeploy.PreValidationScript));
            Assert.IsFalse(string.IsNullOrWhiteSpace(databaseDeploy.UpgradeScript));
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("DatabaseDeploy")]
        public void TestOverridesCommonRole()
        {
            var factory = new DatabaseDeployFactory("default");

            Body = CommonXml;
            var element = GenerateServerRoleXml();

            var validationResult = new ValidationResult();
            var baseRole = factory.DomainModelCreate(element, ref validationResult);

            AssertValidationResult(validationResult, () => Assert.IsTrue(validationResult.Result));
            Assert.IsNotNull(baseRole);

            var databaseDeploy = baseRole as DatabaseDeploy;
            Assert.IsNotNull(databaseDeploy);
            Assert.IsTrue(databaseDeploy.Configuration.Equals("default", StringComparison.InvariantCultureIgnoreCase));
            Assert.IsFalse(string.IsNullOrWhiteSpace(databaseDeploy.DatabaseInstance));

            Assert.IsFalse(string.IsNullOrWhiteSpace(databaseDeploy.Name));
            Assert.IsFalse(string.IsNullOrWhiteSpace(databaseDeploy.Include));
            Assert.IsFalse(string.IsNullOrWhiteSpace(databaseDeploy.Description));

            var baseString =
                @"<DatabaseRole xmlns='{0}' Name='{1}' Include='Include' Description='Description' DatabaseInstance='Override' TargetDatabase='Override'></DatabaseRole>";

            element = XmlHelper.CreateXElement(string.Format(baseString, Namespaces.CommonRole.XmlNamespace, RoleName));

            var role = factory.ApplyOverrides(baseRole, element, ref validationResult) as DatabaseDeploy;
            Assert.IsTrue(role.TargetDatabase.Equals("Override", StringComparison.InvariantCultureIgnoreCase));
            Assert.IsTrue(role.DatabaseInstance.Equals("Override", StringComparison.InvariantCultureIgnoreCase));
        }

        protected override XElement GenerateServerRoleXml()
        {
            return XmlHelper.CreateXElement(string.Format(BaseRoleString, Namespaces.CommonRole.XmlNamespace, RoleName, Groups, Config, Body));
        }

        private const string CommonXml = @"
    <TargetDatabase>must_be_overridden</TargetDatabase>
    <DatabaseInstance>must_be_overridden</DatabaseInstance>
    <PreDeployment></PreDeployment>
    <PatchDeployment></PatchDeployment>
    <PostDeployment></PostDeployment>
    <PatchDeploymentFolder>Partitioning.Database\Scripts\Patching</PatchDeploymentFolder>
    <PatchFolderFormatStartsWith>B???_R????_</PatchFolderFormatStartsWith>
    <UpgradeScriptName>Patching.sql</UpgradeScriptName>
    <PreValidationScriptName>PreValidation.sql</PreValidationScriptName>
    <PostValidationScriptName>PostValidation.sql</PostValidationScriptName>
    <DetermineIfDatabaseIsAtThisPatchLevelScriptName>DetermineIfDatabaseIsAtThisPatchLevel.sql</DetermineIfDatabaseIsAtThisPatchLevelScriptName>
    <TestInfo Ignore='true'><Sql>select 1;</Sql></TestInfo>";

    }
}