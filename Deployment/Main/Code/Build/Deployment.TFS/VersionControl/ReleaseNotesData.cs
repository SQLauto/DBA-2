using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Xml.Serialization;

using Deployment.TFS.WorkItems;

namespace Deployment.TFS.VersionControl
{
    /// <summary>
    /// Class to control the output of the release notes xml
    /// </summary>
    [XmlRoot("ReleaseNotes")]
    public class ReleaseNotesData
    {
        [XmlAttribute("StartLabel")]
        public string StartLabel { get; set; }

        [XmlAttribute("EndLabel")]
        public string EndLabel { get; set; }

        [XmlArray("Changesets")]
        [XmlArrayItem("Changeset")]
        public List<MergedChangeset> ChangeSets { get; set; }

        [XmlArray("WorkItems")]
        [XmlArrayItem("WorkItem")]
        public List<TFLWorkItem> WorkItems { get; set; }
    }


}
