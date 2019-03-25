using System.Management.Automation;

namespace TFL.PowerShell.Logging.Commands
{
    [Cmdlet(VerbsLifecycle.Register, "Host")]
    public class RegisterHostCommand : PSCmdlet
    {
        [Parameter]
        public SwitchParameter NoConsole { get; set; }

        protected override void EndProcessing()
        {
            HostIoInterceptor.Instance.AttachToHost(CommandRuntime);
            HostIoInterceptor.Instance.SupressConsole = NoConsole;
        }
    }
}