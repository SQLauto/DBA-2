using System;
using System.IO;
using System.Management.Automation;
using System.Text;

namespace TFL.PowerShell.Logging
{
    public class LogFile : HostIoSubscriberBase
    {
        private readonly StringBuilder _writeCache;
        public LogFile(string logFile, StreamType streams = StreamType.All, ScriptBlock errorCallback = null, Guid? runspaceId = null)
        {
            Path = logFile;
            Streams = streams;
            ErrorCallback = errorCallback;
            RunspaceId = runspaceId ?? System.Management.Automation.Runspaces.Runspace.DefaultRunspace.InstanceId;
            _writeCache = new StringBuilder();
            CheckDirectory();
        }

       public ScriptBlock ErrorCallback { get; set; }

       public StreamType Streams { get; set; }

        public override void WriteDebugLine(string message)
        {
            if ((Streams & StreamType.Debug) != StreamType.Debug)
            {
                return;
            }

            if (message == null)
            {
                message = string.Empty;
            }

            try
            {
                if (message != string.Empty)
                {
                    message = LogTimestamp
                        ? $"{DateTime.Now,-19:s} - [D] {message}"
                        : $"[D] {message}";
                }

                _writeCache.Append(message);

                File.AppendAllText(Path, _writeCache.ToString());

                _writeCache.Length = 0;
            }
            catch (Exception e)
            {
                ReportError(e);
            }
        }

        public override void WriteErrorLine(string message)
        {
            if ((Streams & StreamType.Error) != StreamType.Error)
            {
                return;
            }
            if (message == null)
            {
                message = string.Empty;
            }

            try
            {
                if (message.Trim() != string.Empty)
                {
                    message = LogTimestamp
                        ? $"{DateTime.Now,-19:s} - [ERR] {message}"
                        : $"[ERR] {message}";
                }

                //this is to ensure that if we have anything in cache, it gets written out first and flushed.
                _writeCache.Append(message);

                File.AppendAllText(Path, _writeCache.ToString());

                _writeCache.Length = 0;
            }
            catch (Exception e)
            {
                ReportError(e);
            }
        }

        public override void WriteLine(string message)
        {
            if ((Streams & StreamType.Output) != StreamType.Output)
            {
                return;
            }

            if (message == null)
            {
                message = string.Empty;
            }

            try
            {
                if (message.Trim() != string.Empty)
                {
                    if (LogTimestamp)
                        message = $"{DateTime.Now,-19:s} - {message}";
                }

                _writeCache.Append(message);

                if (CacheLog)
                    return;

                File.AppendAllText(Path, _writeCache.ToString());

                _writeCache.Length = 0;
            }
            catch (Exception e)
            {
                ReportError(e);
            }
        }

        public override void Write(string message)
        {
            if ((Streams & StreamType.Output) != StreamType.Output)
            {
                return;
            }

            if (message == null)
            {
                message = string.Empty;
            }

            try
            {
                _writeCache.Append(message);

                if (CacheLog)
                    return;

                File.AppendAllText(Path, _writeCache.ToString());

                _writeCache.Length = 0;
            }
            catch (Exception e)
            {
                ReportError(e);
            }
        }

        public override void WriteHeader(string message)
        {
            var logTimestamp = LogTimestamp;
            LogTimestamp = false;
            CacheLog = false;
            WriteLine(message);
            LogTimestamp = logTimestamp;
        }

        public override void WriteVerboseLine(string message)
        {
            if ((Streams & StreamType.Verbose) != StreamType.Verbose)
            {
                return;
            }
            if (message == null)
            {
                message = string.Empty;
            }

            try
            {
                if (message.Trim() != string.Empty)
                {
                    message = LogTimestamp
                        ? $"{DateTime.Now,-19:s} - [V] {message}"
                        : $"[V] {message}";
                }

                _writeCache.Append(message);

                File.AppendAllText(Path, _writeCache.ToString());

                _writeCache.Length = 0;
            }
            catch (Exception e)
            {
                ReportError(e);
            }
        }

        public override void WriteWarningLine(string message)
        {
            if ((Streams & StreamType.Warning) != StreamType.Warning)
            {
                return;
            }
            if (message == null)
            {
                message = string.Empty;
            }

            try
            {
                if (message.Trim() != string.Empty)
                {
                    message = LogTimestamp
                        ? $"{DateTime.Now,-19:s} - [WARN] {message}"
                        : $"[WARN] {message}";
                }

                _writeCache.Append(message);

                File.AppendAllText(Path, _writeCache.ToString());

                _writeCache.Length = 0;
            }
            catch (Exception e)
            {
                ReportError(e);
            }
        }

        public override void WriteEmptyLine(int lineCount = 1)
        {
            try
            {
                for (int i = 0; i < lineCount; i++)
                {
                    File.AppendAllText(Path, Environment.NewLine);
                }
            }
            catch (Exception e)
            {
                ReportError(e);
            }
        }

        public override void DeleteLog()
        {
            if (File.Exists(Path))
            {
                File.Delete(Path);
            }
        }

        private void CheckDirectory()
        {
            var path = System.IO.Path.GetDirectoryName(Path);

            if (!string.IsNullOrEmpty(path) && !Directory.Exists(path))
            {
                Directory.CreateDirectory(path);
            }
        }

        private void ReportError(Exception e)
        {
            //var interceptor = HostIoInterceptor.Instance;

            // ReSharper disable once EmptyGeneralCatchClause
            try {
                //interceptor.Paused = true;
                ErrorCallback?.Invoke(this, e);
            }
            catch
            {
            }
            //finally
            //{
            //    //interceptor.Paused = false;
            //}
        }
    }
}
