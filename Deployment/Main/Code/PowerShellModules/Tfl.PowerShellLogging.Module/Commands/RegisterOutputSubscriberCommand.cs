using System.Management.Automation;

namespace TFL.PowerShell.Logging.Commands
{
    [Cmdlet(VerbsLifecycle.Register, "OutputSubscriber")]
    public class RegisterOutputSubscriberCommand : PSCmdlet
    {
        #region Parameters

        [Parameter(ParameterSetName = "AttachExisting",
            Mandatory = true,
            ValueFromPipeline = true,
            Position = 0)]
        public ScriptBlockOutputSubscriber InputObject { get; set; }

        [Parameter(ParameterSetName = "New")]
        public ScriptBlock OnWriteDebug { get; set; }

        [Parameter(ParameterSetName = "New")]
        public ScriptBlock OnWriteError { get; set; }

        [Parameter(ParameterSetName = "New")]
        public ScriptBlock OnWriteOutput { get; set; }

        [Parameter(ParameterSetName = "New")]
        public ScriptBlock OnWriteVerbose { get; set; }

        [Parameter(ParameterSetName = "New")]
        public ScriptBlock OnWriteWarning { get; set; }

        #endregion

        protected override void EndProcessing()
        {
            ScriptBlockOutputSubscriber subscriber;

            if (ParameterSetName == "New")
            {
                subscriber = new ScriptBlockOutputSubscriber(OnWriteOutput,
                                                             OnWriteDebug,
                                                             OnWriteVerbose,
                                                             OnWriteError,
                                                             OnWriteWarning);
                WriteObject(subscriber);
            }
            else
            {
                subscriber = InputObject;
            }

            HostIoInterceptor.Instance.AttachToHost(CommandRuntime);
            HostIoInterceptor.Instance.AddSubscriber(System.Management.Automation.Runspaces.Runspace.DefaultRunspace.InstanceId, subscriber);
        }
    }
}