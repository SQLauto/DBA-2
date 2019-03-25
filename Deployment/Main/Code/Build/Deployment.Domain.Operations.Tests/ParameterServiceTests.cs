using System;
using System.Collections.Generic;
using System.Configuration;
using System.IO;
using System.Linq;
using System.Xml.Linq;
using System.Xml.Xsl;
using Deployment.Common.Xml;
using Deployment.Domain.Operations.Services;
using Deployment.Domain.Parameters;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using MSTestExtensions;

namespace Deployment.Domain.Operations.Tests
{
    [TestClass]
    public class ParameterServiceTests : DomainOperationsTestBase
    {
        private IParameterService _parameterService;
        private const string AppConfig = @"App.config";
        private const string Xsl = @"App.Transform.config";
        private const string TransformedConfig = "SimpleWindowsService.exe.config";
        private const string DeploymentConfigFile = "Baseline.Apps.config.xml";


        [TestInitialize]
        public void TestInitialize()
        {
            Logger = new TestContextLogger(TestContext);
            _parameterService = new ParameterService(Logger);
        }

        [TestMethod]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [TestCategory("ParameterService")]
        public void TestReadsDeploymentDefaultConfigParameters()
        {
            //Test parameter service as used during a deployment.

            var files = new[] { "Test.AA.Parameters.xml", "Test.BB.Parameters.xml", "Test.Global.Parameters.xml" };

            CopyFiles(files, "Parameters");

            Config = "Test";
            OverrideConfig = null;

            IDeploymentPathBuilder pathBuilder = new DeploymentPathBuilder(TestContext.TestDeploymentDir, Logger) { IsLocalDebugMode = true };

            //should only pick up parameters from Test.Global, Test.AA and Test.BB
            var parameters = _parameterService.ParseDeploymentParameters(pathBuilder, Config, OverrideConfig, null);

            Assert.AreEqual(9, parameters.Dictionary.Count);
            //first value was defined in global, but AA overrides it
            Assert.AreEqual("AAValue1", parameters.Dictionary["Param1"].Text);
            //comes from global, not overriden
            Assert.AreEqual("GlobalValue5", parameters.Dictionary["Param5"].Text);
            //Comes from AA only
            Assert.AreEqual("AAValue8", parameters.Dictionary["Param8"].Text);
            //Comes from BB only
            Assert.AreEqual("BBValue10", parameters.Dictionary["Param10"].Text);

            RemoveFiles(files, "Parameters");
        }

        [TestMethod]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [TestCategory("ParameterService")]
        public void TestReadsDeploymentOverrideConfigParameters()
        {
            //Test parameter service as used during a deployment.

            var files = new[] { "Test.AA.Parameters.xml", "Test.BB.Parameters.xml", "Test_Override.AA.Parameters.xml", "Test.Global.Parameters.xml",
                "Test_Override.Global.Parameters.xml" };

            CopyFiles(files, "Parameters");

            var pathBuilder = new DeploymentPathBuilder(TestContext.TestDeploymentDir, Logger) { IsLocalDebugMode = true };

            Config = "Test";
            OverrideConfig = "Test_Override";

            //should only pick up parameters from Test.Global,Test_Override.Global, Test.AA, Test_override.AA and Test.BB
            var parameters = _parameterService.ParseDeploymentParameters(pathBuilder, Config, OverrideConfig, null);

            Assert.AreEqual(13, parameters.Dictionary.Count);
            //first value was defined in global, global_overide,and AA but AA_override overrides it
            Assert.AreEqual("AAOverrideValue1", parameters.Dictionary["Param1"].Text);
            //comes from global, not overriden
            Assert.AreEqual("GlobalValue5", parameters.Dictionary["Param5"].Text);
            //Comes from AA only
            Assert.AreEqual("AAValue8", parameters.Dictionary["Param8"].Text);
            //Overrride in AA
            Assert.AreEqual("AAValue2", parameters.Dictionary["Param2"].Text);
            //Comes from BB only
            Assert.AreEqual("BBValue10", parameters.Dictionary["Param10"].Text);
            //Comes from Global_Overrride only
            Assert.AreEqual("OverrideGlobalValue7", parameters.Dictionary["Param7"].Text);
            //Comes from AA_Overrride only
            Assert.AreEqual("AAOverrideValue12", parameters.Dictionary["Param12"].Text);

            RemoveFiles(files, "Parameters");
        }

