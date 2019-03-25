using System;
using Deployment.Common;
using Deployment.Domain.Operations.DomainModelFactory;
using Deployment.Domain.Roles;
using Deployment.Domain.TaskScheduler;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using MSTestExtensions;

namespace Deployment.Domain.Operations.Tests
{
    [TestClass]
    public class ScheduledTaskDeployFactoryTests : DomainOperationsTestBase
    {
        [TestInitialize]
        public void Setup()
        {
            RoleName = "TFL.ScheduledTaskDeploy";
            Body = "<ScheduledTaskDeploy>{0}</ScheduledTaskDeploy>";
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("ScheduledTaskDeploy")]
        public void TestValidatesResponsibility()
        {
            var element = GenerateServerRoleXml();

            var factory = new ScheduledTaskDeployFactory("default");

            Assert.IsTrue(factory.IsResponsibleFor(element));
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("ScheduledTaskDeploy")]
        public void TestValidatesNonResponsibility()
        {
            RoleName = "Invalid";
            var element = GenerateServerRoleXml();

            var factory = new ScheduledTaskDeployFactory("default");

            Assert.IsFalse(factory.IsResponsibleFor(element));
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("ScheduledTaskDeploy")]
        public void TestCreatesAtStartUpTask()
        {
            Body = string.Format(Body, AtStartUp);
            var element = GenerateServerRoleXml();

            var factory = new ScheduledTaskDeployFactory("default");

            var validationResult = new ValidationResult();
            var model = factory.DomainModelCreate(element, ref validationResult);

            AssertValidationResult(validationResult, () => Assert.IsTrue(validationResult.Result));
            Assert.IsNotNull(model);
            Assert.IsInstanceOfType(model, typeof(ScheduledTaskDeploy));
            var deployRole = (ScheduledTaskDeploy)model;
            Assert.IsTrue(deployRole.Action == ScheduledTaskAction.Install);
            Assert.IsTrue(deployRole.Triggers.Count == 1);
            Assert.IsTrue(deployRole.Triggers[0].ScheduleType == ScheduleType.OnStart);
            Assert.IsTrue(deployRole.Triggers[0].Disabled);
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("ScheduledTaskDeploy")]
        public void TestCreatesOneTimeTask()
        {
            Body = string.Format(Body, OneTime);
            var element = GenerateServerRoleXml();

            var factory = new ScheduledTaskDeployFactory("default");

            var validationResult = new ValidationResult();
            var model = factory.DomainModelCreate(element, ref validationResult);

            AssertValidationResult(validationResult, () => Assert.IsTrue(validationResult.Result));
            Assert.IsNotNull(model);
            Assert.IsInstanceOfType(model, typeof(ScheduledTaskDeploy));
            var deployRole = (ScheduledTaskDeploy)model;
            Assert.IsTrue(deployRole.Action == ScheduledTaskAction.Install);
            Assert.IsTrue(deployRole.Triggers.Count == 1);
            Assert.IsTrue(deployRole.Triggers[0].ScheduleType == ScheduleType.Once);
            Assert.IsTrue(deployRole.Triggers[0].StartDate == DateTime.Parse("30/12/2015"));
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("ScheduledTaskDeploy")]
        public void TestCreatesDailyTask()
        {
            Body = string.Format(Body, Daily);
            var element = GenerateServerRoleXml();

            var factory = new ScheduledTaskDeployFactory("default");

            var validationResult = new ValidationResult();
            var model = factory.DomainModelCreate(element, ref validationResult);

            AssertValidationResult(validationResult, () => Assert.IsTrue(validationResult.Result));
            Assert.IsNotNull(model);
            Assert.IsInstanceOfType(model, typeof(ScheduledTaskDeploy));
            var deployRole = (ScheduledTaskDeploy)model;
            Assert.IsTrue(deployRole.Action == ScheduledTaskAction.Install);
            Assert.IsTrue(deployRole.Triggers.Count == 1);
            Assert.IsTrue(deployRole.Triggers[0].ScheduleType == ScheduleType.Daily);
            Assert.IsTrue(deployRole.Triggers[0].StartDate == DateTime.Parse("28/12/2015"));
            Assert.IsTrue(deployRole.Triggers[0].Interval == 1);
            Assert.IsTrue(deployRole.Triggers[0].RepeatEvery == TimeSpan.Zero);
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("ScheduledTaskDeploy")]
        public void TestCreatesDailyWithRepeatTask()
        {
            Body = string.Format(Body, DailyWithRepeat);
            var element = GenerateServerRoleXml();

            var factory = new ScheduledTaskDeployFactory("default");

            var validationResult = new ValidationResult();
            var model = factory.DomainModelCreate(element, ref validationResult);

            AssertValidationResult(validationResult, () => Assert.IsTrue(validationResult.Result));
            Assert.IsNotNull(model);
            Assert.IsInstanceOfType(model, typeof(ScheduledTaskDeploy));
            var deployRole = (ScheduledTaskDeploy)model;
            Assert.IsTrue(deployRole.Action == ScheduledTaskAction.Install);
            Assert.IsTrue(deployRole.Triggers.Count == 1);
            Assert.IsTrue(deployRole.Triggers[0].ScheduleType == ScheduleType.Daily);
            Assert.IsTrue(deployRole.Triggers[0].StartDate == DateTime.Parse("28/12/2015"));
            Assert.IsTrue(deployRole.Triggers[0].RepeatEvery == TimeSpan.FromHours(2));
            Assert.IsTrue(deployRole.Triggers[0].RepeatDuration == TimeSpan.Zero);
            Assert.IsTrue(deployRole.Triggers[0].Interval == 1);
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("ScheduledTaskDeploy")]
        public void TestCreatesDailyWithRepeatAndDurationTask()
        {
            Body = string.Format(Body, DailyWithRepeatAndDuration);
            var element = GenerateServerRoleXml();

            var factory = new ScheduledTaskDeployFactory("default");

            var validationResult = new ValidationResult();
            var model = factory.DomainModelCreate(element, ref validationResult);

            AssertValidationResult(validationResult, () => Assert.IsTrue(validationResult.Result));
            Assert.IsNotNull(model);
            Assert.IsInstanceOfType(model, typeof(ScheduledTaskDeploy));
            var deployRole = (ScheduledTaskDeploy)model;
            Assert.IsTrue(deployRole.Action == ScheduledTaskAction.Install);
            Assert.IsTrue(deployRole.Triggers.Count == 1);
            Assert.IsTrue(deployRole.Triggers[0].ScheduleType == ScheduleType.Daily);
            Assert.IsTrue(deployRole.Triggers[0].StartDate == DateTime.Parse("28/12/2015"));
            Assert.IsTrue(deployRole.Triggers[0].RepeatEvery == TimeSpan.FromHours(1));
            Assert.IsTrue(deployRole.Triggers[0].RepeatDuration == TimeSpan.FromHours(12));
            Assert.IsTrue(deployRole.Triggers[0].Interval == 1);
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("ScheduledTaskDeploy")]
        public void TestCreatesWeeklyTask()
        {
            Body = string.Format(Body, Weekly);
            var element = GenerateServerRoleXml();

            var factory = new ScheduledTaskDeployFactory("default");

            var validationResult = new ValidationResult();
            var model = factory.DomainModelCreate(element, ref validationResult);

            AssertValidationResult(validationResult, () => Assert.IsTrue(validationResult.Result));
            Assert.IsNotNull(model);
            Assert.IsInstanceOfType(model, typeof(ScheduledTaskDeploy));
            var deployRole = (ScheduledTaskDeploy)model;
            Assert.IsTrue(deployRole.Action == ScheduledTaskAction.Install);
            Assert.IsTrue(deployRole.Triggers.Count == 1);
            Assert.IsTrue(deployRole.Triggers[0].ScheduleType == ScheduleType.Weekly);
            Assert.IsTrue(deployRole.Triggers[0].StartDate == DateTime.Parse("30/12/2015"));
            Assert.IsTrue(deployRole.Triggers[0].Interval == 2);
            Assert.IsTrue(deployRole.Triggers[0].DaysOfWeek.Count == 4);
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("ScheduledTaskDeploy")]
        public void TestCreatesActions()
        {
            Body = string.Format(Body, AtStartUp);
            var element = GenerateServerRoleXml();

            var factory = new ScheduledTaskDeployFactory("default");

            var validationResult = new ValidationResult();
            var model = factory.DomainModelCreate(element, ref validationResult);

            AssertValidationResult(validationResult, () => Assert.IsTrue(validationResult.Result));
            Assert.IsNotNull(model);
            Assert.IsInstanceOfType(model, typeof(ScheduledTaskDeploy));
            var deployRole = (ScheduledTaskDeploy)model;
            Assert.IsTrue(deployRole.Action == ScheduledTaskAction.Install);
            Assert.IsTrue(deployRole.Actions.Count == 1);
            Assert.StringNotNullOrEmpty(deployRole.Actions[0].Command);
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("ScheduledTaskDeploy")]
        public void TestCreatesUninstall()
        {
            Body = $@"<ScheduledTaskDeploy Action=""Uninstall"" Enabled=""true"">{AtStartUp}</ScheduledTaskDeploy>";
            var element = GenerateServerRoleXml();

            var factory = new ScheduledTaskDeployFactory("default");

            var validationResult = new ValidationResult();
            var model = factory.DomainModelCreate(element, ref validationResult);

            AssertValidationResult(validationResult, () => Assert.IsTrue(validationResult.Result));
            Assert.IsNotNull(model);
            Assert.IsInstanceOfType(model, typeof(ScheduledTaskDeploy));
            var deployRole = (ScheduledTaskDeploy)model;
            Assert.IsTrue(deployRole.Action == ScheduledTaskAction.Uninstall);
            Assert.IsTrue(deployRole.Enabled);
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("ScheduledTaskDeploy")]
        public void TestCreatesDisabled()
        {
            Body = $@"<ScheduledTaskDeploy>{AtStartUp}</ScheduledTaskDeploy>";
            var element = GenerateServerRoleXml();

            var factory = new ScheduledTaskDeployFactory("default");

            var validationResult = new ValidationResult();
            var model = factory.DomainModelCreate(element, ref validationResult);

            AssertValidationResult(validationResult, () => Assert.IsTrue(validationResult.Result));
            Assert.IsNotNull(model);
            Assert.IsInstanceOfType(model, typeof(ScheduledTaskDeploy));
            var deployRole = (ScheduledTaskDeploy)model;
            Assert.IsFalse(deployRole.Enabled);
        }

