using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Reflection;
using System.Text;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace Deployment.Domain.Operations.Tests
{
    [TestClass]
    public class DatabasePathLengthCodeTests
    {
        /// <summary>
        /// Note that these tests are not strictly unit tests however we wish for the rolling build
        /// to fail if files are too long or a forward merge has put programability back in.
        /// Files containing 'ToRun' can be ignored as they are not copied during deployment.
        /// </summary>
        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        public void SolutionFilesMustNotExceedMaxLengthSoBuildProcessesCanBeSupported()
        {
            var directoriesOfInterest = GetDirectoriesUnderTest();

            foreach (DirectoryInfo currentDir in directoriesOfInterest)
            {
                const int maxPathLength = 140;
                var maxTotalLength = maxPathLength + currentDir.FullName.Length + 1;
                var potentialFilesOfInterest = GetAllFiles(currentDir);
                var pathsWhichAreTooLong = potentialFilesOfInterest
                    .Where(f => f.FullName.Length > maxTotalLength && !f.FullName.Contains("ToRun"))
                    .Select(x => x.FullName)
                    .OrderByDescending(p => p.Length)
                    .ToList();

                bool thereExistsPathsWhichAreTooLong = pathsWhichAreTooLong.Any();

                if (thereExistsPathsWhichAreTooLong)
                {
                    var builder = new StringBuilder();

                    builder.AppendFormat("The {3} paths are greater than the permitted path length of [{0}] from the root of the solution [{1}] on [{2}]", maxPathLength, currentDir.FullName, Environment.MachineName, pathsWhichAreTooLong.Count);
                    builder.AppendLine();
                    int count = 1;
                    foreach (string pathTooLong in pathsWhichAreTooLong)
                    {
                        builder.AppendLine(
                            $"{count++:000}. {pathTooLong} ({pathTooLong.Length - currentDir.FullName.Length})");
                    }

                    Assert.Fail(builder.ToString());
                }
            }
        }

        private static readonly List<string> PossiblePaths = new List<string>
        {
            @"Deployment.Scripts\bin\Debug\DeploymentSchema.Scripts", // [RL 2017.12.07] Local Dev -Type -'Pre' on Physical VM run through DeploymentTool project

            @"..\..\..\DeploymentSchema.Scripts", // dev machine test run  [RL 2017.11.20] NOT SURE

            //@"..\..\..\DeploymentSchema.Scripts", // nightly build test run
            //@"..\..\..\Binaries\DeploymentSchema.Scripts",
            //@"..\..\..\SimpleDB.Scripts",
            @"..\..\..\..\b\DeploymentSchema.Scripts",
        };

        private List<DirectoryInfo> GetDirectoriesUnderTest()
        {
            var assemblyLocation = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);

            var directoriesOfInterest = new List<DirectoryInfo>();

            foreach (var path in PossiblePaths)
            {
                var newPath = Path.Combine(assemblyLocation, path);
                var dir = new DirectoryInfo(newPath);
                if (dir.Exists)
                {
                    directoriesOfInterest.Add(dir.Parent);
                }
            }

            if (directoriesOfInterest.Any())
            {
                return directoriesOfInterest;
            }

            throw new Exception($"Could not find folder from [{assemblyLocation}] on [{Environment.MachineName}]");
        }

        private static readonly List<string> ExcludedDirectoryNames = new List<string>
            {
                "_PublishedWebsites",
                "Configuration",
                "ConfigurationParameters",
                "Pare.Testing.Common",
                "bin",
                "obj",
                "Properties",
                "ExternalResources",
                "Archive"
            };

        private IEnumerable<FileInfo> GetAllFiles(DirectoryInfo directory)
        {
            if (ExcludedDirectoryNames.Contains(directory.Name))
                yield break;

            foreach (var file in directory.GetFiles())
            {
                yield return file;
            }

            foreach (var childDirectory in directory.GetDirectories().Where(d=>ExcludedDirectoryNames.Contains(d.Name)))
            {
                foreach (var childFile in GetAllFiles(childDirectory))
                {
                    yield return childFile;
                }
            }
        }
    }
}