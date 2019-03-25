using System;
using System.Collections.Generic;

namespace Deployment.Domain
{
    public struct  ArchiveEntry
    {
        /// <summary>
        /// The physical location of the file to archive
        /// </summary>
        public string FileLocation { get; set; }

        /// <summary>
        /// The relative location of the file in the archive, if null or empty the relative path from FileLocation will be used
        /// </summary>
        public string FileRelativePath { get; set; }

        /// <summary>
        /// The name of the file in the archive, if null or empty will use the original name
        /// </summary>
        public string FileName { get; set; }
    }

    public class ArchiveEntryComparer : IEqualityComparer<ArchiveEntry>
    {
        public bool Equals(ArchiveEntry x, ArchiveEntry y)
        {
            return x.FileLocation.Equals(y.FileLocation, StringComparison.CurrentCultureIgnoreCase) &&
                x.FileRelativePath.Equals(y.FileRelativePath, StringComparison.CurrentCultureIgnoreCase);

        }

        public int GetHashCode(ArchiveEntry entry)
        {
            //Get hash code for the Name field if it is not null.
            int locHc = string.IsNullOrEmpty(entry.FileLocation) ? 0 : entry.FileLocation.GetHashCode();

            int relHc = string.IsNullOrEmpty(entry.FileRelativePath) ? 0 : entry.FileRelativePath.GetHashCode();
            return locHc ^ relHc;
        }

    }
}
