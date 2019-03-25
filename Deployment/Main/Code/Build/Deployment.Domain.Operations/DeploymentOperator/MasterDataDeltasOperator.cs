using System.Collections.Generic;
using System.IO;
using System.Linq;
using Deployment.Common.Helpers;
using Deployment.Common.Logging;
using Deployment.Domain.Roles;

namespace Deployment.Domain.Operations.DeploymentOperator
{
    public class MasterDataDeltasOperator : IDeploymentOperator<MasterDataDeltas>
    {
        private readonly IDeploymentLogger _logger;

        public MasterDataDeltasOperator(IParameterService parameterService = null, IDeploymentLogger logger = null)
        {
            _logger = logger;
        }

        public bool PreDeploymentValidate(MasterDataDeltas role, ConfigurationParameters parameters, List<string> outputLocations)
        {
            var foundDayKeys = false;
            System.Text.StringBuilder validationErrors = new System.Text.StringBuilder();

            foreach (var items in role.DayKeys)
            {
                foreach (string location in outputLocations)
                {
                    string sourceFileorPath = Path.Combine(location, role.Source);
                    var subPath = Path.Combine(sourceFileorPath, role.Subsystem, items);

                    if (!Directory.Exists(subPath) && !File.Exists(subPath))
                        foundDayKeys = false;
                    else
                    {
                        foundDayKeys = true;
                        break;
                    }

                    validationErrors.AppendLine($"Unable to determine location of Day Key {items}.");
                }
            }


            if (!foundDayKeys)
            {
                _logger?.WriteWarn($"Source path was not determined for Copy Assets {role.Description}");
                _logger?.WriteWarn(validationErrors.ToString());
            }

            return foundDayKeys;
        }

        public bool PostDeploymentValidate(PostDeployParameters postDeployParameters, MasterDataDeltas role) => true;

        public IList<ArchiveEntry> GetDeploymentFiles(MasterDataDeltas role, List<string> dropFolders, ConfigurationParameters parameters)
        {
            var files = new List<ArchiveEntry>();
            foreach (var item in role.DayKeys)
            {
                foreach (var dropFolder in dropFolders)
                {
                    var sourcePath = Path.Combine(dropFolder, role.Source);
                    var subPath = Path.Combine(sourcePath, role.Subsystem, item);

                    if (!(!Directory.Exists(subPath) && !File.Exists(subPath)))
                    {
                        SearchOption searchOption = true ? SearchOption.AllDirectories : SearchOption.TopDirectoryOnly;
                        var fileToCopy = Directory.GetFiles(subPath, role.Filter, searchOption);

                        files.AddRange(fileToCopy.Select(file => new ArchiveEntry
                        {
                            FileLocation = file,
                            FileRelativePath = FileHelper.GetFileRelativePath(file, dropFolder),
                            FileName = string.Empty
                        }));
                    }
                }
            }
            return files;
        }
    }
}