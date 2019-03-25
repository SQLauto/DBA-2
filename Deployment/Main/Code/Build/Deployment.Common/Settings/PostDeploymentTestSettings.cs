using System.Configuration;
using System.Linq;
using Deployment.Common.Helpers;

namespace Deployment.Common.Settings
{
    public class PostDeploymentTestSettings
    {
        public static string RigConfigLocation => ResolvePostDeploymentTestSetting("Testing.RigConfigLocation");

        public static string JumpFolderPath => ResolvePostDeploymentTestSetting("Testing.JumpServerDropFolder");

        public static string DropLocation => ResolvePostDeploymentTestSetting("Build.DropFolder");

        public static string RigConfigFile => ResolvePostDeploymentTestSetting("Testing.RigConfigFile");

        public static string RigName => ResolvePostDeploymentTestSetting("Testing.RigName");

        public static string QualifiedUsername
        {
            get
            {
                var domain = ResolvePostDeploymentTestSetting("Testing.vCloud.TestRigDomain");
                var username = Username;

                return string.IsNullOrWhiteSpace(domain) ? username : $@"{domain}\{username}";
            }
        }


        public static string Username => ResolvePostDeploymentTestSetting("Testing.vCloud.TestRigUsername");

        public static string Password => ResolvePostDeploymentTestSetting("Testing.vCloud.TestRigPwd");

        public static DeploymentPlatform TargetPlatform
        {
            get
            {
                var platform = ResolvePostDeploymentTestSetting("Testing.TargetPlatform");

                if (string.IsNullOrWhiteSpace(platform))
                    platform = "VCloud";

                var result = EnumHelper.GetEnumByDescription<DeploymentPlatform>(platform);

                return result;
            }
        }

        public static string MasterDataConnectionString => ResolvePostDeploymentTestSetting("Testing.MasterDataConnectionString");

        public static string ServiceAccountsPassword => ResolvePostDeploymentTestSetting("Testing.ServiceAccountsPassword");

        public static string Groups => ResolvePostDeploymentTestSetting("Testing.Groups");

        public static string Servers => ResolvePostDeploymentTestSetting("Testing.Servers");

        /// <summary>
        /// This is the glue between tfsbuild and labmanager. Tfsbuild will update the file 'PostDeploymentTests.config' during a build
        /// when the test run they will read this updated values instead of the values in their app.config file
        /// </summary>
        /// <param name="name"></param>
        /// <returns></returns>
        private static string ResolvePostDeploymentTestSetting(string name)
        {
            var value = GetPostDeploymentTestSetting(name);
            if (!string.IsNullOrEmpty(value))
            {
                return value;
            }
            return ConfigurationManager.AppSettings[name] ?? string.Empty;
        }

        /// <summary>
        /// This is the glue between tfsbuild and labmanager. Tfsbuild will update the file 'PostDeploymentTests.config' during a build
        /// when the test run they will read this updated values instead of the values in their app.config file
        /// </summary>
        /// <param name="name"></param>
        /// <returns></returns>
        private static string GetPostDeploymentTestSetting(string name)
        {
            var fileMap = GetFileMapForTargetPlatform();

            // Relative file path, assumes the file "PostDeploymentTests.config" was copied to the test directory either by
            // using testsettings - deployment settings or DeploymentItem attributes

            var config = ConfigurationManager.OpenMappedExeConfiguration(fileMap, ConfigurationUserLevel.None);
            return config.AppSettings.Settings.AllKeys.Contains(name) ? config.AppSettings.Settings[name].Value : null;
        }

        private static ExeConfigurationFileMap GetFileMapForTargetPlatform()
        {
            var targetPlatform = ConfigurationManager.AppSettings["Testing.TargetPlatform"] ?? string.Empty;
            string filename;

            switch (targetPlatform.ToLower())
            {
                case "zerodeploy":
                    filename = @"PostDeploymentTests.ZD.config";
                    break;
                default: //inc. vCloud
                    filename = @"PostDeploymentTests.config";
                    break;
            }

            return new ExeConfigurationFileMap
            {
                ExeConfigFilename = filename
            };
        }

        public static bool LocalDebugMode
        {
            get
            {
                var localMode = ResolvePostDeploymentTestSetting("Testing.LocalDebugMode");
                return !string.IsNullOrEmpty(localMode) && bool.Parse(localMode);
            }
        }
    }
}
