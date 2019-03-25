using System;
using System.Collections.Concurrent;
using System.Diagnostics;
using System.Linq;
using System.ServiceProcess;
using System.Threading;
using System.Threading.Tasks;
using Deployment.Common;
using Deployment.Common.Logging;
using Deployment.Domain.Roles;

namespace Deployment.Domain.Operations.Services
{
    public class WindowsServiceController
    {
        private readonly IDeploymentLogger _logger;
        public WindowsServiceController(IDeploymentLogger logger)
        {
            _logger = logger;
        }

        public bool HasServiceBeenRemoved(string service, string hostName, string hostAddress)
        {
            var services = ServiceController.GetServices(hostAddress);

            var isAvailable =
                services.FirstOrDefault(
                    s => s.ServiceName.Equals(service, StringComparison.CurrentCultureIgnoreCase)) != null;

            var message = isAvailable
                ? $"Windows service {service} has not been removed from {hostName} ({hostAddress})."
                : $"Windows service {service} has been removed from {hostName} ({hostAddress}).";

            _logger?.WriteSummary(message, isAvailable ? LogResult.Fail :  LogResult.Success);

            return isAvailable;
        }

        public bool IsServiceAvailableAndRunning(string serviceName, string hostName, string hostAddress, TimeSpan timeout, bool startIfStopped = true)
        {
            _logger?.WriteLine($"Checking the state of service {serviceName}.");

            var watch = new Stopwatch();
            watch.Start();

            var bag = new ConcurrentBag<ValidationResult>();

            var isRunning = false;
            try
            {
                using (var serviceController = new ServiceController(serviceName, hostAddress))
                {
                    // Need to call a property to determine acquisition, this is enough to determine whether service exists
                    var type = serviceController.ServiceType;

                    // Ensure the service is running
                    isRunning = serviceController.Status == ServiceControllerStatus.Running;

                    if (!isRunning)
                    {
                        if (startIfStopped)
                        {
                            // Try to start the service and then poll until it starts
                            var status = StartService(serviceName, hostName, hostAddress, timeout, bag, serviceController);

                            isRunning = status.Item1 && status.Item2 == ServiceControllerStatus.Running;
                        }
                    }

                    _logger?.WriteSummary(
                        isRunning
                            ? $"Starting service {serviceName} on {hostName}. Time Elapsed: {watch.Elapsed.TotalSeconds:0.00} Seconds"
                            : $"Windows service {serviceName} is available but not running on {hostName}. Time Elapsed: {watch.Elapsed.TotalSeconds:0.00} Seconds",
                        LogResult.Success);
                }
            }
            catch (Exception ex)
            {
                _logger?.WriteSummary(
                    $"Unable to validate windows service {serviceName} on {hostName}. Time Elapsed: {watch.Elapsed.TotalSeconds:0.00}", LogResult.Fail);
                _logger?.WriteError(ex);
            }

            watch.Stop();

            return isRunning;
        }

        public bool CheckServiceStatus(string serviceName, string hostName, ServiceControllerStatus serviceState)
        {
            ServiceControllerStatus initialServiceState;
            using (var sc = new ServiceController(serviceName, hostName))
            {
                initialServiceState = sc.Status;
            }
            return initialServiceState == serviceState;
        }

        public bool StartAllWindowsServices(Deployment deployment, int timeoutSeconds = 90)
        {
            var deploymentService = new DeploymentService(_logger);
            var serviceDeploys = deploymentService.GetServiceDeployments(deployment);
            var success = true;

            var bag = new ConcurrentBag<ValidationResult>();
            Parallel.ForEach(serviceDeploys.Machines, machine => StartMachineServices(machine, bag, timeoutSeconds));

            foreach (var validationResult in bag)
            {
                success &= validationResult.Result;

                if (validationResult.Result)
                {
                    _logger?.WriteLine(validationResult.Message);
                }
                else
                {
                    _logger?.WriteError(validationResult.Message);
                    _logger?.WriteError(validationResult.Exceptions[0]);
                }
            }

            return success;
        }

        public bool StopAllWindowsServices(Deployment deployment, int timeoutSeconds = 90)
        {
            var deploymentService = new DeploymentService(_logger);
            var serviceDeploys = deploymentService.GetServiceDeployments(deployment);
            var success = true;

            var bag = new ConcurrentBag<ValidationResult>();
            Parallel.ForEach(serviceDeploys.Machines, machine => StopMachineServices(machine, bag, timeoutSeconds));

            foreach (var validationResult in bag)
            {
                success &= validationResult.Result;

                if (validationResult.Result)
                {
                    _logger?.WriteLine(validationResult.Message);
                }
                else
                {
                    _logger?.WriteError(validationResult.Message);
                    _logger?.WriteError(validationResult.Exceptions[0]);
                }
            }

            return success;
        }

        public Tuple<bool, ServiceControllerStatus> StartService(string serviceName, string hostName, string hostAddress, TimeSpan timeout)
        {
            return StartService(serviceName, hostName, hostAddress, timeout, null);
        }
        public Tuple<bool, ServiceControllerStatus> StopService(string serviceName, string hostName, string hostAddress, TimeSpan timeout)
        {
            return StopService(serviceName, hostName, hostAddress, timeout, null);
        }

        private bool StopMachineServices(Machine machine, ConcurrentBag<ValidationResult> bag, int timeoutSeconds)
        {
            return machine.DeploymentRoles.Cast<ServiceDeploy>()
                .SelectMany(s => s.Services)
                .Select(service => StopService(service.Name, machine.Name, machine.ExternalIpAddress, TimeSpan.FromSeconds(timeoutSeconds), bag))
                .Aggregate(true, (current, status) => current & status.Item1);
        }

