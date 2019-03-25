using System;
using System.Collections.Generic;
using System.Net.NetworkInformation;
using System.Text;
using Deployment.Common.Logging;

namespace Deployment.Domain
{
    public class PingTest
    {
        private readonly IDeploymentLogger _logger;

        public PingTest(IDeploymentLogger logger)
        {
            _logger = logger;
        }

        public PingReply PingStatus { get; private set; }
        public bool IsConnected { get; private set; }

        internal bool PingMachines(IList<Domain.Machine> hosts)
        {
            IsConnected = true;
            foreach (var host in hosts)
            {
                var checkIfConnected = PingMachine(host);
                if (checkIfConnected)
                    continue;

                IsConnected = false;
                _logger?.WriteWarn($"Unable to ping host name: [{ host.Name}], IP address: [{host.ExternalIpAddress ?? string.Empty}]");
            }

            return IsConnected;
        }

        internal bool PingMachine(Domain.Machine machine)
        {
            if (machine == null)
                throw new ArgumentException("\r\n Machine information not found.");

            var who = machine.ExternalIpAddress;
            if (string.IsNullOrWhiteSpace(who))
            {
                throw new ArgumentException(
                    $"There is not an external IP address for machine: [{machine.Name ?? "unknown"}].");
            }

            return PingMachine(machine.Name, machine.ExternalIpAddress);
        }

        internal bool PingMachine(string name, string externalIpAddress)
        {
            if (string.IsNullOrWhiteSpace(externalIpAddress))
                throw new ArgumentException("\r\n Machine external IP address information not found.");

            try
            {
                var pingSender = new Ping();

                // When the PingCompleted event is raised, the PingCompletedCallback method is called.
                //pingSender.PingCompleted += new PingCompletedEventHandler(PingCompletedCallback);

                //Create a buffer of 32 bytes of data to be transmitted.
                var data = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa";
                var buffer = Encoding.ASCII.GetBytes(data);

                // Wait 12 seconds for a reply.
                int timeout = 12000;

                //Set options for transmission: The data can go through 64 gateways or routers before it is destroyed, and the data packet cannot be fragmented.
                var options = new PingOptions(64, true);
                //Send the ping asynchronously. Use the waiter as the user token. When the callback completes, it can wake up this thread.
                //pingSender.SendAsync(who, timeout, buffer, options, waiter);
                PingStatus = pingSender.Send(externalIpAddress, timeout, buffer, options);
                IsConnected = DisplayReply(PingStatus, name);

                _logger?.WriteSummary($"Completed Ping Test of machine {name} ({externalIpAddress}).",IsConnected ? LogResult.Success : LogResult.Fail);
            }
            catch (Exception ex)
            {
                IsConnected = false;
                _logger?.WriteError(ex);
                _logger?.WriteSummary("Ping failed.", LogResult.Fail);
            }

            return IsConnected;
        }

        private bool DisplayReply(PingReply reply, string name)
        {
            if (reply == null)
                return false;

            _logger?.WriteLine($"{name} {reply.Address} returns ping status of: {reply.Status}");

            return reply.Status == IPStatus.Success;
        }
    }
}
