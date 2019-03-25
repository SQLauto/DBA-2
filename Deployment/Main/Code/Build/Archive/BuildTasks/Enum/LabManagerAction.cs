using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace CustomBuildActivities.CustomType
{
    public enum LabManagerAction
    {
        /// <summary>
        /// Do Nothing
        /// </summary>
        DoNothing = 1,

        /// <summary>
        /// Create a new lm rig
        /// </summary>
        CreateRig = 2,

        /// <summary>
        /// Force a refresh of the specified rig
        /// </summary>
        ForceRigRefresh = 3,

        /// <summary>
        /// Refresh the rig if certain conditions are met (e.g. rig is more than a set number of days old and it is a weekend
        /// Conditions defined in powershell scripts
        /// </summary>
        RefreshRig = 4
    }
}