        [TestMethod]
        [TestCategory("Gated")]
        [TestCategory("Unit")]
        [TestCategory("ScheduledTaskDeploy")]
        public void TestCreatesNoTriggers()
        {
            Body = $@"<ScheduledTaskDeploy>{NoTriggers}</ScheduledTaskDeploy>";
            var element = GenerateServerRoleXml();

            var factory = new ScheduledTaskDeployFactory("default");

            var validationResult = new ValidationResult();
            var model = factory.DomainModelCreate(element, ref validationResult);

            AssertValidationResult(validationResult, () => Assert.IsTrue(validationResult.Result));
            Assert.IsNotNull(model);
            Assert.IsInstanceOfType(model, typeof(ScheduledTaskDeploy));
            var deployRole = (ScheduledTaskDeploy)model;
            Assert.AreEqual(0, deployRole.Triggers.Count);
        }

        private const string NoTriggers = @"
    <TaskName>CreateAndDeleteTask</TaskName>
    <Folder>FTP</Folder>
    <ServiceAccount>FAEServiceAccount</ServiceAccount>
    <Triggers />
    <Actions>
        <Action>
            <Command>C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe</Command>
        </Action>
    </Actions>
    <TestInfo DisableTests=""true"" />";

        private const string AtStartUp = @"
    <TaskName>CreateAndDeleteTask</TaskName>
    <Folder>FTP</Folder>
    <ServiceAccount>FAEServiceAccount</ServiceAccount>
    <Triggers>
        <Trigger Disabled=""true"">
		    <AtStartUp />
	    </Trigger>
    </Triggers>
    <Actions>
        <Action>
            <Command>C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe</Command>
        </Action>
    </Actions>
    <TestInfo DisableTests=""true"" />";

