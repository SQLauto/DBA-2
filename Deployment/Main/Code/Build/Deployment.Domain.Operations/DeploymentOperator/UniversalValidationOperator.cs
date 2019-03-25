using Deployment.Common.Logging;
using Deployment.Domain.Roles;
using System.Collections.Generic;

namespace Deployment.Domain.Operations.DeploymentOperator
{
    public class UniversalValidationOperator
    {
        private readonly IDomainOperatorFactory _operatorFactory;
        private readonly IDeploymentLogger _logger;

        public UniversalValidationOperator(IDomainOperatorFactory operatorFactory, IDeploymentLogger logger)
        {
            _operatorFactory = operatorFactory;
            _logger = logger;
        }

        public bool PreDeploymentValidate<T>(T role, ConfigurationParameters parameters, List<string> outputLocations, string deploymentAddress) where T : IBaseRole
        {
            var result = _operatorFactory.GetOperator<T>()?.PreDeploymentValidate(role, parameters, outputLocations);

            if (!result.HasValue)
                return true;

            if (!result.Value)
                _logger?.WriteSummary($"Pre-Validation failed for role [{role.Include}] with description [{role.Description}] on machine [{deploymentAddress}]", LogResult.Fail);

            return result.Value;
        }

        public bool PostDeploymentValidate<T>(T role, PostDeployParameters postDeployParameters) where T : IBaseRole
        {
            var result = _operatorFactory.GetOperator<T>()?.PostDeploymentValidate(postDeployParameters, role);

            return !result.HasValue || result.Value;
        }
    }
}