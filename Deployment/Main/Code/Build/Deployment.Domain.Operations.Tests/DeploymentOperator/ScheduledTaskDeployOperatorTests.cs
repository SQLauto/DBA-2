using System;
using System.Collections.Generic;
using Deployment.Common;
using Deployment.Domain.Operations.DeploymentOperator;
using Deployment.Domain.Operations.DomainModelFactory;
using Deployment.Domain.Roles;
using Deployment.Domain.TaskScheduler;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using MSTestExtensions;

namespace Deployment.Domain.Operations.Tests.DeploymentOperator
{
    [TestClass]
    public class ScheduledTaskDeployOperatorTests : DomainOperationsTestBase
    {
        private readonly ConfigurationParameters _configurationParameters = new ConfigurationParameters();
        private readonly List<string> _outputLocations = new List<string>();

        [TestInitialize]
        public void Setup()
        {
            _outputLocations.Add(string.Empty);

            RoleName = "TFL.ScheduledTaskDeploy";
            Body = "<ScheduledTaskDeploy>{0}</ScheduledTaskDeploy>";

            _configurationParameters.ServiceAccounts = new List<ServiceAccount>
            {
                new ServiceAccount {Username = "TestServiceAccount1", LookupName = "TestServiceAccount1"},
                new ServiceAccount {Username = "TestServiceAccount2", LookupName = "TestServiceAccount2"},
            };
        }


        [TestMethod]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [TestCategory("ScheduledTaskDeploy")]
        public void TestTaskIsValidIfHasNoTriggerDefined()
        {
            var logger = new TestContextLogger(TestContext);

            var taskWithNoTriggers =
                GetScheduledTaskDeploy(
                    actions: new List<TaskAction>
                    {
                        new TaskAction {ActionType = ActionType.DisplayMessage, Message = "Test message"}
                    }
                );

            var sut = new ScheduledTaskDeployOperator(null, logger);
            var isValid = sut.PreDeploymentValidate(taskWithNoTriggers, _configurationParameters, _outputLocations);

            Assert.IsTrue(isValid);
        }

        [TestMethod]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [TestCategory("ScheduledTaskDeploy")]
        public void TestTaskIsNotValidIfAllTriggersAreDisabled()
        {
            var logger = new TestContextLogger(TestContext);

            var taskWithNoTriggers =
                GetScheduledTaskDeploy(
                    triggers: new List<ScheduleInfo>
                    {
                        new ScheduleInfo {Disabled = true}
                    },
                    actions: new List<TaskAction>{
                        new TaskAction {ActionType = ActionType.DisplayMessage, Message = "Test message"}
                    }
                );

            var sut = new ScheduledTaskDeployOperator(null, logger);
            var isValid = sut.PreDeploymentValidate(taskWithNoTriggers, _configurationParameters, _outputLocations);

            Assert.IsFalse(isValid);
        }

        [TestMethod]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [TestCategory("ScheduledTaskDeploy")]
        public void TestTaskIsNotValidWithNoActionDefined()
        {
            var logger = new TestContextLogger(TestContext);

            var taskWithNoTriggers =
                GetScheduledTaskDeploy(
                    triggers: new List<ScheduleInfo>
                    {
                        new ScheduleInfo {Disabled = true}
                    }
                );

            var sut = new ScheduledTaskDeployOperator(null, logger);
            var isValid = sut.PreDeploymentValidate(taskWithNoTriggers, _configurationParameters, _outputLocations);

            Assert.IsFalse(isValid);
        }


        [TestMethod]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [TestCategory("ScheduledTaskDeploy")]
        public void TestTaskIsNotValidIfTwoOnStartTriggersAreActive()
        {
            var logger = new TestContextLogger(TestContext);

            var task =
                GetScheduledTaskDeploy(
                    triggers: new List<ScheduleInfo>
                    {
                        new ScheduleInfo {Disabled = false, ScheduleType = ScheduleType.OnStart},
                        new ScheduleInfo {Disabled = false, ScheduleType = ScheduleType.OnStart}
                    }
                );

            var sut = new ScheduledTaskDeployOperator(null, logger);
            var isValid = sut.PreDeploymentValidate(task, _configurationParameters, _outputLocations);

            Assert.IsFalse(isValid);
        }

        [TestMethod]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [TestCategory("ScheduledTaskDeploy")]
        public void TestTaskIsNotValidIfTwoOnceTriggersAreActive()
        {
            var logger = new TestContextLogger(TestContext);

            var task =
                GetScheduledTaskDeploy(
                    triggers: new List<ScheduleInfo>
                    {
                        new ScheduleInfo {Disabled = false, ScheduleType = ScheduleType.Once},
                        new ScheduleInfo {Disabled = false, ScheduleType = ScheduleType.Once}
                    }
                );

            var sut = new ScheduledTaskDeployOperator(null, logger);
            var isValid = sut.PreDeploymentValidate(task, _configurationParameters, _outputLocations);

            Assert.IsFalse(isValid);
        }

