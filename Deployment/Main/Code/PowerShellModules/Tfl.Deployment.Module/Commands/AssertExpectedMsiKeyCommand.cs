using System;
using System.Management.Automation;
using Deployment.Installation;
using Tfl.PowerShell.Common;

namespace Tfl.Deployment.Commands
{
    [Cmdlet(VerbsLifecycle.Assert, "ExpectedMsiKey")]
    [OutputType(typeof(bool))]
    public class AssertExpectedMsiKeyCommand : PSCmdletBase
    {
        [Parameter(Mandatory = true, Position = 0)]
        [ValidateNotNull]
        public MsiKey MsiKey { get; set; }
        [Parameter(Mandatory = true)]
        [AllowNull]
        [AllowEmptyString]
        public string UpgradeCode { get; set; }
        [Parameter]
        [AllowNull]
        [AllowEmptyString]
        public string ProductCode { get; set; }

        protected override void ProcessRecord()
        {
            if (string.IsNullOrWhiteSpace(UpgradeCode) && string.IsNullOrWhiteSpace(ProductCode))
            {
                WriteError(new ArgumentException("UpgradeCode and ProductCode are both null or empty. This is invalid"), this, ErrorCategory.InvalidArgument, true);
            }

            if (!string.IsNullOrWhiteSpace(UpgradeCode) && !string.IsNullOrWhiteSpace(ProductCode))
            {
                if(UpgradeCode.Equals(ProductCode, StringComparison.InvariantCultureIgnoreCase))
                    WriteError(new ArgumentException("UpgradeCode and ProductCode are have the same value. This is invalid."), this, ErrorCategory.InvalidArgument, true);
            }

            if (MsiKey.UpgradeCode.Equals(MsiKey.ProductCode))
            {
                WriteError(new ArgumentException("MSI Key UpgradeCode and ProductCode are the same. This is invalid."), this, ErrorCategory.InvalidArgument, true);
            }

            if (!MsiKey.HasVersion)
            {
                WriteError(new ArgumentException("MSI Key must have a valid Version."), this, ErrorCategory.InvalidArgument, true);
            }

            var installHelper = new InstallationHelper();

            if (!string.IsNullOrWhiteSpace(ProductCode))
            {
                WriteHost("No upgrade code specified. Asserting existing product code.");

                Guid productCode;

                var result = Guid.TryParse(ProductCode, out productCode)
                                && installHelper.ValidateMsiProductCode(MsiKey, productCode);
                if (!result)
                {
                    WriteError(new ArgumentException($"MSI Key does not have expected product code {productCode}, and there is not upgrade specifed."), this, ErrorCategory.InvalidArgument, true);
                }
            }

            if (!string.IsNullOrWhiteSpace(UpgradeCode))
            {
                WriteHost("No product code specified. Asserting existing upgrade code.");

                Guid upgradeCode;

                var result = Guid.TryParse(UpgradeCode, out upgradeCode)
                             && installHelper.ValidateMsiUpgradeCode(MsiKey, upgradeCode);

                if (!result)
                {
                    WriteError(new ArgumentException($"MSI Key does not have expected upgrade code {upgradeCode}."), this, ErrorCategory.InvalidArgument, true);
                }
            }

            WriteObject(true);
        }
    }
}