using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using System.Threading;
using System.Threading.Tasks;
using Deployment.Domain.Operations;
using Deployment.Tool.Tasks;
using log4net;
using log4net.Appender;
using log4net.Core;
using log4net.Layout;
using log4net.Repository.Hierarchy;

namespace Deployment.Tool
{
    public enum ConsoleResult
    {
        None = 0,
        Fail,
        InvalidArgs,
        Cancelled,
        Success
    }

    public class ConsoleHarness : IDisposable
    {
        private bool _cancel;
        private ManualResetEventSlim _resetEvent;
        private readonly Hierarchy _repository;
        private bool _complete;
        private CancellationTokenSource _cancellationTokenSource;
        private DeploymentOperationParameters _toolParameters;
        private IDeploymentToolTask _task;
        private readonly ICommandLineParser _parser;

        public ConsoleHarness() : this(new CommandLineParser())
        {
            _repository = (Hierarchy)LogManager.GetRepository();
            HookUpLogger();
        }

        public ConsoleHarness(ICommandLineParser parser)
        {
            _parser = parser;
        }

        public ConsoleResult Initialise(IList<string> args)
        {
            _toolParameters = _parser.Parse(args);

            if (_toolParameters == null)
            {
                var message = string.Concat("Invalid arguments specified", Environment.NewLine, _parser.GetHelp());
                WriteError(message);
                return ConsoleResult.InvalidArgs;
            }

            var deploymentToolTasks = DeploymentToolTasksCreate();
            _task = deploymentToolTasks.FirstOrDefault(x => x.TaskType == _toolParameters.TaskType);

            if (_task == null)
            {
                var message = string.Concat("Invalid Type specified", Environment.NewLine, _parser.GetHelp());
                WriteError(message);
                return ConsoleResult.InvalidArgs;
            }

            var success = _task.ValidateInputParameters(_toolParameters);
            if (!success)
            {
                var message = string.Concat($"Invalid arguments for type: {_task.TaskType}", Environment.NewLine, _parser.GetHelp());
                WriteError(message);
                return ConsoleResult.InvalidArgs;
            }

            return ConsoleResult.Success;
        }

        private void HookUpLogger()
        {
            _repository.Threshold = Level.Debug;

            foreach (var rootAppender in _repository.Root.Appenders)
            {
                var type = rootAppender.GetType();
                if (type == typeof(ConsoleAppender) || type == typeof(ColoredConsoleAppender))
                {
                    return;
                }
            }

            var appender = new ColoredConsoleAppender
            {
                Layout = new PatternLayout("%date %-5level %method - %message%newline"),
                Threshold = Level.Debug
            };

            appender.AddMapping(new ColoredConsoleAppender.LevelColors { ForeColor = ColoredConsoleAppender.Colors.Red, Level = Level.Error });
            appender.AddMapping(new ColoredConsoleAppender.LevelColors { ForeColor = ColoredConsoleAppender.Colors.Yellow, Level = Level.Warn });
            appender.AddMapping(new ColoredConsoleAppender.LevelColors { ForeColor = ColoredConsoleAppender.Colors.White, Level = Level.Info });
            appender.AddMapping(new ColoredConsoleAppender.LevelColors { ForeColor = ColoredConsoleAppender.Colors.Blue, Level = Level.Debug });

            _repository.Root.AddAppender(appender);
            _repository.Configured = true;
            _repository.RaiseConfigurationChanged(EventArgs.Empty);
        }

        public ConsoleResult Run()
        {
            if (Environment.UserInteractive)
            {
                InitializeCancelKey();
                _cancellationTokenSource = new CancellationTokenSource();
                WriteToConsole("Enter [Q]uit to cancel:", ConsoleColor.Yellow);
            }

            var result = Execute();

            if (Environment.UserInteractive)
            {
                WriteToConsole("Press any key to continue...", ConsoleColor.Yellow);
                Console.ReadLine();
            }

            return result;
        }

        private ConsoleResult Execute()
        {
            var retVal = ConsoleResult.Success;

            try
            {
                if (Environment.UserInteractive)
                {
                    Task.Run(() => DoWorkAsync(_task, _toolParameters, _cancellationTokenSource.Token),
                        _cancellationTokenSource.Token).ContinueWith(HandleTasks);

                    do
                    {
                    } while (ContinueProcessing());
                }
                else
                {
                    var result = DoWork(_task, _toolParameters);
                    retVal = result ? ConsoleResult.Success : ConsoleResult.Fail;
                }
            }
            catch (OperationCanceledException)
            {
                _repository.Root.Log(Level.Warn, "Operation cancelled.", null);
                retVal = ConsoleResult.Cancelled;
            }
            catch (Exception ex)
            {
                _repository.Root.Log(Level.Error, "Error occured.", ex);
                retVal = ConsoleResult.Fail;
            }

            return retVal;
        }

