using System;
using System.Collections.Generic;
using System.Linq.Expressions;
using System.Reflection;
using System.Text.RegularExpressions;
using System.Xml.Linq;
using Deployment.Common.Helpers;

namespace Deployment.Common.Xml
{
    public class XmlParserService : IXmlParserService
    {
        private const string SplitRegEx = @"\,\s*";

        public bool ParseElementAttribute<TValue>(XElement includedRole, string name, Expression<Func<TValue>> expression, ref ValidationResult validationResult,
            ValidationAction<TValue> validationAction = null)
        {
            if (includedRole == null)
                return false;

            var property = expression.Property();
            var container = expression.Container();

            var attribute = property.GetCustomAttribute<MandatoryAttribute>();
            var mandatory = attribute != null;

            var tryReadResult = includedRole.TryReadAttribute<TValue>(name);

            if (!tryReadResult.Item1.HasValue)
            {
                var typeName = typeof(TValue).Name;
                validationResult.AddError($"Attribute value cannot be casted to type {typeName} for property {property.Name}");
                return false;
            }

            //if element not found and value is mandatory, need to return error
            //but not if calling as an override, as common role property may be already set.
            if (!tryReadResult.Item1.Value)
            {
                var typeName = container?.GetType().Name ?? string.Empty;

                if (!mandatory)
                    return false;

                //if the case of reading overrides, we can see if we have a current value on the item.
                //if we do, then value is not overriden, so use current (do nothing)
                var value = expression.Compile()();

                if (validationAction?.Expresssion != null)
                {
                    var result = ArgumentHelper.ValidateArgument(validationAction, value);

                    if (result != null)
                        validationResult.AddError(result);
                }
                else
                {
                    if (value == null)
                        validationResult.AddError($"Value for property {property.Name} on type {typeName} is mandatory and was not set.");
                }

                return false;
            }

            if (validationAction != null)
            {
                var result = ArgumentHelper.ValidateArgument(validationAction, tryReadResult.Item2);
                if (result != null)
                    validationResult.AddError(result);
            }

            property.SetValue(container, tryReadResult.Item2);

            return true;
        }

        public bool ParseElementAttribute<TValue>(XElement includedRole, string name, IList<TValue> target, ref ValidationResult validationResult)
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

        private void ProcessStringList<TValue>(ICollection<TValue> sourceList, string value)
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
    }

    public interface IXmlParserService
    {
        bool ParseElementAttribute<TValue>(XElement includedRole, string name, Expression<Func<TValue>> expression,
            ref ValidationResult validationResult,
            ValidationAction<TValue> validationAction = null);

        bool ParseElementAttribute<TValue>(XElement includedRole, string name, IList<TValue> target,
            ref ValidationResult validationResult);
    }
}