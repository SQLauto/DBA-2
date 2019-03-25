using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using Deployment.Common.Helpers;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Tfl.Module.Testing;
using TFL.Utilities.Commands;

namespace TFL.Utilities.Module.Tests
{
    [TestClass]
    public class GetGacAssemblyCommandTests
    {
        [TestMethod]
        [TestCategory("GetGacAssemlby")]
        public void TestReturnsListWithoutFiltering()
        {
            var result = PsCmdletAssert.Invoke(typeof(GetGacAssemblyCommand), null);

            Assert.IsNotNull(result);

            Assert.IsTrue(result.Count == 1);

            var output = ((IEnumerable<AssemblyName>)result[0].BaseObject).ToList();

            Assert.IsNotNull(output);
            Assert.IsTrue(output.Count > 1);
        }

        [TestMethod]
        [TestCategory("GetGacAssemlby")]
        public void TestReturnsListFilterBySingleName()
        {
            var result = PsCmdletAssert.Invoke(typeof(GetGacAssemblyCommand), new[] { new Parameter("Name", "mscorlib")});

            Assert.IsNotNull(result);
            Assert.IsTrue(result.Count == 1);

            var output = ((IEnumerable<AssemblyName>)result[0].BaseObject).ToList();

            //should return 1 or more assemblies
            Assert.IsNotNull(output);
            Assert.IsTrue(output.Count > 0);
        }

        [TestMethod]
        [TestCategory("GetGacAssemlby")]
        public void TestReturnsListFilterBySingleNameLatestOnly()
        {
            var result = PsCmdletAssert.Invoke(typeof(GetGacAssemblyCommand), new[] { new Parameter("Name", "mscorlib"), new Parameter("Latest", true) });

            Assert.IsNotNull(result);
            Assert.IsTrue(result.Count == 1);

            var output = ((IEnumerable<AssemblyName>)result[0].BaseObject).ToList();

            //should return 1 assembly only
            Assert.IsNotNull(output);
            Assert.AreEqual(1, output.Count);
        }

        [TestMethod]
        [TestCategory("GetGacAssemlby")]
        public void TestReturnsListFilterByMultiName()
        {
            var result = PsCmdletAssert.Invoke(typeof(GetGacAssemblyCommand), new[] { new Parameter("Name", new[] {"mscorlib", ""}) });

            Assert.IsNotNull(result);
            Assert.IsTrue(result.Count == 1);

            var output = ((IEnumerable<AssemblyName>)result[0].BaseObject).ToList();

            Assert.IsNotNull(output);
            Assert.IsTrue(output.Count > 0);
        }

        [TestMethod]
        [TestCategory("GetGacAssemlby")]
        public void TestReturnsListFilterByFuzzyName()
        {
            var result = PsCmdletAssert.Invoke(typeof(GetGacAssemblyCommand), new[] { new Parameter("Name", "System*") });

            Assert.IsNotNull(result);
            Assert.IsTrue(result.Count == 1);

            var output = ((IEnumerable<AssemblyName>)result[0].BaseObject).ToList();

            Assert.IsNotNull(output);
            Assert.IsTrue(output.Count > 0);
        }
    }
}