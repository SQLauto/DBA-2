using System.Collections.Generic;
using Deployment.Common;

namespace Deployment.Domain.Operations
{
    public interface IDomainModelValidator
    {
        bool ValidateCommonIncludes();
        bool ValidateMachineCreation(IList<Machine> machines);
        bool ValidateDeploymentFileParser();
        bool ValidateDomainModelFile(string domainModelFile);
        ValidationResult ValidationResult { get; }
    }
}