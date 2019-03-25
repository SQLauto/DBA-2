using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Diagnostics;
using System.Globalization;
using System.Linq;
using System.Xml.Linq;
using System.Xml.XPath;
using Deployment.Common.Helpers;

namespace Deployment.Common.Xml {
    public static class XDocumentExtensions {

        public static T ReadAttribute<T>(this XElement element, string name, XNamespace xmlNamespace = null) {

            if(element.Attributes(name).IsNullOrEmpty())
                throw new ArgumentException($"No attribute was found for given name '{name}'");

            var value = element.Attribute(name)?.Value;

            var type = Nullable.GetUnderlyingType(typeof(T)) ?? typeof(T);
            if (type != typeof(T) && string.IsNullOrWhiteSpace(value))
            {
                return default(T);
            }

            if (type.IsEnum)
            {
                var result = EnumHelper.TryParse<T>(value);

                if (!result.Item1)
                    throw new InvalidCastException("Not a valid enumeration value.");

                return result.Item2;
            }

            var converter = TypeDescriptor.GetConverter(typeof(T));

            try
            {
                return (T)converter.ConvertFromInvariantString(value);
            }
            catch
            {
                return (T)Convert.ChangeType(value, type);
            }
        }

        public static IList<T> ReadAttribute<T>(this IEnumerable<XElement> element, string name, XNamespace xmlNamespace = null)
        {
            return element.Select(item => item.ReadAttribute<T>(name, xmlNamespace)).ToList();
        }

        public static Tuple<bool?, T> TryReadAttribute<T>(this XElement element, string name, XNamespace xmlNamespace = null)
        {
            try
            {
                var value = element.ReadAttribute<T>(name, xmlNamespace);
                return new Tuple<bool?, T>(true, value);
            }
            catch (ArgumentException)
            {
                return new Tuple<bool?, T>(false, default(T));
            }
            catch (InvalidCastException)
            {
                return new Tuple<bool?, T>(null, default(T));
            }
        }

        public static T ReadElement<T>(this XElement rootNode)
        {
            if (rootNode == null)
                throw new ArgumentException("RootNode element as null.");

            var value = rootNode.Value;

            var type = Nullable.GetUnderlyingType(typeof(T)) ?? typeof(T);
            if (type != typeof(T) && string.IsNullOrWhiteSpace(value))
            {
                return default(T);
            }

            if (type.IsEnum)
            {
                var result = EnumHelper.TryParse<T>(value);

                if (!result.Item1)
                    throw new InvalidCastException("Not a valid enumeration value.");

                return result.Item2;
            }

            var converter = TypeDescriptor.GetConverter(typeof(T));

            try
            {
                return (T)converter.ConvertFromInvariantString(value);
            }
            catch
            {
                return (T)Convert.ChangeType(value, type);
            }
        }

        public static T ReadChildElement<T>(this XElement rootNode, string name, XNamespace xmlNamespace = null) {

            var node = xmlNamespace == null ? rootNode.Element(name) : rootNode.Element(xmlNamespace + name);

            if (node == null) throw new ArgumentException("No element found for given name");

            return ReadElement<T>(node);
        }

        public static Tuple<bool?, T> TryReadChildElement<T>(this XElement element, string name, XNamespace xmlNamespace = null)
        {
            try
            {
                var value = element.ReadChildElement<T>(name, xmlNamespace);
                return new Tuple<bool?, T>(true, value);
            }
            catch (ArgumentException)
            {
                return new Tuple<bool?, T>(false, default(T));
            }
            catch (InvalidCastException)
            {
                return new Tuple<bool?, T>(null, default(T));
            }
        }

        public static XElement AddAttribute<T>(this XElement element, string name, T value)
        {
            element.Add(new XAttribute(name, value));
            return element;
        }

        [DebuggerHidden]
        public static T XPathReadElement<T>(this XElement rootNode, string path) {
            var node = rootNode.XPathSelectElement(path);

            if (node == null) throw new ArgumentException("No node found for given xpath");
            return ReadElement<T>(node);
        }

        [DebuggerHidden]
        public static bool ElementExists(this XElement node, string xpathExpression)
        {
            var result = node.XPathSelectElement(xpathExpression);
            return result != null;
        }
    }
}