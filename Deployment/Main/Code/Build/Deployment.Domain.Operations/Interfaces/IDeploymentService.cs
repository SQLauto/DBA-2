using System;
using System.Collections.Generic;
using Deployment.Domain.Roles;
using Deployment.Common;

namespace Deployment.Domain.Operations
{
    public interface IDeploymentService
    {
        string ConvertDeployRoleToXml(IBaseRole role);
        IBaseRole ConverXmlToDeployRole(string sourceXml, Type type);
        Deployment GetDeployment(string rootPath, string deploymentFile);
        Deployment GetDeployment(IDomainModelValidator validator, IDomainModelFactoryBuilder factoryBuilder,
            IDeploymentPathBuilder deploymentPathBuilder, IList<ICIBasePathBuilder> ciPathBuilders);
        Deployment GetDeployment(Deployment baseDeployment, Type type);
        Deployment FilterDeployment(Deployment source, IList<string> machines, GroupFilters groups);
        IList<string> ParseGroups(string filePath);
        Deployment GetMsiDeployments(Deployment deployment);
        Deployment GetServiceDeployments(Deployment deployment);
        Deployment GetWebDeployments(Deployment deployment);
        Deployment GetScheduledTaskDeployments(Deployment deployment);
        bool ValidateDeploymentConfig(string path);
        GroupFilters ValidateGroups(IList<string> groups, string filePath);
        Deployment GetVirtualIPAddresses(Deployment deployment, string rigName, DeploymentPlatform targetPlatform);
    }
}