using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data;
using System.Data.SqlClient;
using System.IO;
using Microsoft.VisualStudio.TestTools.UnitTesting;

namespace DatabaseHelpers.Tests
{
    [TestClass]
    public abstract class BaseDeploymentHelperTest
    {
        public SqlConnection Connection { get; private set; }
        public List<string> DeploymentHelperTestFiles { get; private set; }
        public const string DeploymentHelperFolder = @"Deploy\HelperScripts\SQLHelpers\DeploymentHelpers\";

        protected const string TableSchemaName = "dbo";
        protected const string TableName = "Random";
        protected const string TableLockEscalationType = "auto";
        protected const string TableLockEscalationTypeForNegativeTesting = "table";
        protected const string TableTypeName = "ExampleTableType";
        protected const string TableTypeSchema = "dbo";
        protected const string NullableColumnName = "Descr";
        protected const string NotNullableColumnName = "Name";
        protected const string DefaultConstraintColumnName = "ColumnWithDefaultConstraint";
        protected const string PrimaryKeyName = "pk_PrimaryKey";
        protected const string CheckConstraintName = "chk_CountOf";
        protected const string IdentityColumnName = "Id";
        protected const string ServiceContractName = "ExampleContract";
        protected const string ServiceMessageTypeName = "ExampleMessageType";
        protected const string ServiceQueueName = "ExampleQueue";
        protected const string ServiceQueueSchema = "dbo";
        protected const string ServiceName = "ExampleService";
        protected const string StoredProcedureName = "ExampleSproc";
        protected const string StoredProcedureSchema = "dbo";
        protected const string StoredProcedureContent = "select 1 as ThisWillExistInTheExampleSproc";
        protected const string ViewName = "ExampleView";
        protected const string ViewSchema = "dbo";
        protected const string ViewContent = "select * from sys.tables";
        protected const string FunctionName = "ExampleFunction";
        protected const string FunctionSchema = "dbo";
        protected const string SequenceSchema = "dbo";
        protected const string SequenceName = "ExampleSequence";
        protected const string InsertTriggerName = "ExampleInsertTriggerName";
        protected const string InsertTriggerContent = "select 1 ThisIsExampleTriggerContent";
        protected const string SynonymSchema = "dbo";
        protected const string SynonymName = "ExampleSynonym";
        protected const string ForeignKeyName = "ExampleForeignKey";
        protected const int ColumnMaxLength = 255;
        protected const string MaxLengthColumnName = "MaxLengthColumn";
        protected const string MaxLengthColumnType = "varchar";
        protected const string IndexName = "idx_ExampleIndex";
        protected const string UniqueConstraintName = "unq_ExampleConstraint";
        protected const string XmlSchemaCollectionName = "XmlSchemaCollectionExample";
        protected const string XmlSchemaCollectionSchema = "dbo";

        protected BaseDeploymentHelperTest()
        {
            DeploymentHelperTestFiles = new List<string>();
        }

        [TestInitialize]
        public void TestInitialise()
        {

            if (DeploymentHelperTestFiles == null || DeploymentHelperTestFiles.Count == 0)
            {
                throw new Exception("The DeploymentHelperTestFiles may not be null or empty.");
            }

            string connectionString = ConfigurationManager.ConnectionStrings["DatabaseHelpersConnectionString"].ConnectionString;
            Connection = new SqlConnection(connectionString);
            Connection.Open();

            foreach (string helperSproc in DeploymentHelperTestFiles)
            {
                ExecuteTestHelper(helperSproc);
            }
        }

        private void ExecuteTestHelper(string helperFileName)
        {
            var testFileOfInterest = helperFileName; //Path.Combine(DeploymentHelperFolder, helperFileName);
            bool fileExists = File.Exists(helperFileName);
            if (!fileExists)
            {
                throw new Exception("The DeploymentHelperTestFiles does not exist: " + helperFileName);
            }

            string sql = File.ReadAllText(helperFileName);

            using (var command = new SqlCommand(sql, Connection))
            {
                command.ExecuteNonQuery();
            }
        }

        protected void ExampleTriggerDelete()
        {
            string sql = string.Format(@"if exists (select 1 from sys.triggers tr inner join 
                                                        sys.tables t on 
	                                                        t.object_id = tr.parent_id
                                                        inner join sys.schemas sc on
	                                                        t.schema_id = sc.schema_id
                                                        where
                                                            t.name = '{1}' and
                                                sc.name = '{0}' and
                                                tr.name = '{2}'
            
                                                )
                            begin
	                           exec('drop trigger {0}.{2} ')
                            end

                            ", TableSchemaName, TableName, InsertTriggerName);

            using (var command = new SqlCommand(sql, Connection))
            {
                command.ExecuteNonQuery();
            }
        }

