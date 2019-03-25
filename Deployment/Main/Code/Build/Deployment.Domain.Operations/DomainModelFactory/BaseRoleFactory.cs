using System;
using System.Collections.Generic;
using System.IO;
using System.Linq.Expressions;
using System.Reflection;
using System.Runtime.Serialization.Formatters.Binary;
using System.Text.RegularExpressions;
using System.Xml.Linq;
using Deployment.Common;
using Deployment.Common.Helpers;
using Deployment.Common.Xml;
using Deployment.Domain.Roles;

namespace Deployment.Domain.Operations.DomainModelFactory
{
    public abstract class BaseRoleFactory<T> : XmlParserBase, IDomainModelFactory where T : IBaseRole
    {
        protected readonly IList<string> XPathExpressions;
        protected string DefaultConfig;
        private const string SplitRegEx = @"\,\s*";

        protected BaseRoleFactory(string defaultConfig, IEnumerable<string> isResponsibleForXPathExpressions)
        {
            DefaultConfig = defaultConfig;
            XPathExpressions = new List<string>(isResponsibleForXPathExpressions);
        }

        public abstract IBaseRole DomainModelCreate(XElement rootNode, ref ValidationResult validationResult);

        public virtual bool ValidateDomainObject(T domainObject, ref ValidationResult validationResult,
            bool suppressStandardParseValidations = false)
        {
            return validationResult.Result;
        }

        protected virtual IBaseRole ParseCommonAttributes(IBaseRole role, XElement domainModelElement, ref ValidationResult validationResult)
        {
            //TODO: Really name and include should be immutable as they are used for hashing etc. Think of an alternative way of handling these.
            ParseElementAttribute(domainModelElement, "Name", () => role.Name, ref validationResult, ValidationAction.NotNullOrEmpty("Name attribute cannot be null or empty."));
            ParseElementAttribute(domainModelElement, "Description", () => role.Description, ref validationResult, ValidationAction.NotNullOrEmpty("Description attribute cannot be null or empty."));
            ParseElementAttribute(domainModelElement, "Include", () => role.Include, ref validationResult, ValidationAction.NotNullOrEmpty("Include attribute cannot be null or empty."));
            ParseElementAttribute(domainModelElement, "Config", () => role.Configuration, ref validationResult, ValidationAction.NotNullOrEmpty("Config attribute cannot be null or empty."));
            ParseElementAttribute(domainModelElement, "Groups", role.Groups, ref validationResult);

            return role;
        }

        public virtual IBaseRole ApplyOverrides(IBaseRole commonRole, XElement includedRole, ref ValidationResult validationResult)
        {
            var clone = DeepClone(commonRole);
            ParseCommonAttributes(clone, includedRole, ref validationResult);
            return clone;
        }

        public virtual IBaseRole UpdateParameterisedValues(IBaseRole deployRole, IParameterService parameterService, IDeploymentPathBuilder deploymentPathBuilder, IList<ICIBasePathBuilder> ciPathBuilders,
            ref ValidationResult validationResult)
        {
            return deployRole;
        }

        public virtual bool IsResponsibleFor(XElement domainModelElement)
        {
            var isResponsibleFor = false;
            foreach (var xPathExpression in XPathExpressions)
            {
                isResponsibleFor = domainModelElement.XElementXPathExistanceTest(xPathExpression, Namespaces.NamespaceManager);

                if (isResponsibleFor)
                    break;
            }

            return isResponsibleFor;
        }


        public IBaseRole CommonRole(XElement element, Dictionary<string, IBaseRole> commonRoles)
        {
            var includeKey = element.ReadAttribute<string>("Include");
            if (commonRoles.ContainsKey(includeKey))
            {
                return commonRoles[includeKey];
            }

            throw new ArgumentOutOfRangeException(
                $"Unable to find the common role for the include [{includeKey}] for role [{element}]");
        }

