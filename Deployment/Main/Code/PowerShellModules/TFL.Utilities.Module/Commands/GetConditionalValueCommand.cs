using System;
using System.Management.Automation;

namespace TFL.Utilities.Commands
{
    [Cmdlet(VerbsCommon.Get, "ConditionalValue")]
    public class GetConditionalValueCommand : PSCmdlet
    {
        [Parameter(Mandatory = true,
          Position = 0,
          ValueFromPipeline = true)]
        public bool Condition { get; set; }

        [Parameter(Mandatory = true)]
        [AllowNull]
        public object TrueValue { get; set; }

        [Parameter(Mandatory = true)]
        [AllowNull]
        public object FalseValue { get; set; }

        protected override void ProcessRecord()
        {
            if (TrueValue == null && FalseValue == null)
                throw new ArgumentException("Both TrueValue and FalseValue are null.  At least one of these values needs to be a non-null value.");

            var trueScript = TrueValue as ScriptBlock;
            var falseScript = FalseValue as ScriptBlock;

            WriteObject(Condition ? trueScript == null ? TrueValue : trueScript.Invoke()[0].BaseObject : falseScript == null ? FalseValue : falseScript.Invoke()[0].BaseObject);
        }
    }
}