using System.ComponentModel;

namespace Deployment.Database.Logging
{
    public enum DeploymentVCloudAction
    {
        None = 0,
        [Description("Enter_InitSession")]
        EnterInitSession = 1,
        [Description("Exit_InitSession")]
        ExitInitSession = 2,
        [Description("Enter_Execute_Refresh_vApp")]
        EnterExecuteRefreshVapp = 3,
        [Description("Exit_Execute_Refresh_vApp")]
        ExitExecuteRefreshVapp = 4,
        [Description("Enter_New_Vapp_from_Template")]
        EnterNewVappFromTemplate = 5,
        [Description("Exit_New_Vapp_from_Template")]
        ExitNewVappFromTemplate = 6,
        [Description("Begin_Start_CIvApp")]
        BeginStartCiVapp = 7,
        [Description("End_Start_CIvApp")]
        EndStartCiVapp = 8,
        [Description("Begin_Stop_CIvApp")]
        BeginStopCiVapp = 9,
        [Description("End_Stop_CIvApp")]
        EndStopCiVapp = 10,
        [Description("Begin_Remove_CIvApp")]
        BeginRemoveCiVapp = 11,
        [Description("End_Remove_CIvApp")]
        EndRemoveCiVapp = 12,
        [Description("Enter_Verify_Vapp")]
        EnterVerifyVapp = 13,
        [Description("Exit_Verify_Vapp")]
        ExitVerifyVapp = 14,
        [Description("Begin_New_CIvApp")]
        BeginNewCiVapp = 15,
        [Description("End_New_CIvApp")]
        EndNewCiVapp = 16,
        EnterExecuteCreateVapp = 17,
        ExitExecuteCreateVapp = 18
    }
}