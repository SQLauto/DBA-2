using System.Drawing.Design;
using System.Windows.Forms.Design;
using System.ComponentModel;
using System;
using System.Windows.Forms;

namespace LabManager
{

    public class DetailsEditor : UITypeEditor
    {

        public override object EditValue(ITypeDescriptorContext context, IServiceProvider provider, object value)
        {
            if (provider != null)
            {
                IWindowsFormsEditorService editorService = (IWindowsFormsEditorService)provider.GetService(typeof(IWindowsFormsEditorService));

                if (editorService != null)
                {
                    Details details = value as Details;

                    using (DetailsDialog dialog = new DetailsDialog())
                    {
                        dialog.Details = details;

                        if (editorService.ShowDialog(dialog) == DialogResult.OK)
                        {
                            details = dialog.Details;
                        }
                    }
                }

            }

            return value;

        }

        public override UITypeEditorEditStyle GetEditStyle(ITypeDescriptorContext context)
        {
            return UITypeEditorEditStyle.Modal;
        }
    }
}
