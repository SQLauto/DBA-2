using System.Collections.Generic;
using Deployment.Common;

namespace Deployment.Domain
{
    public class GroupFilters
    {
        public GroupFilters()
        {
            IncludeGroups = new List<string>();
            ExcludeGroups = new List<string>();
        }

        public GroupFilters(IEnumerable<string> includeGroups, IEnumerable<string> excludeGroups)
        {
            IncludeGroups = new List<string>(includeGroups);
            ExcludeGroups = new List<string>(excludeGroups);
        }

        public IList<string> IncludeGroups { get; }
        public IList<string> ExcludeGroups { get; }
        public bool IsEmpty => IncludeGroups.IsNullOrEmpty() && ExcludeGroups.IsNullOrEmpty();
    }
}