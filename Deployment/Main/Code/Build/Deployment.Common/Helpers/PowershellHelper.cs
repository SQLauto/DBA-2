using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Linq;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Text;

namespace Deployment.Common.Helpers
{
    public class PowershellHelper
    {
        private const string PowershellCmdletNameFormatstring = "{0}-{1}";
        // it really does not matter which help file name we use so we take this as a default when contructing a CmdletConfigurationEntry

        private const string CmdletParameterFormat = "{0} {1}";
        private const string ScriptblockDelimiter = "; ";

        public IList<PSObject> InvokeScript(string scriptDefinition, IList<Parameter> parameters, Func<Exception, Exception> exceptionHandler = null, Action<IList<ErrorRecord>> errorHandler = null)
        {
            var runspaceConfiguration = RunspaceConfiguration.Create();

            using (var runspace = RunspaceFactory.CreateRunspace(runspaceConfiguration))
            {
                runspace.Open();

                using (var pipeline = runspace.CreatePipeline())
                {
                    try
                    {
                        var command = new Command(scriptDefinition, true);

                        if (parameters != null)
                        {
                            foreach (var parameter in parameters)
                            {
                                var p = new CommandParameter(parameter.Name, parameter.Value);
                                command.Parameters.Add(p);
                            }
                        }

                        pipeline.Commands.Add(command);

                        var invocationResults = pipeline.Invoke();

                        if (null != errorHandler && pipeline.HadErrors)
                        {
                            var errorRecords = pipeline.Error.ReadToEnd().Cast<PSObject>().Select(e => e.BaseObject).Cast<ErrorRecord>().ToList();
                            errorHandler(errorRecords);
                        }

                        return invocationResults.ToList();
                    }
                    catch (CmdletInvocationException ex)
                    {
                        if (exceptionHandler == null || ex.InnerException == null)
                        {
                            throw;
                        }

                        throw exceptionHandler(ex.InnerException);
                    }
                }
            }
        }

        public IList<PSObject> InvokeCommand(string commandText, Func<Exception, Exception> exceptionHandler = null, Action<IList<ErrorRecord>> errorHandler = null)
        {
            var runspaceConfiguration = RunspaceConfiguration.Create();


            using (var runspace = RunspaceFactory.CreateRunspace(runspaceConfiguration))
            {
                runspace.Open();

                using (var pipeline = runspace.CreatePipeline(commandText))
                {
                    try
                    {
                        var invocationResults = pipeline.Invoke();

                        if (null != errorHandler && pipeline.HadErrors)
                        {
                            var errorRecords = pipeline.Error.ReadToEnd().Cast<PSObject>().Select(e => e.BaseObject).Cast<ErrorRecord>().ToList();
                            errorHandler(errorRecords);
                        }

                        return invocationResults.ToList();
                    }
                    catch (CmdletInvocationException ex)
                    {
                        if (exceptionHandler == null || ex.InnerException == null)
                        {
                            throw;
                        }

                        throw exceptionHandler(ex.InnerException);
                    }
                }
            }
        }
    }
}