using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Xml.Linq;
using System.Xml.XPath;
using Deployment.Common;
using Deployment.Common.Logging;
using Deployment.Common.Xml;
using Deployment.Domain.Roles;

namespace Deployment.Domain.Operations.Services
{
    public class DeploymentManifestService : IDeploymentManifestService
    {
        private readonly IDeploymentLogger _logger;
        private readonly IXmlParserService _xmlParser;
        private readonly IRootPathBuilder _pathBuilder;
        private readonly string _packageManifestFilePath;

        public DeploymentManifestService(IRootPathBuilder pathBuilder, IXmlParserService xmlParser, IDeploymentLogger logger)
        {
            _pathBuilder = pathBuilder;
            _xmlParser = xmlParser;
            _logger = logger;
            _packageManifestFilePath = _pathBuilder.PackageManifestFilePath;
        }

        public bool GenerateDeploymentManifest(Deployment deployment, DeploymentServer deploymentServer, DeploymentOperationParameters parameters, string accountsDirectory)
        {
            var manifest = GetDeploymentManifest();

            if(manifest == null)
                throw new NullReferenceException("Unable to get existing or create a new deployment manifest object.");

            //get current max index of existing (if any) packages.
            var index = manifest.Deployments.Count == 0
                ? -1
                : manifest.Deployments.Max(d => d.Index);

            var deploymentInfo = new DeploymentInfo
            {
                Index = ++index,
                IsDatabaseDeployment = parameters.IsDatabaseDeployment,
                PackageInfo =
                {
                    Config = parameters.DeploymentConfigFileName,
                    Environment = deployment.Environment,
                    Groups = parameters.Groups,
                    Servers = parameters.Servers,
                    Name = Path.GetFileName(parameters.PackageFileName)
                },
                ServerInfo =
                {
                    Name = deploymentServer.Name,
                    ExternalIP = deploymentServer.ExternalIpAddress
                }
            };

            if (!string.IsNullOrWhiteSpace(parameters.PackageDeploymentAccount))
            {
                _logger?.WriteLine("DeploymentAccount has been set. Getting account info from ServiceAccounts file.");
                var serviceAccountsFileName = $"{deployment.Environment}.ServiceAccounts.xml";
                var serviceAccountsFilePath = Path.Combine(accountsDirectory, serviceAccountsFileName);
                var manager = new ServiceAccountsManager(parameters.Password, _logger);

                var deploymentAccount = manager.GetServiceAccount(serviceAccountsFilePath, parameters.PackageDeploymentAccount);
                if (deploymentAccount == null)
                {
                    _logger?.WriteError($"Unable to find deployment service account {parameters.PackageDeploymentAccount} for package manifest");
                    return false;
                }

                var accountInfo = new DeploymentAccountInfo
                {
                    Name = deploymentAccount.QualifiedUsername,
                    Password = deploymentAccount.EncryptedPassword
                };

                deploymentInfo.AccountInfo = accountInfo;
            }

            var packageAlreadyExists =
                manifest.Deployments.Any(x => x.PackageInfo.Config == deploymentInfo.PackageInfo.Config && x.PackageInfo.Name == deploymentInfo.PackageInfo.Name);

            if (packageAlreadyExists)
            {
                _logger?.WriteLine(
                    $"Deployment of Package [{deploymentInfo.PackageInfo.Name}] has already been added to Manifest. Skipping add.");
            }
            else
            {
                manifest.Deployments.Add(deploymentInfo);
            }

            var xmlToOutput = new StringBuilder();
            xmlToOutput.AppendLine("<?xml version='1.0' encoding='UTF-8'?>");
            xmlToOutput.Append(ConvertToManifestXml(manifest));

            File.WriteAllText(_packageManifestFilePath, xmlToOutput.ToString(), Encoding.UTF8);

            return true;
        }

        public bool UpdateDeploymentManifest(DeploymentManifest currentDeploymentManifest)
        {
            var xmlToOutput = new StringBuilder();
            xmlToOutput.Append(ConvertToManifestXml(currentDeploymentManifest));

            File.WriteAllText(_packageManifestFilePath, xmlToOutput.ToString(), Encoding.UTF8);

            return true;
        }

        public DeploymentManifest GetDeploymentManifest()
        {
            _logger?.WriteLine("Determining if Deployment Manifest file already exists.");

            if (!File.Exists(_packageManifestFilePath))
            {
                _logger?.WriteLine($"Deployment manifest {_packageManifestFilePath} does not exist. Creating new.");
                return new DeploymentManifest();
            }

            _logger?.WriteLine($"Deployment manifest {_packageManifestFilePath} exists. Appending.");

            return ParseManifestXml();
        }

