namespace Deployment.Common
{
    public static class Strings
    {
        public static readonly string LogHeader = @"#########################################################################################
Title: {5}
Start Date: {0}
UserName: {1}
UserDomain: {2}
ComputerName: {3}
Windows version: {4}
#########################################################################################
";
        public static readonly string LogSubHeader = @"--------------------------------------------------------------------------------------------------------
--- {0} at {1}
--------------------------------------------------------------------------------------------------------";

        public static readonly string ErrorMultipleActiveTriggersWithTypeOnceIsNotAllowed = "Multiple active triggers with type Once is not allowed.";
        public static readonly string ErrorMultipleActiveTriggersWithTypeOnStartIsNotAllowed = "Multiple active triggers with type OnStart is not allowed.";
        public static readonly string ErrorTriggerMustHaveAnAction = "There must be at least one action defined for a task.";
        public static readonly string ErrorEndCantBeBeforeStartDate = "End date cannot be before the start date.";
        public static readonly string ErrorEndCantBeBeforeStartTime = "End time cannot be before the start time.";
        public static readonly string ErrorScheduledTaskIntervalMustBePositive = "Scheduled task Interval must be greater than zero. ";
        public static readonly string ErrorAtLeastOneTriggerMustBeEnabled = "For task to be valid, at least one trigger must be enabled.";
        public static readonly string ErrorScheduledTaskIntervalIsNotValid = "Scheduled task Interval is not valid.";
        public static readonly string ErrorMultipleActiveTriggersAreNotAllowed = "Multiple active triggers are not allowed; there must be only one active trigger with schedule type: ";
        public static readonly string ErrorMultipleDefinitionOfSameDaysAreNotAllowedInSchedule = "Multiple definition of same days are not allowed in schedule.";
        public static readonly string ErrorWeeklyTriggerHasAtLeastOneDayScheduleDefined = "Weekly trigger has at least one day schedule defined.";
        public static readonly string ErrorServiceAccountDoesNotExistInServiceAccountsFile = "Service account does not exist in service accounts file: ";
        public static readonly string ErrorTriggerRepeatDurationSetAndRepeatEveryNotSet = "Scheduled task trigger repeat duration should not be set in repeat every (for) is not.";
    }
}