using System;
using System.Linq.Expressions;
using System.Reflection;

namespace Deployment.Common.Helpers
{

    /// <summary>
    /// Helper class for allowing the use of passing Property names using a lambda expression rather that hard coded strings.
    /// </summary>
    /// <example>
    /// <code>
    /// public abstract class ObservableObject : INotifyPropertyChanged {
    ///    public event PropertyChangedEventHandler PropertyChanged = delegate { };
    ///
    ///    protected void OnPropertyChanged() { // All properties changed
    ///        OnPropertyChanged(null);
    ///    }
    ///
    ///    protected virtual void OnPropertyChanged(string propertyName) {
    ///        PropertyChanged(this, new PropertyChangedEventArgs(propertyName));
    ///    }
    ///
    ///    protected void OnPropertyChanged{T}(Expression{Func{T}} expression) {
    ///        OnPropertyChanged(Reflect.GetProperty(expression).Name);
    ///    }
    /// }
    /// public class Foo : ObservableObject {
    ///    private string message;
    ///
    ///    public string Message {
    ///        get { return this.message; }
    ///        set { this.message = value; OnPropertyChanged(() => Message); }
    ///    }
    /// }
    /// </code>
    /// </example>
    public static class Reflect
    {
        public static MemberInfo GetMember(Expression<Action> expression)
        {
            if (expression == null)
            {
                throw new ArgumentNullException(
                    GetMember(() => expression).Name);
            }

            return GetMemberInfo(expression);
        }

        /// <summary>
        /// </summary>
        /// <param name="expression">The expression.</param>
        /// <returns></returns>
        public static MemberInfo Member(this Expression<Action> expression)
        {
            return GetMember(expression);
        }

        /// <summary>
        ///
        /// </summary>
        /// <param name="expression"></param>
        /// <typeparam name="T"></typeparam>
        /// <returns></returns>
        /// <exception cref="ArgumentNullException"></exception>
        public static MemberInfo GetMember<T>(Expression<Func<T>> expression)
        {
            if (expression == null)
            {
                throw new ArgumentNullException(
                    GetMember(() => expression).Name);
            }

            return GetMemberInfo(expression);
        }

        /// <summary>
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="expression">The expression.</param>
        /// <returns></returns>
        public static MemberInfo Member<T>(this Expression<Func<T>> expression)
        {
            return GetMember(expression);
        }

        /// <summary>
        ///
        /// </summary>
        /// <param name="expression"></param>
        /// <returns></returns>
        /// <exception cref="ArgumentException"></exception>
        public static MethodInfo GetMethod(Expression<Action> expression)
        {
            var method = GetMember(expression) as MethodInfo;
            if (method == null)
            {
                throw new ArgumentException(
                    "Not a method call expression", GetMember(() => expression).Name);
            }

            return method;
        }

        /// <summary>
        /// </summary>
        /// <param name="expression">The expression.</param>
        /// <returns></returns>
        public static MethodInfo Method(this Expression<Action> expression)
        {
            return GetMethod(expression);
        }

        /// <summary>
        ///
        /// </summary>
        /// <param name="expression"></param>
        /// <typeparam name="T"></typeparam>
        /// <returns></returns>
        /// <exception cref="ArgumentException"></exception>
        public static PropertyInfo GetProperty<T>(Expression<Func<T>> expression)
        {
            var property = GetMember(expression) as PropertyInfo;
            if (property == null)
            {
                throw new ArgumentException(
                    "Not a property expression", GetMember(() => expression).Name);
            }

            return property;
        }

        /// <summary>
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="expression">The expression.</param>
        /// <returns></returns>
        public static PropertyInfo Property<T>(this Expression<Func<T>> expression)
        {
            return GetProperty(expression);
        }

        /// <summary>
        ///
        /// </summary>
        /// <param name="expression"></param>
        /// <typeparam name="T"></typeparam>
        /// <returns></returns>
        /// <exception cref="ArgumentException"></exception>
        public static FieldInfo GetField<T>(Expression<Func<T>> expression)
        {
            var field = GetMember(expression) as FieldInfo;
            if (field == null)
            {
                throw new ArgumentException(
                    "Not a field expression", GetMember(() => expression).Name);
            }

            return field;
        }

        public static object Container<T>(this Expression<Func<T>> expression)
        {
            var x = expression.Body as MemberExpression;

            if (x == null)
            {
                return null;
            }

