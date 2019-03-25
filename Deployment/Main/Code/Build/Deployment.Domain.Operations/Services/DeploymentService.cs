using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Xml.Linq;
using Deployment.Common;
using Deployment.Common.Helpers;
using Deployment.Common.Logging;
using Deployment.Common.Xml;
using Deployment.Common.VCloud;
using Deployment.Domain.Roles;

namespace Deployment.Domain.Operations.Services
{
    public class DeploymentService : IDeploymentService
    {
        private readonly IParameterService _parameterService;
        private readonly IDeploymentLogger _logger;
        private readonly bool _isLocalDebug;

        public DeploymentService(IDeploymentLogger logger, IParameterService parameterService = null, bool isLocalDebug = false)
        {
            _logger = logger;
            _parameterService = parameterService ?? new ParameterService(logger);
            _isLocalDebug = isLocalDebug;
        }

        public Deployment GetDeployment(IDomainModelValidator validator, IDomainModelFactoryBuilder factoryBuilder, IDeploymentPathBuilder deploymentPathBuilder, IList<ICIBasePathBuilder> ciPathBuilders)
        {
            var builder = new DomainModelBuilder(validator, factoryBuilder, deploymentPathBuilder, ciPathBuilders, _parameterService, _logger);
            return builder.BuildDomain();
        }

        public Deployment GetDeployment(string rootPath, string deploymentFile)
        {
            var rootPathBuilder = new RootPathBuilder(rootPath, _logger);
            DeploymentPathBuilder deploymentPathBuilder;
            var ciPathBuilders = new List<ICIBasePathBuilder>();

            if (Directory.Exists(rootPathBuilder.CIRelativeDirectory))
            {
                deploymentPathBuilder = new DeploymentPathBuilder(Path.Combine(rootPathBuilder.CIRelativeDirectory, "Deployment"), deploymentFile, _logger) {IsLocalDebugMode = _isLocalDebug};

                ciPathBuilders.AddRange(Directory.EnumerateDirectories(rootPathBuilder.CIRelativeDirectory).Where(d => !d.Contains("Deployment"))
                    .Select(directory => new CIBasePathBuilder(directory, _logger) { IsLocalDebugMode = _isLocalDebug }));
            }
            else
            {
                deploymentPathBuilder = new DeploymentPathBuilder(rootPathBuilder.RootDirectory, deploymentFile, _logger) { IsLocalDebugMode = _isLocalDebug };
                ciPathBuilders.Add(new CIBasePathBuilder(rootPathBuilder.RootDirectory, _logger) { IsLocalDebugMode = _isLocalDebug });
            }

            return GetDeployment(new DomainModelValidator(_logger), new DomainModelFactoryBuilder(), deploymentPathBuilder, ciPathBuilders);
        }

        public Deployment GetDeployment(Deployment baseDeployment, Type type)
        {
            var deployment = new Deployment(baseDeployment);

            var machines = baseDeployment.Machines.Where(m => m.AllRoles().Any()).Select(m =>
            {
                var machine = new Machine(m);

                var validRoles = m.DeploymentRoles.RemoveAll(r => r.GetType() != type);

                machine.AddRoles(validRoles);

                return machine;
            });

            deployment.Machines.AddRange(machines.Where(m=>m.AllRoles().Any()));

            return deployment;
        }

        public Deployment GetWebDeployments(Deployment deployment)
        {
            var retVal = GetDeployment(deployment, typeof(WebDeploy));
            retVal.ClearSqlInstances();
            return retVal;
        }

        public Deployment GetServiceDeployments(Deployment deployment)
        {
            var retVal = GetDeployment(deployment, typeof(ServiceDeploy));
            retVal.ClearSqlInstances();
            return retVal;
        }

        public Deployment GetMsiDeployments(Deployment deployment)
        {
            var retVal = GetDeployment(deployment, typeof(MsiDeploy));
            retVal.ClearSqlInstances();
            return retVal;
        }

        public Deployment GetScheduledTaskDeployments(Deployment deployment)
        {
            var retVal = GetDeployment(deployment, typeof(ScheduledTaskDeploy));
            retVal.ClearSqlInstances();
            return retVal;
        }

        public Deployment FilterDeployment(Deployment source, IList<string> machines, GroupFilters groups)
        {
            if(groups == null)
                throw new ArgumentNullException(nameof(groups));

            var deploymentFilter = new DeploymentFilterService(_logger);

            var deployment = deploymentFilter.FilterByGroup(deploymentFilter.FilterByMachine(source, machines), groups);

            deployment.ClearSqlInstances();
            deploymentFilter.ProcessDatabaseInstances(deployment);

            return deployment;
        }

        public bool ValidateDeploymentConfig(string path)
        {
            var validator = new DomainModelValidator(_logger);
            var result = validator.ValidateDomainModelFile(path);

            foreach (var error in validator.ValidationResult.ValidationErrors)
            {
                _logger?.WriteError(error);
            }

            //TODO: Do we want to do anything with ValidationErrors (in Validator) if any?

            return result;
        }

        public GroupFilters ValidateGroups(IList<string> groups, string filePath)
        {
            if (groups.IsNullOrEmpty())
                return new GroupFilters();

            var groupInfo = ParseGroups(filePath);

            var includeGroups = groups.Where(g => !g.StartsWith("!")).ToList();
            var excludeGroups = groups.Where(g => g.StartsWith("!")).Select(g=>g.TrimStart('!')).ToList();

            var valid = groupInfo.Intersect(includeGroups).CountEqualTo(includeGroups.Count)
                && groupInfo.Intersect(excludeGroups).CountEqualTo(excludeGroups.Count);

            return valid ? new GroupFilters(includeGroups, excludeGroups) : null;
        }

        public IList<string> ParseGroups(string filePath)
        {
            ArgumentHelper.AssertNotNullOrEmpty(filePath, "filePath");

            if (!File.Exists(filePath))
                throw new FileNotFoundException($"Group file {filePath} was not found.");

            var groupXml = XElement.Load(filePath);

            var elements = groupXml.Elements("Group");
            //TODO: Determine if this is null

            var groupInfo = elements.Select(e => e.Value).OrderBy(g=>g).ToList();

            return groupInfo;
        }

        public string ConvertDeployRoleToXml(IBaseRole role)
        {
            return XmlHelper.ToXml(role);
        }

        public IBaseRole ConverXmlToDeployRole(string sourceXml, Type type)
        {
            return XmlHelper.FromXml<IBaseRole>(sourceXml, type);
        }

        public Deployment GetVirtualIPAddresses(Deployment deployment, string rigName, DeploymentPlatform targetPlatform)
        {
            var virtualPlatformFactory = new VirtualPlatformFactory(targetPlatform);
            var virtualPlatform = virtualPlatformFactory.GetTargetVirtualPlatform();

            var machineNames = deployment.Machines.Select(m => m.Name).ToList();

            var externalIPAddresses = virtualPlatform.GetExternalIpAdresses(rigName, machineNames, _logger);

            foreach(var machine in deployment.Machines)
            {
                if(!externalIPAddresses.ContainsKey(machine.Name))
                {
                    _logger?.WriteError($"Unable to obtain external IP address for machine: [{machine.Name}]");
                    throw new Exception($"Unable to obtain external IP address for machine: [{machine.Name}]");
                }

                machine.ExternalIpAddress = externalIPAddresses[machine.Name];
            }

            return deployment;
        }
    }
}