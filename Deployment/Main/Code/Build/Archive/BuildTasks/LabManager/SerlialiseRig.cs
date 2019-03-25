using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Activities;
using System.Net;
using System.IO;
using System.Xml.Serialization;
using CustomBuildActivities.LabManagerService;
using Microsoft.TeamFoundation.Build.Client;
using Microsoft.TeamFoundation.Build.Workflow.Activities;
using System.ServiceModel;

namespace LabManager
{
    [BuildActivity(HostEnvironmentOption.All)]
    public sealed class SerialiseRig : CodeActivity<Boolean>
    {
        // Define the activity arguments
        public InArgument<CustomBuildActivities.Rig> RigToSerialise { get; set; }
        public InArgument<string> OutputFilename { get; set; }
        
        protected override Boolean Execute(CodeActivityContext context)
        {

            try
            {

                CustomBuildActivities.Rig rigToSerialise = context.GetValue(this.RigToSerialise);
                string outputFilename = context.GetValue(this.OutputFilename);

                FileStream fs = new FileStream(outputFilename, FileMode.OpenOrCreate);
                XmlSerializer xs = new XmlSerializer(typeof(CustomBuildActivities.Rig));
                xs.Serialize(fs, rigToSerialise);
                fs.Close();                
            }
            catch (Exception ex)
            {
                context.TrackBuildError(ex.Message);
                return false;
            }

            return true;
        }


    }
}