            return Evaluate(x.Expression);
        }
        public static object Evaluate(Expression e)
        {
            switch (e.NodeType)
            {
                case ExpressionType.Constant:
                    return (e as ConstantExpression).Value;
                case ExpressionType.MemberAccess:
                    {
                        var propertyExpression = e as MemberExpression;
                        var field = propertyExpression.Member as FieldInfo;
                        var property = propertyExpression.Member as PropertyInfo;
                        var container = propertyExpression.Expression == null ? null : Evaluate(propertyExpression.Expression);
                        if (field != null)
                            return field.GetValue(container);

                        return property != null ? property.GetValue(container, null) : null;
                    }
                case ExpressionType.ArrayIndex: //Arrays
                    {
                        var arrayIndex = e as BinaryExpression;
                        var idx = (int)Evaluate(arrayIndex.Right);
                        var array = (object[])Evaluate(arrayIndex.Left);
                        return array[idx];
                    }
                case ExpressionType.Call: //Generic Lists and Dictionaries
                    {
                        var call = e as MethodCallExpression;
                        var callingObj = Evaluate(call.Object);
                        object[] args = new object[call.Arguments.Count];
                        for (var idx = 0; idx < call.Arguments.Count; ++idx)
                            args[idx] = Evaluate(call.Arguments[idx]);
                        return call.Method.Invoke(callingObj, args);
                    }
                default:
                    return null;
            }
        }

        /// <summary>
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="expression">The expression.</param>
        /// <returns></returns>
        public static FieldInfo Field<T>(this Expression<Func<T>> expression)
        {
            return GetField(expression);
        }

        internal static MemberInfo GetMemberInfo(LambdaExpression lambda)
        {
            if (lambda == null)
            {
                throw new ArgumentNullException(
                    GetMember(() => lambda).Name);
            }

            MemberExpression memberExpression = null;
            switch (lambda.Body.NodeType)
            {
                case ExpressionType.Convert:
                    memberExpression = ((UnaryExpression)lambda.Body).Operand as MemberExpression;
                    break;
                case ExpressionType.MemberAccess:
                    memberExpression = lambda.Body as MemberExpression;
                    break;
                case ExpressionType.Call:
                    return ((MethodCallExpression)lambda.Body).Method;
            }

            if (memberExpression == null)
            {
                throw new ArgumentException(
                    "Not a member access", GetMember(() => lambda).Name);
            }

            return memberExpression.Member;
        }
    }

    /// <summary>
    /// Helper class for using lambda expressions for reflecting on types.
    /// <example>
    /// <code>
    /// class Program {
    /// public void Foo() { }
    /// static void Main(string[] args) {
    /// Console.WriteLine(ReflectOn{Program}.GetMethod(p => p.Foo()).Name);
    /// } }
    /// </code>
    ///  </example>
    /// </summary>
    public static class ReflectOn<T>
    {
        public static MemberInfo GetMember(Expression<Action<T>> expression)
        {
            if (expression == null)
            {
                throw new ArgumentNullException(Reflect.GetMember(() => expression).Name);
            }

            return Reflect.GetMemberInfo(expression);
        }

        /// <summary>
        ///
        /// </summary>
        /// <param name="expression"></param>
        /// <typeparam name="TResult"></typeparam>
        /// <returns></returns>
        /// <exception cref="ArgumentNullException"></exception>
        public static MemberInfo GetMember<TResult>(Expression<Func<T, TResult>> expression)
        {
            if (expression == null)
            {
                throw new ArgumentNullException(Reflect.GetMember(() => expression).Name);
            }

            return Reflect.GetMemberInfo(expression);
        }

        /// <summary>
        ///
        /// </summary>
        /// <param name="expression"></param>
        /// <returns></returns>
        /// <exception cref="ArgumentException"></exception>
        public static MethodInfo GetMethod(Expression<Action<T>> expression)
        {
            var method = GetMember(expression) as MethodInfo;
            if (method == null)
            {
                throw new ArgumentException(
                    "Not a method call expression",
                    Reflect.GetMember(() => expression).Name);
            }

            return method;
        }

        /// <summary>
        ///
        /// </summary>
        /// <param name="expression"></param>
        /// <typeparam name="TResult"></typeparam>
        /// <returns></returns>
        /// <exception cref="ArgumentException"></exception>
        public static PropertyInfo GetProperty<TResult>(Expression<Func<T, TResult>> expression)
        {
            var property = GetMember(expression) as PropertyInfo;
            if (property == null)
            {
                throw new ArgumentException(
                    "Not a property expression", Reflect.GetMember(() => expression).Name);
            }

            return property;
        }

        /// <summary>
        ///
        /// </summary>
        /// <param name="expression"></param>
        /// <typeparam name="TResult"></typeparam>
        /// <returns></returns>
        /// <exception cref="ArgumentException"></exception>
        public static FieldInfo GetField<TResult>(Expression<Func<T, TResult>> expression)
        {
            var field = GetMember(expression) as FieldInfo;
            if (field == null)
            {
                throw new ArgumentException(
                    "Not a field expression", Reflect.GetMember(() => expression).Name);
            }

            return field;
        }
    }
}