using System;
using System.Collections.Generic;
using System.Text;

namespace Deployment.Common
{
    public class ValidationResult
    {
        private readonly List<string> _errors;
        private readonly List<Exception> _exceptions;

        public ValidationResult()
        {
            _errors = new List<string>();
            _exceptions = new List<Exception>();
            Result = true;
        }

        public ValidationResult(Exception exception) : this()
        {
            AddException(exception);
        }

        public ValidationResult(string message, Exception exception = null) : this()
        {
            Message = message;
            AddException(exception);
        }

        public void AddException(Exception exception)
        {
            Result = exception == null;

            if (exception == null) return;

            var error = exception.BuildExceptionMessage();
            _errors.Add(error);
            _exceptions.Add(exception);
        }

        public void AddError(string error)
        {
            _errors.Add(error);
            Result = false;
        }

        public void AddErrors(IEnumerable<string> errors)
        {
            _errors.AddRange(errors);
            Result = false;
        }

        public string Message { get; }
        public IList<string> ValidationErrors => _errors;
        public IList<Exception> Exceptions => _exceptions;
        public bool Result { get; private set; }
        public string ErrorString(string rootString)
        {
            if(_errors.IsNullOrEmpty())
                return string.Empty;

            var errorBuilder = new StringBuilder(rootString);

            _errors.ForEach(s => errorBuilder.Append("\t").AppendLine(s));

            return errorBuilder.ToString();
        }

        public static ValidationResult Success(string message = null)
        {
            return new ValidationResult(message);
        }

        public static ValidationResult Failed(Exception exception)
        {
            return new ValidationResult(exception);
        }

        public static ValidationResult Failed(string error)
        {
            var result = new ValidationResult();
            result.AddError(error);
            return result;
        }
    }
}