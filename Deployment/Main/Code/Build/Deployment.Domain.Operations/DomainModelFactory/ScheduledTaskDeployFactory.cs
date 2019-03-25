using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Xml.Linq;
using System.Xml.XPath;
using Deployment.Common;
using Deployment.Common.Xml;
using Deployment.Domain.Roles;
using Deployment.Domain.TaskScheduler;

namespace Deployment.Domain.Operations.DomainModelFactory
{
    public class ScheduledTaskDeployFactory : BaseRoleFactory<ScheduledTaskDeploy>
    {
        public ScheduledTaskDeployFactory(string defaultConfig) : base(defaultConfig, new[] { "config:ServerRole[@Name='TFL.ScheduledTaskDeploy']", "role:ServerRole[@Name='TFL.ScheduledTaskDeploy']" })
        {
        }

        public override IBaseRole DomainModelCreate(XElement rootNode, ref ValidationResult validationResult)
        {
            var retVal = new ScheduledTaskDeploy(DefaultConfig);

            try
            {
                ParseCommonAttributes(retVal, rootNode, ref validationResult);

                var child = rootNode.Element(Namespaces.CommonRole.XmlNamespace + "ScheduledTaskDeploy");

                if (child == null)
                {
                    validationResult.AddError("ScheduledTaskDeploy element was not found.");
                    return null;
                }

                ParseElementAttribute(child, "Action", () => retVal.Action, ref validationResult);
                ParseElementAttribute(child, "Enabled", () => retVal.Enabled, ref validationResult);

                ParseElementValue(child, "TaskName", Namespaces.CommonRole.XmlNamespace, () => retVal.TaskName, ref validationResult, ValidationAction.NotNullOrEmpty("Scheduled Task name cannot be null or empty."));
                ParseElementValue(child, "ServiceAccount", Namespaces.CommonRole.XmlNamespace, () => retVal.Account.LookupName, ref validationResult);
                ParseElementValue(child, "Folder", Namespaces.CommonRole.XmlNamespace, () => retVal.Folder, ref validationResult);
                ParseElementValue(child, "Description", Namespaces.CommonRole.XmlNamespace, () => retVal.TaskDescription, ref validationResult);

                ParseElementAttribute(child.Element(Namespaces.CommonRole.XmlNamespace + "TestInfo"), "DisableTests", () => retVal.DisableTests, ref validationResult);

                ProcessTriggers(child, retVal.Triggers, ref validationResult);
                ProcessActions(child, retVal.Actions, ref validationResult);

                ValidateDomainObject(retVal, ref validationResult, true);
            }
            catch (Exception ex)
            {
                validationResult.AddException(ex);
                return null;
            }

            return validationResult.Result ? retVal : null;
        }

        public override bool ValidateDomainObject(ScheduledTaskDeploy domainObject, ref ValidationResult validationResult,
            bool suppressStandardParseValidations = false)
        {
            foreach (var schedule in domainObject.Triggers.Where(t => t.ScheduleType == ScheduleType.Weekly))
            {
                if (schedule.DaysOfWeek == null || !schedule.DaysOfWeek.Any())
                {
                    validationResult.AddError($"The scheduled task [{ domainObject.TaskName}] has a weekly trigger and no days of week defined one must define at least one day of the week.");
                }
            }

            return validationResult.Result;
        }

        public override IBaseRole ApplyOverrides(IBaseRole commonRole, XElement includedRole, ref ValidationResult validationResult)
        {
            var retVal = (ScheduledTaskDeploy)base.ApplyOverrides(commonRole, includedRole, ref validationResult);

            var actionTuple = includedRole.TryReadAttribute<ScheduledTaskAction>("Action");
            if (actionTuple.Item1.HasValue && actionTuple.Item1.Value)
            {
                retVal.Action = actionTuple.Item2;
            }

            var disableTuple = includedRole.TryReadAttribute<bool>("DisableTests");
            if (disableTuple.Item1.HasValue && disableTuple.Item1.Value)
            {
                retVal.DisableTests = disableTuple.Item2;
            }

            return retVal;
        }

