using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

using Microsoft.TeamFoundation.Client;
using Microsoft.TeamFoundation.Framework.Common;
using Microsoft.TeamFoundation.Framework.Client;
using Microsoft.TeamFoundation.VersionControl.Client;

namespace Deployment.TFS.VersionControl
{
    public class LabelHelper
    {
        internal static VersionControlLabel GetMatchingLabel(VersionControlServer vcs, string label)
        {
            // Parse the label is needed
            string scope = null;
            int index = label.IndexOf('@');
            if (index > -1)
            {
                scope = label.Substring(index + 1);
                label = label.Substring(0, index);                
            }
            VersionControlLabel[] matchingLabels = vcs.QueryLabels(label, scope, null, true);

            if (matchingLabels == null || matchingLabels.Length == 0)
            {
                throw new ApplicationException(string.Format("No matching labels found for '{0}'", label));
            }

            if (matchingLabels.Length > 1)
            {
                throw new ApplicationException(string.Format("More than one matching label found for '{0}'", label));
            }

            return matchingLabels[0];
        }
    }
}
