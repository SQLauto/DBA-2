using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using Deployment.Common.Helpers;
using Deployment.Common.Logging;
using Deployment.Domain.Operations.Services;
using Deployment.Domain.Roles;
using Deployment.Domain.Parameters;

namespace Deployment.Domain.Operations.DeploymentOperator
{
    public class DatabaseDeployOperator : IDeploymentOperator<DatabaseDeploy>
    {
        private readonly IDeploymentLogger _logger;
        private readonly IParameterService _parameterService;

        public DatabaseDeployOperator(IParameterService parameterService, IDeploymentLogger logger = null)
        {
            _parameterService = parameterService ?? new ParameterService(logger);
            _logger = logger;
        }

        public bool PreDeploymentValidate(DatabaseDeploy role, ConfigurationParameters parameters, List<string> outputLocations)
        {
            bool isValid = true;

            // HS Note about tokenised parameter validation
            // We could iterate through every sql file and validate that every sqlcmd token is defined in the parameters file
            // We cannot however as the packaging system for sql deployments packages up all *.sql files, regardless of whether they
            // are actually set to be run in the given deployment
            // That means if we were to try and validate all sqlcmd varibales, we may incorrectly fail the validation against a sqlcmd
            // variable that wont actually be used in the deployment
            if (!string.IsNullOrEmpty(role.PatchDeploymentFolder))
            {
                var foundFolder = false;
                foreach (string location in outputLocations)
                {
                    string folderLocation = Path.Combine(location, role.PatchDeploymentFolder);
                    if(Directory.Exists(folderLocation))
                    {
                        foundFolder = true;
                        break;
                    }
                }

                if (!foundFolder)
                {
                    isValid = false;
                    _logger?.WriteWarn($"Patch Deployment Folder '{role.PatchDeploymentFolder}' cannot be found");
                }
            }

            if (!string.IsNullOrEmpty(role.BaselineDeployment))
            {
                var foundScript = false;
                foreach (string location in outputLocations)
                {
                    string scriptLocation = Path.Combine(location, role.BaselineDeployment);
                    if (File.Exists(scriptLocation))
                    {
                        foundScript = true;
                        break;
                    }
                }

                if (!foundScript)
                {
                    isValid = false;
                    _logger?.WriteWarn($"Baseline Deployment Script '{role.BaselineDeployment}' cannot be found'");
                }
            }

            if (!string.IsNullOrEmpty(role.PreDeployment))
            {
                var foundScript = false;
                foreach(string location in outputLocations)
                { 
                    string scriptLocation = Path.Combine(location, role.PreDeployment);
                    if (File.Exists(scriptLocation))
                    {
                        foundScript = true;
                        break;
                    }
                }

                if (!foundScript)
                {
                    isValid = false;
                    _logger?.WriteWarn($"Pre Deployment Script '{role.PreDeployment}' cannot be found");
                }
            }

            if (!string.IsNullOrEmpty(role.PatchDeployment))
            {
                var foundScript = false;
                foreach(string location in outputLocations)
                {
                    string scriptLocation = Path.Combine(location, role.PatchDeployment);
                    if(File.Exists(scriptLocation))
                    {
                        foundScript = true;
                        break;
                    }
                }
                
                if (!foundScript)
                {
                    isValid = false;
                    _logger?.WriteWarn(
                        $"Patch Deployment Script '{role.PatchDeployment}' cannot be found");
                }
            }

            if (!string.IsNullOrEmpty(role.PostDeployment))
            {
                var foundScript = false;
                foreach (string location in outputLocations)
                {
                    string scriptLocation = Path.Combine(location, role.PostDeployment);
                    if(File.Exists(scriptLocation))
                    {
                        foundScript = true;
                        break;
                    }
                }

                if (!foundScript)
                {
                    isValid = false;
                    _logger?.WriteWarn($"Post Deployment Script '{role.PostDeployment}' cannot be found");
                }
            }

            if (!string.IsNullOrEmpty(role.PostDeployment) && string.IsNullOrEmpty(role.PatchDeployment) && string.IsNullOrEmpty(role.PatchDeploymentFolder))
            {
                isValid = false;
                _logger?.WriteWarn(
                    $"Post Deployment Script '{role.PostDeployment}' has been specified and there is no Patching script this is is not permitted.");
            }

            return isValid;
        }

        public bool PostDeploymentValidate(PostDeployParameters postDeployParameters, DatabaseDeploy role) => true;

        public IList<ArchiveEntry> GetDeploymentFiles(DatabaseDeploy role, List<string> dropFolders, ConfigurationParameters parameters)
        {
            var files = new List<ArchiveEntry>();

            var scriptRootFolder = string.Empty;
            var dropLocation = string.Empty;
            var includeAllParameters = true;
            if (!string.IsNullOrEmpty(role.BaselineDeployment))
            {
                scriptRootFolder = string.IsNullOrEmpty(role.BaselineDeployment) ? string.Empty : role.BaselineDeployment.Substring(0, role.BaselineDeployment.IndexOf("\\", StringComparison.Ordinal));
            }
            if (!string.IsNullOrEmpty(role.PatchDeployment))
            {
                scriptRootFolder = string.IsNullOrEmpty(role.PatchDeployment) ? string.Empty : role.PatchDeployment.Substring(0, role.PatchDeployment.IndexOf("\\", StringComparison.Ordinal));
            }
            if (!string.IsNullOrEmpty(role.PatchDeploymentFolder))
            {
                scriptRootFolder = string.IsNullOrEmpty(role.PatchDeploymentFolder) ? string.Empty : role.PatchDeploymentFolder.Substring(0, role.PatchDeploymentFolder.IndexOf("\\", StringComparison.Ordinal));
                includeAllParameters = false;
            }

            foreach(string targetDropLocation in dropFolders)
            {
                var scriptDirectory = Path.Combine(targetDropLocation, scriptRootFolder);
                if(Directory.Exists(scriptDirectory))
                {
                    dropLocation = targetDropLocation;
                    break;
                }
            }

            // Create Parameters file
            CreateParametersFile(role, dropLocation, scriptRootFolder, parameters, includeAllParameters);

            // Just include all the sql files in the drop folder. It aint pretty but its how it was setup to work
            files.AddRange(GetSqlDeploymentScripts(dropLocation, scriptRootFolder));

            return files;
        }

