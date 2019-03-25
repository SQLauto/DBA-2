using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;

namespace Deployment.Common
{
    /// <summary>
    ///
    /// </summary>
    /// <remarks></remarks>
    public static class TypeExtensions
    {
        public static void Do(this Boolean value, Action action)
        {
            if (value) action();
        }

        /// <summary>
        /// Gets the property value.
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="type">The type.</param>
        /// <param name="propertyName">Name of the property.</param>
        /// <param name="instance">The instance.</param>
        /// <param name="flags">The flags.</param>
        /// <returns></returns>
        public static T GetPropertyValue<T>(this Type type, string propertyName, object instance, BindingFlags flags) {

            var prop = type.GetProperty(propertyName, flags);

            return prop.GetValue<T>(instance);
        }

        /// <summary>
        /// Gets the property value.
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="type">The type.</param>
        /// <param name="propertyName">Name of the property.</param>
        /// <param name="instance">The instance.</param>
        /// <returns></returns>
        public static T GetPropertyValue<T>(this Type type, string propertyName, object instance) {

            return GetPropertyValue<T>(type, propertyName, instance,
                                       BindingFlags.IgnoreCase | BindingFlags.Public | BindingFlags.Instance);
        }

        /// <summary>
        /// Gets the value.
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="propInfo">The prop info.</param>
        /// <param name="instance">The instance.</param>
        /// <returns></returns>
        public static T GetValue<T>(this PropertyInfo propInfo, object instance) {
            return (T)propInfo.GetValue(instance, null);
        }

        /// <summary>
        /// Sets the value.
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="propInfo">The prop info.</param>
        /// <param name="instance">The instance.</param>
        /// <param name="value">The value.</param>
        /// <returns></returns>
        public static bool SetValue<T>(this PropertyInfo propInfo, object instance, T value)
        {
            if (!propInfo.CanWrite)
                return false;

            try
            {
                propInfo.SetValue(instance, value, null);
            }
            catch (InvalidCastException)
            {
                return false;
            }

            return true;
        }

        public static IEnumerable<Type> GetLoadableTypes(this Assembly assembly)
        {
            if (assembly == null) throw new ArgumentNullException("assembly");
            try
            {
                return assembly.GetTypes();
            }
            catch (ReflectionTypeLoadException e)
            {
                return e.Types.Where(t => t != null);
            }
        }

    }
}