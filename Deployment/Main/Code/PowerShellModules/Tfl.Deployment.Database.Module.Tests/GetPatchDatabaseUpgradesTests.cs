using Deployment.Common.Helpers;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Tfl.Deployment.Database.Commands;
using Tfl.Module.Testing;

namespace Tfl.Deployment.Database.Module.Tests
{
    [TestClass]
    public class GetPatchDatabaseUpgradesTests
    {
        [TestMethod]
        [TestCategory("PatchDBUpgrades")]
        [ExpectParameterBindingException(MessagePattern = "Path")]
        public void TestInvokeWithMissingPathThrows()
        {
            PsCmdletAssert.Invoke(typeof(GetDatabasePatchUpgrades), new[] { new Parameter("PatchFolderPath", "Path") });
        }

        [TestMethod]
        [TestCategory("PatchDBUpgrades")]
        [ExpectParameterBindingValidationException(MessagePattern = "Path")]
        public void TestInvokeWithEmptPathThrows()
        {
            PsCmdletAssert.Invoke(typeof(GetDatabasePatchUpgrades), new[] { new Parameter("Path", string.Empty), new Parameter("PatchFolderPath", "Path") });
        }

        [TestMethod]
        [TestCategory("PatchDBUpgrades")]
        [ExpectParameterBindingValidationException(MessagePattern = "Path")]
        public void TestInvokeWithNullPathThrows()
        {
            PsCmdletAssert.Invoke(typeof(GetDatabasePatchUpgrades), new[] { new Parameter("Path", null), new Parameter("PatchFolderPath", "Path") });
        }

        [TestMethod]
        [TestCategory("PatchDBUpgrades")]
        public void TestInvokeWitValidParameters()
        {
            var xx = new[]
            {
                new Parameter("Path", @"D:\Deploy\DropFolderDB"),
                new Parameter("PatchFolderPath", @"Pare.Database\Pcs.Common\Scripts\Patching"),
                new Parameter("UpgradeScript", "Patching.sql"),
                new Parameter("PreValidationScript", "PreValidation.sql"),
                new Parameter("PostValidationScript", "PostValidation.sql"),
                new Parameter("PatchLevelDeterminationScript", "DetermineIfDatabaseIsAtThisPatchLevel.sql"),
                new Parameter("PatchFolderFormatStartsWith", "B???_R????_"),

            };

            var result = PsCmdletAssert.Invoke(typeof(GetDatabasePatchUpgrades), xx);
        }
    }
}

//----                           -----
//UpgradeScript Patching.sql
//PatchLevelDeterminationScript DetermineIfDatabaseIsAtThisPatchLevel.sql
//PostValidationScript           PostValidation.sql
//PreValidationScript            PreValidation.sql
//ScriptPath                     D:\Deploy\DropFolderDB\Pare.Database\Pcs.Common\Scripts\Patching