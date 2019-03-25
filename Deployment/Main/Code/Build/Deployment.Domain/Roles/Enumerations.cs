using System.ComponentModel;

namespace Deployment.Domain.Roles
{
    public enum MsiAction
    {
        Install = 0,
        Uninstall,
        Reinstall
    }

    public enum ScheduledTaskAction
    {
        Install = 0,
        Uninstall,
        Reinstall
    }

    public enum ActionType
    {
        Program = 0,
        Email,
        DisplayMessage
    }

    public enum WindowsServiceStartupType
    {
        Manual = 0,
        Automatic,
        [Description("Automatic Delayed")]
        AutomaticDelayed,
        Disabled
    }
}