using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.IO;

using Microsoft.TeamFoundation.Client;
using Microsoft.TeamFoundation.Framework.Common;
using Microsoft.TeamFoundation.Framework.Client;
using Microsoft.TeamFoundation.VersionControl.Client;

namespace Deployment.TFS.VersionControl
{
    public class ChangesetHelper
    {
        /// <summary>
        /// Get all the changesets between two labels
        /// </summary>
        /// <param name="projectCollectionUrl"></param>
        /// <param name="startLabel"></param>
        /// <param name="endLabel"></param>
        /// <param name="getMerges"></param>
        /// <returns></returns>
        public static List<MergedChangeset> GetChangesetsBetweenLabels(string projectCollectionUrl, string startLabel, string endLabel, bool getMerges)
        {
            TfsTeamProjectCollection tfsCollection = new TfsTeamProjectCollection(new Uri(projectCollectionUrl));
            // tfsCollection.Connect(ConnectOptions.IncludeServices);
            VersionControlServer vcs = (VersionControlServer)tfsCollection.GetService(typeof(VersionControlServer));

            return GetChangesetsBetweenLabels(vcs, startLabel, endLabel, getMerges);
        }

        /// <summary>
        /// Get all the changesets between two labels
        /// </summary>
        /// <param name="vcs"></param>
        /// <param name="startLabel"></param>
        /// <param name="endLabel"></param>
        /// <param name="getMerges"></param>
        /// <returns></returns>
        public static List<MergedChangeset> GetChangesetsBetweenLabels(VersionControlServer vcs, string startLabel, string endLabel, bool getMerges)
        {
            List<MergedChangeset> result = new List<MergedChangeset>();
            VersionControlLabel startVCLabel = LabelHelper.GetMatchingLabel(vcs, startLabel);
            VersionControlLabel endVCLabel = LabelHelper.GetMatchingLabel(vcs, endLabel);

            // Find the highest changeset id for all files in the matching label
            int highestStartChangesetId = (from item in startVCLabel.Items select item.ChangesetId).OrderByDescending(id => id).First();
            int highestEndChangesetId = (from item in endVCLabel.Items select item.ChangesetId).OrderByDescending(id => id).First();

            // Dynamically create a workign folder to query for the changesets
            List<string> workingFolders = GetWorkingFolder(endVCLabel);

            // Need to consider cloaked parts of the workspace
            foreach (string folder in workingFolders)
            {
                var changeSets = vcs.QueryHistory(
                    folder,
                    VersionSpec.Latest,
                    0, RecursionType.Full, null,
                    VersionSpec.Parse("C" + highestStartChangesetId.ToString(), null)[0],
                    VersionSpec.Parse("C" + highestEndChangesetId.ToString(), null)[0],
                    Int32.MaxValue, true, false);

                result.AddRange(from Changeset cs in changeSets select new MergedChangeset(cs));
            }

            if (getMerges)
            {
                foreach (MergedChangeset mcs in result)
                {
                    PopulateMerges(vcs, mcs);
                }
            }

            return result;
        }

        /// <summary>
        /// Populate the merges (if any) from a given changeset
        /// Operates recursivley until no more child merges are found
        /// </summary>
        /// <param name="vcs"></param>
        /// <param name="mcs"></param>
        private static void PopulateMerges(VersionControlServer vcs, MergedChangeset mcs)
        {
            if (IsChangeSetFromMerge(mcs.Changeset))
            {
                List<Changeset> mergedChangeSets = GetMergeChangesets(vcs, mcs.Changeset);
                mergedChangeSets.ForEach(cs => mcs.MergedChangesets.Add(new MergedChangeset(cs)));
                foreach (MergedChangeset mmcs in mcs.MergedChangesets)
                {
                    PopulateMerges(vcs, mmcs);
                }
            }
        }

        /// <summary>
        /// Get the merges (if any) that are aprt of the given changeset
        /// </summary>
        /// <param name="vcs"></param>
        /// <param name="changeSet"></param>
        /// <returns></returns>
        private static List<Changeset> GetMergeChangesets(VersionControlServer vcs, Changeset changeSet)
        {
            List<Changeset> mergedChangesets = new List<Changeset>();

            // Re get the merged changes but this time make sure to pull down the 'merge sources' data
            Change[] mergedChanges = vcs.GetChangesForChangeset(changeSet.ChangesetId, false, Int32.MaxValue, null, null, true);
                
            foreach (Change change in mergedChanges)
            {
                foreach (MergeSource ms in change.MergeSources)
                {
                    IEnumerable history = GetMergeHistory(vcs, ms);
                    mergedChangesets.AddRange(from Changeset cs in history where !mergedChangesets.Any(x => x.ChangesetId == cs.ChangesetId) select cs);
                }
            }
            
            return mergedChangesets;
        }

        /// <summary>
        /// Is the given changeset created from a merge
        /// </summary>
        /// <param name="changeSet"></param>
        /// <returns></returns>
        private static bool IsChangeSetFromMerge(Changeset changeSet)
        {
            if (changeSet.Changes == null || changeSet.Changes.Count() == 0)
            {
                throw new ApplicationException("Changeset changes collection not populated");
            }

            if (changeSet.Changes.Where(ch => (ch.ChangeType & ChangeType.Merge) == ChangeType.Merge).Any())
                return true;

            return false;
        }

        /// <summary>
        /// Get the list of changesets the correspond to a merge source
        /// </summary>
        /// <param name="vcs"></param>
        /// <param name="ms"></param>
        /// <returns></returns>
        private static IEnumerable GetMergeHistory(VersionControlServer vcs, MergeSource ms)
        {
            ChangesetVersionSpec from = new ChangesetVersionSpec(ms.VersionFrom);
            ChangesetVersionSpec to = new ChangesetVersionSpec(ms.VersionTo);
            return vcs.QueryHistory(ms.ServerItem, from, 0, RecursionType.Full, null,
                                    from, to, Int32.MaxValue, true, true);
        }
        /// <summary>
        /// Given a label, construct a working folder mapping of TFS directories
        /// </summary>
        /// <param name="label"></param>
        /// <returns></returns>
        private static List<string> GetWorkingFolder(VersionControlLabel label)
        {
            string serverItem = string.Empty;
            string containingFolder = string.Empty;
            List<string> workingFolders = new List<string>();

            foreach (Item item in label.Items)
            {
                serverItem = NormalisePath(item.ServerItem.ToLower());
                if (!IsItemContainedInWorkingFolders(serverItem, workingFolders))
                {
                    if (item.ItemType == ItemType.File)
                    {
                        containingFolder = NormalisePath(Path.GetDirectoryName(serverItem));
                    }
                    else
                    {
                        containingFolder = serverItem;
                    }
                    workingFolders.Add(containingFolder);
                }
            }
            return workingFolders;
        }

        /// <summary>
        /// Is the given item contained in one of the folders
        /// </summary>
        /// <param name="item">the path of a file or folder</param>
        /// <param name="workingFolders">a list of directories</param>
        /// <returns></returns>
        private static bool IsItemContainedInWorkingFolders(string item, List<string> workingFolders)
        {
            foreach (string folder in workingFolders)
            {
                if (item.Contains(folder))
                    return true;
            }

            return false;
        }

        /// <summary>
        /// Normalise all the forward and backward slashes in a file path
        /// </summary>
        /// <param name="path"></param>
        /// <returns></returns>
        private static string NormalisePath(string path)
        {
            return path.Replace('\\', '/');
        }
    }
}
