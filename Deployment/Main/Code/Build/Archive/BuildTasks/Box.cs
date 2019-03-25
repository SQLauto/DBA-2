using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace CustomBuildActivities
{
    public class Box
    {
        public string Name { get; set; }
        public string InternalIP { get; set; }
        public string ExternalIP { get; set; }
        public string Layer { get; set; }
        public Box()
        {
        }
        public Box(string name, string internalIP, string externalIP, string layer)
        {
            Name = name;
            InternalIP = internalIP;
            ExternalIP = externalIP;
            Layer = layer;
        }

    }
}
