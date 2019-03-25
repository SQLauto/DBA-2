using System;
using System.ComponentModel;
using System.Globalization;
using System.Linq;

namespace Deployment.Common.Helpers
{
    /// <summary>
    /// Provides a set of helper methods for manipulating <see cref="Enum"/> types.
    /// </summary>
    /// <remarks>
    /// Some of the functionality here is not need if using .net 4.0 as it provides new functionality.
    /// </remarks>
    public static class EnumHelper {

        /// <summary>
        /// Gets the description.
        /// </summary>
        /// <param name="type">The type.</param>
        /// <param name="member">The member.</param>
        /// <returns></returns>
        public static string GetDescription(Type type, string member) {

            ArgumentHelper.AssertEnum(type);

            var memInfo = type.GetMember(member);

            if(memInfo.Length > 0) {
                var attrib = memInfo[0].GetCustomAttributes(false).OfType<DescriptionAttribute>().FirstOrDefault();

                if(attrib != null) {
                    return attrib.Description;
                }
            }

            return CultureInfo.CurrentCulture.TextInfo.ToTitleCase(member);
        }

        /// <summary>
        /// Attempts to find an Enumerations value based upon it's description attrbute value, if any.
        /// If no description attribute is present, the string value of the enum is assumed, and it will then attempt
        /// to parse that value.
        /// If no match is found, the default value for the enum is returned.
        /// It is worth ensuring that all Enums have a properly defined default (initial) value.
        /// </summary>
        /// <typeparam name="TEnum"></typeparam>
        /// <param name="description">The description.</param>
        /// <returns>The found enum or the default value if not found.</returns>
        public static TEnum GetEnumByDescription<TEnum>(string description) {

            ArgumentHelper.AssertNotNullOrEmpty(description, "description");

            var type = typeof (TEnum);

            if (!type.IsEnum || string.IsNullOrEmpty(description))
                throw new InvalidEnumArgumentException();

            var names = type.GetEnumNames();

            var result = (from name in names
                      let memInfo = type.GetMember(name)
                      where memInfo.Length > 0
                      let attrib = memInfo[0].GetCustomAttributes(false).OfType<DescriptionAttribute>().FirstOrDefault()
                      where
                          attrib != null &&
                          attrib.Description.Equals(description, StringComparison.InvariantCultureIgnoreCase)
                      select name).FirstOrDefault();

            if(result==null)
                throw new ArgumentException("The argument supplied is not a valid enum description", "description");

            //cannot use normal TryParse here as our TEnum is not constrained.
            var parsedValue = (int)Enum.Parse(type, result, false);

            if (!Enum.IsDefined(type, parsedValue))
                throw new ArgumentException("The argument supplied is not a valid enum value", "result");

            var enumeration = (TEnum)Enum.ToObject(typeof(TEnum), parsedValue);

            return enumeration;
        }

        /// <summary>
        /// Attempts to parse a string value to a given type of enumeration.  Anything other than a successful parse
        /// will return false.  The enumeration to be created is set as an out parameter.
        /// </summary>
        /// <typeparam name="TEnum">The type of the enum.</typeparam>
        /// <param name="value">The value.</param>
        /// <param name="ignoreCase">Ignore the case.</param>
        /// <returns></returns>
        public static Tuple<bool, TEnum> TryParse<TEnum>(string value, bool ignoreCase = true)
        {
            var enumeration = default(TEnum);

            if(string.IsNullOrWhiteSpace(value))
                return new Tuple<bool, TEnum>(false, enumeration);

            var type = typeof(TEnum);

            if(!type.IsEnum || string.IsNullOrEmpty(value))
                return new Tuple<bool, TEnum>(false, enumeration);

            if(value.IndexOf('|') != -1) {
                var values = value.Split('|');

                foreach(var item in values) {
                    try {
                        var temp = (TEnum)Enum.Parse(type, item, ignoreCase);

                        enumeration =
                            (TEnum)Enum.ToObject(typeof(TEnum),
                                ToUInt64(temp) | ToUInt64(enumeration));
                    }
                    catch(ArgumentException) {
                        return new Tuple<bool, TEnum>(false, enumeration);
                    }
                }
            }
            else {
                try
                {
                    var names = type.GetEnumNames();

                    if (names.Any(n =>
                        n.Equals(value,
                            ignoreCase
                                ? StringComparison.InvariantCultureIgnoreCase
                                : StringComparison.InvariantCulture)))
                    {

                        //cannot use normal TryParse here as our TEnum is not constrained.
                        var parsedValue = (int)Enum.Parse(type, value, ignoreCase);

                        if (!Enum.IsDefined(type, parsedValue))
                            return new Tuple<bool, TEnum>(false, enumeration);

                        enumeration = (TEnum)Enum.ToObject(typeof(TEnum), parsedValue);
                    }
                    else
                    {
                        //attempt to find by description
                        enumeration = GetEnumByDescription<TEnum>(value);
                    }
                }
                catch(ArgumentException) {
                    return new Tuple<bool, TEnum>(false, enumeration);
                }
            }

            return new Tuple<bool, TEnum>(true, enumeration);
        }

        /// <exception cref="InvalidOperationException">Unrecognized enum type.</exception>
        //[CLSCompliant(false)] - Not needed as Assembly does not have CSLCompliantAttribute set.
        internal static ulong ToUInt64(object value) {
            switch(Convert.GetTypeCode(value)) {
                case TypeCode.SByte:
                case TypeCode.Int16:
                case TypeCode.Int32:
                case TypeCode.Int64:
                    return (ulong)Convert.ToInt64(value, CultureInfo.InvariantCulture);

                case TypeCode.Byte:
                case TypeCode.UInt16:
                case TypeCode.UInt32:
                case TypeCode.UInt64:
                    return Convert.ToUInt64(value, CultureInfo.InvariantCulture);
            }

            throw new InvalidOperationException("Unrecognized enum type.");
        }
    }
}