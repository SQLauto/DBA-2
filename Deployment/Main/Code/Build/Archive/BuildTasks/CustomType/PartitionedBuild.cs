using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace CustomBuildActivities.CustomType
{
    /// <summary>
    /// Class representing a build that we will partition a deployment build on
    /// </summary>
    public class PartitionedBuild
    {
        /// <summary>
        /// Default constructor
        /// </summary>
        public PartitionedBuild()
        {
            TeamProjectName = string.Empty;
            BuildDefinitionName = string.Empty;
            BuildNumber = string.Empty;
            AllowPartiallySuccesfulBuilds = false; // disallow these by default
        }

        /// <summary>
        /// Copy constructor 
        /// </summary>
        public PartitionedBuild(PartitionedBuild build)
            : this(build.TeamProjectName, build.BuildDefinitionName, build.BuildNumber, build.AllowPartiallySuccesfulBuilds)
        {

        }

        /// <summary>
        /// Constructor with all parameters provided
        /// </summary>
        public PartitionedBuild(string teamProjectName, string buildDefinitionName, string buildNumber, bool allowPartiallySuccesfulBuilds)
        {
            TeamProjectName = teamProjectName;
            BuildDefinitionName = buildDefinitionName;
            BuildNumber = buildNumber;
            AllowPartiallySuccesfulBuilds = allowPartiallySuccesfulBuilds; // disallow these by default
        }


        /// <summary>
        /// The team project name
        /// </summary>
        public string TeamProjectName { get; set; }

        /// <summary>
        /// The build defintion name
        /// </summary>
        public string BuildDefinitionName { get; set; }

        /// <summary>
        /// The build number, optional. If null or empty, the last succesful build will be used
        /// </summary>
        public string BuildNumber { get; set; }

        /// <summary>
        /// Allow partially succesful builds when finding the last succesful build
        /// </summary>
        public bool AllowPartiallySuccesfulBuilds { get; set; }

        /// <summary>
        /// Override for debugging purposes
        /// </summary>
        /// <returns></returns>
        public override string ToString()
        {
            if (!string.IsNullOrEmpty(BuildNumber))
            {
                return string.Format("{0} : {1}", TeamProjectName, BuildNumber);
            }
            else
            {
                return string.Format("{0} : {1}", TeamProjectName, BuildDefinitionName);
            }
        }
    }
}
