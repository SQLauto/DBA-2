using System.Collections.Generic;
using Deployment.Common;

namespace Deployment.Domain.Operations.DomainModelFactory
{
    public class DeploymentFileParseResult
    {
        public DeploymentFileParseResult() : this(ValidationResult.Success())
        {
        }

        public DeploymentFileParseResult(ValidationResult validationResult)
        {
            ValidationResult = validationResult;
            CommonRoleIncludes = new List<ParseElement>();
            Machines = new List<ParseElement>();
            CustomTests = new List<ParseElement>();
            ServiceDependencies = new List<ParseElement>();
        }

        public List<ParseElement> CommonRoleIncludes { get; set; }
        public string PostDeploymentTestAccount { get; set; }
        public List<ParseElement> Machines { get; set; }
        public List<ParseElement> CustomTests { get; set; }
        public List<ParseElement> ServiceDependencies { get; set; }

        public ValidationResult ValidationResult { get; set; }

        public string Id { get; set; }
        public string Name { get; set; }
        public string Environment { get; set; }
        public string Config { get; set; }
        public string ProductGroup { get; set; }
    }
}