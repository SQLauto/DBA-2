using System.Collections.Generic;
using System.Xml.Linq;

namespace Deployment.Domain.Operations.DomainModelFactory
{
    public class MachineParseResult
    {
        public MachineParseResult()
        {
            Roles = new List<XElement>();
        }

        public Machine Machine { get; set; }
        public IList<XElement> Roles { get; private set; }
    }
}