using System;
using System.IO;
using System.Text;

namespace Deployment.Common.Helpers
{
    public interface IFileHelper
    {
        string GetRelativePath(string rootPath, string relativePath);
    }

    public class FileHelper : IFileHelper
    {
        public static string GetFileRelativePath(string file, string dropFolder)
        {
            var folder = Path.GetDirectoryName(file);
            return folder?.Substring(dropFolder.Length);
        }

        public string GetRelativePath(string rootPath, string relativePath)
        {
            //rootPath needs to be rooted.
            if (!Path.IsPathRooted(rootPath))
                throw new DirectoryNotFoundException("The rootPath argument must be a rooted path.");

            var root = new DirectoryInfo(rootPath);

            //if we already have relative path, just return it.
            //TODO:  Ideally we should handle when we have overlapping relative paths (to the root)
            //come back and address this.
            if (!Path.IsPathRooted(relativePath))
                return relativePath;

            var relative = new DirectoryInfo(relativePath);

            var rootUri = new Uri(root.FullName);
            var relativeUri = new Uri(relative.FullName);

            //firstly ensure value1 is a base of value2
            //if not just return the full relativePath value
            if (!rootUri.IsBaseOf(relativeUri))
                return relativePath;

            var rootLength = root.FullName.Length;
            var sourceLength = relative.FullName.Length;

            var rootSegments = rootUri.Segments;
            var sourceSegments = relativeUri.Segments;

            var builder = new StringBuilder(sourceLength - rootLength);

            //we can build up the relative filename of the source by iterating over the segments, relative to root
            for (var index = rootSegments.Length; index < sourceSegments.Length; index++)
            {
                var part = sourceSegments[index].EndsWith("/") ? Uri.UnescapeDataString(sourceSegments[index].TrimEnd('/')) : Uri.UnescapeDataString(sourceSegments[index]);
                builder.Append($"{part}{Path.DirectorySeparatorChar}");
            }

            //removing trailing directory separator.
            return builder.ToString(0, builder.Length - 1);
        }
    }
}