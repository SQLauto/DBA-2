using System;
using System.Data;
using System.Data.Common;

namespace Deployment.Database
{
    public static class DataExtensions
    {
        public static IDbCommand OfType(this IDbCommand command, CommandType commandType)
        {
            command.CommandType = commandType;
            return command;
        }

        public static IDbCommand AddOutputParameter(this IDbCommand command, string name, DbType type, int size = 0)
        {
            var isString = type == DbType.String || type == DbType.StringFixedLength || type == DbType.AnsiString ||
                           type == DbType.AnsiStringFixedLength;

            var param = command.CreateParameter();
            param.ParameterName = name;
            param.DbType = type;
            param.Direction = ParameterDirection.Output;

            if (isString && size == 0)
                throw new ArgumentException("size cannot be zero for string parameters");

            if (isString)
                param.Size = size;

            command.Parameters.Add(param);

            return command;
        }

        private static IDbCommand AddParameter(this IDbCommand command, string name, DbType type, object value)
        {
            var param = command.CreateParameter();
            param.ParameterName = name;
            param.DbType = type;
            param.Value = value;
            param.Direction = ParameterDirection.Input;

            command.Parameters.Add(param);

            return command;
        }

        public static IDbCommand AddStringParameter(this IDbCommand command, string name, string value)
        {
            return AddParameter(command, name, DbType.String, value);
        }

        public static IDbCommand AddAnsiStringParameter(this IDbCommand command, string name, string value)
        {
            return AddParameter(command, name, DbType.AnsiString, value);
        }

        public static IDbCommand AddBoolParameter(this IDbCommand command, string name, bool? value)
        {
            return AddParameter(command, name, DbType.Boolean, value);
        }

        public static IDbCommand AddInt32Parameter(this IDbCommand command, string name, int? value)
        {
            return AddParameter(command, name, DbType.Int32, value);
        }

        public static IDbCommand AddInt64Parameter(this IDbCommand command, string name, long? value)
        {
            return AddParameter(command, name, DbType.Int64, value);
        }

        public static IDbCommand AddDateParameter(this IDbCommand command, string name, DateTime? value)
        {
            return AddParameter(command, name, DbType.DateTime, value);
        }

        public static IDbCommand AddDate2Parameter(this IDbCommand command, string name, DateTime? value)
        {
            return AddParameter(command, name, DbType.DateTime2, value);
        }

        public static T ExecuteWithOutputParameter<T>(this IDbCommand command, string name, DbType type, int size = 0)
        {
            AddOutputParameter(command, name, type);
            command.ExecuteNonQuery();
            return ReadOutputParameterValue<T>(command, name);
        }

        public static IDataReader ExecuteSingleRow(this IDbCommand command)
        {
            return command.ExecuteReader(CommandBehavior.SingleResult);
        }

        public static T ReadOutputParameterValue<T>(this IDbCommand command, string name)
        {
            var param = (DbParameter)command.Parameters[name];
            return param.Value == DBNull.Value ? default(T) : (T)param.Value;
        }

        public static T ReadValue<T>(this IDataReader dataReader, string name)
        {
            var ordinal = dataReader.GetOrdinal(name);
            return dataReader.IsDBNull(ordinal) ? default(T) : (T)dataReader.GetValue(ordinal);
        }

        public static T ReadValue<T>(this IDataReader dataReader, string name, T defaultValue)
        {
            var ordinal = dataReader.GetOrdinal(name);
            return dataReader.IsDBNull(ordinal) ? defaultValue : (T)dataReader.GetValue(ordinal);
        }

        public static string ReadString(this IDataReader dataReader, string name)
        {
            var ordinal = dataReader.GetOrdinal(name);
            return dataReader.IsDBNull(ordinal) ? null : dataReader.GetString(ordinal).Trim();
        }

        public static bool? ReadBool(this IDataReader dataReader, string name)
        {
            var ordinal = dataReader.GetOrdinal(name);
            return dataReader.IsDBNull(ordinal) ? (bool?)null : dataReader.GetBoolean(ordinal);
        }

        public static int? ReadInt16(this IDataReader dataReader, string name)
        {
            var ordinal = dataReader.GetOrdinal(name);
            return dataReader.IsDBNull(ordinal) ? (int?)null : dataReader.GetInt16(ordinal);
        }

        public static int? ReadInt32(this IDataReader dataReader, string name)
        {
            var ordinal = dataReader.GetOrdinal(name);
            return dataReader.IsDBNull(ordinal) ? (int?)null : dataReader.GetInt32(ordinal);
        }

        public static long? ReadInt64(this IDataReader dataReader, string name)
        {
            var ordinal = dataReader.GetOrdinal(name);
            return dataReader.IsDBNull(ordinal) ? (long?)null : dataReader.GetInt64(ordinal);
        }

        public static double? ReadDouble(this IDataReader dataReader, string name)
        {
            var ordinal = dataReader.GetOrdinal(name);
            return dataReader.IsDBNull(ordinal) ? (double?)null : dataReader.GetDouble(ordinal);
        }

        public static float? ReadFloat(this IDataReader dataReader, string name)
        {
            var ordinal = dataReader.GetOrdinal(name);
            return dataReader.IsDBNull(ordinal) ? (float?)null : dataReader.GetFloat(ordinal);
        }

        public static byte? ReadTinyInt(this IDataReader dataReader, string name)
        {
            var ordinal = dataReader.GetOrdinal(name);
            return dataReader.IsDBNull(ordinal) ? (byte?)null : dataReader.GetByte(ordinal);
        }

        public static DateTime? ReadDateTime(this IDataReader dataReader, string name)
        {
            var ordinal = dataReader.GetOrdinal(name);
            return dataReader.IsDBNull(ordinal) ? (DateTime?)null : dataReader.GetDateTime(ordinal);
        }
    }
}