        [TestMethod]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [TestCategory("ParameterService")]
        public void TestReadsDistributedDeploymentDefaultConfigParameters()
        {
            //Test parameter service as used during a deployment.

            var ciDirectory = Path.Combine(TestContext.TestDeploymentDir, "CI");

            if (!Directory.Exists(ciDirectory))
                Directory.CreateDirectory(ciDirectory);

            var files = new[] { "Test.Global.Parameters.xml", "Test_Override.Global.Parameters.xml" };

            CopyFiles(files, "Parameters");

            files = new[] { "Test.AA.Parameters.xml", "Test_Override.AA.Parameters.xml"};

            CopyFiles(files, "CI", "AA", "Parameters");

            files = new[] { "Test.BB.Parameters.xml" };

            CopyFiles(files, "CI", "BB", "Parameters");

            Config = "Test";
            OverrideConfig = null;

            var pathBuilder = new RootPathBuilder(TestContext.TestDeploymentDir, Logger) { IsLocalDebugMode = true };

            var childPathBuilders = pathBuilder.CreateChildPathBuilders();

            //should only pick up parameters from Test.Global, Test.AA and Test.BB
            var parameters = _parameterService.ParseDeploymentParameters(childPathBuilders.Item1, Config, OverrideConfig, childPathBuilders.Item2);

            Assert.AreEqual(9, parameters.Dictionary.Count);
            //first value was defined in global, but AA overrides it
            Assert.AreEqual("AAValue1", parameters.Dictionary["Param1"].Text);
            //comes from global, not overriden
            Assert.AreEqual("GlobalValue5", parameters.Dictionary["Param5"].Text);
            //Comes from AA only
            Assert.AreEqual("AAValue8", parameters.Dictionary["Param8"].Text);
            //Comes from BB only
            Assert.AreEqual("BBValue10", parameters.Dictionary["Param10"].Text);

            Directory.Delete(ciDirectory, true);
        }

        [TestMethod]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [TestCategory("ParameterService")]
        public void TestReadsDeploymentDefaultConfigAndRigParameters()
        {
            //Test parameter service as used during a deployment.

            var files = new[] { "Test.AA.Parameters.xml", "Test.BB.Parameters.xml", "Test.Global.Parameters.xml" };

            CopyFiles(files, "Parameters");

            Config = "Test";
            OverrideConfig = null;
            var rigConfigFile = "FTP.Main.Top10.RTN.Config.xml";
            var rigManifest = new RigManifest("FTP.Main.Top10.RTN", null);
            rigManifest.Add("TS-CAS1", "1.0.0.1");
            var mappings = new PlaceholderMappings();
            mappings.Add("SDMSiteIP", "TS-CAS1");

            var pathBuilder = new DeploymentPathBuilder(TestContext.TestDeploymentDir, Logger) { IsLocalDebugMode = true };

            //should only pick up parameters from Test.Global, Test.AA and Test.BB
            var parameters = _parameterService.ParseDeploymentParameters(pathBuilder, Config, OverrideConfig, null, rigConfigFile, mappings,rigManifest);

            Assert.AreEqual(26, parameters.Dictionary.Count);
            //first value was defined in global, but AA overrides it
            Assert.AreEqual("AAValue1", parameters.Dictionary["Param1"].Text);
            //comes from global, not overriden
            Assert.AreEqual("GlobalValue5", parameters.Dictionary["Param5"].Text);
            //Comes from AA only
            Assert.AreEqual("AAValue8", parameters.Dictionary["Param8"].Text);
            //Comes from BB only
            Assert.AreEqual("BBValue10", parameters.Dictionary["Param10"].Text);
            //Comes Dynamic Config
            Assert.AreEqual("localhost;cascm10necasc.ce-asev2.p.azurewebsites.net;1.0.0.1;", parameters.Dictionary["SSO_WebsiteSsoRedirectWhiteListUrls"].Text);

            RemoveFiles(files, "Parameters");
        }

