using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Xml.Serialization;

using Microsoft.TeamFoundation.VersionControl.Client;
using Microsoft.TeamFoundation.WorkItemTracking.Client;

namespace Deployment.TFS.WorkItems
{
    public class TFLWorkItem
    {
        public TFLWorkItem()
        {

        }

        public TFLWorkItem(WorkItem _workItem)
        {
            workItem = _workItem;
        }

        private WorkItem workItem;

        [XmlElement("WorkItemId")]
        public int WorkItemId
        {
            get
            {
                return workItem.Id;
            }
            set
            {
                throw new NotSupportedException("This setter is only here to support serialisation. Setting the WorkItemId property is not supported");
            }
        }

        [XmlElement("Title")]
        public string Title
        {
            get
            {
                return workItem.Title;
            }
            set
            {
                throw new NotSupportedException("This setter is only here to support serialisation. Setting the Title property is not supported");
            }
        }

        [XmlElement("State")]
        public string State
        {
            get
            {
                return workItem.State;
            }
            set
            {
                throw new NotSupportedException("This setter is only here to support serialisation. Setting the State property is not supported");
            }
        }
    }
}