        private void ProcessTriggers(XElement rootNode, IList<ScheduleInfo> triggers, ref ValidationResult validationResult)
        {
            var xpathExpression = string.Format("{0}:Triggers/{0}:Trigger", Namespaces.CommonRole.Prefix);
            var childNodes = rootNode.XPathSelectElements(xpathExpression, Namespaces.NamespaceManager);

            if (!childNodes.Any())
            {
                return;
            }

            foreach (var triggerNode in childNodes)
            {
                var trigger = new ScheduleInfo();

                var child = triggerNode.GetChildElement(new []{"AtStartUp","OneTime","Daily","Weekly"});

                if (child == null)
                {
                    validationResult.AddError("ScheduledTaskDeploy trigger does not have any valid child elements.");
                    return;
                }

                switch (child.Name.LocalName)
                {
                    case "AtStartUp":
                        trigger.ScheduleType = ScheduleType.OnStart;
                        break;
                    case "OneTime":
                        trigger.ScheduleType = ScheduleType.Once;
                        ParseElementValue(child, "StartDate", Namespaces.CommonRole.XmlNamespace, () => trigger.StartDate, ref validationResult);
                        ParseElementValue(child, "StartTime", Namespaces.CommonRole.XmlNamespace, () => trigger.StartTime, ref validationResult);
                        ParseElementValue(child, "RepeatEvery", Namespaces.CommonRole.XmlNamespace, () => trigger.RepeatEvery, ref validationResult);
                        ParseElementValue(child, "RepeatDuration", Namespaces.CommonRole.XmlNamespace, () => trigger.RepeatDuration, ref validationResult);
                        break;
                    case "Daily":
                        trigger.ScheduleType = ScheduleType.Daily;
                        ParseElementAttribute(child, "Interval", () => trigger.Interval, ref validationResult);
                        ParseElementValue(child, "StartDate", Namespaces.CommonRole.XmlNamespace, () => trigger.StartDate, ref validationResult);
                        ParseElementValue(child, "StartTime", Namespaces.CommonRole.XmlNamespace, () => trigger.StartTime, ref validationResult);
                        ParseElementValue(child, "RepeatEvery", Namespaces.CommonRole.XmlNamespace, () => trigger.RepeatEvery, ref validationResult);
                        ParseElementValue(child, "RepeatDuration", Namespaces.CommonRole.XmlNamespace, () => trigger.RepeatDuration, ref validationResult);
                        break;
                    case "Weekly":
                        trigger.ScheduleType = ScheduleType.Weekly;
                        ParseElementAttribute(child, "Interval", () => trigger.Interval, ref validationResult);
                        ParseElementValue(child, "StartDate", Namespaces.CommonRole.XmlNamespace, () => trigger.StartDate, ref validationResult);
                        ParseElementValue(child, "StartTime", Namespaces.CommonRole.XmlNamespace, () => trigger.StartTime, ref validationResult);
                        ParseElementValue(child, "RepeatEvery", Namespaces.CommonRole.XmlNamespace, () => trigger.RepeatEvery, ref validationResult);
                        ParseElementValue(child, "RepeatDuration", Namespaces.CommonRole.XmlNamespace, () => trigger.RepeatDuration, ref validationResult);

                        xpathExpression = string.Format("{0}:Days/{0}:DayOfWeek", Namespaces.CommonRole.Prefix);
                        var days = child.XPathSelectElements(xpathExpression, Namespaces.NamespaceManager);

                        ParseElementValue(days, trigger.DaysOfWeek, ref validationResult);
                        break;
                }

                ParseElementAttribute(triggerNode, "Disabled", () => trigger.Disabled, ref validationResult);

                triggers.Add(trigger);
            }
        }

        private void ProcessActions(XElement rootNode, IList<TaskAction> actions, ref ValidationResult validationResult)
        {
            var xpathExpression = string.Format("{0}:Actions/{0}:Action", Namespaces.CommonRole.Prefix);
            var childNodes = rootNode.XPathSelectElements(xpathExpression, Namespaces.NamespaceManager);

            if (!childNodes.Any())
            {
                validationResult.AddError("ScheduledTaskDeploy element does not have any Action elements.");
                return;
            }

            foreach (var actionNode in childNodes)
            {
                var action = new TaskAction();

                ParseElementValue(actionNode, "Command", Namespaces.CommonRole.XmlNamespace, () => action.Command,
                    ref validationResult);

                ParseElementValue(actionNode, "Arguments", Namespaces.CommonRole.XmlNamespace, () => action.Arguments,
                    ref validationResult);

                action.ActionType = ActionType.Program;

                actions.Add(action);
            }
        }

        public override IBaseRole UpdateParameterisedValues(IBaseRole deployRole, IParameterService parameterService, IDeploymentPathBuilder deploymentPathBuilder, IList<ICIBasePathBuilder> ciPathBuilders, ref ValidationResult validationResult)
        {
            try
            {
                var deploymentParameters = parameterService.ParseDeploymentParameters(deploymentPathBuilder, DefaultConfig, deployRole.Configuration, ciPathBuilders, null, null);

                var taskRole = (ScheduledTaskDeploy) deployRole;

                var regex = new Regex(@"\s+", RegexOptions.IgnoreCase);

                foreach (var action in taskRole.Actions.Where(a=>!string.IsNullOrWhiteSpace(a.Arguments)))
                {
                    var builder = new StringBuilder();

                    var arguments = regex.Split(action.Arguments);

                    foreach (var argument in arguments)
                    {
                        var resolveValue = deploymentParameters.ResolveValue(argument);
                        builder.Append(resolveValue.Item2).Append(" ");
                    }

                    action.Arguments = builder.ToString().TrimEnd();
                }
            }
            catch (Exception ex)
            {
                validationResult.AddException(ex);
                return null;
            }

            return validationResult.Result ? deployRole : null;
        }

        //TODO: Change DisableTests to TestInfo to be consistent.
        //        private const string FullXml = @"<ScheduledTaskDeploy Action='Install' DisableTests='False'>
        //            <Task Name='TaskName' Enabled='true'>
        //                <Folder>FolderName</Folder>
        //                <ServiceAccount>FolderName</ServiceAccount>
        //            </Task>
        //</ScheduledTaskDeploy>";
    }

}