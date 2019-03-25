using System.Collections.Generic;
using System.Xml.Linq;
using Deployment.Common;
using Deployment.Domain.Roles;

namespace Deployment.Domain.Operations.DomainModelFactory
{
    public class FileSystemDeployFactory : BaseRoleFactory<FileSystemDeploy>
    {
        public FileSystemDeployFactory(string defaultConfig) : base(defaultConfig, new[] { "config:ServerRole[@Name='TFL.FileSystem']", "role:ServerRole[@Name='TFL.FileSystem']" })
        {
        }

        public override IBaseRole DomainModelCreate(XElement rootNode, ref ValidationResult validationResult)
        {
            var retVal = new FileSystemDeploy(DefaultConfig);
            ParseCommonAttributes(retVal, rootNode, ref validationResult);

            foreach (var element in rootNode.Elements())
            {
                IFileSystemRole role = null;
                var elementName = element.Name.LocalName;
                switch (elementName)
                {
                    case "CreateFolder":
                        role = FolderDeployCreate(element, DeploymentAction.Install, ref validationResult);
                        break;
                    case "RemoveFolder":
                        role = FolderDeployCreate(element, DeploymentAction.Uninstall, ref validationResult);
                        break;
                    case "CopyItem":
                        role = CopyItemCreate(element, ref validationResult);
                        break;
                    default:
                        validationResult.AddError($"Parsing IFileSystemRole, unknown element named: {elementName}");
                        break;
                }

                if (role == null)
                    continue;

                ParseCommonAttributes(role, rootNode, ref validationResult);
                retVal.FileSystemRoles.Add(role);
            }

            ValidateDomainObject(retVal, ref validationResult, true);

            return retVal;
        }

        public override bool ValidateDomainObject(FileSystemDeploy domainObject, ref ValidationResult validationResult,
            bool suppressStandardParseValidations = false)
        {
            return validationResult.Result;
        }

        public override IBaseRole UpdateParameterisedValues(IBaseRole deployRole, IParameterService parameterService,
            IDeploymentPathBuilder deploymentPathBuilder, IList<ICIBasePathBuilder> ciPathBuilders, ref ValidationResult validationResult)
        {
            var role = (FileSystemDeploy)deployRole;

            var deploymentParameters = parameterService.ParseDeploymentParameters(deploymentPathBuilder, DefaultConfig, deployRole.Configuration, ciPathBuilders, null);

            foreach (var copyItem in role.CopyItems)
            {
                var resolveValue = deploymentParameters.ResolveValue(copyItem.Source);

                if(resolveValue.Item1)
                    copyItem.Source = resolveValue.Item2;

                resolveValue = deploymentParameters.ResolveValue(copyItem.Target);

                if (resolveValue.Item1)
                    copyItem.Target = resolveValue.Item2;
            }

            foreach (var copyItem in role.CreateFolderDeploys)
            {
                var resolveValue = deploymentParameters.ResolveValue(copyItem.TargetPath);

                if (resolveValue.Item1)
                    copyItem.TargetPath = resolveValue.Item2;
            }

            foreach (var copyItem in role.RemoveFolderDeploys)
            {
                var resolveValue = deploymentParameters.ResolveValue(copyItem.TargetPath);

                if (resolveValue.Item1)
                    copyItem.TargetPath = resolveValue.Item2;
            }

            return base.UpdateParameterisedValues(deployRole, parameterService, deploymentPathBuilder, ciPathBuilders, ref validationResult);
        }

        private IFileSystemRole CopyItemCreate(XElement element, ref ValidationResult validationResult)
        {
            var copy = new CopyItem {Configuration = DefaultConfig};
            ParseElementAttribute(element, "Source", () => copy.Source, ref validationResult, ValidationAction.NotNullOrEmpty("CopyItem - Source"));
            ParseElementAttribute(element, "Target", () => copy.Target, ref validationResult, ValidationAction.NotNullOrEmpty("CopyItem - Target"));
            ParseElementAttribute(element, "Recurse", () => copy.Recurse, ref validationResult);
            ParseElementAttribute(element, "Filter", () => copy.Filter, ref validationResult, ValidationAction.NotNullOrEmpty("CopyItem - Filter"));
            ParseElementAttribute(element, "Replace", () => copy.Replace, ref validationResult);
            ParseElementAttribute(element, "IsAbsolutePath", () => copy.IsAbsolutePath, ref validationResult);

            return copy;
        }

        private IFileSystemRole FolderDeployCreate(XElement element, DeploymentAction action, ref ValidationResult validationResult)
        {
            var deploy = new FolderDeploy {Action = action, Configuration = DefaultConfig};
            ParseElementAttribute(element, "TargetPath", () => deploy.TargetPath, ref validationResult, ValidationAction.NotNullOrEmpty("FolderDeploy - TargetPath"));
            ParseElementAttribute(element, "IsAbsolutePath", () => deploy.IsAbsolutePath, ref validationResult);

            return deploy;
        }
    }
}