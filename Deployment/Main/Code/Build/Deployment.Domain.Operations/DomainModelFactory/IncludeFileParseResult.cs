using System.Collections.Generic;

namespace Deployment.Domain.Operations.DomainModelFactory
{
    public class IncludeFileParseResult
    {
        public IncludeFileParseResult()
        {
            FullDefinitionRoles = new List<ParseElement>();
        }

        public List<ParseElement> FullDefinitionRoles { get; set; }


    }
}