        private const string OneTime = @"
    <TaskName>CreateAndDeleteTask</TaskName>
    <Folder>FTP</Folder>
    <ServiceAccount>FAEServiceAccount</ServiceAccount>
    <Triggers>
        <Trigger>
		    <OneTime>
				<StartDate>30/12/2015</StartDate>
                <StartTime>12:00:00</StartTime>
			</OneTime>
        </Trigger>
    </Triggers>
    <Actions>
        <Action>
            <Command>C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe</Command>
        </Action>
    </Actions>
    <TestInfo DisableTests=""true"" />";

        private const string Daily = @"
    <TaskName>CreateAndDeleteTask</TaskName>
    <Folder>FTP</Folder>
    <ServiceAccount>FAEServiceAccount</ServiceAccount>
    <Triggers>
        <Trigger>
		    <Daily Interval=""1"">
				<StartDate>28/12/2015</StartDate>
                <StartTime>10:00:00</StartTime>
			</Daily>
        </Trigger>
    </Triggers>
    <Actions>
        <Action>
            <Command>C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe</Command>
            <Arguments>D:\AppFabricConfiguration\StartApfabricHostOnServerBoot.ps1</Arguments>
        </Action>
    </Actions>
    <TestInfo DisableTests=""true"" />";

        private const string DailyWithRepeat = @"
    <TaskName>CreateAndDeleteTask</TaskName>
    <Folder>FTP</Folder>
    <ServiceAccount>FAEServiceAccount</ServiceAccount>
    <Triggers>
        <Trigger>
		    <Daily Interval=""1"">
				<StartDate>28/12/2015</StartDate>
                <StartTime>10:00:00</StartTime>
                <RepeatEvery>02:00:00</RepeatEvery>
			</Daily>
        </Trigger>
    </Triggers>
    <Actions>
        <Action>
            <Command>C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe</Command>
            <Arguments>D:\AppFabricConfiguration\StartApfabricHostOnServerBoot.ps1</Arguments>
        </Action>
    </Actions>
    <TestInfo DisableTests=""true"" />";

