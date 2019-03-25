using System;

namespace Deployment.Common {
    /// <summary>
    ///
    /// </summary>
    public static class StringExtensions {
        /// <summary>
        /// universal conversion from string
        /// !! throws exception on error
        /// </summary>
        public static T StringToValue<T>(this string strValue) {
            if(typeof(Enum).IsAssignableFrom(typeof(T))) {
                return (T)Enum.Parse(typeof(T), strValue);
            }

            return (T)Convert.ChangeType(strValue, typeof(T));
        }

        /// <summary>
        /// Parses the int or default.
        /// </summary>
        /// <param name="valueToParse">The value to parse.</param>
        /// <param name="defaultValue">The default value.</param>
        /// <returns></returns>
        public static int ParseOrDefault(this string valueToParse, int defaultValue) {

            if(string.IsNullOrWhiteSpace(valueToParse))
                return defaultValue;

            int value;

            return !int.TryParse(valueToParse, out value) ? defaultValue : value;
        }

        /// <summary>
        /// Parses the boolean or default.
        /// </summary>
        /// <param name="valueToParse">The value to parse.</param>
        /// <param name="defaultValue">if set to <c>true</c> [default value].</param>
        /// <returns></returns>
        public static bool ParseOrDefault(this string valueToParse, bool defaultValue) {

            if(string.IsNullOrWhiteSpace(valueToParse))
                return defaultValue;

            bool value;

            return !bool.TryParse(valueToParse, out value) ? defaultValue : value;
        }
    }
}