        public static StringComparison ICIC = StringComparison.InvariantCultureIgnoreCase;
        private class TryGetParamComparer : IEqualityComparer<TryGetParam>
        {
            public TryGetParamComparer()
            {
            }

            public bool Equals(TryGetParam x, TryGetParam y)
            {
                return string.Compare(x.DeploymentParameter.Text, y.DeploymentParameter.Text, ICIC) == 0;
            }

            public int GetHashCode(TryGetParam tgParam)
            {
                string hCode = tgParam.DeploymentParameter.Text;
                return hCode.GetHashCode();
            }
        }

        private void CreateParametersFile(DatabaseDeploy role, string dropFolder, string scriptRootFolder, ConfigurationParameters parameters, bool includeAllParameters)
        {
            var scriptFilesFolder = Path.Combine(dropFolder, scriptRootFolder);
            
            string[] files = Directory.GetFiles(scriptFilesFolder, "*.sql", SearchOption.AllDirectories);
            var requiredParameters = new DeploymentParameters();

            foreach (var file in files)
            {
                var content = File.ReadAllText(file).RemoveComments();

                // RL Having difficulty with the custom comparer for the distict() and removestandardparamsters bit on conversion to tryGetParam.
                // For now I'm just converting it back to list<string> and ignoring the extra bits of isFound and isLookup
                requiredParameters.AddRange(_parameterService.GetParametersFromString(content)); // .Select(o => o.DeploymentParameter.Text).ToList());
            }

            // Distinct is handled by filter at the ppoint of adding to the DeploymentParameters collection
            requiredParameters = requiredParameters.RemoveStandardParameters();

            string parameterfile = Path.Combine(dropFolder, scriptRootFolder, $"{role.Include}.Parameters.sql");
            if (File.Exists(parameterfile)) return;
            using (var stream = File.CreateText(parameterfile))
            {
                if (includeAllParameters)
                {
                    foreach (var parameter in parameters.TargetParameters.Dictionary)
                    {
                        stream.WriteLine($":setvar {parameter.Key} {parameter.Value.Text}");
                    }
                }
                else
                {
                    foreach (var requiredParameter in requiredParameters.Dictionary)
                    {
                        if (parameters.TargetParameters.Dictionary.ContainsKey(requiredParameter.Key))
                        {
                            stream.WriteLine(
                                $":setvar {requiredParameter} {parameters.TargetParameters.Dictionary[requiredParameter.Key]}");
                        }
                    }
                }
            }
        }

        private List<ArchiveEntry> GetSqlDeploymentScripts(string dropFolder, string script)
        {
            List<ArchiveEntry> files = new List<ArchiveEntry>();

            if (!string.IsNullOrEmpty(script))
            {
                string scriptDirectory = Path.Combine(dropFolder, script);
                string[] scriptFiles = Directory.GetFiles(scriptDirectory, "*.sql", SearchOption.AllDirectories);
                string[] backupFiles = Directory.GetFiles(scriptDirectory, "*.bak", SearchOption.AllDirectories);

                var sqlFiles = scriptFiles.Union(backupFiles).ToList();

                foreach (string sqlFile in sqlFiles)
                {
                    files.Add(new ArchiveEntry
                    {
                        FileLocation = sqlFile,
                        FileRelativePath = FileHelper.GetFileRelativePath(sqlFile, dropFolder),
                        FileName = string.Empty
                    });
                }
            }

            return files;
        }
    }

    public static class SqlParametersHelper
    {
        /// <summary>
        ///     http://stackoverflow.com/questions/3524317/regex-to-strip-line-comments-from-c-sharp/3524689#3524689
        /// </summary>
        /// <param name="content"></param>
        /// <returns></returns>
        public static string RemoveComments(this string content)
        {
            const string blockComments = @"/\*(.*?)\*/";
            const string lineComments = @"//(.*?)\r?\n";
            const string strings = @"""((\\[^\n]|[^""\n])*)""";
            const string verbatimStrings = @"@(""[^""]*"")+";

            var noComments = Regex.Replace(content,
                blockComments + "|" + lineComments + "|" + strings + "|" + verbatimStrings,
                me =>
                {
                    if (me.Value.StartsWith("/*") || me.Value.StartsWith("//"))
                        return me.Value.StartsWith("//") ? Environment.NewLine : "";
                    // Keep the literal strings
                    return me.Value;
                },
                RegexOptions.Singleline);
            return noComments;
        }

    }
}
