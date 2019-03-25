using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

using System.ComponentModel;
using Microsoft.TeamFoundation.Build;
using System.Drawing.Design;

namespace CustomBuildActivities
{
    [Serializable]//, Editor("Microsoft.TeamFoundation.Build.Controls.TestSpecEditor, Microsoft.TeamFoundation.Build.Controls", typeof(UITypeEditor))]
    public class Rig
    {
        [Browsable(true), RefreshProperties(System.ComponentModel.RefreshProperties.All)]
        public string Name { get; set; }
        [Browsable(true), RefreshProperties(System.ComponentModel.RefreshProperties.All)]
        public List<Box> Boxes { get; set; }
        [Browsable(true), RefreshProperties(System.ComponentModel.RefreshProperties.All), EditorBrowsable()]
        public bool Available { get; set; }
        public Rig()
        {
            Boxes = new List<Box>();
        }
        public override string ToString()
        {
            return string.Format("{0} ({1} machines)", Name, Boxes.Count);
        }
    }
}
