using System.Data.SqlClient;

namespace Deployment.Common.Helpers
{
    public static class DataHelper
    {
        public static string GetConnectionString(string databaseServer, string databaseInstance, string targetDatabase,
                                                 string userName, string password)
        {
            var connString = new SqlConnectionStringBuilder
            {
                DataSource = $@"{databaseServer}\{databaseInstance}",
                InitialCatalog = targetDatabase
            };
            if (string.IsNullOrEmpty(userName) || string.IsNullOrEmpty(password))
            {
                connString.IntegratedSecurity = true;
            }
            else
            {
                connString.UserID = userName;
                connString.Password = password;
            }

            return connString.ConnectionString;
        }
    }
}