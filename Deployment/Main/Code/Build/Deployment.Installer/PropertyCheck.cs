using System;
using System.Collections.Generic;

namespace Deployment.Installation
{
    /// <summary>
    /// </summary>
    [Serializable]
    public class PropertyCheck
    {
        public PropertyCheck()
        {
            AllExpectedPropertiesExist = true;
            InvalidPropertyNames = new List<string>();
        }

        public bool AllExpectedPropertiesExist { get; set; }
        public List<string> InvalidPropertyNames { get; set; }
    }
}
