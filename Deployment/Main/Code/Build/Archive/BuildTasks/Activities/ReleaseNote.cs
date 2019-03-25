using System.Activities;
using System.Collections.Generic;
using System;
using System.Linq;
using System.Collections;

using Microsoft.TeamFoundation.Client;
using Microsoft.TeamFoundation.Build.Client;
using Microsoft.TeamFoundation.VersionControl.Client;
using Microsoft.TeamFoundation.WorkItemTracking.Client;
using Microsoft.TeamFoundation.Build.Workflow.Activities;

namespace CustomBuildActivities.Activities
{
    [BuildActivity(HostEnvironmentOption.All)]
    public sealed class ReleaseNote : CodeActivity
    {
        [RequiredArgument]
        public InArgument<IList<Changeset>> AssociatedChangesets { get; set; }

        [RequiredArgument]
        public InArgument<IBuildDetail> BuildDetail { get; set; }

        protected override void Execute(CodeActivityContext context)
        {
            IList<Changeset> associatedChangesets = context.GetValue(AssociatedChangesets);
            IBuildDetail buildDetail = context.GetValue(BuildDetail);

            if (associatedChangesets == null)
                context.TrackBuildMessage("AssociatedChangeSets is NULL", BuildMessageImportance.High);

            context.TrackBuildMessage(string.Format("Associated changesets contains {0} changeset(s)", associatedChangesets.Count), BuildMessageImportance.High);

            // Get the associated workitems
            List<WorkItem> associatedWorkItems = new List<WorkItem>();
            associatedChangesets.ToList().ForEach(cs => associatedWorkItems.AddRange(cs.WorkItems));
            context.TrackBuildMessage(string.Format("Associated WorkItems contains {0} workitem(s)", associatedWorkItems.Count), BuildMessageImportance.High);

            // Deal with merged changesets   
            List<Change> mergedChanges = new List<Change>();
            List<Changeset> mergedChangesets = new List<Changeset>();
            VersionControlServer vcs = buildDetail.BuildServer.TeamProjectCollection.GetService<VersionControlServer>();

            associatedChangesets.ToList().ForEach(
                cs => mergedChanges.AddRange(cs.Changes.Where(ch => (ch.ChangeType & ChangeType.Merge) == ChangeType.Merge)));

            context.TrackBuildMessage(string.Format("Merged changes contains {0} change(s)", mergedChanges.Count), BuildMessageImportance.High);            

            foreach (Change change in mergedChanges)
            {
                foreach (MergeSource ms in change.MergeSources)
                {
                    IEnumerable history = GetMergeHistory(vcs, ms); // the orginal changesets
                    mergedChangesets.AddRange(from Changeset cs in history where !mergedChangesets.Any(x => x.ChangesetId == cs.ChangesetId) select cs);
                }
            }

            context.TrackBuildMessage(string.Format("Merged changesets contains {0} changeset(s)", mergedChangesets.Count), BuildMessageImportance.High);

            associatedWorkItems.AddRange(from Changeset cs in mergedChangesets
                                    from wi in cs.WorkItems.Where(wi => !associatedWorkItems.Any(w => w.Id == wi.Id))
                                    select wi);

            context.TrackBuildMessage(string.Format("Associated WorkItems contains {0} workitem(s)", associatedWorkItems.Count), BuildMessageImportance.High);

            // Display changeset data
            foreach (Changeset changeSet in associatedChangesets)
            {
                context.TrackBuildMessage(string.Format("Changeset: {0}     {1}     {2}",
                    changeSet.ChangesetId, changeSet.Committer, changeSet.Comment), BuildMessageImportance.High);
            }

            // Display merged changeset data
            context.TrackBuildMessage("  ", BuildMessageImportance.High);

            foreach (Changeset changeSet in mergedChangesets)
            {
                context.TrackBuildMessage(string.Format("Changeset: {0}     {1}     {2}",
                    changeSet.ChangesetId, changeSet.Committer, changeSet.Comment), BuildMessageImportance.High);
            }

            // Display the work item data
            foreach (WorkItem workItem in associatedWorkItems)
            {
                context.TrackBuildMessage(string.Format("WorkItem: {0}     {1}     {2}",
                    workItem.Id, workItem.Title, workItem.State), BuildMessageImportance.High);
            }
            
            // Derive PBI and FPBI
        }

        private static IEnumerable<Change> PendingMerges(List<Change> changes)
        {
            return changes.Where(ch => (ch.ChangeType & ChangeType.Merge) == ChangeType.Merge);
        }

        private static IEnumerable GetMergeHistory(VersionControlServer vcs, MergeSource ms)
        {
            ChangesetVersionSpec from = new ChangesetVersionSpec(ms.VersionFrom);
            ChangesetVersionSpec to = new ChangesetVersionSpec(ms.VersionTo);
            return vcs.QueryHistory(ms.ServerItem, from, 0, RecursionType.Full, null,
                                    from, to, Int32.MaxValue, true, true);
        }
    }
}
