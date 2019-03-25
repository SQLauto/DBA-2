using System.Collections.Generic;
using System.Xml.Linq;
using Deployment.Common;
using Deployment.Domain.Roles;

namespace Deployment.Domain.Operations
{
    public interface IDomainModelFactory
    {
        IBaseRole DomainModelCreate(XElement rootNode, ref ValidationResult validationResult);
        IBaseRole ApplyOverrides(IBaseRole commonRole, XElement includedRole, ref ValidationResult validationResult);

        IBaseRole UpdateParameterisedValues(IBaseRole deployRole, IParameterService parameterService,
            IDeploymentPathBuilder deploymentPathBuilder, IList<ICIBasePathBuilder> ciPathBuilders, ref ValidationResult validationResult);
        bool IsResponsibleFor(XElement domainModelElement);
        IBaseRole CommonRole(XElement element, Dictionary<string, IBaseRole> commonRoles);
    }
}