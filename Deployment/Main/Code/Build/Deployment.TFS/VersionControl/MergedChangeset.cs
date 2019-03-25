using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Xml.Serialization;

using Microsoft.TeamFoundation.Client;
using Microsoft.TeamFoundation.Framework.Common;
using Microsoft.TeamFoundation.Framework.Client;
using Microsoft.TeamFoundation.VersionControl.Client;

namespace Deployment.TFS.VersionControl
{
    /// <summary>
    /// Encapsulate the concept of a TFS changeset and any merges that created it
    /// </summary>
    public class MergedChangeset
    {
        #region properties

        /// <summary>
        /// The change set
        /// </summary>
        [XmlIgnore]
        public Changeset Changeset { get; set; }

        [XmlElement("ChangesetId")]
        public int ChangesetId
        {
            get 
            {
                return Changeset.ChangesetId;
            }
            set
            {
                throw new NotSupportedException("This setter is only here to support serialisation. Setting the ChangesetId property is not supported");
            }

        }

        [XmlElement("Date")]
        public string Date
        {
            get
            {
                return Changeset.CreationDate.ToShortDateString();
            }
            set
            {
                throw new NotSupportedException("This setter is only here to support serialisation. Setting the Date property is not supported");
            }
        }

        [XmlElement("Committer")]
        public string Committer
        {
            get
            {
                return Changeset.Committer;
            }
            set
            {
                throw new NotSupportedException("This setter is only here to support serialisation. Setting the Committer property is not supported");
            }
        }

        [XmlElement("Comment")]
        public string Comment
        {
            get
            {
                return Changeset.Comment;
            }
            set
            {
                throw new NotSupportedException("This setter is only here to support serialisation. Setting the Comment property is not supported");
            }
        }

        /// <summary>
        /// The merges (if any) this changeset was created from
        /// </summary>
        [XmlArray("Changesets")]
        [XmlArrayItem("Changeset")]
        public List<MergedChangeset> MergedChangesets { get; set; }

        /// <summary>
        /// Does this contain any merges
        /// </summary>
        [XmlIgnore]
        public bool HasMerges
        {
            get
            {
                return MergedChangesets != null && MergedChangesets.Count > 0;
            }
        } 

        #endregion

        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="cs"></param>
        public MergedChangeset()
        {
            Changeset = null;
            MergedChangesets = new List<MergedChangeset>();
        }

        /// <summary>
        /// Constructor
        public MergedChangeset(Changeset cs)
        {
            Changeset = cs;
            MergedChangesets = new List<MergedChangeset>();
        }

        /// <summary>
        /// Recursivley get all the change sets in this tree
        /// </summary>
        /// <returns></returns>
        public List<Changeset> GetAllChangeSets()
        {
            List<Changeset> allChangeSets = new List<Changeset>();
            if(!allChangeSets.Any(cs => cs.ChangesetId == Changeset.ChangesetId))
                allChangeSets.Add(Changeset);

            if (HasMerges)
            {
                foreach (MergedChangeset mcs in this.MergedChangesets)
                {
                    allChangeSets.AddRange(mcs.GetAllChangeSets());
                }
            }

            return allChangeSets;
        }

    }
}
