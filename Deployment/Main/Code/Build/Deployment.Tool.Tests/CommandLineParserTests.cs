using System;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace Deployment.Tool.Tests
{
    [TestClass]
    public class CommandLineParserTests
    {
        [TestMethod]
        public void TestParsesCommandLineArgumentsAsArray()
        {
            //arrange
            var parser = new CommandLineParser();

            var args = new[]
                {"-Type", "Pre", "-ConfigFile", "Some Config File","-LocalDebugMode", "-OutputDir", "Some Ouput Dir", "-NonInteractive"};

            var result = parser.Parse(args);

            Assert.IsNotNull(result, "Parser returned null.");
            Assert.IsNotNull(result.Paths, "Parser Paths property was null.");
            Assert.IsTrue(result.Type.Equals("Pre", StringComparison.InvariantCultureIgnoreCase), "Type should be Post");
            Assert.IsTrue(result.NonInteractive, "result.NonInteractive should have been true");
            Assert.IsFalse(string.IsNullOrWhiteSpace(result.Paths.ConfigFileName), "result.Paths.ConfigFileName should not be null or empty.");

        }

        [TestMethod]
        public void TestParsesCommandLineArgumentsAsString()
        {
            //arrange
            var parser = new CommandLineParser();

            var args = new[]
                {"-Type Post -ConfigFile 'Some Config File' -OutputDir 'Some Ouput Dir' -LocalDebugMode"};

            var result = parser.Parse(args);

            Assert.IsNotNull(result, "Parser returned null.");
            Assert.IsNotNull(result.Paths, "Parser Paths property was null.");
            Assert.IsTrue(result.Type.Equals("Post", StringComparison.InvariantCultureIgnoreCase), "Type should be Post");
            Assert.IsFalse(result.NonInteractive, "result.NonInteractive should have been false");
            Assert.IsFalse(string.IsNullOrWhiteSpace(result.Paths.ConfigFileName), "result.Paths.ConfigFileName should not be null or empty.");
            Assert.IsTrue(result.Paths.IsLocalDebugMode, "result.Paths.IsLocalDebugMode should have been true");
        }

        [TestMethod]
        public void TestParsesCommandLineArgumentsGroupsArray()
        {
            //arrange
            var parser = new CommandLineParser();

            var args = new[]
                {"-Type", "Package", "-ConfigFile", "Some Config File", "-Groups", "Group1, Group2, Group3"};

            var result = parser.Parse(args);

            Assert.IsNotNull(result, "Parser returned null.");
            Assert.IsNotNull(result.Paths, "Parser Paths property was null.");
            Assert.IsTrue(result.Type.Equals("Package", StringComparison.InvariantCultureIgnoreCase), "Type should be Post");
            Assert.IsNotNull(result.Groups, "Parser groups returned null.");
            Assert.AreEqual(3, result.Groups.Count, "Groups count should be 3");
            Assert.IsTrue(result.Groups.Contains("Group2"));

        }
    }
}