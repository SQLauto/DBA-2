using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;


namespace CustomBuildActivities.Enum
{
    /// <summary>
    /// This type is a duplicate of one in deployment utils
    /// A strange xaml issue means I can not include the enum from deployment  utils in the build template
    /// only the one from this assembly.
    /// Until I can resolve that I have to keep two copies of the same type in the codebase, 
    /// one from the build template and one for core deployment logic - HS
    /// </summary>
    public enum DeploymentPlatform
    {
        /// <summary>
        /// Will do deployment to LM
        /// </summary>
        LabManager = 1,

        /// <summary>
        /// Will do deployment to VCloud
        /// </summary>
        VCloud = 2,

        /// <summary>
        /// Will do deployment to current domain e.g. devint
        /// </summary>
        CurrentDomain = 3,

    }
}