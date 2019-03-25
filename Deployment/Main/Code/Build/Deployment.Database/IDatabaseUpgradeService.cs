using System.Collections.Generic;

namespace Deployment.Database
{
    public interface IDatabaseUpgradeService
    {
        PatchUpgradeData IsPatchDefinitionValid(PatchUpgradeParameters upgradeParameters);
        PatchUpgradeData GetPatchesToUpgrade(PatchUpgradeParameters upgradeParameters);
    }
}