        [TestMethod]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [TestCategory("ScheduledTaskDeploy")]
        public void TestTaskIsNotValidIfWeeklyTriggerHasSameDayScheduleDefinedMoreThenOnce()
        {
            var logger = new TestContextLogger(TestContext);

            var task =
                GetScheduledTaskDeploy(
                    triggers: new List<ScheduleInfo>
                    {
                        new ScheduleInfo
                        {
                            Disabled = false,
                            ScheduleType = ScheduleType.Weekly,
                            DaysOfWeek = new List<DayOfWeek> {DayOfWeek.Monday, DayOfWeek.Monday}
                        },
                    }
                );

            var sut = new ScheduledTaskDeployOperator(null, logger);
            var isValid = sut.PreDeploymentValidate(task, _configurationParameters, _outputLocations);

            Assert.IsFalse(isValid);
        }

        [TestMethod]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [TestCategory("ScheduledTaskDeploy")]
        public void TestTaskIsNotValidIfWeeklyTriggerHasNoDayOfWeekDefined()
        {
            var logger = new TestContextLogger(TestContext);

            var task =
                GetScheduledTaskDeploy(
                    triggers: new List<ScheduleInfo>()
                    {
                        new ScheduleInfo
                        {
                            Disabled = false,
                            ScheduleType = ScheduleType.Weekly,
                            // DaysOfWeek = new List<DayOfWeek> {DayOfWeek.Monday}
                        },
                    },
                    actions: new List<TaskAction>
                    {
                        new TaskAction {ActionType = ActionType.DisplayMessage, Message = "Test message"}
                    }
                );

            var sut = new ScheduledTaskDeployOperator(null, logger);
            var isValid = sut.PreDeploymentValidate(task, _configurationParameters, _outputLocations);

            Assert.IsFalse(isValid);
        }

        [TestMethod]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [TestCategory("ScheduledTaskDeploy")]
        public void TestTaskIsNotValidIfTriggerHasInvalidIntervalValueWeekly()
        {
            var logger = new TestContextLogger(TestContext);

            var task =
                GetScheduledTaskDeploy(
                    triggers: new List<ScheduleInfo>
                    {
                        GetScheduleInfo(
                            disabled: false,
                            scheduleType: ScheduleType.Weekly,
                            interval: 52 + 1,
                            daysOfWeek: new [] {DayOfWeek.Monday}
                        )
                    },
                    actions: new List<TaskAction>
                    {
                        new TaskAction {ActionType = ActionType.DisplayMessage, Message = "Test message"}
                    }
                );

            var sut = new ScheduledTaskDeployOperator(null, logger);
            var isValid = sut.PreDeploymentValidate(task, _configurationParameters, _outputLocations);
            Assert.IsFalse(isValid);
        }

        [TestMethod]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [TestCategory("ScheduledTaskDeploy")]
        public void TestTaskIsNotValidIfTriggerHasMultipleWeeklySchedulesDefined()
        {
            var logger = new TestContextLogger(TestContext);

            var task =
                GetScheduledTaskDeploy(
                    triggers: new List<ScheduleInfo>
                    {
                        GetScheduleInfo(
                            disabled: false,
                            scheduleType: ScheduleType.Weekly,
                            interval: 3,
                            daysOfWeek: new[] {DayOfWeek.Monday}
                        ),
                        GetScheduleInfo(
                            disabled: false,
                            scheduleType: ScheduleType.Weekly,
                            interval: 5,
                            daysOfWeek: new[] {DayOfWeek.Monday}
                        )
                    },
                    actions: new List<TaskAction>
                    {
                        new TaskAction {ActionType = ActionType.DisplayMessage, Message = "Test message"}
                    }
                );

            var sut = new ScheduledTaskDeployOperator(null,logger);
            var isValid = sut.PreDeploymentValidate(task, _configurationParameters, _outputLocations);

            Assert.IsFalse(isValid);
        }

        [TestMethod]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [TestCategory("ScheduledTaskDeploy")]
        public void TestTaskIsNotValidIfTriggerHasInvalidIntervalValueDaily()
        {
            var logger = new TestContextLogger(TestContext);

            var task =
                GetScheduledTaskDeploy(
                    triggers: new List<ScheduleInfo>
                    {
                        GetScheduleInfo(
                            disabled: false,
                            scheduleType: ScheduleType.Daily,
                            interval: 365 + 1
                        )
                    },
                    actions: new List<TaskAction>
                    {
                        new TaskAction {ActionType = ActionType.DisplayMessage, Message = "Test message"}
                    }
                );

            var sut = new ScheduledTaskDeployOperator(null,logger);
            var isValid = sut.PreDeploymentValidate(task, _configurationParameters, _outputLocations);

            Assert.IsFalse(isValid);
        }

