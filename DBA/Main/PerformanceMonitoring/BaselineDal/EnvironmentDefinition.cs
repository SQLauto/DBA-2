using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Text;

namespace PerformanceMonitoring.BaselineDal
{
    public class Environments : ConfigurationSection
    {
        public const string sectionName = "Environments";

        [ConfigurationProperty("", IsDefaultCollection = true)]
        public MonitoredEnvironmentCollection MonitoredEnvironments
        {
            get
            {
                return this[""] as MonitoredEnvironmentCollection;
            }
        }

        public static Environments GetSection()
        {
            return (Environments)ConfigurationManager.GetSection(sectionName);
        }
    }

    
    public class MonitoredDatabase : ConfigurationElement
    {
        private const string DATABASE_NAME = "DatabaseName";
        private const string CONN_STRING = "ConnectionString";        

        [ConfigurationProperty(DATABASE_NAME, DefaultValue = "", IsKey = true, IsRequired = true)]
        public string DatabaseName
        {
            get { return ((string)(base[DATABASE_NAME])); }
            set { base[DATABASE_NAME] = value; }
        }

        [ConfigurationProperty(CONN_STRING, DefaultValue = "", IsKey = false, IsRequired = true)]
        public string ConnectionString
        {
            get { return ((string)(base[CONN_STRING])); }
            set { base[CONN_STRING] = value; }
        }               

    }

    [ConfigurationCollection(typeof(MonitoredDatabase))]
    public class MonitoredEnvironment : ConfigurationElementCollection
    {

        public MonitoredEnvironment()
        {
            this.AddElementName = "Database";
        }

        private const string ENVIRONMENT_NAME = "EnvironmentName";

        [ConfigurationProperty(ENVIRONMENT_NAME, DefaultValue = "", IsKey = true, IsRequired = true)]
        public string EnvironmentName
        {
            get { return ((string)(base[ENVIRONMENT_NAME])); }
            set { base[ENVIRONMENT_NAME] = value; }
        }


        protected override ConfigurationElement CreateNewElement()
        {
            return new MonitoredDatabase();
        }

        protected override object GetElementKey(ConfigurationElement element)
        {
            return (element as MonitoredDatabase).DatabaseName;
        }

        public new MonitoredDatabase this[string key]
        {
            get { return base.BaseGet(key) as MonitoredDatabase; }
        }

        public MonitoredDatabase this[int ind]
        {
            get { return base.BaseGet(ind) as MonitoredDatabase; }
        }
    }

    public class MonitoredEnvironmentCollection : ConfigurationElementCollection
    {

        public MonitoredEnvironmentCollection()
        {
            this.AddElementName = "MonitoredEnvironment";
        }

        protected override object GetElementKey(ConfigurationElement element)
        {
            return (element as MonitoredEnvironment).EnvironmentName;
        }

        protected override ConfigurationElement CreateNewElement()
        {
            return new MonitoredEnvironment();
        }

        public new MonitoredEnvironment this[string key]
        {
            get { return base.BaseGet(key) as MonitoredEnvironment; }
        }

        public MonitoredEnvironment this[int ind]
        {
            get { return base.BaseGet(ind) as MonitoredEnvironment; }
        }
    }
}
