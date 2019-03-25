using System.Collections.Generic;

namespace Deployment.Domain.Operations
{
    public interface IDeploymentFilterService
    {
        Deployment FilterByMachine(Deployment source, IList<string> machines);
        Deployment FilterByGroup(Deployment source, GroupFilters groupFilters);
        Deployment ProcessDatabaseInstances(Deployment deployment);
    }
}