        [TestMethod]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [TestCategory("ScheduledTaskDeploy")]
        public void TestTaskIsNotValidIfTriggerHasDailyScheduleAndNegativeInterval()
        {
            var logger = new TestContextLogger(TestContext);

            var task =
                GetScheduledTaskDeploy(
                    triggers: new List<ScheduleInfo>
                    {
                        GetScheduleInfo(
                            disabled: false,
                            scheduleType: ScheduleType.Daily,
                            interval: -1
                        )
                    },
                    actions: new List<TaskAction>
                    {
                        new TaskAction {ActionType = ActionType.DisplayMessage, Message = "Test message"}
                    }
                );

            var sut = new ScheduledTaskDeployOperator(null,logger);
            var isValid = sut.PreDeploymentValidate(task, _configurationParameters, _outputLocations);

            Assert.IsFalse(isValid);
        }


        [TestMethod]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [TestCategory("ScheduledTaskDeploy")]
        public void TestIntervalCases()
        {
            var inputList = new List<TestInputInterval>
            {
                new TestInputInterval
                {   // date OK, time OK
                    StartDate = DateTime.MinValue, EndDate = DateTime.MaxValue,
                    StartTime = TimeSpan.MinValue, EndTime = TimeSpan.MaxValue,
                    IsValid = true
                },
                new TestInputInterval
                {   // date NOT, time OK
                    StartDate = DateTime.MaxValue, EndDate = DateTime.MinValue,
                    StartTime = TimeSpan.MinValue, EndTime = TimeSpan.MaxValue,
                    IsValid = false, ErrorMessage = Strings.ErrorEndCantBeBeforeStartDate
                },
                new TestInputInterval
                {   // date OK, time NOT
                    StartDate = DateTime.MinValue, EndDate = DateTime.MaxValue,
                    StartTime = TimeSpan.MaxValue, EndTime = TimeSpan.MinValue,
                    IsValid = true,
                },
                new TestInputInterval
                {   // date NOT, time NOT
                    StartDate = DateTime.MaxValue, EndDate = DateTime.MinValue,
                    StartTime = TimeSpan.MaxValue, EndTime = TimeSpan.MinValue,
                    IsValid = false, ErrorMessage = Strings.ErrorEndCantBeBeforeStartDate
                },
                new TestInputInterval
                {   // Same day, different time: date OK, time NOT
                    StartDate = DateTime.Now, EndDate = DateTime.Now,
                    StartTime = TimeSpan.MaxValue, EndTime = TimeSpan.MinValue,
                    IsValid = false, ErrorMessage = Strings.ErrorEndCantBeBeforeStartTime
                },
                new TestInputInterval
                {   // Same day, different time: date OK, time OK
                    StartDate = DateTime.Now, EndDate = DateTime.Now,
                    StartTime = TimeSpan.MinValue, EndTime = TimeSpan.MaxValue,
                    IsValid = true,
                },
                new TestInputInterval
                {   // RepeatEvery set, RepeatDuration not.
                    StartDate = DateTime.Now, EndDate = DateTime.Now,
                    StartTime = TimeSpan.MinValue, EndTime = TimeSpan.MaxValue,
                    RepeatEvery = TimeSpan.FromHours(2),
                    IsValid = true,
                },
                new TestInputInterval
                {   // RepeatEvery set, RepeatDuration set.
                    StartDate = DateTime.Now, EndDate = DateTime.Now,
                    StartTime = TimeSpan.MinValue, EndTime = TimeSpan.MaxValue,
                    RepeatEvery = TimeSpan.FromHours(2),
                    RepeateDuration = TimeSpan.FromMinutes(30),
                    IsValid = true,
                },
                new TestInputInterval
                {   // RepeatEvery set, RepeatDuration set.
                    StartDate = DateTime.Now, EndDate = DateTime.Now,
                    StartTime = TimeSpan.MinValue, EndTime = TimeSpan.MaxValue,
                    RepeateDuration = TimeSpan.FromMinutes(30),
                    IsValid = false,
                },
            };


            inputList.ForEach(inputInterval =>
            {
                var logger = new TestContextLogger(TestContext);

                var task =
                GetScheduledTaskDeploy(
                    triggers: new List<ScheduleInfo>
                    {
                        GetScheduleInfo(
                            scheduleType:ScheduleType.Daily,
                            interval: 1,

                            startDate: inputInterval.StartDate,
                            endDate: inputInterval.EndDate,

                            startTime:inputInterval.StartTime,
                            endTime:inputInterval.EndTime,

                            repeatEvery:inputInterval.RepeatEvery,
                            repeatDuration:inputInterval.RepeateDuration
                        )
                    },
                    actions: new List<TaskAction> { new TaskAction { ActionType = ActionType.DisplayMessage, Message = "test message" } }
                );

                var sut = new ScheduledTaskDeployOperator(null, logger);
                var isValid = sut.PreDeploymentValidate(task, _configurationParameters, _outputLocations);

                if (inputInterval.IsValid)
                    Assert.IsTrue(isValid);
                else
                {
                    Assert.IsFalse(isValid);
                }
            });
        }

