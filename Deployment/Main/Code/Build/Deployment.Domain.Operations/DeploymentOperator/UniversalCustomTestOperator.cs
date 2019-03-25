using Deployment.Common;
using Deployment.Common.Logging;
using Deployment.Domain.Roles;

namespace Deployment.Domain.Operations.DeploymentOperator
{
    public class UniversalCustomTestOperator
    {
        private readonly IDeploymentLogger _logger;

        public UniversalCustomTestOperator(IDeploymentLogger logger)
        {
            _logger = logger;
        }

        public bool RunTest(dynamic obj, Machine machine, PostDeployParameters parameters)
        {
            return false;
        }

        public bool RunTest(AppFabricTest test, Machine machine, PostDeployParameters parameters)
        {
            var result = true;

            var deployOperator = new AppFabricTestOperator();

            if (parameters.TargetPlatform == DeploymentPlatform.VCloud)
                result = SetExternalAddress(test, machine);

            return result & deployOperator.RunTest(test, machine, parameters, _logger);
        }

        public bool RunTest(ServiceBrokerTest test, Machine machine, PostDeployParameters parameters)
        {
            var result = true;

            var deployOperator = new ServiceBrokerTestOperator();

            if (parameters.TargetPlatform == DeploymentPlatform.VCloud)
                result = SetExternalAddress(test, machine);

            return result & deployOperator.RunTest(test, machine, parameters, _logger);
        }

        private bool SetExternalAddress(ServiceBrokerTest test, Machine machine)
        {
            foreach (var sqlTestPart in test.Tests)
            {
                sqlTestPart.DatabaseServer = machine.ExternalIpAddress;
            }

            return true;
        }

        private bool SetExternalAddress(AppFabricTest test, Machine machine)
        {
            test.HostName = machine.ExternalIpAddress;
            return true;
        }
    }
}