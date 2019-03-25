using System;
using System.Linq.Expressions;

namespace Deployment.Common
{
    public class ValidationAction<TValue>
    {
        public ValidationAction()
        {
        }

        public ValidationAction(Expression<Func<TValue, bool>> expresssion)
        {
            Expresssion = expresssion;

        }
        public Expression<Func<TValue, bool>> Expresssion { get; set; }
        public string ErrorMessage { get; set; }
    }

    public static class ValidationAction
    {
        public static ValidationAction<string> NotNullOrEmpty(string errorMessage)
        {
            return new ValidationAction<string> { Expresssion = s => !string.IsNullOrWhiteSpace(s), ErrorMessage = errorMessage + " cannot be null or empty."};
        }

        public static ValidationAction<int> GreaterThanZero(string errorMessage)
        {
            return new ValidationAction<int> { Expresssion = i => i > 0, ErrorMessage = errorMessage + " must be greater than zero." };
        }

        public static ValidationAction<int> EqualToOrGreaterThanZero(string errorMessage)
        {
            return new ValidationAction<int> { Expresssion = i => i >= 0, ErrorMessage = errorMessage + " must be greater than or equal to zero." };
        }
    }
}