        [TestMethod]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [TestCategory("ParameterService")]
        public void TestGetsRawParameterValues()
        {
            //set up
            var service = new ParameterService(Logger);
            var parameter = "$(Baseline_SimpleDBConnectionString)";
            var parameterName = "Baseline_SimpleDBConnectionString";

            //act
            var rawValue = service.GetRawParameterValue(parameter);

            //assert
            Assert.IsTrue(rawValue.IsValid);
            Assert.AreEqual(parameterName, rawValue.ParameterKey);
        }


        [TestMethod]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [TestCategory("ParameterService")]
        public void TestParametersCanBeObtainedFromString()
        {
            Logger.WriteLine(@"aSetting\<""bsetting"">");

            var transformedConfigFullPath = GenerateConfigFile();

            //setup
            string configData = File.ReadAllText(transformedConfigFullPath);

            //act
            var parameters = _parameterService.GetParametersFromString(configData);

            //assert
            Assert.IsTrue(parameters.ContainsKey("Baseline_SimpleDBConnectionString"));
            Assert.IsTrue(parameters.ContainsKey("Baseline_TestValueA"));
            Assert.IsTrue(parameters.ContainsKey("Baseline_TestValueB"));
            Assert.AreEqual(4, parameters.Dictionary.Count);
        }

        [TestMethod]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [TestCategory("ParameterService")]
        public void TestParametersCanBeObtainedFromDoc()
        {
            //setup
            var doc =
                new XDocument(
                    XmlHelper.CreateXElement(
                        @"<RootNode><Node1>$(Param1)</Node1><Node2 name=""$(Param2)"" /></RootNode>"));

            var parameters = _parameterService.GetParametersFromXDocument(doc);

            //act
            //assert
            Assert.IsTrue(parameters.ContainsKey("Param1"));
            Assert.IsTrue(parameters.ContainsKey("Param2"));
            Assert.AreEqual(2, parameters.Dictionary.Count);
        }

        [TestMethod]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [TestCategory("ParameterService")]
        public void TestParametersCanBeObtainedFromConfig()
        {
            Logger.WriteLine(@"aSetting\<""bsetting"">");
            //setup
            var transformedConfigFullPath = GenerateConfigFile();

            //act
            var parameters = _parameterService.GetParametersFromConfig(transformedConfigFullPath);

            //assert
            Assert.IsTrue(parameters.ContainsKey("Baseline_SimpleDBConnectionString"));
            Assert.IsTrue(parameters.ContainsKey("Baseline_TestValueA"));
            Assert.IsTrue(parameters.ContainsKey("Baseline_TestValueB"));
            Assert.AreEqual(3, parameters.Dictionary.Count);
        }

        [TestMethod]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [TestCategory("ParameterService")]
        public void TestAvailableParametersPassValidationCaseIgnored()
        {
            //setup

            // CHECKME: 112236: This changed ot DeploymentParameters from List<string> in web and app.
            //     have had to leave this
            //var deployParams = new Dictionary<string, DeploymentParameter>
            //{
            //    { "myAppSetting", new DeploymentParameter(@"$(Baseline_TestValueA)\$(Baseline_TestValueB)")}
            //};
            var deployParams = new DeploymentParameters();
            deployParams.Add("myAppSetting", new DeploymentParameter(@"$(Baseline_TestValueA)\$(Baseline_TestValueB)"));

            //var paramsToValidate = new List<string> { "myAppSETTING", "myAPPSetting", "MYAppSetting" };
            var paramsToValidate = new DeploymentParameters();
            paramsToValidate.Add("myAppSETTING", new DeploymentParameter(@"???"));
            paramsToValidate.Add("myAPPSetting", new DeploymentParameter(@"???"));
            paramsToValidate.Add("MYAppSetting", new DeploymentParameter(@"???"));

            var validationResult = _parameterService.ValidateParameterList(paramsToValidate, deployParams.Dictionary);
            Assert.IsTrue(validationResult);

            //var paramsToValidateInvalid = new List<string> { "myAppSetting", "myAppSetting_DoesNotExist" };
            var paramsToValidateInvalid = new DeploymentParameters();
            paramsToValidateInvalid.Add("myAppSetting", new DeploymentParameter(@"???"));
            paramsToValidateInvalid.Add("myAppSetting_DoesNotExist", new DeploymentParameter(@"???"));

            validationResult = _parameterService.ValidateParameterList(paramsToValidateInvalid, deployParams.Dictionary);
            Assert.IsFalse(validationResult);
        }

