using System;

namespace Deployment.Domain
{
    [Serializable]
    public class Parameter
    {
        public string Name { get; set; }
        public string Value { get; set; }
        public string Type { get; set; }
        public string Description { get; set; }
    }
}