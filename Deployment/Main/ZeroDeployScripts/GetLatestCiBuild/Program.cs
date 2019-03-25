using System;
using System.Configuration;
using System.IO;
using System.Linq;
using Microsoft.TeamFoundation.Build.Client;
using Microsoft.TeamFoundation.Client;

namespace GetLatestSuccsessfulBuild
{
    internal class Program
    {
        private static void Main(string[] args)
        {
            if (args.Length < 4 || args.Length > 5)
            {
                Console.WriteLine("Usage:\t\tGetLatestCiBuild.exe TFSURL PROJECTNAME BUILDNAME TARGETFOLDER [buildNumber]");
                Console.WriteLine(
                    @"E.g.:     GetLatestCiBuild.exe ""http://tfs:8080/tfs/ftpdev"" ""FAE"" ""FAE.Main.CI D:\\Autogration\\Components\\FAE\\"" [""FAE.Main.CI_2015.03.11.1""]");
                System.Environment.Exit(1);
            }

            var tfsUrl = args[0];
            var projectName = args[1];
            var buildName = args[2];
            var targetFolder = args[3];

            var buildNumber = (args.Length == 5) ? args[4] : null;

            GetComponent(tfsUrl, projectName, buildName, targetFolder, buildNumber);

            //Console.WriteLine("Drop folder for {0} is: \t{1}", buildName, dropFolder);
            //var targetFolder = string.Format(@"D:\Autogration\Components\{0}\", projectName);


            //foreach (var projectName in args)
            //{
            //    try
            //    {
            //        var dropFolder = GetDropLocation(projectName);
            //        Console.WriteLine("Drop folder for {0} is: \t{1}", projectName, dropFolder);
            //        var targetFolder = string.Format(@"D:\Autogration\Components\{0}\", projectName);
            //        EnsureEmptyFolderExists(targetFolder);
            //        CopyFilesRecursively(
            //         new DirectoryInfo(dropFolder),
            //         new DirectoryInfo(targetFolder));
            //        Console.WriteLine("Finished copying {0} to {1}", projectName, targetFolder);
            //    }
            //    catch (Exception ex)
            //    {
            //        continue;
            //    }
            //}

            //Console.ReadLine();
        }

        private static void GetComponent(string tfsUrl, string projectName, string buildName, string targetFolder, string buildNumber = null)
        {
            var dropFolder = GetDropLocation(tfsUrl, projectName, buildName, buildNumber);

            EnsureEmptyFolderExists(targetFolder);
            CopyFilesRecursively(
                new DirectoryInfo(dropFolder),
                new DirectoryInfo(targetFolder));
            Console.WriteLine("Finished copying {0} to {1}", projectName, targetFolder);
        }

        private static void EnsureEmptyFolderExists(string targetFolder)
        {
            if (Directory.Exists(targetFolder))
            {
                Directory.Delete(targetFolder);
            }

            Directory.CreateDirectory(targetFolder);
        }

        //public static string GetDropLocation(string projectName)
        //{
        //    var tfsUrl = ConfigurationManager.AppSettings["TfsUrl"];
        //    var buildDefinitionName = ConfigurationManager.AppSettings[projectName];
        //    var details = GetBuildDetails(tfsUrl, projectName, buildDefinitionName);

        //    return GetDropLocation(details);
        //}

        public static string GetDropLocation(string tfsUrl, string projectName, string buildName, string buildNumber =null)
        {
            var buildDetails = GetBuildDetails(tfsUrl, projectName, buildName);
        
            if (buildDetails.Builds.Length == 0)
            {
                throw new Exception("No builds found.");
            }

            var targetBuild = (string.IsNullOrEmpty(buildNumber))
                ? buildDetails.Builds[0]
                : buildDetails.Builds.SingleOrDefault(b => b.BuildNumber == buildNumber);

            Console.WriteLine("Found build number : {0}\n", targetBuild.BuildNumber);
            if (!string.IsNullOrEmpty(targetBuild.DropLocation))
            {
                return targetBuild.DropLocation;
            }

            throw new Exception(
                "Drop location is not available. Check if the build definition was set true for Copy to Output Folder parameter...");
        }

        public static IBuildQueryResult GetBuildDetails(string tfsUrl, string projectName, string buildDefinitionName)
        {
            try
            {
                var tfsUri = new Uri(tfsUrl);

                var teamProjectCollection = TfsTeamProjectCollectionFactory.GetTeamProjectCollection(tfsUri);
                teamProjectCollection.Authenticate();
                IBuildServer service = teamProjectCollection.GetService<IBuildServer>();

                var spec = service.CreateBuildDetailSpec(projectName, buildDefinitionName);
                spec.MaxBuildsPerDefinition = 10;
                spec.QueryOrder = BuildQueryOrder.FinishTimeDescending;
                spec.Status = BuildStatus.Succeeded;
                var results = service.QueryBuilds(spec);
                return results;
            }
            catch (Exception ex)
            {
                throw new Exception("There is a problem with Get Last successful build\n" + ex.Message);
            }

            return null;
        }

        public static void CopyFilesRecursively(DirectoryInfo source, DirectoryInfo target)
        {
            foreach (DirectoryInfo dir in source.GetDirectories())
                CopyFilesRecursively(dir, target.CreateSubdirectory(dir.Name));
            foreach (FileInfo file in source.GetFiles())
                file.CopyTo(Path.Combine(target.FullName, file.Name));
        }
    }
}