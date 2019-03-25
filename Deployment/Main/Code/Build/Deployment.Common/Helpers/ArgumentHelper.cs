using System;
using System.Diagnostics;
using System.Globalization;
using System.Linq;
using System.Linq.Expressions;

namespace Deployment.Common.Helpers
{
    public static class ArgumentHelper
    {
        [DebuggerHidden]
        public static void AssertIntValue(int value, Func<int, bool> comparer, string argName, string message)
        {
            if (comparer(value))
                throw new ArgumentException(message, argName);
        }

        [DebuggerHidden]
        public static void AssertEnum(Type type)
        {
            if (!type.IsEnum)
                throw new ArgumentException("Type is not an Enumeration");
        }

        [DebuggerHidden]
        public static void AssertArgument(Expression<Func<bool>> expression, string argName = "") {

            var unary = expression.Body as UnaryExpression;

            if(unary != null) {

                if(unary.Type != typeof(bool))
                    throw new ArgumentException("Invalid expression argument", nameof(expression));

                var result = expression.Compile().Invoke();

                if(!result)
                    throw new ArgumentException("Invalid argument", nameof(expression));

                return;
            }

            var method = expression.Body as MethodCallExpression;

            if(method != null) {

                if(typeof(bool) != method.Method.ReturnType)
                    throw new ArgumentException("Invalid expression argument", nameof(expression));

                var result = expression.Compile().Invoke();

                if(!result)
                    throw new ArgumentException("Invalid argument", nameof(expression));

                return;
            }

            var binaryExpression = expression.Body as BinaryExpression;

            if(binaryExpression == null)
                throw new ArgumentException("Invalid expression argument", nameof(expression));

            var success = expression.Compile().Invoke();

            if(success)
                return;

            var member = binaryExpression.Left as MemberExpression ?? binaryExpression.Right as MemberExpression;
            throw new ArgumentException("Invalid argument.", member?.Member.Name ?? argName);
        }

        [DebuggerHidden]
        public static string ValidateArgument<TValue>(Expression<Func<TValue, bool>> expression, TValue value, string argName = "")
        {
            var unary = expression.Body as UnaryExpression;

            if (unary != null)
            {

                if (unary.Type != typeof(bool))
                    throw new ArgumentException("Invalid expression argument", nameof(expression));

                var result = expression.Compile().Invoke(value);

                return !result ? "Invalid argument value." : null;
            }

            var method = expression.Body as MethodCallExpression;

            if (method != null)
            {

                if (typeof(bool) != method.Method.ReturnType)
                    throw new ArgumentException("Invalid expression argument", nameof(expression));

                var result = expression.Compile().Invoke(value);

                return !result ? "Invalid argument value." : null;
            }

            var binaryExpression = expression.Body as BinaryExpression;

            if (binaryExpression == null)
                throw new ArgumentException("Invalid expression argument", nameof(expression));

            var success = expression.Compile().Invoke(value);

            if (success)
                return null;

            var member = binaryExpression.Left as MemberExpression ?? binaryExpression.Right as MemberExpression;
            return "Invalid argument value for member " + (member?.Member.Name ?? argName);
        }

        public static string ValidateArgument<TValue>(ValidationAction<TValue> validationAction , TValue value, string argName = "")
        {
            var unary = validationAction.Expresssion.Body as UnaryExpression;

            if (unary != null)
            {
                if (unary.Type != typeof(bool))
                    throw new ArgumentException("Invalid expression argument", "expression");

                var result = validationAction.Expresssion.Compile().Invoke(value);
                return !result ? validationAction.ErrorMessage ?? "Invalid argument value." : null;
            }
            var method = validationAction.Expresssion.Body as MethodCallExpression;
            if (method != null)
            {
                if (typeof(bool) != method.Method.ReturnType)
                    throw new ArgumentException("Invalid expression argument", "expression");
                var result = validationAction.Expresssion.Compile().Invoke(value);
                return !result ? validationAction.ErrorMessage ?? "Invalid argument value." : null;
            }
            var binaryExpression = validationAction.Expresssion.Body as BinaryExpression;
            if (binaryExpression == null)
                throw new ArgumentException("Invalid expression argument", "expression");
            var success = validationAction.Expresssion.Compile().Invoke(value);
            if (success)
                return null;

            var member = binaryExpression.Left as MemberExpression ?? binaryExpression.Right as MemberExpression;
            return validationAction.ErrorMessage ?? "Invalid argument value for member " + (member?.Member.Name ?? argName);
        }

        [DebuggerHidden]
        public static bool IsValidEnumMember<TEnum>(TEnum enumValue, string argName) where TEnum : struct, IConvertible
        {
            if (Attribute.IsDefined(typeof(TEnum), typeof(FlagsAttribute), false))
            {
                bool throwEx;
                long longValue = enumValue.ToInt64(CultureInfo.InvariantCulture);
                if (longValue == 0L)
                {
                    throwEx =
                        !Enum.IsDefined(typeof(TEnum),
                                        ((IConvertible)0).ToType(Enum.GetUnderlyingType(typeof(TEnum)),
                                                                  CultureInfo.InvariantCulture));
                }
                else
                {
                    longValue = Enum.GetValues(typeof(TEnum)).Cast<TEnum>().Aggregate(longValue, (current, value) => current & ~value.ToInt64(CultureInfo.InvariantCulture));
                    throwEx = longValue != 0L;
                }
                return !throwEx;
            }

            return Enum.IsDefined(typeof(TEnum), enumValue);
        }

        [DebuggerHidden]
        public static void AssertNotNull<T>(T arg, string argName) where T : class
        {
            if (arg == null)
                throw new ArgumentNullException(argName);
        }

        [DebuggerHidden]
        public static void AssertNotNull<T>(T arg, string argName, string message) where T : class
        {
            if (arg == null)
            {
                throw new ArgumentNullException(argName, message);
            }
        }

        [DebuggerHidden]
        public static void AssertNotNullOrEmpty(string arg, string argName)
        {
            if (string.IsNullOrWhiteSpace(arg))
                throw new ArgumentException("Value cannot be null, empty or whitespace.", argName);
        }

        [DebuggerHidden]
        public static void AssertNotNullOrEmpty(string arg, string argName, string message)
        {
            if(string.IsNullOrWhiteSpace(arg))
                throw new ArgumentException(message, argName);
        }

        //[DebuggerHidden]
        //public static void ValidateString(string value, string argumentName, ref ValidationResult validationResult)
        //{
        //    if (string.IsNullOrWhiteSpace(argumentName))
        //        validationResult.AddError(
        //            "Value cannot be null, empty or whitespace: " +argumentName);
        //}
    }
}