using Deployment.Common;
using Deployment.Domain.Operations;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Moq;

namespace Deployment.Tool.Tests
{
    [TestClass]
    public class ConsoleHarnessTests
    {
        [TestMethod]
        public void TestForNullTaskType()
        {
            //arrange
            var parameters = new DeploymentOperationParameters();
            var mock = new Mock<ICommandLineParser>();
            mock.Setup(m => m.Parse(null)).Returns(parameters);
            mock.Setup(m => m.GetHelp()).Returns(string.Empty);

            var harness = new ConsoleHarness(mock.Object);

            //act
            var result = harness.Initialise(null);

            Assert.IsTrue(result == ConsoleResult.InvalidArgs);
        }

        [TestMethod]
        public void TestForEmptyTaskType()
        {
            //arrange
            var parameters = new DeploymentOperationParameters { TaskType = DeploymentTaskType.None};
            var mock = new Mock<ICommandLineParser>();
            mock.Setup(m => m.Parse(null)).Returns(parameters);
            mock.Setup(m => m.GetHelp()).Returns(string.Empty);

            var harness = new ConsoleHarness(mock.Object);

            //act
            var result = harness.Initialise(null);

            Assert.IsTrue(result == ConsoleResult.InvalidArgs);
        }

        [TestMethod]
        public void TestForInvalidTaskType()
        {
            //arrange
            var parameters = new DeploymentOperationParameters { TaskType = DeploymentTaskType.None };
            var mock = new Mock<ICommandLineParser>();
            mock.Setup(m => m.Parse(null)).Returns(parameters);
            mock.Setup(m => m.GetHelp()).Returns(string.Empty);

            var harness = new ConsoleHarness(mock.Object);

            //act
            var result = harness.Initialise(null);

            Assert.IsTrue(result == ConsoleResult.InvalidArgs);
        }
    }
}