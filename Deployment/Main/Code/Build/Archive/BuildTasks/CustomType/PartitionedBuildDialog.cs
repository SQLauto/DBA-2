using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Windows.Forms;

using CustomBuildActivities.CustomType;

namespace CustomBuildActivities.CustomType
{
    public partial class PartitionedBuildDialog : Form
    {
        public PartitionedBuildDialog(PartitionedBuildSettings settings)
        {
            InitializeComponent();
            Settings = settings;
        }

        protected override void OnLoad(EventArgs e)
        {
            base.OnLoad(e);
            // Initialise control values
            enbalePartition_CheckBox.CheckState = Settings.UsePartitionedBuild ? CheckState.Checked : CheckState.Unchecked;
            EnableDisablePartitionedBuilds(Settings.UsePartitionedBuild);
            foreach (PartitionedBuild build in Settings.PartitionedBuilds)
            {
                string[] row = new string[] { build.TeamProjectName, build.BuildDefinitionName, build.BuildNumber };
                buildsGridView.Rows.Add(row);
            }            
        }

        private void enablePartitionCheckBox_CheckedChanged(object sender, EventArgs e)
        {
            EnableDisablePartitionedBuilds(enbalePartition_CheckBox.CheckState == CheckState.Checked);           
        }

        private void buttonOK_Click(object sender, EventArgs e)
        {
            // Update setting values
            Settings.UsePartitionedBuild = enbalePartition_CheckBox.CheckState == CheckState.Checked ? true : false;

            Settings.PartitionedBuilds.Clear();
            foreach (DataGridViewRow row in buildsGridView.Rows)
            {
                if (!row.IsNewRow)
                {
                    Settings.PartitionedBuilds.Add(new PartitionedBuild()
                        {
                            TeamProjectName = row.Cells[0].Value != null ? row.Cells[0].Value.ToString() : string.Empty,
                            BuildDefinitionName = row.Cells[1].Value != null ? row.Cells[1].Value.ToString() : string.Empty,
                            BuildNumber = row.Cells[2].Value != null ? row.Cells[2].Value.ToString() : string.Empty
                        });
                }
            }
            this.DialogResult = DialogResult.OK;

        }

        private void buttonCancel_Click(object sender, EventArgs e)
        {
            this.DialogResult = DialogResult.Cancel;
        }

        public PartitionedBuildSettings Settings = new PartitionedBuildSettings();

        private void linkHelp_LinkClicked(object sender, LinkLabelLinkClickedEventArgs e)
        {
            System.Diagnostics.Process.Start("http://10.107.197.124/mediawiki/index.php?title=Multi-Partitioned_TFS_Builds");
        }

        private void EnableDisablePartitionedBuilds(bool enable)
        {
            if (enable)
            {
                buildsGridView.Enabled = true;
                buildsGridView.EnableHeadersVisualStyles = true;
                buildsGridView.DefaultCellStyle.BackColor = SystemColors.Window;
                buildsGridView.DefaultCellStyle.ForeColor = SystemColors.ControlText;
                buildsGridView.ColumnHeadersDefaultCellStyle.BackColor = SystemColors.Window;
                buildsGridView.ColumnHeadersDefaultCellStyle.ForeColor = SystemColors.ControlText;
            }
            else
            {
                buildsGridView.Enabled = false;
                buildsGridView.EnableHeadersVisualStyles = false;
                buildsGridView.DefaultCellStyle.BackColor = SystemColors.Control;
                buildsGridView.DefaultCellStyle.ForeColor = SystemColors.GrayText;
                buildsGridView.ColumnHeadersDefaultCellStyle.BackColor = SystemColors.Control;
                buildsGridView.ColumnHeadersDefaultCellStyle.ForeColor = SystemColors.GrayText;
            }
        }
    }
}
