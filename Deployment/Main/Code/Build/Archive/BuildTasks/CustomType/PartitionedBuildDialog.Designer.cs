namespace CustomBuildActivities.CustomType
{
    partial class PartitionedBuildDialog
    {
        /// <summary>
        /// Required designer variable.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Clean up any resources being used.
        /// </summary>
        /// <param name="disposing">true if managed resources should be disposed; otherwise, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Windows Form Designer generated code

        /// <summary>
        /// Required method for Designer support - do not modify
        /// the contents of this method with the code editor.
        /// </summary>
        private void InitializeComponent()
        {
            this.enbalePartition_CheckBox = new System.Windows.Forms.CheckBox();
            this.buildsGridView = new System.Windows.Forms.DataGridView();
            this.column_TeamProject = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.column_BuildName = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.column_BuildNumber = new System.Windows.Forms.DataGridViewTextBoxColumn();
            this.buttonCancel = new System.Windows.Forms.Button();
            this.buttonOK = new System.Windows.Forms.Button();
            this.linkHelp = new System.Windows.Forms.LinkLabel();
            ((System.ComponentModel.ISupportInitialize)(this.buildsGridView)).BeginInit();
            this.SuspendLayout();
            // 
            // enbalePartition_CheckBox
            // 
            this.enbalePartition_CheckBox.AutoSize = true;
            this.enbalePartition_CheckBox.Location = new System.Drawing.Point(12, 12);
            this.enbalePartition_CheckBox.Name = "enbalePartition_CheckBox";
            this.enbalePartition_CheckBox.Size = new System.Drawing.Size(143, 17);
            this.enbalePartition_CheckBox.TabIndex = 0;
            this.enbalePartition_CheckBox.Text = "Enable Partitioned Builds";
            this.enbalePartition_CheckBox.UseVisualStyleBackColor = true;
            this.enbalePartition_CheckBox.CheckedChanged += new System.EventHandler(this.enablePartitionCheckBox_CheckedChanged);
            // 
            // buildsGridView
            // 
            this.buildsGridView.AllowUserToOrderColumns = true;
            this.buildsGridView.Anchor = ((System.Windows.Forms.AnchorStyles)((((System.Windows.Forms.AnchorStyles.Top | System.Windows.Forms.AnchorStyles.Bottom) 
            | System.Windows.Forms.AnchorStyles.Left) 
            | System.Windows.Forms.AnchorStyles.Right)));
            this.buildsGridView.ClipboardCopyMode = System.Windows.Forms.DataGridViewClipboardCopyMode.EnableWithoutHeaderText;
            this.buildsGridView.ColumnHeadersHeightSizeMode = System.Windows.Forms.DataGridViewColumnHeadersHeightSizeMode.AutoSize;
            this.buildsGridView.Columns.AddRange(new System.Windows.Forms.DataGridViewColumn[] {
            this.column_TeamProject,
            this.column_BuildName,
            this.column_BuildNumber});
            this.buildsGridView.Location = new System.Drawing.Point(12, 35);
            this.buildsGridView.Name = "buildsGridView";
            this.buildsGridView.Size = new System.Drawing.Size(655, 150);
            this.buildsGridView.TabIndex = 1;
            // 
            // column_TeamProject
            // 
            this.column_TeamProject.AutoSizeMode = System.Windows.Forms.DataGridViewAutoSizeColumnMode.None;
            this.column_TeamProject.HeaderText = "Team Project";
            this.column_TeamProject.Name = "column_TeamProject";
            this.column_TeamProject.Width = 115;
            // 
            // column_BuildName
            // 
            this.column_BuildName.AutoSizeMode = System.Windows.Forms.DataGridViewAutoSizeColumnMode.Fill;
            this.column_BuildName.HeaderText = "Build Name";
            this.column_BuildName.Name = "column_BuildName";
            // 
            // column_BuildNumber
            // 
            this.column_BuildNumber.AutoSizeMode = System.Windows.Forms.DataGridViewAutoSizeColumnMode.Fill;
            this.column_BuildNumber.HeaderText = "Build Number";
            this.column_BuildNumber.Name = "column_BuildNumber";
            // 
            // buttonCancel
            // 
            this.buttonCancel.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Right)));
            this.buttonCancel.Location = new System.Drawing.Point(592, 191);
            this.buttonCancel.Name = "buttonCancel";
            this.buttonCancel.Size = new System.Drawing.Size(75, 23);
            this.buttonCancel.TabIndex = 2;
            this.buttonCancel.Text = "Cancel";
            this.buttonCancel.UseVisualStyleBackColor = true;
            this.buttonCancel.Click += new System.EventHandler(this.buttonCancel_Click);
            // 
            // buttonOK
            // 
            this.buttonOK.Anchor = ((System.Windows.Forms.AnchorStyles)((System.Windows.Forms.AnchorStyles.Bottom | System.Windows.Forms.AnchorStyles.Right)));
            this.buttonOK.Location = new System.Drawing.Point(511, 191);
            this.buttonOK.Name = "buttonOK";
            this.buttonOK.Size = new System.Drawing.Size(75, 23);
            this.buttonOK.TabIndex = 3;
            this.buttonOK.Text = "OK";
            this.buttonOK.UseVisualStyleBackColor = true;
            this.buttonOK.Click += new System.EventHandler(this.buttonOK_Click);
            // 
            // linkHelp
            // 
            this.linkHelp.AutoSize = true;
            this.linkHelp.Location = new System.Drawing.Point(12, 195);
            this.linkHelp.Name = "linkHelp";
            this.linkHelp.Size = new System.Drawing.Size(29, 13);
            this.linkHelp.TabIndex = 4;
            this.linkHelp.TabStop = true;
            this.linkHelp.Text = "Help";
            this.linkHelp.LinkClicked += new System.Windows.Forms.LinkLabelLinkClickedEventHandler(this.linkHelp_LinkClicked);
            // 
            // PartitionedBuildDialog
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.BackgroundImageLayout = System.Windows.Forms.ImageLayout.None;
            this.ClientSize = new System.Drawing.Size(682, 223);
            this.Controls.Add(this.linkHelp);
            this.Controls.Add(this.buttonOK);
            this.Controls.Add(this.buttonCancel);
            this.Controls.Add(this.buildsGridView);
            this.Controls.Add(this.enbalePartition_CheckBox);
            this.MaximizeBox = false;
            this.MinimizeBox = false;
            this.Name = "PartitionedBuildDialog";
            this.ShowIcon = false;
            this.ShowInTaskbar = false;
            this.StartPosition = System.Windows.Forms.FormStartPosition.CenterParent;
            this.Text = "Partitioned Builds";
            ((System.ComponentModel.ISupportInitialize)(this.buildsGridView)).EndInit();
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.CheckBox enbalePartition_CheckBox;
        private System.Windows.Forms.DataGridView buildsGridView;
        private System.Windows.Forms.Button buttonCancel;
        private System.Windows.Forms.Button buttonOK;
        private System.Windows.Forms.DataGridViewTextBoxColumn column_TeamProject;
        private System.Windows.Forms.DataGridViewTextBoxColumn column_BuildName;
        private System.Windows.Forms.DataGridViewTextBoxColumn column_BuildNumber;
        private System.Windows.Forms.LinkLabel linkHelp;
    }
}