        private const string DailyWithRepeatAndDuration = @"
    <TaskName>CreateAndDeleteTask</TaskName>
    <Folder>FTP</Folder>
    <ServiceAccount>FAEServiceAccount</ServiceAccount>
    <Triggers>
        <Trigger>
		    <Daily Interval=""1"">
				<StartDate>28/12/2015</StartDate>
                <StartTime>10:00:00</StartTime>
                <RepeatEvery>01:00:00</RepeatEvery>
                <RepeatDuration>12:00:00</RepeatDuration>
			</Daily>
        </Trigger>
    </Triggers>
    <Actions>
        <Action>
            <Command>C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe</Command>
            <Arguments>D:\AppFabricConfiguration\StartApfabricHostOnServerBoot.ps1</Arguments>
        </Action>
    </Actions>
    <TestInfo DisableTests=""true"" />";

        private const string Weekly = @"
    <TaskName>CreateAndDeleteTask</TaskName>
    <Folder>FTP</Folder>
    <ServiceAccount>FAEServiceAccount</ServiceAccount>
    <Triggers>
        <Trigger>
		    <Weekly Interval=""2"">
				<StartDate>30/12/2015</StartDate>
                <StartTime>12:00:00</StartTime>
                <Days>
					<DayOfWeek>Monday</DayOfWeek>
					<DayOfWeek>Tuesday</DayOfWeek>
					<DayOfWeek>Thursday</DayOfWeek>
					<DayOfWeek>Friday</DayOfWeek>
				</Days>
            </Weekly>
        </Trigger>
    </Triggers>
    <Actions>
        <Action>
            <Command>C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe</Command>
            <Arguments>D:\AppFabricConfiguration\StartApfabricHostOnServerBoot.ps1</Arguments>
        </Action>
    </Actions>
    <TestInfo DisableTests=""true"" />";
    }
}