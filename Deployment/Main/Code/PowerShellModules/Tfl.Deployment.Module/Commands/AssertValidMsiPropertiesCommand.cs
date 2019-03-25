using System.Management.Automation;
using Deployment.Installation;

namespace Tfl.Deployment.Commands
{
    [Cmdlet(VerbsLifecycle.Assert, "ValidMsiProperties")]
    [OutputType(typeof(bool))]
    public class AssertValidMsiPropertiesCommand : PSCmdlet
    {
        [Parameter(Mandatory = true, Position = 0)]
        [ValidateNotNullOrEmpty]
        [Alias("MsiPath", "FilePath")]
        public string Path { get; set; }

        [Parameter(Mandatory = true)]
        public string[] Name { get; set; }

        protected override void ProcessRecord()
        {
            var installHelper = new InstallationHelper();

            var result = installHelper.ExpectedPublicPropertiesExist(Path, Name);

            if (!result.AllExpectedPropertiesExist)
            {
                WriteWarning("Check the WIX definition as one or more properties appear to be: (a) missing, (b) misspelt or (c) not upper case. FOR A PROPERTY TO BE PUBLIC IT MUST BE UPPER CASE in WIX.");

                foreach (var prop in result.InvalidPropertyNames)
                {
                    WriteWarning(
                        $"The Property {prop} was not found within the Property or CustomAction section of the MSI");
                }

            }

            WriteObject(result.AllExpectedPropertiesExist);
        }
    }
}