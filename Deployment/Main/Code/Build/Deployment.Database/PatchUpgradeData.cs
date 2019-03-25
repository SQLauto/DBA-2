using System.Collections.Generic;
using System.Linq;

namespace Deployment.Database
{
    public class PatchUpgradeData
    {
        public PatchUpgradeData()
        {
            ValidationErrors = new List<string>();
            PatchUpgrades = new List<PatchUpgradeScriptInfo>();
        }

        public bool IsValid => ValidationErrors.Count == 0 && !PatchUpgrades.SelectMany(x=>x.ValidationErrors).Any();

        public IList<string> ValidationErrors { get; }

        public IList<PatchUpgradeScriptInfo> PatchUpgrades { get; }
    }
}