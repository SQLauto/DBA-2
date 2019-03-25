using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Activities;
using System.Data.SqlClient;
using System.IO;
using System.Configuration;
using System.Diagnostics;
using System.Threading;
using System.Xml;
using System.Xml.Linq;
using Microsoft.TeamFoundation.VersionControl;
using Microsoft.TeamFoundation.Build.Client;
using Microsoft.TeamFoundation.Build.Workflow.Activities;
using Microsoft.TeamFoundation.VersionControl.Common;
using Microsoft.TeamFoundation.VersionControl.Client;
using CustomBuildActivities;
using CustomBuildActivities.Exceptions;
using Deployment.Utils;
namespace CustomBuildActivities.Helper
{
    public class UpdateAppSettingHelper
    {
        public UpdateAppSettingHelper() { }
        public void UpdateAppSetting( Workspace ws, string configFile, string configRoot, string oldConfigName, string newConfigName, string configValue, CodeActivityContext context)
        {

            context.TrackBuildMessage("Started to Update Setting "); 
            var oldValue="";
            XmlDocument xmlDoc = new XmlDocument();
            //WE NEED TO CHECK OUT AND CHECK IN THE FILE
            try
            {

                if (configValue.ToString().Length == 0)
                {
                    throw new ActivityException(string.Format("There was an error with configValue: {0}", configValue));
                }
                try
                {
                    ws.Get(new GetRequest(configFile, RecursionType.None, VersionSpec.Latest), GetOptions.Overwrite);
                }
                catch (Exception ex)
                {
                    throw new ActivityException("ws.get", ex);
                }

                try
                {
                    //Checks out files for editing from the version-control repository.
                    ws.PendEdit(configFile);
                }
                catch (Exception ex)
                {
                    throw new ActivityException("ws.pendedit", ex);
                }

                try
                {
                    //Edit the file:
                    
                    xmlDoc.Load(configFile);
                    //get the old value from xml
                    oldValue = DeploymentUtilities.GetAppSetting(configFile, configRoot, newConfigName);
                

                    //set this value to oldCongfig element's value.
                    XmlNode lastNode = xmlDoc.SelectSingleNode(string.Format(@"/{0}/{1}", configRoot, newConfigName));
                    oldValue=lastNode.InnerText;
                    context.TrackBuildMessage(string.Format("This function will change configfile {0}, picking up last build number {1} to oldConfiName {2}, and replacing newConfigName {3} with configValue {4}: ",
                    configFile, oldValue, oldConfigName, newConfigName, configValue.ToString())); 
                
                    if (oldValue.ToString().Length == 0)
                    {
                        throw new ActivityException(string.Format("There was an error with oldValue: {0}", oldValue));
                    }
                    
                    //set the ConfigValue to newConfig element's value.
                    XmlNode previousNode = xmlDoc.SelectSingleNode(string.Format(@"/{0}/{1}", configRoot, oldConfigName));
                    previousNode.InnerText = oldValue;
                    lastNode.InnerText = configValue;
                    ws.PendEdit(configFile);
                    xmlDoc.Save(configFile);
                    context.TrackBuildMessage("xmldoc save finished", BuildMessageImportance.High);

                    var pendingChanges = ws.GetPendingChanges();
                    var pendingChange = pendingChanges.Where(x => x.LocalItem.ToString() == configFile);

                    var listSingle= "";
                    var listAll = "";
                    var listServerAll = "";
                    foreach (var pend in pendingChanges)
                    {
                        listAll += " : " + pend.LocalItem.ToString();
                        listServerAll += " : " + pend.ServerItem.ToString();

                    }
                    foreach (var pend in pendingChange)
                    {
                        listSingle += " : " + pend.LocalItem.ToString();

                    }
                    
                    context.TrackBuildMessage("pending changes: " + listAll, BuildMessageImportance.High);
                    context.TrackBuildMessage("pending server changes: " + listServerAll , BuildMessageImportance.High);
                    context.TrackBuildMessage("pending single change: " + listSingle, BuildMessageImportance.High);
                    

                    if (pendingChanges.Length <= 0 || (pendingChange.Equals(null)))
                    {
                        throw new ActivityException("ws.pending changes:" + pendingChanges.ToString() + "::" + listAll);
                    }

                    else
                    {
                        try
                        {
                            // Finally check-in, don't trigger a Continuous Integration build and override gated check-in.
                            var scSrv = ws.VersionControlServer;
                            var wip = new WorkspaceCheckInParameters(pendingChanges, "***NO_CI***")
                            {
                                OverrideGatedCheckIn = ((CheckInOptions2)scSrv.SupportedFeatures & CheckInOptions2.OverrideGatedCheckIn) == CheckInOptions2.OverrideGatedCheckIn,
                                PolicyOverride = new PolicyOverrideInfo("Check-in from IterationManager.", null)
                            };
                            ws.CheckIn(wip);
                            context.TrackBuildMessage("Check in finished");
                        }
                        catch (Exception ex)
                        {
                            throw new ActivityException("ws.CheckIn", ex);
                        }
                    }
                }
                catch (Exception ex)
                {
                    throw new ActivityException("ws.general", ex);
                }

            }
            catch (Exception ex)
            {
                throw new ActivityException("Deployment util exception", ex);
            }
        }
    }
}
