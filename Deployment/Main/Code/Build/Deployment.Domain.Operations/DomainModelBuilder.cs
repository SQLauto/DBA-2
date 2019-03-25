using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Xml.Linq;
using System.Xml.XPath;
using Deployment.Common;
using Deployment.Common.Helpers;
using Deployment.Common.Logging;
using Deployment.Domain.Operations.DomainModelFactory;
using Deployment.Common.Xml;
using Deployment.Domain.Operations.Services;
using Deployment.Domain.Roles;

namespace Deployment.Domain.Operations
{
    public class DomainModelBuilder : XmlParserBase
    {
        private readonly IDomainModelValidator _validator;
        private readonly string _deploymentConfiguration;
        private readonly IDomainModelFactoryBuilder _factoryBuilder;
        private readonly IDeploymentPathBuilder _deploymentPathBuilder;
        private readonly IList<ICIBasePathBuilder> _ciPathBuilders;
        private readonly IParameterService _parameterService;
        private readonly IDictionary<string, CommonRoleInfo> _commonIncludes = new Dictionary<string, CommonRoleInfo>();
        private readonly IDeploymentLogger _logger;

        public DomainModelBuilder(IDomainModelValidator validator, IDomainModelFactoryBuilder factoryBuilder, IDeploymentPathBuilder deploymentPathBuilder,
                                        IList<ICIBasePathBuilder> ciPathBuilders, IParameterService parameterService, IDeploymentLogger logger)
        {
            ArgumentHelper.AssertNotNull(validator, nameof(validator));
            ArgumentHelper.AssertNotNull(factoryBuilder, nameof(factoryBuilder));
            ArgumentHelper.AssertNotNull(deploymentPathBuilder, nameof(deploymentPathBuilder));
            ArgumentHelper.AssertNotNull(ciPathBuilders, nameof(ciPathBuilders));
            ArgumentHelper.AssertNotNull(parameterService, nameof(parameterService));

            _validator = validator;
            _factoryBuilder = factoryBuilder;
            _deploymentPathBuilder = deploymentPathBuilder;
            _ciPathBuilders = ciPathBuilders;
            _parameterService = parameterService;
            _logger = logger;
            _deploymentConfiguration = deploymentPathBuilder.DeploymentConfigFilePath;
        }

        public Deployment BuildDomain()
        {
            _validator.ValidateDomainModelFile(_deploymentConfiguration);

            var fileParseResult = ParseDomainModelFile();
            var domainModelFactories = _factoryBuilder.GetFactories(fileParseResult.Config);

            var commonIncludeFiles = ProcessCommonIncludes(fileParseResult, domainModelFactories);

            var deployment = DeploymentCreate(fileParseResult, commonIncludeFiles);

            foreach (var machineElement in fileParseResult.Machines)
            {
                var machine = MachineCreate(machineElement, fileParseResult.Config);

                deployment.Machines.Add(machine);
            }

            _validator.ValidateMachineCreation(deployment.Machines);

            var deploymentFilter = new DeploymentFilterService(_logger);

            deploymentFilter.ProcessDatabaseInstances(deployment);

            ProcessCustomTests(deployment, fileParseResult, domainModelFactories);

            //TODO: Service Dependencies

            return deployment;

        }

        private IList<string> ProcessCommonIncludes(DeploymentFileParseResult fileParseResult, IList<IDomainModelFactory> domainModelFactories)
        {
            var validationResult = _validator.ValidationResult;

            _logger?.WriteLine("Processing Common Includes.");

            var commonIncludeFiles = new List<string>();

            var rootDirectory = Path.GetDirectoryName(_deploymentConfiguration);

            //validate all common files are found first
            foreach (var commonRoleInclude in fileParseResult.CommonRoleIncludes)
            {
                var commonFileName = commonRoleInclude.Element.Value;
                if (rootDirectory == null)
                    continue;

                var commonIncludeFile = Path.Combine(rootDirectory, commonFileName);

                if (!File.Exists(commonIncludeFile))
                {
                    validationResult.AddError($"Common include file '{commonFileName}' was not found.");
                    continue;
                }

                commonIncludeFiles.Add(commonIncludeFile);
            }

            _validator.ValidateCommonIncludes();

            foreach (var commonRoleInclude in commonIncludeFiles)
            {
                var include = XElement.Load(commonRoleInclude);
                var xpathExpression = $"{Namespaces.CommonRole.Prefix}:CommonRoles/*";
                var commonRoles = include.XPathSelectElements(xpathExpression, Namespaces.NamespaceManager);

                //process the file
                foreach (var commonRole in commonRoles)
                {
                    var factoryOfInterest = domainModelFactories.FirstOrDefault(f => f.IsResponsibleFor(commonRole));
                    if (factoryOfInterest == null)
                    {
                        validationResult.AddError($"No factory was found for processing ServerRole '{ commonRole.ReadAttribute<string>("Name")}' with Include value '{commonRole.ReadAttribute<string>("Name")}'.");
                        continue;
                    }

                    var role = factoryOfInterest.DomainModelCreate(commonRole, ref validationResult);

                    if (role == null)
                        continue;

                    if (_commonIncludes.ContainsKey(role.Include))
                    {
                        validationResult.AddError($"Common include role '{role.Include}' is defined multiple times. This is not allowed.");
                        continue;
                    }

                    _commonIncludes.Add(role.Include, new CommonRoleInfo(role, factoryOfInterest));
                }
            }

            _validator.ValidateCommonIncludes();

            return commonIncludeFiles;
        }

