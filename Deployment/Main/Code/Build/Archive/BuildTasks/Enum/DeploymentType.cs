using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;


namespace CustomBuildActivities.Enum
{
    public enum DeploymentType
    {
        /// <summary>
        /// Will only do deployment
        /// </summary>
        Deploy=1,
        
        /// <summary>
        /// Will do deployment and test
        /// </summary>
        DeployAndTest = 2,

        /// <summary>
        /// Will only do test
        /// </summary>
        Test = 3,

        /// <summary>
        /// Will only do packagin
        /// </summary>
        Package=4,

        /// <summary>
        /// Will only Validate that a CI can be packaged
        /// </summary>
        ValidatePackage = 5,
    }
}
