using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Windows.Forms;

namespace LabManager
{
    public partial class DetailsDialog : Form
    {
        public DetailsDialog()
        {
            InitializeComponent();
        }

        private Details currentDetails;

        public Details Details
        {
            get
            {
                getValues();
                return currentDetails;
            }
            set
            {
                currentDetails = value;
                setValues();
            }
        }

        private void getValues()
        {
            currentDetails.Domain = textDomain.Text;
            currentDetails.Organisation = textOrganisation.Text;
            currentDetails.Password = textPassword.Text;
            currentDetails.Server = textServer.Text;
            currentDetails.UserName = textUserName.Text;

            currentDetails.Workspace = comboWorkspace.Text; //comboWorkspace.SelectedText;
            currentDetails.TargetWorkspace = comboTargetWorkspace.Text; //comboTargetWorkspace.SelectedText;

        }

        private void setValues()
        {
            textDomain.Text = currentDetails.Domain;
            textOrganisation.Text = currentDetails.Organisation;
            textPassword.Text = currentDetails.Password;
            textServer.Text = currentDetails.Server;
            textUserName.Text = currentDetails.UserName;

            comboWorkspace.Text = currentDetails.Workspace;
            comboTargetWorkspace.Text = currentDetails.TargetWorkspace;
   
        }

        private void buttonTest_Click(object sender, EventArgs e)
        {
            try
            {

                getValues();
                Service testService = new Service(currentDetails);

                textBox1.Text = string.Format("calling {0} \r\n", currentDetails.ServiceURL);

                var conf = from c in testService.Client.ListConfigurations(testService.AuthHeader, 1)
                           select c.name;

                foreach (string s in conf)
                {
                    textBox1.Text += string.Format("found configuration {0} \r\n", s);
                }

                //populate the Workspace comboboxes
                //CustomBuildActivities.LabManagerInternalService.Workspace[] workspaces = testService.InternalClient.GetAllWorkspaces(testService.InternalAuthHeader);
 

                this.comboWorkspace.DataSource = testService.InternalClient.GetAllWorkspaces(testService.InternalAuthHeader);
                this.comboTargetWorkspace.DataSource = testService.InternalClient.GetAllWorkspaces(testService.InternalAuthHeader);


            }
            catch (Exception ex)
            {
                textBox1.Text += ex.Message + "/r/n" + ex.StackTrace;

                //throw;
            }




            
        }


    }
}
