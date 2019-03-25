using System;
using Deployment.Common.Helpers;

namespace Deployment.Common
{
    /// <summary>
    ///
    /// </summary>
    public static class EnumExtensions
    {
        /// <summary>
        /// Returns the description attribute value of an enumeration if present,
        /// otherwise simply returns ToString()
        /// </summary>
        /// <param name="value">The enumeration.</param>
        /// <returns></returns>
        public static string Description(this Enum value) {

            var type = value.GetType();

            return EnumHelper.GetDescription(type, value.ToString());
        }
    }
}