        private bool DoWork(IDeploymentToolTask task, DeploymentOperationParameters toolParameters)
        {
            var success = task.TaskWork(toolParameters);

            if (!success)
            {
                WriteError("DeploymentTool task failed.");
            }
            else
            {
                WriteToConsole("DeploymentTool task completed.");
            }

            return success;
        }

        private Task<Tuple<bool>> DoWorkAsync(IDeploymentToolTask task, DeploymentOperationParameters toolParameters, CancellationToken token)
        {
            //TODO: Look to make this all async
            var success = task.TaskWork(toolParameters);

            return Task.FromResult(Tuple.Create(success));
        }

        private void HandleTasks(Task<Tuple<bool>> task)
        {
            _complete = true;

            switch (task.Status)
            {
                case TaskStatus.Canceled:
                    WriteToConsole("DeploymentTool task cancelled.");
                    break;
                case TaskStatus.RanToCompletion:
                    WriteToConsole("DeploymentTool task completed.");
                    break;
                case TaskStatus.Faulted:
                    //This should never happen, but to ensure we don't the app domain to crash, handle the error
                    task.Exception?.Handle(e =>
                    {
                        var message = string.Concat("DeploymentTool task failed:", Environment.NewLine, e.Message);
                        WriteToConsole(message);
                        return true;
                    });
                    break;
            }

        }

        private IEnumerable<IDeploymentToolTask> DeploymentToolTasksCreate()
        {
            var instances =
                Assembly.GetExecutingAssembly()
                    .GetExportedTypes()
                    .Where(t => typeof(IDeploymentToolTask).IsAssignableFrom(t) && t.IsClass)
                    .Select(t=> Activator.CreateInstance(t))
                    .Select(x => x as IDeploymentToolTask);

            return instances;
        }

        private bool HandleConsoleInput(ConsoleKey key)
        {
            if (_complete)
                return true;

            var result = false;

            switch (key)
            {
                case ConsoleKey.Q:
                    WriteToConsole("Cancel Pressed", ConsoleColor.Yellow);
                    _cancellationTokenSource.Cancel();
                    result = true;
                    break;
                default:
                    WriteError("Did not understand that input, try again.", prompt:false);
                    break;

            }

            return result;
        }

        public static void WriteToConsole(string message, ConsoleColor foregroundColor = ConsoleColor.Green, bool prompt = false)
        {
            if (!Environment.UserInteractive) return;

            var originalColor = Console.ForegroundColor;
            Console.ForegroundColor = foregroundColor;

            Console.WriteLine(message);

            if (prompt)
            {
                Console.WriteLine("Press any key to continue...");
                Console.ReadLine();
            }

            Console.Out.Flush();

            Console.ForegroundColor = originalColor;
        }

        public static void WriteError(string message, ConsoleColor foregroundColor = ConsoleColor.Red, bool prompt = true)
        {
            WriteToConsole(message, foregroundColor, prompt);
        }

        private bool ContinueProcessing()
        {
            if (_complete)
                return false;

            var keyAvailable = Console.KeyAvailable;

            if (keyAvailable)
            {
                _cancel = _complete || HandleConsoleInput(Console.ReadKey(true).Key);
            }

            if (_cancel)
                return false;

            //usign a manual reset event allows us to block for a certain amount of time
            //but if we cancel in the meantime it means we can stop immediately.
            _resetEvent.Wait(2000);

            //don't just return true or repeat, as cancelled could occur between thread sleeps.
            return !_cancel;
        }

        private void InitializeCancelKey()
        {
            _cancel = false;
            _resetEvent = new ManualResetEventSlim();

            Console.CancelKeyPress += delegate (object sender, ConsoleCancelEventArgs e)
            {
                e.Cancel = true;
                _cancel = true;
                _resetEvent.Set();
            };
        }

        public void Dispose()
        {
            _resetEvent?.Dispose();
            _cancellationTokenSource?.Dispose();
        }
    }
}