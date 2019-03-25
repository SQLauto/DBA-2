using System.Collections.Generic;
using Deployment.Domain.Roles;

namespace Deployment.Domain.Operations.Services
{
    public class ConfigurationParameterService
    {
        private readonly IParameterService _parameterService;
        private readonly IDeploymentPathBuilder _deploymentPathBuilder;
        private readonly IList<ICIBasePathBuilder> _ciPathBuilders;

        public ConfigurationParameterService(IParameterService parameterService, IDeploymentPathBuilder deploymentPathBuilder,IList<ICIBasePathBuilder> ciPathBuilders)
        {
            _parameterService = parameterService;
            _deploymentPathBuilder = deploymentPathBuilder;
            _ciPathBuilders = ciPathBuilders;
    }

        public ConfigurationParameters BuildConfigurationParameters(Domain.Deployment deployment, IBaseRole role, IList<ServiceAccount> serviceAccounts)
        {
            var deploymentParameters = _parameterService.ParseDeploymentParameters(_deploymentPathBuilder, deployment.Configuration, role.Configuration, _ciPathBuilders, null);

            var param = new ConfigurationParameters
            {
                RootConfig = deployment.Configuration,
                OverriddenConfigName = role.Configuration,
                EnvironmentName = deployment.Environment,
                ServiceAccounts = serviceAccounts,
                TargetParameters = deploymentParameters
            };

            return param;
        }
    }
}