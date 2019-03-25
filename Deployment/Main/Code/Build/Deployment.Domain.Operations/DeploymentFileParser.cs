using System.Collections.Generic;
using System.Xml.Linq;
using Deployment.Common;
using Deployment.Common.Helpers;
using Deployment.Common.Logging;
using Deployment.Domain.Operations.DomainModelFactory;

namespace Deployment.Domain.Operations
{
    public sealed class DeploymentFileParser : XmlParserBase, IDeploymentFileParser
    {
        private readonly ValidationResult _validationResult;
        private readonly IDeploymentLogger _logger;

        public DeploymentFileParser(ValidationResult validationResult, IDeploymentLogger logger = null)
        {
            _validationResult = validationResult;
            _logger = logger;
        }

        public DeploymentFileParseResult ParseDeploymentFile(string deploymentConfigFile)
        {
            ArgumentHelper.AssertNotNullOrEmpty(deploymentConfigFile, nameof(deploymentConfigFile));

            var parseResult = new DeploymentFileParseResult(_validationResult);
            var domainModel = XElement.Load(deploymentConfigFile);

            ParseRootAttributes(domainModel, parseResult);
            ParseSection(domainModel, ParseElements.CommonRoleFile, parseResult.CommonRoleIncludes);
            ParseSection(domainModel, ParseElements.Machine, parseResult.Machines);

            ParseTestIdentity(domainModel, parseResult);
            ParseCustomTests(domainModel, parseResult);

            return parseResult;
        }

        private int ParseSection(XElement domainModel, string section, IList<ParseElement> parseElements, int ordinalSeed = 0)
        {
            var elements = domainModel.Elements(Namespaces.DeploymentConfig.XmlNamespace + section);
            var ordinal = ordinalSeed;

            foreach (var element in elements)
            {
                var parseElement = new ParseElement(element, ordinal);
                parseElements.Add(parseElement);
                ordinal++;
            }

            return ordinal;
        }

        private void ParseCustomTests(XElement domainModel, DeploymentFileParseResult parseResult)
        {
            var customTests = domainModel.Element(Namespaces.DeploymentConfig.XmlNamespace + ParseElements.CustomTests);
            if (customTests == null)
            {
                return;
            }

            var seed = ParseSection(customTests, ParseElements.ServiceBrokerTest, parseResult.CustomTests);
            ParseSection(customTests, ParseElements.AppFabricTest, parseResult.CustomTests, seed);
        }

        private void ParseTestIdentity(XElement domainModel, DeploymentFileParseResult parseResult)
        {
            var testIdentity = domainModel.Element(Namespaces.DeploymentConfig.XmlNamespace + ParseElements.PostDeploymentTestIdentity);
            if (testIdentity == null)
            {
                return;
            }

            parseResult.PostDeploymentTestAccount = testIdentity.Value;
        }

        private void ParseRootAttributes(XElement domainModel, DeploymentFileParseResult parseResult)
        {
            var validationResult = parseResult.ValidationResult;
            ParseElementAttribute(domainModel, "Id", () => parseResult.Id, ref validationResult);
            ParseElementAttribute(domainModel, "Name", () => parseResult.Name, ref validationResult);
            ParseElementAttribute(domainModel, "Environment", () => parseResult.Environment, ref validationResult, ValidationAction.NotNullOrEmpty("DeploymentFileParser - Environment"));
            ParseElementAttribute(domainModel, "Config", () => parseResult.Config, ref validationResult, ValidationAction.NotNullOrEmpty("DeploymentFileParser - Config"));
            ParseElementAttribute(domainModel, "ProductGroup", () => parseResult.ProductGroup, ref validationResult, ValidationAction.NotNullOrEmpty("DeploymentFileParser - ProductGroup"));
        }
    }

    public interface IDeploymentFileParser
    {
        DeploymentFileParseResult ParseDeploymentFile(string deploymentConfigFile);
    }
}