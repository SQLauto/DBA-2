using Deployment.Domain.Operations.DeploymentOperator;
using Deployment.Domain.Operations.Services;
using Deployment.Domain.Roles;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace Deployment.Domain.Operations.Tests
{
    [TestClass]
    public class OperatorFactoryTests
    {
        public TestContext TestContext { get; set; }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        public void TestCreatesValidOperator()
        {
            var logger = new TestContextLogger(TestContext);

            var parameterService = new ParameterService(logger);

            var factory = new DomainOperatorFactory(parameterService, logger);

            var testy = factory.GetOperator<DatabaseDeploy>();

            Assert.IsNotNull(testy);
            Assert.IsInstanceOfType(testy, typeof(DatabaseDeployOperator));
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        public void TestInvalidOperatorReturnsNull()
        {
            var logger = new TestContextLogger(TestContext);

            var parameterService = new ParameterService(logger);

            var factory = new DomainOperatorFactory(parameterService, logger);

            var testy = factory.GetOperator<IisSetupDeploy>();

            Assert.IsNull(testy);
        }
    }
}