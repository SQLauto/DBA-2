/**
 * Copyright 2016 d-fens GmbH
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

using System;
using System.Collections.Generic;
using System.Diagnostics.Contracts;
using System.Linq;
using System.Management.Automation;
using System.Management.Automation.Runspaces;
using System.Text;
using Deployment.Common.Helpers;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace Tfl.Module.Testing
{
    public static class PsCmdletAssert
    {
        private const string PowershellCmdletNameFormatstring = "{0}-{1}";
        // it really does not matter which help file name we use so we take this as a default when contructing a CmdletConfigurationEntry
        private const string HelpFileName = "Microsoft.Windows.Installer.PowerShell.dll-Help.xml";

        private const string CmdletParameterFormat = "{0} {1}";
        private const string ScriptblockDelimiter = "; ";

        public static IList<PSObject> InvokeScript(Type implementingType, string parameters, string scriptDefinition)
        {
            Contract.Requires(null != implementingType);
            Contract.Requires(!string.IsNullOrWhiteSpace(scriptDefinition));
            Contract.Ensures(null != Contract.Result<IList<PSObject>>());

            return InvokeScript(new [] { implementingType }, parameters, scriptDefinition, HelpFileName);
        }

        public static IList<PSObject> InvokeScript(Type[] implementingTypes, string parameters, string scriptDefinition)
        {
            Contract.Requires(null != implementingTypes);
            Contract.Requires(!string.IsNullOrWhiteSpace(scriptDefinition));
            Contract.Ensures(null != Contract.Result<IList<PSObject>>());

            return InvokeScript(implementingTypes, parameters, scriptDefinition, HelpFileName);
        }

        public static IList<PSObject> InvokeScript(Type[] implementingTypes, string parameters, string scriptDefinition, string helpFileName, Func<Exception, Exception> exceptionHandler = null, Action<IList<ErrorRecord>> errorHandler = null)
        {
            Contract.Requires(null != implementingTypes);
            Contract.Requires(!string.IsNullOrWhiteSpace(helpFileName));
            Contract.Ensures(null != Contract.Result<IList<PSObject>>());

            var runspaceConfiguration = RunspaceConfiguration.Create();
            var cmdletNameToInvoke = string.Empty;

            foreach (var implementingType in implementingTypes)
            {
                // construct the Cmdlet name the type implements
                var cmdletAttribute = (CmdletAttribute)implementingType.GetCustomAttributes(typeof(CmdletAttribute), true).Single();
                Contract.Assert(null != cmdletAttribute, typeof(CmdletAttribute).FullName);
                var cmdletName = string.Format(PowershellCmdletNameFormatstring, cmdletAttribute.VerbName, cmdletAttribute.NounName);

                if (implementingType == implementingTypes[0])
                {
                    cmdletNameToInvoke = cmdletName;
                }

                // add the cmdlet to the runspace
                var cmdletConfigurationEntry = new CmdletConfigurationEntry
                (
                    cmdletName,
                    implementingType,
                    helpFileName
                );
                runspaceConfiguration.Cmdlets.Append(cmdletConfigurationEntry);
            }
            Contract.Assert(!string.IsNullOrWhiteSpace(cmdletNameToInvoke));

            using (var runspace = RunspaceFactory.CreateRunspace(runspaceConfiguration))
            {
                runspace.Open();

                // add scripts to cmdlet to be executed
                var commandText = new StringBuilder();
                commandText.Append(scriptDefinition);
                commandText.AppendLine(ScriptblockDelimiter);
                commandText.AppendLine(cmdletNameToInvoke);
                commandText.AppendLine(ScriptblockDelimiter);

                using (var pipeline = runspace.CreatePipeline(commandText.ToString()))
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

        public static IList<PSObject> Invoke(Type implementingType, IList<Parameter> parameters)
        {
            Contract.Requires(null != implementingType);
            Contract.Ensures(null != Contract.Result<IList<PSObject>>());

            return Invoke(new[] { implementingType }, parameters, HelpFileName);
        }

        public static IList<PSObject> Invoke(Type[] implementingTypes, IList<Parameter> parameters)
        {
            Contract.Requires(null != implementingTypes);
            Contract.Ensures(null != Contract.Result<IList<PSObject>>());

            return Invoke(implementingTypes, parameters, HelpFileName);
        }

        public static IList<PSObject> Invoke(Type[] implementingTypes, IList<Parameter> parameters, string helpFileName, Func<Exception, Exception> exceptionHandler = null, Action<IList<ErrorRecord>> errorHandler = null)
        {
            Contract.Requires(null != implementingTypes);
            Contract.Requires(!string.IsNullOrWhiteSpace(helpFileName));
            Contract.Ensures(null != Contract.Result<IList<PSObject>>());

            var runspaceConfiguration = RunspaceConfiguration.Create();
            var cmdletNameToInvoke = string.Empty;

            foreach (var implementingType in implementingTypes)
            {
                // construct the Cmdlet name the type implements
                var cmdletAttribute = (CmdletAttribute)implementingType.GetCustomAttributes(typeof(CmdletAttribute), true).Single();
                Contract.Assert(null != cmdletAttribute, typeof(CmdletAttribute).FullName);
                var cmdletName = string.Format(PowershellCmdletNameFormatstring, cmdletAttribute.VerbName, cmdletAttribute.NounName);

                if (implementingType == implementingTypes[0])
                {
                    cmdletNameToInvoke = cmdletName;
                }

                // add the cmdlet to the runspace
                var cmdletConfigurationEntry = new CmdletConfigurationEntry
                (
                    cmdletName,
                    implementingType,
                    helpFileName
                );
                runspaceConfiguration.Cmdlets.Append(cmdletConfigurationEntry);
            }
            Contract.Assert(!string.IsNullOrWhiteSpace(cmdletNameToInvoke));

            using (var runspace = RunspaceFactory.CreateRunspace(runspaceConfiguration))
            {
                runspace.Open();

                using (var pipeline = runspace.CreatePipeline())
                {
                    var command = new Command(cmdletNameToInvoke);

                    if (parameters != null)
                    {
                        foreach (var parameter in parameters)
                        {
                            command.Parameters.Add(parameter.Name, parameter.Value);
                        }
                    }

                    pipeline.Commands.Add(command);

                    try
                    {
                        var invocationResults = pipeline.Invoke();

                        if (errorHandler!=null && pipeline.HadErrors)
                        {
                            var errorRecords = pipeline.Error.ReadToEnd().Cast<PSObject>().Select(e => e.BaseObject).Cast<ErrorRecord>().ToList();
                            errorHandler(errorRecords);
                        }

                        return invocationResults.ToList();
                    }
                    catch (CmdletInvocationException ex)
                    {
                        if (null == exceptionHandler || null == ex.InnerException)
                        {
                            throw;
                        }

                        throw exceptionHandler(ex.InnerException);
                    }
                }
            }
        }

        public static void HasAlias(Type implementingType, string expectedAlias)
        {
            Contract.Requires(null != implementingType);
            Contract.Requires(!string.IsNullOrWhiteSpace(expectedAlias));

            HasAlias(implementingType, expectedAlias, null);
        }

        public static void HasAlias(Type implementingType, string expectedAlias, string message)
        {
            Contract.Requires(null != implementingType);
            Contract.Requires(!string.IsNullOrWhiteSpace(expectedAlias));

            var customAttribute = (AliasAttribute)implementingType.GetCustomAttributes(typeof(AliasAttribute), true).FirstOrDefault();
            var isAttributeDefined = null != customAttribute && null != customAttribute.AliasNames;
            if (!isAttributeDefined)
            {
                var attributeNotDefinedMessage = new StringBuilder();
                attributeNotDefinedMessage.AppendFormat("PsCmdletAssert.IsAliasDefined FAILED. No AliasAttribute defined.");
                if (null != message)
                {
                    attributeNotDefinedMessage.AppendFormat(" '{0}'", message);
                }
                throw new AssertFailedException(attributeNotDefinedMessage.ToString());
            }

            var isAliasDefined = customAttribute.AliasNames.Any(expectedAlias.Equals);
            if (isAliasDefined)
            {
                return;
            }

            var aliasNotDefinedMessage = new StringBuilder();
            aliasNotDefinedMessage.AppendFormat("PsCmdletAssert.IsAliasDefined FAILED. ExpectedAlias '{0}' not defined.", expectedAlias);
            if (null != message)
            {
                aliasNotDefinedMessage.AppendFormat(" '{0}'", message);
            }
            throw new AssertFailedException(aliasNotDefinedMessage.ToString());
        }

        public static void HasOutputType(Type implementingType, Type expectedOutputType)
        {
            Contract.Requires(null != implementingType);
            Contract.Requires(null != expectedOutputType);

            HasOutputType(implementingType, expectedOutputType.FullName, ParameterAttribute.AllParameterSets, null);
        }

        public static void HasOutputType(Type implementingType, string expectedOutputTypeName)
        {
            Contract.Requires(null != implementingType);
            Contract.Requires(!string.IsNullOrWhiteSpace(expectedOutputTypeName));

            HasOutputType(implementingType, expectedOutputTypeName, ParameterAttribute.AllParameterSets, null);
        }

        public static void HasOutputType(Type implementingType, Type expectedOutputType, string parameterSetName)
        {
            Contract.Requires(null != implementingType);
            Contract.Requires(null != expectedOutputType);

            HasOutputType(implementingType, expectedOutputType.FullName, parameterSetName, null);
        }

        public static void HasOutputType(Type implementingType, string expectedOutputTypeName, string parameterSetName)
        {
            Contract.Requires(null != implementingType);
            Contract.Requires(!string.IsNullOrWhiteSpace(expectedOutputTypeName));

            HasOutputType(implementingType, expectedOutputTypeName, parameterSetName, null);
        }

        public static void HasOutputType(Type implementingType, string expectedOutputTypeName, string parameterSetName, string message)
        {
            Contract.Requires(null != implementingType);
            Contract.Requires(!string.IsNullOrWhiteSpace(expectedOutputTypeName));
            Contract.Requires(!string.IsNullOrWhiteSpace(parameterSetName));

            var outputTypeAttributes = (OutputTypeAttribute[])implementingType.GetCustomAttributes(typeof(OutputTypeAttribute), true);

            var isValidOutputType = false;

            var outputTypeAttributesForGivenParameterSetName = outputTypeAttributes.Where(e => e.ParameterSetName.Contains(parameterSetName));
            foreach (var outputTypeAttribute in outputTypeAttributesForGivenParameterSetName)
            {
                isValidOutputType |= outputTypeAttribute.Type.Any(e => e.Name == expectedOutputTypeName);
            }

            if (isValidOutputType)
            {
                return;
            }

            var outputTypeAttributesForAllParameterSets = outputTypeAttributes.Where(e => e.ParameterSetName.Contains(ParameterAttribute.AllParameterSets));
            foreach (var outputTypeAttribute in outputTypeAttributesForAllParameterSets)
            {
                isValidOutputType |= outputTypeAttribute.Type.Any(e => e.Name == expectedOutputTypeName);
            }

            if (isValidOutputType)
            {
                return;
            }

            var invalidOutputTypeMessage = new StringBuilder();
            invalidOutputTypeMessage.AppendFormat("PsCmdletAssert.IsOutputType FAILED. ExpectedType '{0}' not defined for ParameterSetName '{1}'.", expectedOutputTypeName, parameterSetName);
            if (null != message)
            {
                invalidOutputTypeMessage.AppendFormat(" '{0}'", message);
            }
            throw new AssertFailedException(invalidOutputTypeMessage.ToString());
        }

    }
}