using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Text;
using Deployment.Common;

namespace Deployment.Database.Logging
{
    public class SqlDataLogger
    {
        private string _connectionString;
        private readonly string _server;
        private readonly string _databaseName;
        private readonly string _username;
        private readonly string _password;

        public SqlDataLogger() : this("TDC2SQL005.FAE.TFL.LOCAL", "FTPEnvironmentManagment", "tfsbuild", "LMTF$Bu1ld")
        {

        }

        public SqlDataLogger(string connectionString)
        {
            _connectionString = connectionString;
        }

        public SqlDataLogger(string server, string databaseName, string username, string password)
        {
            _server = server;
            _databaseName = databaseName;
            _username = username;
            _password = password;
        }

        public string ConnectionString
        {
            get
            {
                return
                _connectionString =
                    _connectionString ?? string.Format("Server={0};Initial Catalog={1};User Id={2};Password={3};", _server,
                        _databaseName, _username, _password);
            }
        }
        public int GenerateDeploymentId(string rigName, string packageName, string scriptHost, string initialisationSource)
        {
            var cmdText = new StringBuilder();
            cmdText.Append("INSERT INTO dbo.FTPDeployment (RigName, PackageName, ScriptHost, InitialisationSource ) VALUES (")
                .AppendFormat("'{0}', ", rigName.Replace("'", "''"))
                .AppendFormat("'{0}', ", packageName.Replace("'", "''"))
                .AppendFormat("'{0}', ", scriptHost.Replace("'", "''"))
                .AppendFormat("'{0}' ", initialisationSource.Replace("'", "''"))
                .Append("); ")
                .Append(" SELECT SCOPE_IDENTITY()");

            var result = CreateRecord(cmdText.ToString());

            if(result == null)
                throw new ApplicationException("Unable to generate new Deployment event logging ID");

            int deploymentId;
            int.TryParse(result.ToString(), out deploymentId);
            return deploymentId;
        }

        public int GenerateVCloudDeploymentId(string vAppName, string notes, string scriptHost, string initialisationSource)
        {
            var cmdText = new StringBuilder();
            cmdText.Append(
                "INSERT INTO dbo.vCloudDeployment (vAppName, Notes, ScriptHost, InitialisationSource) VALUES(")
                .AppendFormat("'{0}', ", vAppName.Replace("'", "''"))
                .AppendFormat("'{0}', ", notes.Replace("'", "''"))
                .AppendFormat("'{0}', ", scriptHost.Replace("'", "''"))
                .AppendFormat("'{0}' ", initialisationSource.Replace("'", "''"))
                .Append("); ")
                .Append(" SELECT SCOPE_IDENTITY()");

            var result = CreateRecord(cmdText.ToString());

            if (result == null)
                throw new ApplicationException("Unable to generate new VCloud Deployment event logging ID");

            int deploymentId;
            int.TryParse(result.ToString(), out deploymentId);
            return deploymentId;
        }

        public int LogDeploymentEvent(int deploymentId, IDictionary<string, object> logEvents)
        {
            if (deploymentId < 0)
                throw new ApplicationException(
                    "Deployment database logging has not been initialised correctly and cannot log events.");

            int result = 0;

            foreach (var logEvent in logEvents)
            {
                switch (logEvent.Key.ToUpper())
                {
                    case "EVENTID":
                        DeploymentEventAction action;
                        var success = Enum.TryParse(logEvent.Value.ToString(), true, out action);

                        var columnName = success ? action.Description() : null;

                        if (!string.IsNullOrEmpty(columnName))
                        {
                            result =
                                UpdateRecord(
                                    string.Format(
                                        "UPDATE [dbo].[FTPDeployment] SET [{0}] = GETDATE() WHERE [ID] = {1};",
                                        columnName, deploymentId));
                        }
                        break;

                    case "SETUPDEPLOYMENTEXITCODE":
                        result =
                            UpdateRecord(
                                string.Format(
                                    "UPDATE [dbo].[FTPDeployment] SET [SetupDeployment_ExitCode] = {0} WHERE [ID] = {1}",
                                    logEvent.Value, deploymentId));
                        break;

                    case "DEPLOYRIGEXITCODE":
                        result =
                            UpdateRecord(
                                string.Format(
                                    "UPDATE [dbo].[FTPDeployment] SET [DeployRig_ExitCode] = {0} WHERE [ID] = {1}",
                                    logEvent.Value, deploymentId));
                        break;

                    case "LASTERROR":
                        result =
                            UpdateRecord(
                                string.Format(
                                    "UPDATE [dbo].[FTPDeployment] SET [LastError] = '{0}' WHERE [ID] = {1}",
                                    logEvent.Value, deploymentId));
                        break;

                    case "LASTEXCEPTION":
                        result =
                            UpdateRecord(
                                string.Format(
                                    "UPDATE [dbo].[FTPDeployment] SET [LastException] = '{0}' WHERE [ID] = {1}",
                                    logEvent.Value, deploymentId));
                        break;

                    case "VAPPGUID":
                        result =
                            UpdateRecord(
                                string.Format(
                                    "UPDATE [dbo].[FTPDeployment] SET [vAppGuid] = CONVERT(uniqueidentifier,'{0}') WHERE [ID] = {1}",
                                    logEvent.Value.ToString().ToUpper(), deploymentId));
                        break;

                    case "BUILDNUMBER":
                        result = UpdateRecord(string.Format("UPDATE [dbo].[FTPDeployment] SET [BuildNumber] = '{0}' WHERE [ID] = {1}", logEvent.Value, deploymentId));
                        break;

                    case "TESTRESULT":
                        result = UpdateRecord(string.Format("UPDATE [dbo].[FTPDeployment] SET [TestResult] = {0} WHERE [ID] = {1}", logEvent.Value, deploymentId));
                        break;

                    case "SHUTDOWNONGREEN":
                        result = UpdateRecord(string.Format("UPDATE [dbo].[FTPDeployment] SET [ShutdownOnGreen] = {0} WHERE [ID] = {1}", logEvent.Value, deploymentId));
                        break;

                    case "ENVIRONMENT":
                        result = UpdateRecord(string.Format("UPDATE [dbo].[FTPDeployment] SET [Environment] = '{0}' WHERE [ID] = {1}", logEvent.Value, deploymentId));
                        break;

                    default:
                        throw new ApplicationException(string.Format("No valid column exists for {0}", logEvent.Key));
                }
            }

            return result;
        }

