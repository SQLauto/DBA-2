using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

using Microsoft.TeamFoundation.Client;
using Microsoft.TeamFoundation.Framework.Common;
using Microsoft.TeamFoundation.Framework.Client;
using Microsoft.TeamFoundation.VersionControl.Client;
using Microsoft.TeamFoundation.WorkItemTracking.Client;

namespace Deployment.TFS.WorkItems
{
    public class WorkItemHelper
    {
        public static List<TFLWorkItem> GetAssociatedWorkItems(List<Changeset> changeSets)
        {
            List<TFLWorkItem> associatedWorkItems = new List<TFLWorkItem>();

            foreach(Changeset cs in changeSets)
            {
                associatedWorkItems.AddRange(from wi in cs.WorkItems where !associatedWorkItems.Any(x => x.WorkItemId == wi.Id) select new TFLWorkItem(wi));
            }

            return associatedWorkItems;
        }

        //********************Test Methods to test WIQL*********************************
        public static void RunLinkQuery(string projectCollectionUrl)
        {
            TfsTeamProjectCollection tfsCollection = new TfsTeamProjectCollection(new Uri(projectCollectionUrl));
            WorkItemStore workItemStore = new WorkItemStore(tfsCollection);

            Query treeQuery = new Query(workItemStore, wiql);
            WorkItemLinkInfo[] links = treeQuery.RunLinkQuery();

            int[] ids = (from WorkItemLinkInfo info in links select info.TargetId).ToArray();

            StringBuilder detailsWiql = new StringBuilder(); 
            detailsWiql.AppendLine("SELECT"); 
            bool first = true;
            foreach (FieldDefinition field in treeQuery.DisplayFieldList) 
            { 
                detailsWiql.Append("    "); 
                if (!first)        
                    detailsWiql.Append(","); 
                detailsWiql.AppendLine("[" + field.ReferenceName + "]"); 
                first = false; 
            } 
            detailsWiql.AppendLine("FROM WorkItems");

            Query flatQuery = new Query(workItemStore, detailsWiql.ToString(), ids); 
            WorkItemCollection details = flatQuery.RunQuery();
        }

        private static string wiql =
@"SELECT 
    [System.Id],
    [System.WorkItemType],
    [System.Title]
FROM WorkItemLinks
WHERE 
    Target.[System.WorkItemType] = 'Product Backlog Item' AND 
    Target.[System.Id] = 7740 AND
    [System.Links.LinkType] = 'Scrum.ImplementedBy'
mode(MustContain)";

    }
}
