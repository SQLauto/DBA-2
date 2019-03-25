using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Diagnostics;
using System.IO;
using System.Linq;
using Deployment.Common.Helpers;
using Deployment.Common.Logging;
using Deployment.Domain.Operations.Services;
using Deployment.Domain.Roles;

namespace Deployment.Domain.Operations.DeploymentOperator
{
    public class SsisDeployOperator : IDeploymentOperator<SsisDeploy>
    {
        private readonly IDeploymentLogger _logger;
        private readonly IParameterService _parameterService;

        public SsisDeployOperator(IParameterService parameterService = null, IDeploymentLogger logger = null)
        {
            _parameterService = parameterService ?? new ParameterService(logger);
            _logger = logger;
        }

        public IList<ArchiveEntry> GetDeploymentFiles(SsisDeploy role, List<string> dropFolders, ConfigurationParameters parameters)
        {
            var files = new List<ArchiveEntry>();

            // The SSIS package
            foreach (var dropFolder in dropFolders)
            {
                string packageFile = Path.Combine(dropFolder, role.SsisFile);
                if (File.Exists(packageFile))
                {
                    files.Add(new ArchiveEntry
                    {
                        FileLocation = packageFile,
                        FileRelativePath = FileHelper.GetFileRelativePath(packageFile, dropFolder),
                        FileName = string.Empty
                    });
                    break;
                }
            }

            return files;
        }

        public bool PreDeploymentValidate(SsisDeploy role, ConfigurationParameters parameters, List<string> outputLocations)
        {
            var foundPkg = false;

            foreach(string location in outputLocations)
            {
                string pkgLocation = Path.Combine(location, $"{role.SsisFile}");
                if(File.Exists(pkgLocation))
                {
                    foundPkg = true;
                    break;
                }
            }
            
            if (!foundPkg)
            {
                _logger?.WriteWarn($"SSIS Package file '{role.SsisFile}' cannot be found");
                return false;
            }

            var deployParams = parameters.TargetParameters.Dictionary;

            // Validate parameter values

            return role.Parameters.Select(parameter => _parameterService.GetParametersFromString(parameter.Value))
                .Aggregate(true, (current, paramsToValidate) => current & _parameterService.ValidateParameterList(paramsToValidate, deployParams));
        }

        public bool PostDeploymentValidate(PostDeployParameters postDeployParameters, SsisDeploy role)
        {
            bool result;

            using (var timer = new PerformanceLogger(_logger))
            {
                switch (role.DeploymentMode)
                {
                    case SsisDepoymentMode.Wiz:
                        result = ValidateWizDeployment(postDeployParameters, role);
                        break;
                    case SsisDepoymentMode.File:
                        result = ValidateFileDeployment(postDeployParameters, role);
                        break;
                    case SsisDepoymentMode.Sql:
                        result = ValidateSqlDeployment(postDeployParameters, role);
                        break;
                    default:
                        _logger?.WriteWarn(
                            $"{role.ProjectName} - {role.DeploymentMode} is not supported for SSIS post-deployment validation.");
                        result = false;
                        break;
                }

                timer.WriteSummary("Completed Post-Deployment validation of SSIS deployment.", result ? LogResult.Success : LogResult.Fail);
            }

            return result;
        }

        private bool ValidateFileDeployment(PostDeployParameters postDeployParameters, SsisDeploy role)
        {
            _logger?.WriteLine("Validating File SSIS Deployment.");

            var package =
                $@"\\{postDeployParameters.Machine.DeploymentAddress}\{
                        role.DestinationFolder.Replace(':', '$')
                    }\{role.SsisFile}.dtsx";

            var result = File.Exists(package);

            var message = result ? $"SSIS package '{package}' found." : $"SSIS package '{package}' cannot be found.";

            _logger?.WriteLine(message);

            return result;
        }

        private bool ValidateSqlDeployment(PostDeployParameters postDeployParameters, SsisDeploy role)
        {
            _logger?.WriteLine("Validating Sql SSIS Deployment.");

            var proc = new Process {StartInfo = {FileName = "dtutil"}};

            string targetServer = postDeployParameters.Machine.DeploymentAddress;
            if (!string.IsNullOrEmpty(role.DatabaseInstance))
            {
                targetServer = $@"{targetServer}\{role.DatabaseInstance}";
            }

            proc.StartInfo.Arguments = $"/SQL {role.SsisFile} /EXISTS /SOURCESERVER {targetServer} /Quiet";
            if (!string.IsNullOrEmpty(role.TestInfo?.SqlPassword) && !string.IsNullOrEmpty(role.TestInfo.SqlUserName))
            {
                proc.StartInfo.Arguments =
                    $"/SQL {role.SsisFile} /EXISTS /SOURCESERVER {targetServer} /SOURCEUSER {role.TestInfo.SqlUserName} /SOURCEPASSWORD {role.TestInfo.SqlPassword} /Quiet";
            }

            proc.StartInfo.UseShellExecute = false;
            proc.StartInfo.CreateNoWindow = true;
            proc.Start();
            proc.WaitForExit();

            var result = proc.ExitCode == 0;

            var message = result
                ? $"SSIS package '{role.SsisFile}' was found on server {targetServer}."
                : $"Cannnot find SSIS package '{role.SsisFile}' on {targetServer}.";

            _logger?.WriteLine(message);

            return result;
        }