        public int LogVCloudEvent(int vCloudDeploymentId, IDictionary<string, object> logEvents)
        {
            if (vCloudDeploymentId < 0)
                throw new ApplicationException(
                    "Deployment vCloud database logging has not been initialised correctly and cannot log events.");

            int result = 0;

            foreach (var logEvent in logEvents)
            {
                switch (logEvent.Key.ToUpper())
                {
                    case "EVENTID":

                        DeploymentVCloudAction action;
                        var success = Enum.TryParse(logEvent.Value.ToString(), true, out action);

                        var columnName = success ? action.Description() : null;

                        if (!string.IsNullOrEmpty(columnName))
                        {
                            result =
                                UpdateRecord(
                                    string.Format(
                                        "UPDATE [dbo].[vCloudDeployment] SET [{0}] = GETDATE() WHERE [ID] = {1};",
                                        columnName, vCloudDeploymentId));
                        }
                        break;

                    case "VERIFYSUCCESSFUL":
                        result =
                            UpdateRecord(
                                string.Format(
                                    "UPDATE [dbo].[vCloudDeployment] SET [VerifyVappSuccessful] = '{0}' WHERE [ID] = {1}",
                                    logEvent.Value, vCloudDeploymentId));
                        break;

                    case "VERIFYLOOPSCOMPLETED":
                        result =
                            UpdateRecord(
                                string.Format(
                                    "UPDATE [dbo].[vCloudDeployment] SET [VerifyLoopsCompleted] = '{0}' WHERE [ID] = {1}",
                                    logEvent.Value, vCloudDeploymentId));
                        break;

                    case "EXITCODE":
                        result =
                            UpdateRecord(
                                string.Format(
                                    "UPDATE [dbo].[vCloudDeployment] SET [ExitCode] = '{0}' WHERE [ID] = {1}",
                                    logEvent.Value, vCloudDeploymentId));
                        break;

                    case "LASTERROR":
                        result =
                            UpdateRecord(
                                string.Format(
                                    "UPDATE [dbo].[vCloudDeployment] SET [LastError] = '{0}' WHERE [ID] = {1}",
                                    logEvent.Value, vCloudDeploymentId));
                        break;

                    case "LASTEXCEPTION":
                        result =
                            UpdateRecord(
                                string.Format(
                                    "UPDATE [dbo].[vCloudDeployment] SET [LastException] = '{0}' WHERE [ID] = {1}",
                                    logEvent.Value, vCloudDeploymentId));
                        break;

                    case "NOTES":
                        result =
                            UpdateRecord(
                                string.Format("UPDATE [dbo].[vCloudDeployment] SET [Notes] = '{0}' WHERE [ID] = {1}",
                                    logEvent.Value, vCloudDeploymentId));
                        break;

                    case "STARTSTATE":
                        result =
                            UpdateRecord(
                                string.Format(
                                    "UPDATE [dbo].[vCloudDeployment] SET [StartState] = '{0}' WHERE [ID] = {1}",
                                    logEvent.Value, vCloudDeploymentId));
                        break;

                    case "VAPPGUID":
                        result =
                            UpdateRecord(
                                string.Format(
                                    "UPDATE [dbo].[vCloudDeployment] SET [vAppGuid] = '{0}' WHERE [ID] = {1}",
                                    logEvent.Value.ToString().ToUpper(), vCloudDeploymentId));
                        break;

                    case "TEMPLATENAME":
                        result =
                            UpdateRecord(
                                string.Format(
                                    "UPDATE [dbo].[vCloudDeployment] SET [TemplateName] = '{0}' WHERE [ID] = {1}",
                                    logEvent.Value, vCloudDeploymentId));
                        break;

                    default:
                        throw new ApplicationException(string.Format("No valid column exists for {0}", logEvent.Key));
                }
            }

            return result;
        }

        public object CreateRecord(string commandText)
        {
            if (string.IsNullOrEmpty(commandText))
                throw new ArgumentNullException("commandText");

            using (var connection = new SqlConnection(ConnectionString))
            {
                using (var command = new SqlCommand(commandText, connection))
                {
                    try
                    {
                        connection.Open();
                        var result = command.ExecuteScalar();
                        return result;
                    }
                    catch (Exception)
                    {
                        return null;
                    }
                }
            }
        }

        public int UpdateRecord(string commandText)
        {
            if (string.IsNullOrEmpty(commandText))
                throw new ArgumentNullException("commandText");

            using (var connection = new SqlConnection(ConnectionString))
            {
                using (var command = new SqlCommand(commandText, connection))
                {
                    try
                    {
                        connection.Open();
                        var result = command.ExecuteNonQuery();
                        return result;
                    }
                    catch (Exception)
                    {
                        return -1;
                    }
                }
            }
        }
    }
}