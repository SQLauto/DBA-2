using System;
using System.IO;
using System.Linq;
using System.Text;
using Deployment.Common.Helpers;
using Deployment.Common.Logging;
using Deployment.Domain.Roles;

namespace Deployment.Domain.Operations.DeploymentOperator
{
    public class AppFabricTestOperator
    {
        public bool RunTest(AppFabricTest test, Machine machine, PostDeployParameters parameters, IDeploymentLogger logger)
        {

            // This test is only designed to run against single hosts, not clusters of hosts
            // This test will run against app fabric caches in virtual environments  (lab manager or vcloud)
            // As such we have to connect to app fabric from fae into faelab.
            // The only way to do this is unfortunatley to use the less than perfect psexec.
            // Powershell remoting or direct connection to App fabric is not possible from fae to faelab
            // The test should still work when we run it in the same domain (e.g. CubicABCD) or when running from within a
            // rig - see psexec noe below

            var serviceAccount = parameters.ServiceAccounts.FirstOrDefault(
                s => s.LookupName.Equals(test.AccountName, StringComparison.InvariantCultureIgnoreCase));

            bool isValid = true;

            using (var timer = new PerformanceLogger(logger))
            {
                try
                {
                    // Commented out by Steve Bostock [10-08-17] Reason: We are removing NetUse Commands from the Build Process see PBI 129191
                    //if (!string.IsNullOrWhiteSpace(serviceAccount?.DecryptedPassword))
                    //{
                    //    using (var netUseHelper = new NetUseHelper(logger))
                    //    {
                    //        netUseHelper.CreateMappedDrive(test.HostName, test.HostName, "D$", null, serviceAccount.Username, serviceAccount.DecryptedPassword);
                    //    }
                    //}

                    string scriptFile = $@"\\{test.HostName}\{parameters.DriveLetter}$\AppFabricValidationTest.ps1";
                    if (File.Exists(scriptFile))
                    {
                        File.Delete(scriptFile);
                    }

                    string script = $@"try
                {{
	                import-module DistributedCacheAdministration
	                Use-CacheCluster
	                $isValid = (Get-CacheStatistics -CacheName {test.CacheName}).Size	                
                    Write-Output ""CacheName {test.CacheName} is available""
                    exit 0
                }}
     		    catch [System.Exception]
                {{
                    $msg = ""CacheName {test.CacheName} is not available"" + $_.Exception.ToString()
	                Write-Error $msg
                    exit 1
                }}";

                    using (var stream = File.Create(scriptFile))
                    {
                        byte[] bytes = Encoding.ASCII.GetBytes(script);
                        stream.Write(bytes, 0, bytes.Length);
                    }

                    var commandLineHelper = new CommandLineHelper(logger);

                    string args =
                        $@"powershell -ExecutionPolicy Unrestricted -NonInteractive -File {parameters.DriveLetter}\AppFabricValidationTest.ps1";
                    int exitCode;
                    string remoteName = test.HostName;
                    if (Environment.MachineName.Equals(test.HostName, StringComparison.CurrentCultureIgnoreCase))
                    {
                        exitCode = commandLineHelper.PowershellCommand(args);
                    }
                    else
                    {
                        exitCode = commandLineHelper.RemotePowershellCommand(remoteName, args, serviceAccount.Username,
                            serviceAccount.DecryptedPassword);
                    }

                    if (exitCode != 0)
                    {
                        timer.WriteSummary($"App Fabric Cache '{test.CacheName}' is not available, process exited with code {exitCode}", LogResult.Fail);
                        isValid = false;
                    }
                    else
                    {
                        timer.WriteSummary(
                            $"App Fabric Cache '{test.CacheName}' is  available.", LogResult.Success);
                    }
                }
                catch (Exception ex)
                {
                    timer.WriteSummary($"App Fabric Cache '{test.CacheName}' is not available.", LogResult.Fail);
                    logger?.WriteError(ex);
                    isValid = false;
                }
            }
            return isValid;
        }
    }
}