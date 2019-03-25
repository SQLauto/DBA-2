using System;
using System.Globalization;
using System.Management.Automation;

namespace Tfl.PowerShell.Common
{
    public class ConsoleColorCmdlet : PSCmdletBase
    {
        private ConsoleColor _bgColor;
        private ConsoleColor _fgColor;
        private bool _isBgColorSet;
        private bool _isFgColorSet;

        [Parameter]
        public ConsoleColor ForegroundColor
        {
            get
            {
                if (IsForegroundColorSet) return _fgColor;
                _fgColor = Host.UI.RawUI.ForegroundColor;
                _isFgColorSet = true;
                return _fgColor;
            }
            set
            {
                if (value >= ConsoleColor.Black && value <= ConsoleColor.White)
                {
                    _fgColor = value;
                    _isFgColorSet = true;
                }
                else
                    ThrowTerminatingError(BuildOutOfRangeErrorRecord(value, "SetInvalidForegroundColor"));
            }
        }

        [Parameter]
        public ConsoleColor BackgroundColor
        {
            get
            {
                if (IsBackgroundColorSet) return _bgColor;
                _bgColor = Host.UI.RawUI.BackgroundColor;
                _isBgColorSet = true;
                return _bgColor;
            }
            set
            {
                if (value >= ConsoleColor.Black && value <= ConsoleColor.White)
                {
                    _bgColor = value;
                    _isBgColorSet = true;
                }
                else
                    ThrowTerminatingError(BuildOutOfRangeErrorRecord(value, "SetInvalidBackgroundColor"));
            }
        }

        public bool IsForegroundColorSet => _isFgColorSet;
        public bool IsBackgroundColorSet => _isBgColorSet;

        private static ErrorRecord BuildOutOfRangeErrorRecord(object value, string errorId)
        {
            var message = string.Intern(string.Format(CultureInfo.CurrentCulture, "{0}", value.ToString()));
            //string message = StringUtil.Format(HostStrings.InvalidColorErrorTemplate, (object)val.ToString());
            return new ErrorRecord(new ArgumentOutOfRangeException(nameof(value), value, message), errorId,
                ErrorCategory.InvalidArgument, null);
        }
    }
}