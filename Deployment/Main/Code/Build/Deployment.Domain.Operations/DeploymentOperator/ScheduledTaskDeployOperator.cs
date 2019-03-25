using System;
using System.Collections.Generic;
using System.Linq;
using Deployment.Common;
using Deployment.Common.Logging;
using Deployment.Domain.Roles;
using Deployment.Domain.TaskScheduler;

namespace Deployment.Domain.Operations.DeploymentOperator
{
    public class ScheduledTaskDeployOperator : IDeploymentOperator<ScheduledTaskDeploy>
    {
        private readonly IDeploymentLogger _logger;

        public ScheduledTaskDeployOperator(IParameterService parameterService = null, IDeploymentLogger logger = null)
        {
            _logger = logger;
        }

        public bool PreDeploymentValidate(ScheduledTaskDeploy role, ConfigurationParameters parameters, List<string> outputLocations)
        {
            var retVal = true;

            switch (role.Action)
            {
                case ScheduledTaskAction.Install:
                    break;
                case ScheduledTaskAction.Uninstall:
                    break;
                default:
                    _logger?.WriteWarn(
                        $"Schedule Task {role.TaskName} Action Tag is incorrect: {role.Action}, expected: 'Create','ForceCreate', 'Remove'");
                    break;
            }

            // Actions
            if (role.Actions.Count == 0)
            {
                _logger?.WriteWarn(Strings.ErrorTriggerMustHaveAnAction);
                retVal = false;
            }

            if (parameters.ServiceAccounts.All(sa => sa.LookupName != role.Account.LookupName))
            {
                _logger?.WriteWarn(Strings.ErrorServiceAccountDoesNotExistInServiceAccountsFile + role.Account.LookupName);
                retVal = false;
            }

            if (role.Triggers.Count == 0)
                return retVal;

            if (role.Triggers.All(t => t.Disabled))
            {
                _logger?.WriteWarn(Strings.ErrorAtLeastOneTriggerMustBeEnabled);
                retVal = false;
            }

            if (role.Triggers.Any(t => t.Interval <= 0))
            {
                role.Triggers.Where(t => t.Interval <= 0).ForEach(t =>
                {
                    _logger?.WriteWarn(Strings.ErrorScheduledTaskIntervalMustBePositive +
                                       $"TaskName:{role.TaskName} Interval: {t.Interval}");
                });

                retVal = false;
            }

            if (role.Triggers.Count(t => !t.Disabled && t.ScheduleType == ScheduleType.Once) > 1)
            {
                // Only one schedule type must be defined: Once
                _logger?.WriteWarn(Strings.ErrorMultipleActiveTriggersAreNotAllowed + "Once");
                retVal = false;
            }

            if (role.Triggers.Count(t => !t.Disabled && t.ScheduleType == ScheduleType.OnStart) > 1)
            {
                // Only one schedule type must be defined: OnStart
                _logger?.WriteWarn(Strings.ErrorMultipleActiveTriggersAreNotAllowed + "OnStart");
                retVal = false;
            }

            if (role.Triggers.Count(t => !t.Disabled && t.ScheduleType == ScheduleType.Weekly) > 1)
            {
                // Only one schedule type must be defined: Weekly
                _logger?.WriteWarn(Strings.ErrorMultipleActiveTriggersAreNotAllowed + "Weekly");
                retVal = false;
            }

            if (role.Triggers.Any(t => !t.Disabled && t.ScheduleType == ScheduleType.Weekly
                                            && t?.DaysOfWeek.Distinct().Count() != t?.DaysOfWeek.Count))
            {
                // When weekly schedule type is defined, duplicate days are not allowed.
                _logger?.WriteWarn(Strings.ErrorMultipleDefinitionOfSameDaysAreNotAllowedInSchedule);
                retVal = false;
            }

            if (role.Triggers.Any(t => !t.Disabled && t.ScheduleType == ScheduleType.Weekly
                                            && t?.DaysOfWeek.Count == 0))
            {
                // check if there is at least one day defined. i.e: if there is no DaysOfWeek defined, return error.
                _logger?.WriteWarn(Strings.ErrorWeeklyTriggerHasAtLeastOneDayScheduleDefined);
                retVal = false;
            }

            if (role.Triggers.Any(t => t.StartDate.Date > t.EndDate.Date))
            {
                _logger?.WriteWarn(Strings.ErrorEndCantBeBeforeStartDate);
                retVal = false;
            }

            if (role.Triggers.Any(t => t.StartTime > t.EndTime && t.StartDate.Date == t.EndDate.Date))
            {
                _logger?.WriteWarn(Strings.ErrorEndCantBeBeforeStartTime);
                retVal = false;
            }

            if (role.Triggers.Any(t => !t.Disabled && t.ScheduleType == ScheduleType.Weekly
                                            && (t.Interval <= 0 || t.Interval > 52)))
            {
                // Weekly schedule interval should be between 1 and 52
                _logger?.WriteWarn(Strings.ErrorScheduledTaskIntervalIsNotValid);
                retVal = false;
            }

            if (role.Triggers.Any(t => !t.Disabled && t.ScheduleType == ScheduleType.Daily
                                            && (t.Interval <= 0 || t.Interval > 365)))
            {
                // Weekly schedule interval should be between 1 and 365
                _logger?.WriteWarn(Strings.ErrorScheduledTaskIntervalIsNotValid);
                retVal = false;
            }

            if (role.Triggers.Any(t => !t.Disabled && t.ScheduleType == ScheduleType.Daily
                                                   && (t.Interval <= 0 || t.Interval > 365)))
            {
                // Weekly schedule interval should be between 1 and 365
                _logger?.WriteWarn(Strings.ErrorScheduledTaskIntervalIsNotValid);
                retVal = false;
            }

            if (role.Triggers.Any(t => !t.Disabled && t.RepeatEvery == TimeSpan.Zero
                                                   && t.RepeatDuration > TimeSpan.Zero))
            {
                // Do not set repeat duration if repeat every is not set too.
                _logger?.WriteWarn(Strings.ErrorTriggerRepeatDurationSetAndRepeatEveryNotSet);
                retVal = false;
            }

            return retVal;
        }

        public bool PostDeploymentValidate(PostDeployParameters postDeployParameters, ScheduledTaskDeploy role) => true;


        public IList<ArchiveEntry> GetDeploymentFiles(ScheduledTaskDeploy role, List<string> dropFolder,
            ConfigurationParameters parameters) => null;
    }
}