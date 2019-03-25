using System.Collections.Generic;

namespace Deployment.Database
{
    public class PatchingValidationResult
    {
        private readonly IList<string> _errorMessages;
        public PatchingValidationResult()
        {
            _errorMessages = new List<string>();
        }

        public bool IsValid { get; set; }
        public string UserMessage { get; set; }
        public IList<string> ErrorMessages { get { return _errorMessages; } }
        public string ValidationType { get; set; }
    }
}