        public DeploymentManifest ParseManifestXml()
        {
            if (!File.Exists(_packageManifestFilePath))
            {
                _logger?.WriteError($"Deployment manifest {_packageManifestFilePath} does not exist.");
                return null;
            }

            var rootNode = XElement.Parse(File.ReadAllText(_packageManifestFilePath));

            var result = new ValidationResult();

            //TODO: Allow override of root path?
            var manifest = new DeploymentManifest {RootPath = @"D:\Deploy"};

            var deploymentElements = rootNode.XPathSelectElements("//Deployment").ToList();
            if (!deploymentElements.Any())
            {
                result.AddError("There are no Deployment elements with this package there must be atleast 1");
            }

            foreach (var element in deploymentElements)
            {
                var deployment = new DeploymentInfo();

                _xmlParser.ParseElementAttribute(element, "Index", () => deployment.Index, ref result, ValidationAction.EqualToOrGreaterThanZero("DeploymentManifest - Index"));
                _xmlParser.ParseElementAttribute(element, "IsDatabaseDeployment", () => deployment.IsDatabaseDeployment, ref result);

                var packageElement = element.XPathSelectElement("Package");
                _xmlParser.ParseElementAttribute(packageElement, "Name", () => deployment.PackageInfo.Name, ref result, ValidationAction.NotNullOrEmpty("DeploymentManifest - Name"));
                _xmlParser.ParseElementAttribute(packageElement, "Config", () => deployment.PackageInfo.Config, ref result, ValidationAction.NotNullOrEmpty("DeploymentManifest - Config"));
                _xmlParser.ParseElementAttribute(packageElement, "Environment", () => deployment.PackageInfo.Environment, ref result, ValidationAction.NotNullOrEmpty("DeploymentManifest - Environment"));
                _xmlParser.ParseElementAttribute(packageElement, "Groups", deployment.PackageInfo.Groups, ref result);
                _xmlParser.ParseElementAttribute(packageElement, "Servers", deployment.PackageInfo.Servers, ref result);

                var serverElement = element.XPathSelectElement("DeploymentServer");
                _xmlParser.ParseElementAttribute(serverElement, "Name", () => deployment.ServerInfo.Name, ref result, ValidationAction.NotNullOrEmpty("DeploymentManifest - Name"));
                _xmlParser.ParseElementAttribute(serverElement, "ExternalIP", () => deployment.ServerInfo.ExternalIP, ref result);
                _xmlParser.ParseElementAttribute(serverElement, "DeploymentTempPath", () => deployment.ServerInfo.DeploymentTempPath, ref result);

                var accountElement = element.XPathSelectElement("DeploymentAccount");
                _xmlParser.ParseElementAttribute(accountElement, "Name", () => deployment.AccountInfo.Name, ref result);
                _xmlParser.ParseElementAttribute(accountElement, "Password", () => deployment.AccountInfo.Password, ref result);

                manifest.Deployments.Add(deployment);
            }

            if (result.Result)
                return manifest;

            _logger.WriteSummary("Unable to parse deployment manifest file.", LogResult.Error);

            var builder = new StringBuilder();
            result.ValidationErrors.ForEach(x => builder.AppendLine(x));
            _logger.WriteError(builder.ToString());
            return null;
        }

        public XElement ConvertToManifestXml(DeploymentManifest manifest)
        {
            var root = new XElement("Deployments");
            root.AddAttribute("RootDirectory", manifest.RootPath);

            foreach (var deploymentInfo in manifest.Deployments)
            {
                var deploymentElement = new XElement("Deployment");
                deploymentElement.AddAttribute("Index", deploymentInfo.Index)
                    .AddAttribute("IsDatabaseDeployment", deploymentInfo.IsDatabaseDeployment);

                var packageElement = new XElement("Package");
                packageElement.AddAttribute("Name", deploymentInfo.PackageInfo.Name)
                    .AddAttribute("Config", deploymentInfo.PackageInfo.Config)
                    .AddAttribute("Environment", deploymentInfo.PackageInfo.Environment)
                    .AddAttribute("Groups", JoinList(deploymentInfo.PackageInfo.Groups))
                    .AddAttribute("Servers", JoinList(deploymentInfo.PackageInfo.Servers));

                deploymentElement.Add(packageElement);

                var serverElement = new XElement("DeploymentServer");
                serverElement.AddAttribute("Name", deploymentInfo.ServerInfo.Name ?? string.Empty)
                    .AddAttribute("ExternalIP", deploymentInfo.ServerInfo.ExternalIP ?? string.Empty)
                    .AddAttribute("DeploymentTempPath", deploymentInfo.ServerInfo.DeploymentTempPath ?? string.Empty);

                deploymentElement.Add(serverElement);

                var accountElement = new XElement("DeploymentAccount");
                accountElement.AddAttribute("Name", deploymentInfo.AccountInfo.Name ?? string.Empty)
                    .AddAttribute("Password", deploymentInfo.AccountInfo.Password ?? string.Empty);

                deploymentElement.Add(accountElement);

                root.Add(deploymentElement);
            }

            return root;
        }

        private string JoinList(IList<string> list)
        {
            return list.IsNullOrEmpty() ? string.Empty : string.Join(",", list);
        }
    }
}