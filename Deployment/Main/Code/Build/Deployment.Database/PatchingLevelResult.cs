using System.Collections.Generic;

namespace Deployment.Database
{
    public class PatchingLevelResult
    {
        private readonly IList<string> _errorMessages;
        public PatchingLevelResult()
        {
            _errorMessages = new List<string>();
        }

        public bool IsValid { get; set; }
        public bool IsAtTestedPatchLevel { get; set; }
        public string UserMessage { get; set; }
        public string ErrorMessage { get; set; }
    }
}