        protected void ExampleTriggerCreate()
        {
            ExampleTriggerDelete();

            string sql = string.Format(@"if not exists (select 1 from sys.triggers tr inner join 
                                                        sys.tables t on 
	                                                        t.object_id = tr.parent_id
                                                        inner join sys.schemas sc on
	                                                        t.schema_id = sc.schema_id
                                                        where
                                                            t.name = '{1}' and
                                                        sc.name = '{0}' and
                                                        tr.name = '{2}'
            
                                                        )
                            begin
	                           exec('create trigger {0}.{2} on {0}.{1} for insert as {3}')
                            end

                            ", TableSchemaName, TableName, InsertTriggerName, InsertTriggerContent);

            using (var command = new SqlCommand(sql, Connection))
            {
                command.ExecuteNonQuery();
            }
        }


        protected string CreateARandomName()
        {
            return "Random_" + Guid.NewGuid().ToString();
        }

        protected void CreateServiceBrokerArtifacts()
        {
            string sql = string.Format(@"if not exists (select 1 from sys.service_message_types c where c.name = '{1}')
                            begin
	                            create message type {1}
	                            validation = WELL_FORMED_XML;
                            end

                            if not exists (select 1 from sys.service_contracts c where c.name = '{0}')
                            begin
	                            create contract {0}
	                            ({1} SENT BY INITIATOR);
                            end

                            if exists (select 1 from sys.service_queues q  
                            inner join sys.schemas sc on  
                             q.schema_id = sc.schema_id
                            where 
	                            q.name = '{3}' and
	                            sc.name = '{2}')
                            begin
                                 if exists (select 1 from sys.services where name = '{4}')
                                begin
	                                drop service {4}
                                end

                                drop queue {2}.{3}
                            end

                            create queue {2}.{3};

                            if exists (select 1 from sys.services where name = '{4}')
                            begin
	                            drop service {4}
                            end

                            create service {4} on queue  {2}.{3};
                            ", ServiceContractName, ServiceMessageTypeName, ServiceQueueSchema, ServiceQueueName, ServiceName);

            using (var command = new SqlCommand(sql, Connection))
            {
                command.ExecuteNonQuery();
            }
        }

        protected void ExampleSequenceDelete()
        {
            string sql = string.Format(@"if exists ( select * from sys.sequences s inner join sys.schemas sc on
                                                    sc.schema_id = s.schema_id where sc.name = '{0}' 
                                                    and s.name = '{1}')
                                            exec('drop sequence {0}.{1}')
", SequenceSchema, SequenceName);

            using (var command = new SqlCommand(sql, Connection))
            {
                command.ExecuteNonQuery();
            }
        }

        protected void ExampleSequenceCreate()
        {
            ExampleSequenceDelete();

            ExampleFunctionDelete();

            string sql = string.Format(@"create sequence {0}.{1} ;
", SequenceSchema, SequenceName);

            using (var command = new SqlCommand(sql, Connection))
            {
                command.ExecuteNonQuery();
            }

        }

        protected void ExampleSynonymDelete()
        {
            string sql = string.Format(@"if exists ( select * from sys.synonyms s inner join sys.schemas sc on
                                                    sc.schema_id = s.schema_id where sc.name = '{0}' 
                                                    and s.name = '{1}')
                                            exec('drop synonym {0}.{1}')
", SynonymSchema, SynonymName);

            using (var command = new SqlCommand(sql, Connection))
            {
                command.ExecuteNonQuery();
            }
        }

        protected void ExampleSynonymCreate()
        {
            ExampleSynonymDelete();

            string sql = string.Format(@"create synonym {0}.{1} for sys.tables;
", SynonymSchema, SynonymName);

            using (var command = new SqlCommand(sql, Connection))
            {
                command.ExecuteNonQuery();
            }
        }

        protected void ExampleFunctionDelete()
        {
            string sql = string.Format(@"if exists ( select 1 from sys.objects f inner join sys.schemas sc on
                                                    sc.schema_id = f.schema_id where sc.name = '{0}' 
                                                    and f.name = '{1}')
                                            exec('drop function {0}.{1}')
", FunctionSchema, FunctionName);

            using (var command = new SqlCommand(sql, Connection))
            {
                command.ExecuteNonQuery();
            }
        }

        protected void ExampleTableTypeCreate()
        {
            ExampleTableTypeDelete();

            string sql = string.Format(@"create type {0}.{1} as table
(
	Id int
);
", TableTypeSchema, TableTypeName);

            using (var command = new SqlCommand(sql, Connection))
            {
                command.ExecuteNonQuery();
            }
        }

        protected void ExampleTableTypeDelete()
        {
            string sql = string.Format(@"if exists (select 1 from sys.table_types t 
			inner join sys.schemas sc on t.schema_id = sc.schema_id
			where t.name = '{1}'
			and sc.name = '{0}')
begin 
	exec('drop type {0}.{1}')
end
", TableTypeSchema, TableTypeName);

            using (var command = new SqlCommand(sql, Connection))
            {
                command.ExecuteNonQuery();
            }
        }

        protected void ExampleFunctionCreate()
        {
            ExampleFunctionDelete();

            string sql = string.Format(@"create function {0}.{1} (@i int)
returns int
with execute as caller
as 
begin
    return(@i)
end;
", FunctionSchema, FunctionName);

            using (var command = new SqlCommand(sql, Connection))
            {
                command.ExecuteNonQuery();
            }
        }

        protected void ExampleViewCreate()
        {
            ExampleViewDeleteIfExists();

            string sql = string.Format(@"create view {0}.{1} as 
                                {2};
", ViewSchema, ViewName, ViewContent);

            using (var command = new SqlCommand(sql, Connection))
            {
                command.ExecuteNonQuery();
            }
        }

        protected void ExampleViewDeleteIfExists()
        {
            string sql = string.Format(@"if exists ( select 1 from sys.views v inner join sys.schemas sc on
                                                    sc.schema_id = v.schema_id where sc.name = '{0}' 
                                                    and v.name = '{1}')
                                            exec('drop view {0}.{1}')
", ViewSchema, ViewName);

            using (var command = new SqlCommand(sql, Connection))
            {
                command.ExecuteNonQuery();
            }
        }

        protected void ExampleXmlSchemaCollectionCreate()
        {
            ExampleXmlSchemaCollectionDelete();

            string sql = string.Format(@"CREATE XML SCHEMA COLLECTION {0}.{1} AS
N'<?xml version=|1.0| encoding=|UTF-16|?>
<xsd:schema targetNamespace=|http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/ProductModelManuInstructions| 
   xmlns          =|http://schemas.microsoft.com/sqlserver/2004/07/adventure-works/ProductModelManuInstructions| 
   elementFormDefault=|qualified| 
   attributeFormDefault=|unqualified|
   xmlns:xsd=|http://www.w3.org/2001/XMLSchema| >

    <xsd:complexType name=|StepType| mixed=|true| >
        <xsd:choice  minOccurs=|0| maxOccurs=|unbounded| > 
            <xsd:element name=|tool| type=|xsd:string| />
            <xsd:element name=|material| type=|xsd:string| />
            <xsd:element name=|blueprint| type=|xsd:string| />
            <xsd:element name=|specs| type=|xsd:string| />
            <xsd:element name=|diag| type=|xsd:string| />
        </xsd:choice> 
    </xsd:complexType>

    <xsd:element  name=|root|>
        <xsd:complexType mixed=|true|>
            <xsd:sequence>
                <xsd:element name=|Location| minOccurs=|1| maxOccurs=|unbounded|>
                    <xsd:complexType mixed=|true|>
                        <xsd:sequence>
                            <xsd:element name=|step| type=|StepType| minOccurs=|1| maxOccurs=|unbounded| />
                        </xsd:sequence>
                        <xsd:attribute name=|LocationID| type=|xsd:integer| use=|required|/>
                        <xsd:attribute name=|SetupHours| type=|xsd:decimal| use=|optional|/>
                        <xsd:attribute name=|MachineHours| type=|xsd:decimal| use=|optional|/>
                        <xsd:attribute name=|LaborHours| type=|xsd:decimal| use=|optional|/>
                        <xsd:attribute name=|LotSize| type=|xsd:decimal| use=|optional|/>
                    </xsd:complexType>
                </xsd:element>
            </xsd:sequence>
        </xsd:complexType>
    </xsd:element>
</xsd:schema>' ;
".Replace('|', '"'), XmlSchemaCollectionSchema, XmlSchemaCollectionName);

            using (var command = new SqlCommand(sql, Connection))
            {
                command.ExecuteNonQuery();
            }
        }

        public void ExampleXmlSchemaCollectionDelete()
        {

            string sql = string.Format(@"if exists (select 1 from 
				sys.xml_schema_collections xsc
				inner join sys.schemas sc on	
					sc.Schema_Id = xsc.schema_id
				where
					sc.name = '{0}'
				and xsc.name = '{1}')
                begin
                    exec('drop  XML SCHEMA COLLECTION {0}.{1}');
                end
", XmlSchemaCollectionSchema, XmlSchemaCollectionName);

            using (var command = new SqlCommand(sql, Connection))
            {
                command.ExecuteNonQuery();
            }
        }

        protected void ExampleStoredProcedureCreate()
        {
            ExampleStoredProcedureDeleteIfExists();

            string sql = string.Format(@"create procedure {0}.{1} as 
                            begin
                                {2} 
                            end;
", StoredProcedureSchema, StoredProcedureName, StoredProcedureContent);

            using (var command = new SqlCommand(sql, Connection))
            {
                command.ExecuteNonQuery();
            }
        }

        protected void ExampleStoredProcedureDeleteIfExists()
        {
            string sql = string.Format(@"if exists ( select 1 from sys.procedures p inner join sys.schemas sc on
                                                    sc.schema_id = p.schema_id where sc.name = '{0}' 
                                                    and p.name = '{1}')
                                            exec('drop procedure {0}.{1}')
", StoredProcedureSchema, StoredProcedureName);
            
            using (var command = new SqlCommand(sql, Connection))
            {
                command.ExecuteNonQuery();
            }
        }

        protected void CreateATable()
        {
            string sql = string.Format(@"if exists (select 1 from sys.tables t inner join sys.schemas sc on
                                                    sc.schema_id = t.schema_id where sc.name = '{0}' 
                                                    and t.name = '{1}')
                                            begin
                                                exec('drop table {0}.{1}')
                                            end;
                create table {0}.{1}
                (
                    {2}  int identity(1,1) not null,
                    CountOf int not null,
                    RefColumn varchar({8}) not null,
                    {3} varchar({8}) not null,
                    {4} varchar(max) null,
                    {9} {10}({8}) not null,
                    {12} int null default(-1),
                    constraint {5} primary key ({3}),
                    constraint {6} check(CountOf > 0)
                );

                alter table {0}.{1} set (lock_escalation = {14} )

                if exists (select 1 from sys.foreign_keys s inner join sys.schemas sc on
                                                    sc.schema_id = s.schema_id where sc.name = '{7}' 
                                                    and s.name = '{0}')
                begin
                    alter table {0}.{1} drop {7}
                end;

                alter table {0}.{1} add constraint {7} foreign key (RefColumn) references {0}.{1}({3})

                if exists(select 1 from sys.indexes si
                     inner join sys.tables t on 
                           si.object_id = t.object_id
                     inner join sys.schemas sc on
                           sc.schema_id = t.schema_id
                     where 
                           si.name = '{4}'
                     and t.name = '{1}'
                     and sc.name = '{0}')
	            begin
                    drop index {0}.{13}
                end

                alter table {0}.{1} add constraint {13} unique(CountOf)

                if exists (select * from sys.indexes i 
                            inner join sys.tables t on 
	                            t.object_id = i.object_id
                            inner join sys.schemas sc on	
	                            t.schema_id = sc.schema_id
                            where
	                            i.name = '{11}'
                            and sc.name = '{0}')
                begin
                    drop index {0}.{11}
                end

                create nonclustered index {11} on {0}.{1}(RefColumn)
            ", TableSchemaName, TableName, IdentityColumnName, NotNullableColumnName, NullableColumnName, PrimaryKeyName, 
             CheckConstraintName, ForeignKeyName, ColumnMaxLength, MaxLengthColumnName, MaxLengthColumnType, IndexName, 
             DefaultConstraintColumnName, UniqueConstraintName, TableLockEscalationType);

            using (var command = new SqlCommand(sql, Connection))
            {
                command.ExecuteNonQuery();
            }
        }

        [TestCleanup]
        public void TestCleanup()
        {
            if (Connection != null)
            {
                if (Connection.State == ConnectionState.Open)
                {
                    Connection.Close();
                }

                Connection.Dispose();
            }
        }

        protected bool ExecuteSqlGetBoolean(string sql, string outputParamName)
        {
            bool b = false;
            sql += string.Format("; {0} select {1} ReturnValue;", Environment.NewLine, outputParamName);
 
            using (var command = new SqlCommand(sql, Connection))
            {
                using (var reader = command.ExecuteReader())
                {
                    if (reader.HasRows)
                    {
                        reader.Read();
                        b = (bool) reader["ReturnValue"];
                    }
                }

            }

            return b;
        }

    }
}