        private bool ValidateWizDeployment(PostDeployParameters postDeployParameters, SsisDeploy role)
        {
            _logger?.WriteLine("Validating Wiz Deployment.");
            // Ideally i would just use 'EXEC [SSISDB].[catalog].[validate_project]' here but that sp does not work for sql auth so we cant
            // use it against lm rigs

            var machine = postDeployParameters.Machine;
            var connString = DataHelper.GetConnectionString(machine.DeploymentAddress, role.DatabaseInstance, "SSISDB", role.TestInfo.SqlUserName, role.TestInfo.SqlPassword);
            _logger?.WriteLine($"Connection String: {connString}");

            try
            {
                using (var conn = new SqlConnection(connString))
                {
                    conn.Open();
                    // 1) Check project exists
                    _logger?.WriteLine(" Checking project exists..");
                    var sql =
                        $@"SELECT project_id FROM [SSISDB].[catalog].[projects] WHERE name = N'{role.ProjectName}'";

                    int projectId;
                    using (var command = new SqlCommand(sql, conn))
                    {
                        var result = command.ExecuteScalar();
                        if (result == null)
                        {
                            _logger?.WriteLine(
                            $"SSIS role '{role.Description}' - Project '{role.ProjectName}' was not found.");
                            return false;
                        }
                        projectId = Convert.ToInt32(result);
                    }

                    // 2) Check all packages exist
                    _logger?.WriteLine(" Checking package exists..");

                    sql = $@"SELECT name  FROM [SSISDB].[catalog].[packages] where project_id = N'{projectId}'";

                    using (var command = new SqlCommand(sql, conn))
                    {
                        using (var reader = command.ExecuteReader())
                        {
                            var tablePackages = new List<string>();
                            while (reader.Read())
                            {
                                tablePackages.Add(reader[0] as string);
                                tablePackages.Add(reader[0] as string);
                            }

                            foreach (var package in role.Packages)
                            {
                                if (tablePackages.Contains(package))
                                    continue;

                                _logger?.WriteLine(
                                    $"SSIS role '{role.Description}' - Package '{package}' was not found.");

                                return false;
                            }
                        }
                    }

                    // 3) Check environment configuration exists
                    _logger?.WriteLine("Check environment configuration exists..");
                    sql =
                        $@"select environment_id from SSISDB.internal.environments where environment_name = '{role.Environment}' ";

                    int environmentId;
                    using (var command = new SqlCommand(sql, conn))
                    {
                        var result = command.ExecuteScalar();
                        if (result == null)
                        {
                            _logger?.WriteLine($"SSIS role '{role.Description}' - Environment config '{role.Environment}' was not found.");
                            return false;
                        }

                        environmentId = Convert.ToInt32(result);
                    }


                    // 4) Check all variables are present and have the right value
                    _logger?.WriteLine("Checking all variables are present and have the right value..");

                    sql = $@"select name,value from SSISDB.internal.environment_variables where environment_id = {environmentId}";

                    var environmentVars = new Dictionary<string, string>();

                    using (var command = new SqlCommand(sql, conn))
                    {
                        using (var reader = command.ExecuteReader())
                        {
                            while (reader.Read())
                            {
                                environmentVars.Add(reader[0].ToString(), reader[1].ToString());
                            }
                        }
                    }

                    var missingEnvVars = new List<string>();
                    var wrongEnvVars = new List<string>();

                    foreach (var parameter in role.Parameters)
                    {
                        if (!environmentVars.ContainsKey(parameter.Name))
                        {
                            missingEnvVars.Add(parameter.Name);
                            continue;
                        }

                        var resolvedParameterValue = _parameterService.ResolveValue(parameter.Value, role.Parameters);
                        if (environmentVars[parameter.Name]
                            .Equals(resolvedParameterValue, StringComparison.CurrentCultureIgnoreCase))
                            continue;

                        if (parameter.Name.ToLower() == "strimagelocationurl" && postDeployParameters.Environment == "TSRig")
                        {
                            // Sorry, I know this naff; we overwrite this value in integration rigs so dont validate it
                        }
                        else
                        {
                            // env var : aaa, value : bbb, param value : ccc
                            wrongEnvVars.Add("\r\n env var : " + parameter.Name +
                                             ", value : " + environmentVars[parameter.Name] +
                                             ", param value : " + resolvedParameterValue);
                        }
                    }

                    // report missing
                    if (missingEnvVars.Count > 0)
                    {
                        var vars = string.Join(", ", missingEnvVars);

                        _logger?.WriteLine(
                            $"SSIS role '{role.Description}' - Environment Variables {vars} in Environment '{role.Environment}' do not exist.");

                        return false;
                    }

                    // report wrong
                    if (wrongEnvVars.Count > 0)
                    {
                        var vars = string.Join(", ", wrongEnvVars);
                        _logger?.WriteLine(
                            $"SSIS role '{role.Description}' - Environment Variables {vars} in Environment '{role.Environment}' have the wrong value.");

                        return false;
                    }

                    // 5) Check all required parameters are referenced
                    _logger?.WriteLine("Check all required parameters are referenced");
                    foreach (string package in role.Packages)
                    {
                        sql = $@"SELECT parameter_name FROM [SSISDB].[catalog].[object_parameters] 
                                            WHERE object_name = N'{package}' AND
                                            value_type = 'V' AND
                                            required = 1";

                        using (var command = new SqlCommand(sql, conn))
                        {
                            var unreferencedParameters = new List<string>();
                            using (var reader = command.ExecuteReader())
                            {
                                while (reader.Read())
                                {
                                    unreferencedParameters.Add(reader[0] as string);
                                }
                            }

                            if (unreferencedParameters.Count == 0)
                                continue;

                            var pars = string.Join(", ", unreferencedParameters);
                            _logger?.WriteLine(
                                $@"SSIS role '{role.Description}' - Parameters {pars} in Package '{package}' are not referenced.");

                            return false;
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                _logger?.WriteSummary($"Post-Deployment Validation Failed: SSIS role '{role.Description}'");
                _logger?.WriteError(ex);

                return false;
            }

            _logger?.WriteLine("SISS Wiz package validation successfully completed.");

            return true;
        }
    }
}