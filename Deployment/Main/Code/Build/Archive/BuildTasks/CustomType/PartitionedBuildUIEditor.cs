using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Drawing.Design;
using System.Windows.Forms.Design;
using System.ComponentModel;
using System.Windows.Forms;

namespace CustomBuildActivities.CustomType
{
    /// <summary>
    /// Control what happens when uses tries to edit the partiotned build settings in the build defintion editor
    /// </summary>
    public class PartitionedBuildUIEditor : UITypeEditor
    {
        public override object EditValue(ITypeDescriptorContext context, IServiceProvider provider, object value)
        {
            try
            {
                if (provider != null)
                {
                    IWindowsFormsEditorService editorService = (IWindowsFormsEditorService)provider.GetService(typeof(IWindowsFormsEditorService));

                    if (editorService != null)
                    {
                        PartitionedBuildSettings partitionedBuildSettings = value as PartitionedBuildSettings;

                        using (PartitionedBuildDialog dialog = new PartitionedBuildDialog(partitionedBuildSettings))
                        {
                            if (editorService.ShowDialog(dialog) == DialogResult.OK)
                            {
                                // New the return value, try to make the build show as edited (make sure it is a deep clone)
                                partitionedBuildSettings = new PartitionedBuildSettings(dialog.Settings); //deep copy                               
                                value = partitionedBuildSettings;
                            }
                        }
                    }
                }

                return value;
            }
            catch (Exception ex)
            {
                MessageBox.Show(string.Format("Unable to edit partitioned builds: {0}", ex));
                return null;
            }
        }

        public override UITypeEditorEditStyle GetEditStyle(ITypeDescriptorContext context)
        {
            return UITypeEditorEditStyle.Modal;
        }
    }
}