        protected virtual bool ParseElementAttribute<TValue>(IEnumerable<XElement> includedRoles, string name, IList<TValue> target, ref ValidationResult validationResult)
        {
            var values = includedRoles.ReadAttribute<TValue>(name);

            target.AddRange(values);

            return true;
        }

        protected virtual bool ParseElementAttribute<TValue>(XElement includedRole, string name, IList<TValue> target, ref ValidationResult validationResult)
        {
            if (includedRole == null)
                return false;

            var tryReadResult = includedRole.TryReadAttribute<string>(name);

            if (!tryReadResult.Item1.HasValue)
            {
                validationResult.AddError("Attribute value cannot be casted to type IBaseRole for property");
                return false;
            }

            ProcessStringList(target, tryReadResult.Item2);

            return true;
        }

        protected virtual bool ParseElementValue<TValue>(XElement includedRole, string name, XNamespace xmlNamespace, IList<TValue> target, ref ValidationResult validationResult)
        {
            if (includedRole == null)
                return false;

            var tryReadResult = includedRole.TryReadChildElement<string>(name, xmlNamespace);

            if (!tryReadResult.Item1.HasValue)
            {
                validationResult.AddError("Value for property is invalid");
                return false;
            }

            ProcessStringList(target, tryReadResult.Item2);

            return true;
        }

        protected virtual bool ParseElementValue<TValue>(IEnumerable<XElement> includedRoles, IList<TValue> target, ref ValidationResult validationResult)
        {
            foreach (var includedRole in includedRoles)
            {
                var value = includedRole.ReadElement<TValue>();
                target.Add(value);
            }

            return true;
        }

        protected virtual bool ParseElementValue<TValue>(XElement includedRole, string name, XNamespace xmlNamespace, Expression<Func<TValue>> expression, ref ValidationResult validationResult, ValidationAction<TValue> validationAction = null)
        {
            var property = expression.Property();
            var container = expression.Container();

            var typeName = container?.GetType().Name ?? string.Empty;

            var attribute = property.GetCustomAttribute<MandatoryAttribute>();
            var mandatory = attribute != null;

            var tryReadResult = includedRole.TryReadChildElement<TValue>(name, xmlNamespace);

            if (!tryReadResult.Item1.HasValue)
            {
                validationResult.AddError($"Value for property {property.Name} on type {typeName} is invalid");
                return false;
            }

            //if element not found and value is mandatory, need to return error
            //but not if calling as an override, as common role property may be already set.
            if (!tryReadResult.Item1.Value)
            {
                if (mandatory)
                    validationResult.AddError($"Value for property {property.Name} on type {typeName} is mandatory and was not set.");
                return false;
            }

            if (validationAction?.Expresssion != null)
            {
                var result = ArgumentHelper.ValidateArgument(validationAction, tryReadResult.Item2);
                if (result != null)
                    validationResult.AddError(result);
            }

            property.SetValue(container, tryReadResult.Item2);

            return true;
        }

        protected void ProcessStringList<TValue>(ICollection<TValue> sourceList, string value)
        {
            //should never happen but check anyway
            if (string.IsNullOrWhiteSpace(value))
                return;

            var regEx = new Regex(SplitRegEx);

            var values = regEx.Split(value);

            sourceList.Clear();

            var type = Nullable.GetUnderlyingType(typeof(TValue)) ?? typeof(TValue);

            foreach (var item in values)
            {
                if (type != typeof(TValue) && string.IsNullOrWhiteSpace(item))
                {
                    continue;
                }

                sourceList.Add((TValue)Convert.ChangeType(item, type));
            }
        }

        protected IBaseRole DeepClone(IBaseRole obj)
        {
            using (var memoryStream = new MemoryStream())
            {
                var formatter = new BinaryFormatter();
                formatter.Serialize(memoryStream, obj);
                memoryStream.Position = 0;

                return (IBaseRole)formatter.Deserialize(memoryStream);
            }
        }
    }
}