        private Machine MachineCreate(ParseElement machineElement, string defaultConfig)
        {
            var validationResult = _validator.ValidationResult;

            var parseResult = MachineParseElement(machineElement, ref validationResult);

            var machine = parseResult.Machine;

            foreach (var roleElement in parseResult.Roles)
            {
                var includeKey = roleElement.ReadAttribute<string>("Include");

                if (string.IsNullOrWhiteSpace(includeKey))
                {
                    validationResult.AddError($"Machine '{machine.Name}' role '{machine.Role}' does not have an Include attribute");
                    continue;
                }

                if (!_commonIncludes.ContainsKey(includeKey))
                {
                    validationResult.AddError($"Machine '{machine.Name}' contains an invalid Include attribute '{includeKey}'");
                    continue;
                }

                var commonRoleInfo = _commonIncludes[includeKey];

                var factory = commonRoleInfo.Factory;

                if (factory == null)
                    continue;

                var role = factory.ApplyOverrides(commonRoleInfo.CommonRole, roleElement, ref validationResult);

                //TODO: When we update parameters for each role/machine we end up parsing the parameters multiple times.
                //What we should do is keep a cache.  For a given override we should see if we already have parsed and cached the parameters, if we do, then use them
                //otherwise parse them, cache them, then use them.  So we should pass in params not the service etc.
                //e.g. var x = cache.params(role.Configuration);if(param==null) params =
                //_parameterService.ParseDeploymentParameters(_deploymentPathBuilder, defaultConfig,
                //    role.Configuration, _ciPathBuilders, null);  etc.

                role = factory.UpdateParameterisedValues(role, _parameterService, _deploymentPathBuilder, _ciPathBuilders, ref validationResult);

                machine.AddRole(role);
            }

            return machine;
        }

        private void ProcessCustomTests(Deployment deployment, DeploymentFileParseResult fileParseResult, IList<IDomainModelFactory> domainModelFactories)
        {
            var validationResult = _validator.ValidationResult;
            _logger?.WriteLine("Processing Custom Tests.");

            foreach (var customTest in fileParseResult.CustomTests)
            {
                var factoryOfInterest = domainModelFactories.FirstOrDefault(f => f.IsResponsibleFor(customTest.Element));
                if (factoryOfInterest == null)
                {
                    validationResult.AddError($"No factory was found for processing CustomTest '{customTest.Element.Name}'.");
                    continue;
                }

                var role = factoryOfInterest.DomainModelCreate(customTest.Element, ref validationResult);

                if (role != null)
                {
                    deployment.CustomTests.Add(role as ICustomTest);
                }
            }
        }

        private MachineParseResult MachineParseElement(ParseElement machineElement, ref ValidationResult validationResult)
        {
            var machine = new Machine();
            ParseElementAttribute(machineElement.Element, "Id", () => machine.Id, ref validationResult);
            ParseElementAttribute(machineElement.Element, "Name", () => machine.Name, ref validationResult);
            ParseElementAttribute(machineElement.Element, "ExternalIP", () => machine.ExternalIpAddress, ref validationResult);
            ParseElementAttribute(machineElement.Element, "Role", () => machine.Role, ref validationResult);
            ParseElementAttribute(machineElement.Element, "DeploymentMachine", () => machine.DeploymentMachine, ref validationResult);
            ParseElementAttribute(machineElement.Element, "Cluster", () => machine.Cluster, ref validationResult);

            var children = machineElement.Element.Descendants();
            var parseResult = new MachineParseResult { Machine = machine };
            parseResult.Roles.AddRange(children);

            return parseResult;
        }

        private Deployment DeploymentCreate(DeploymentFileParseResult fileParseResult, IList<string> commonIncludeFiles)
        {
            var deployment = new Deployment
            {
                Configuration = fileParseResult.Config,
                Environment = fileParseResult.Environment,
                Id = fileParseResult.Id,
                Name = fileParseResult.Name,
                ProductGroup = fileParseResult.ProductGroup,
            };

            deployment.CommonRoleFiles.AddRange(commonIncludeFiles);

            return deployment;
        }

        private DeploymentFileParseResult ParseDomainModelFile()
        {
            _logger?.WriteLine("Parsing domain model file.");
            var deploymentFileParser = new DeploymentFileParser(_validator.ValidationResult, _logger);
            var fileParseResult = deploymentFileParser.ParseDeploymentFile(_deploymentConfiguration);
            _validator.ValidateDeploymentFileParser();
            return fileParseResult;
        }
    }
}