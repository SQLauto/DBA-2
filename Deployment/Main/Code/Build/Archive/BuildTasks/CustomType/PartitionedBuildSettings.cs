using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace CustomBuildActivities.CustomType
{
    /// <summary>
    /// Class representing all the settings needed to define what builds a deployment build will
    /// be partitioned on
    /// </summary>
    public class PartitionedBuildSettings
    {
        /// <summary>
        /// Default constructor
        /// </summary>
        public PartitionedBuildSettings()
        {
            PartitionedBuilds = new List<PartitionedBuild>();
            UsePartitionedBuild = true; // on by default
        }

        /// <summary>
        /// Copy constructor
        /// </summary>
        public PartitionedBuildSettings(PartitionedBuildSettings settings)
            : this()
        {
            UsePartitionedBuild = settings.UsePartitionedBuild;
            settings.PartitionedBuilds.ForEach(b => PartitionedBuilds.Add(new PartitionedBuild(b)));
        }
        /// <summary>
        /// This should correspond to a check box on the custom gui where we can easily make a build partitioned
        /// or non partitioned
        /// </summary>
        public bool UsePartitionedBuild { get; set; }

        /// <summary>
        /// The list of builds to partition on
        /// </summary>
        public List<PartitionedBuild> PartitionedBuilds { get; set; }

        /// <summary>
        /// This is what shows up in the build definition editor
        /// </summary>
        /// <returns></returns>
        public override string ToString()
        {
            if (!UsePartitionedBuild)
            {
                return "Build is unpartitioned";
            }
            else if (PartitionedBuilds.Count > 0)
            {
                // List all the partitioned builds in a long string
                return string.Join(" ; ", PartitionedBuilds);
            }
            else
            {
                return "No Partioned builds configured";
            }
        }
    }
}
