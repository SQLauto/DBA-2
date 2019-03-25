using System;

namespace Deployment.Tool
{
    public interface IWindowsService : IDisposable
    {
        /// <summary>
        /// This method is called when the service gets a request to start.
        /// </summary>
        /// <param name="args"></param>
        void OnStart(string[] args);
        /// <summary>
        /// This method is called when the service gets a request to stop.
        /// </summary>
        void OnStop();

        int ExitCode { get; set; }
    }
}