        [TestMethod]
        [TestCategory("Unit")]
        [TestCategory("Gated")]
        [TestCategory("ScheduledTaskDeploy")]
        public void TestTaskIsNotValidIfServiceAccountDoesNotExistInServiceAccountsFile()
        {
            var logger = new TestContextLogger(TestContext);

            var task =
                GetScheduledTaskDeploy(
                    triggers: new List<ScheduleInfo>
                    {
                        GetScheduleInfo(
                            disabled: false,
                            scheduleType: ScheduleType.Daily,
                            interval: 1
                        )
                    },
                    actions: new List<TaskAction>
                    {
                        new TaskAction {ActionType = ActionType.DisplayMessage, Message = "Test message"}
                    },
                    serviceUsername: "UserDoesNotExistInAccountsFile"
                );

            var sut = new ScheduledTaskDeployOperator(null, logger);
            var isValid = sut.PreDeploymentValidate(task, _configurationParameters, _outputLocations);

            Assert.IsFalse(isValid);
        }

        private struct TestInputInterval
        {
            public DateTime StartDate;
            public TimeSpan StartTime;
            public DateTime EndDate;
            public TimeSpan EndTime;
            public bool IsValid;
            public string ErrorMessage;
            public TimeSpan RepeatEvery;
            public TimeSpan RepeateDuration;
        }


        private ScheduleInfo GetScheduleInfo(
            int lastResult = default(int), TimeSpan stopTaskIfRunsXHoursAndXMinutes = default(TimeSpan),
            ScheduleType scheduleType = default(ScheduleType), string modifier = default(string),
            int interval = default(int), TimeSpan startTime = default(TimeSpan), DateTime startDate = default(DateTime),
            TimeSpan endTime = default(TimeSpan), DateTime endDate = default(DateTime), DayOfWeek[] daysOfWeek = null,
            int[] days = null, Month[] months = null, TimeSpan repeatEvery = default(TimeSpan),
            string repeatUntilTime = default(string), TimeSpan repeatDuration = default(TimeSpan),
            TimeSpan repeatStopIfStillRunning = default(TimeSpan), bool stopAtEnd = default(bool),
            TimeSpan delay = default(TimeSpan), int idleTime = default(int), string eventChannelName = default(string),
            bool disabled=default(bool)
        )
        {
            var scheduleInfo = new ScheduleInfo(lastResult, stopTaskIfRunsXHoursAndXMinutes, scheduleType, modifier,
                interval, startTime, startDate, endTime, endDate, daysOfWeek, days, months, repeatEvery,
                repeatUntilTime,
                repeatDuration, repeatStopIfStillRunning, stopAtEnd, delay, idleTime, eventChannelName
            ) {Disabled = disabled};

            return scheduleInfo;
        }


        private ScheduledTaskDeploy GetScheduledTaskDeployFromXml(string xml)
        {
            Body = xml;
            var element = GenerateServerRoleXml();
            var factory = new ScheduledTaskDeployFactory("default");
            var validationResult = new ValidationResult();
            var model = factory.DomainModelCreate(element, ref validationResult);

            AssertValidationResult(validationResult, () => Assert.IsTrue(validationResult.Result));
            Assert.IsNotNull(model);
            Assert.IsInstanceOfType(model, typeof(ScheduledTaskDeploy));
            var deployRole = (ScheduledTaskDeploy) model;

            return deployRole;
        }


        private ScheduledTaskDeploy GetScheduledTaskDeploy(
            string name = "TestName1", string folder = "TestFolder1", string serviceUsername = "TestServiceAccount1",
            List<ScheduleInfo> triggers = null, List<TaskAction> actions = null)
        {
            var scheduledTaskDeploy = new ScheduledTaskDeploy("default")
            {
                Folder = folder,
                Account = new ServiceAccount {Username = serviceUsername, LookupName = serviceUsername},
                Triggers = triggers ?? new List<ScheduleInfo>(),
                Actions = actions ?? new List<TaskAction>(),
                DisableTests = false,
            };

            return scheduledTaskDeploy;
        }
    }
}
