using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Xml.Linq;
using Deployment.Common;
using Deployment.Common.Logging;
using Deployment.Common.Xml;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using MSTestExtensions;

namespace Deployment.Domain.Operations.Tests
{
    public abstract class DomainOperationsTestBase : BaseTest
    {
        protected DomainOperationsTestBase()
        {
            Config = string.Empty;
            OverrideConfig = null;
            Groups = "Group1";
            Body = string.Empty;
        }

        public TestContext TestContext { get; set; }

        protected string BaseRoleString { get; set; } =
            @"<ServerRole xmlns='{4}' Name='{0}' Include='Include' Description='Description' Groups='{1}' {2}>{3}</ServerRole>";

        protected string RoleName { get; set; }
        protected string Config { get; set; }
        protected string OverrideConfig { get; set; }
        protected string Groups { get; set; }
        protected string Body { get; set; }

        protected IDeploymentLogger Logger { get; set; }

        public bool AssertValidationResult(ValidationResult validationResult, Action assert)
        {
            var success = true;
            try
            {
                assert();
            }
            catch (UnitTestAssertException ex)
            {
                TestContext.WriteLine(ex.Message);
                success = false;
            }

            foreach (var error in validationResult.ValidationErrors)
            {
                TestContext.WriteLine(error);
            }

            return success;
        }

        protected virtual XElement GenerateServerRoleXml()
        {
            return XmlHelper.CreateXElement(string.Format(BaseRoleString, RoleName, Groups, Config, Body, Namespaces.CommonRole.XmlNamespace));
        }

        protected virtual void CopyFiles(IList<string> files, params string[] targetPaths)
        {
            var paths = new[] { TestContext.TestDeploymentDir }.Concat(targetPaths);

            var targetPath = Path.Combine(paths.ToArray());

            if (!Directory.Exists(targetPath))
            {
                Directory.CreateDirectory(targetPath);
            }

            foreach (var file in files)
            {
                File.Copy(Path.Combine(TestContext.TestDeploymentDir, $"{file}"),
                    Path.Combine(targetPath, $"{file}"),
                    true);
            }
        }

        protected virtual void RemoveFiles(IList<string> files, string targetPath)
        {
            foreach (var file in files)
            {
                File.Delete(Path.Combine(TestContext.TestDeploymentDir, targetPath, $"{file}"));
            }
        }
    }

    public static class AssertExtensions
    {
        public static void ValidationResult(this IAssertion assert, ValidationResult validationResult, TestContext context)
        {
            try
            {
                assert.IsTrue(validationResult.Result);
            }
            catch (UnitTestAssertException ex)
            {
                context.WriteLine(ex.Message);

                foreach (var error in validationResult.ValidationErrors)
                {
                    context.WriteLine(error);
                }

                assert.Fail();
            }
        }

        public static void StringNotNullOrEmpty(this IAssertion assert, string value)
        {
            assert.IsFalse(string.IsNullOrWhiteSpace(value));
        }

        public static void StringNullOrEmpty(this IAssertion assert, string value)
        {
            assert.IsFalse(string.IsNullOrWhiteSpace(value));
        }

        public static void IsNotNullOrEmpty<T>(this IAssertion assert, IList<T> value)
        {
            assert.IsFalse(value.IsNullOrEmpty());
        }

        public static void FileExists(this IAssertion assert, string targetPath)
        {
            assert.IsTrue(File.Exists(targetPath));
        }

        public static void FileExists(this IAssertion assert, string targetPath, string message, params object[] parameters)
        {
            assert.IsTrue(File.Exists(targetPath), message, parameters);
        }
    }
}