        [TestMethod]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [TestCategory("ParameterService")]
        public void TestUnavailableParametersFailValidationCaseIgnored()
        {
            //setup

            var deployParams = new Dictionary<string, DeploymentParameter>
            {
                { "myAppSetting", new DeploymentParameter(@"$(Baseline_TestValueA)\$(Baseline_TestValueB)")}
            };

            //var paramsToValidateInvalid = new List<string> {"myAppSetting_DoesNotExist1", "myAppSetting_DoesNotExist2"};
            var paramsToValidateInvalid = new DeploymentParameters();
            paramsToValidateInvalid.Add("myAppSetting_DoesNotExist1", new DeploymentParameter(@"???"));
            paramsToValidateInvalid.Add("myAppSetting_DoesNotExist2", new DeploymentParameter(@"???"));

            var validationResult = _parameterService.ValidateParameterList(paramsToValidateInvalid, deployParams);
            Assert.IsFalse(validationResult);
        }

        [TestMethod]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [TestCategory("ParameterService")]
        public void TestValidateParameterSubstitution()
        {
            var files = new[] { "Baseline.Apps.Parameters.xml", "Baseline.DB.Parameters.xml", "BaselineX.Apps.Parameters.xml", "BaselineXNS.Apps.Parameters.xml" };

            CopyFiles(files, "Parameters");

            var pathBuilder = new RootPathBuilder(TestContext.TestDeploymentDir, Logger) { IsLocalDebugMode = true };
            var pathBuilders = pathBuilder.CreateChildPathBuilders(DeploymentConfigFile);

            Config = "Baseline";
            OverrideConfig = null;
            var transformedConfigFullPath = GenerateConfigFile();

            var parameters = _parameterService.ParseDeploymentParameters(pathBuilders.Item1, Config, OverrideConfig, pathBuilders.Item2, null);

            var workingFolder = Path.GetDirectoryName(transformedConfigFullPath);
            var outputFolder = Path.Combine(workingFolder, "Output");
            if (!Directory.Exists(outputFolder))
            {
                Directory.CreateDirectory(outputFolder);
            }

            var transformFile = Path.Combine(workingFolder, "SimpleWindowsService.exe.transform.config");
            File.WriteAllText(transformFile, File.ReadAllText(transformedConfigFullPath));

            var transformer = new ConfigurationTransformationService(_parameterService, Logger);
            transformer.TransformApplicationConfiguration(Config, outputFolder, workingFolder, TransformedConfig,
                parameters.Dictionary, null, null);

            var outputFile = Path.Combine(outputFolder, TransformedConfig);
            var fileContents = File.ReadAllText(outputFile);
            Logger.WriteLine(fileContents);

            var searchFor = "value=\"aSetting\\&lt;&quot;bsetting&quot;&gt;\"";

            Assert.IsTrue(fileContents.Contains(searchFor),
                $"Unable to find string [{searchFor}] in transformed file");

            //var fileMap = new ExeConfigurationFileMap
            //{
            //    ExeConfigFilename = outputFile
            //};

            //var configuration = ConfigurationManager.OpenMappedExeConfiguration(fileMap, ConfigurationUserLevel.None);

        }

        private string GenerateConfigFile()
        {
            var xslt = new XslCompiledTransform();
            xslt.Load(Xsl);
            xslt.Transform(AppConfig, TransformedConfig);

            return Path.GetFullPath(TransformedConfig);
        }
    }
}
