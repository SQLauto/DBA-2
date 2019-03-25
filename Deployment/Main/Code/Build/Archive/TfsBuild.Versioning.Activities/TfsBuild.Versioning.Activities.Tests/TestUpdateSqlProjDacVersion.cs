using System;
using System.Activities;
using System.Collections.Generic;
using System.IO;
using System.Runtime.CompilerServices;
using System.Text;
using System.Xml;
using System.Linq;
using System.Xml.Linq;

using TfsBuild.Versioning.Activities;

using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace TfsBuild.Versioning.Activities.Tests
{
    /// <summary>
    /// 
    /// </summary>
    [DeploymentItem("TfsBuild.Versioning.Activities.Tests\\TestData\\ReplaceTestSqlProj.sqlproj")]
    [TestClass]
    public class TestUpdateSqlProjDacVersion
    {
        /// <summary>
        /// Gets or sets the test context which provides
        /// information about and functionality for the current test run.
        ///</summary>
        public TestContext TestContext { get; set; }

        [TestMethod]
        public void TestUpdateDacVersion()
        {
            string file = "ReplaceTestSqlProj.sqlproj";
            string version = "1.2.3.4";
            string testFilename = string.Format("UpdateDacVersionTest{0}", Path.GetExtension(file));

            File.Copy(file, testFilename);

            UpdateSqlProjDacVersion.UpdateDacVersion(testFilename, version, null);

            // Verify
            XElement projectElement = XElement.Load(testFilename);
            bool found = false;
            foreach (XElement propertyElement in projectElement.Elements().Where(e => e.Name.LocalName == "PropertyGroup"))
            {
                XElement dacVersionElement = (from dv in propertyElement.Elements().Where(e => e.Name.LocalName == "DacVersion") select dv).FirstOrDefault();

                if (dacVersionElement != null)
                {
                    Assert.AreEqual(version, dacVersionElement.Value, "DacVersion is wrong");
                    found = true;
                    break;
                }
            }

            Assert.IsTrue(found, "DacVersion not found");
        }
    }
}