        private bool StartMachineServices(Machine machine, ConcurrentBag<ValidationResult> bag, int timeoutSeconds)
        {
            return machine.DeploymentRoles.Cast<ServiceDeploy>()
                .Where(s => !s.DisableTests && s.Action != MsiAction.Uninstall)
                .SelectMany(s => s.Services)
                .Select(service => StartService(service.Name, machine.Name, machine.ExternalIpAddress, TimeSpan.FromSeconds(timeoutSeconds), bag))
                .Aggregate(true, (current, status) => current & status.Item1);
        }

        private Tuple<bool, ServiceControllerStatus> StartService(string serviceName, string hostName, string hostAddress, TimeSpan timeout, ConcurrentBag<ValidationResult> bag, ServiceController controller = null)
        {
            var initialServiceState = ServiceControllerStatus.Paused;
            var dispose = controller == null;

            if (timeout == TimeSpan.MaxValue || timeout == TimeSpan.MinValue || timeout == TimeSpan.Zero)
                timeout = TimeSpan.FromSeconds(180);

            try
            {
                controller = controller ?? new ServiceController(serviceName, hostAddress);

                initialServiceState = controller.Status;

                WriteLogOrBag(
                    $"Initial state of service {serviceName} on {hostName} ({hostAddress}) is {initialServiceState}", bag);

                if (initialServiceState == ServiceControllerStatus.Running ||
                    initialServiceState == ServiceControllerStatus.StartPending) return Tuple.Create(true, initialServiceState);

                WriteLogOrBag(
                    $"Starting service {serviceName} on {hostName} ({hostAddress})", bag);

                var started = StartService(controller, timeout);

                if(!started)
                    throw new System.ServiceProcess.TimeoutException($"Failed to start service {serviceName} in a timely manner.");

                initialServiceState = controller.Status;
            }
            catch (Exception ex)
            {
                ErrorLogOrBag($"Exception trying to obtain status of service {serviceName} on machine {hostName}", ex, bag);
                return Tuple.Create(false, initialServiceState);
            }
            finally
            {
                if (dispose)
                    controller?.Dispose();
            }

            return Tuple.Create(true, initialServiceState);
        }

        private bool StartService(ServiceController controller, TimeSpan timeout)
        {
            int retryCount = 0;
            do
            {
                try
                {
                    controller.Start();
                    controller.WaitForStatus(ServiceControllerStatus.Running, timeout);
                    controller.Refresh();
                }
                catch (System.ServiceProcess.TimeoutException)
                {
                    retryCount++;
                    Thread.Sleep(5000);
                    controller.Refresh();
                }

            } while (controller.Status != ServiceControllerStatus.Running && retryCount < 3);

            return controller.Status == ServiceControllerStatus.Running;
        }

        private bool StopService(ServiceController controller, TimeSpan timeout)
        {
            int retryCount = 0;
            do
            {
                try
                {
                    controller.Stop();
                    controller.WaitForStatus(ServiceControllerStatus.Running, timeout);
                    controller.Refresh();
                }
                catch (System.ServiceProcess.TimeoutException)
                {
                    retryCount++;
                    Thread.Sleep(5000);
                    controller.Refresh();
                }

            } while (controller.Status != ServiceControllerStatus.Stopped && retryCount < 3);

            return controller.Status == ServiceControllerStatus.Stopped;
        }

        private Tuple<bool, ServiceControllerStatus> StopService(string serviceName, string hostName, string hostAddress, TimeSpan timeout, ConcurrentBag<ValidationResult> bag, ServiceController controller = null)
        {
            var initialServiceState = ServiceControllerStatus.Paused;
            var dispose = controller == null;

            if (timeout == TimeSpan.MaxValue || timeout == TimeSpan.MinValue || timeout == TimeSpan.Zero)
                timeout = TimeSpan.FromSeconds(30);

            try
            {
                controller = controller ?? new ServiceController(serviceName, hostAddress);

                initialServiceState = controller.Status;

                WriteLogOrBag(
                    $"Initial state of service {serviceName} on {hostName} ({hostAddress}) is {initialServiceState}", bag);

                if (initialServiceState == ServiceControllerStatus.Stopped ||
                    initialServiceState == ServiceControllerStatus.StopPending)
                    return Tuple.Create(true, initialServiceState);

                WriteLogOrBag(
                    $"Starting service {serviceName} on {hostName} ({hostAddress})", bag);

                var stopped = StopService(controller, timeout);

                if (!stopped)
                    throw new System.ServiceProcess.TimeoutException("Failed to stop service {serviceName} in a timely manner.");

                initialServiceState = controller.Status;
            }
            catch(Exception ex)
            {
                ErrorLogOrBag($"Exception trying to obtain status of service {serviceName} on machine {hostName}", ex, bag);
                return Tuple.Create(false, initialServiceState);
            }
            finally
            {
                if (dispose)
                    controller?.Dispose();
            }

            return Tuple.Create(true, initialServiceState);
        }

        private void WriteLogOrBag(string message,  ConcurrentBag<ValidationResult> bag = null)
        {
            if (bag == null)
            {
                _logger?.WriteLine(message);
            }
            else
            {
                bag.Add(ValidationResult.Success(message));
            }
        }

        private void ErrorLogOrBag(string message, Exception ex, ConcurrentBag<ValidationResult> bag = null)
        {
            if (bag == null)
            {
                _logger?.WriteError(message);
                _logger?.WriteError(ex);
            }
            else
            {
                bag.Add(new ValidationResult(message, ex));
            }
        }
    }
}