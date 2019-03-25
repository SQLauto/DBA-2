using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Deployment.Entities;
using System.Net;

namespace Deployment.Logic.Entities
{
    public class DeploymentServerHelper
    {
        public static List<string> GetServersFromString(string servers)
        {
            List<string> result = new List<string>();
            if (!string.IsNullOrWhiteSpace(servers))
            {
                string[] serversAsArray = servers.Split(",".ToCharArray());
                result = (from s in serversAsArray select s.Trim()).ToList();
            }

            return result;
        }

        public static bool IsMachineBeingDeployedTo(Machine machine, List<string> servers)
        {
            List<string> includedServers;
            List<string> excludedServers;

            if (servers == null || servers.Count == 0)
            {
                return true;
            }
            if (servers.Contains("!"))
            {
                return false;
            }

            SplitServersIntoGroups(servers, out includedServers, out excludedServers);
            bool isIncluded = IsIncluded(machine, includedServers);
            bool isExcluded = IsExcluded(machine, excludedServers);


            if (isIncluded && !isExcluded)
            {
                return true;
            }

            if (!isIncluded && isExcluded)
            {
                return false;
            }

            if (isIncluded && isExcluded)
            {
                return false;
            }

            if (!isIncluded && !isExcluded && includedServers.Count > 0)
            {
                return false;
            }

            if (!isIncluded && !isExcluded && excludedServers.Count > 0)
            {
                return true;
            }

            if (!isIncluded && !isExcluded && includedServers.Count > 0 && excludedServers.Count > 0)
            {
                return false;
            }
            //none of these matched
            return false;
        }

        private static void SplitServersIntoGroups(List<string> servers, out List<string> includedServers, out List<string> excludedServers)
        {
            includedServers = new List<string>();
            excludedServers = new List<string>();

            foreach (string server in servers)
            {
                if (server.StartsWith("!"))
                {
                    excludedServers.Add(server.TrimStart('!'));
                }
                else
                {
                    includedServers.Add(server);
                }
            }
        }

        private static bool IsIncluded(Machine machine, List<string> inclusionList)
        {
            bool includedServerWithName = inclusionList.Contains(machine.Name, StringComparer.InvariantCultureIgnoreCase);
            bool includedServerWithIP = inclusionList.Contains(machine.ExternalIP);

            if (includedServerWithName || includedServerWithIP)
            {
                return true;
            }
            return false;
        }

        private static bool IsExcluded(Machine machine, List<string> exclusionList)
        {
            bool excludedServerWithName = exclusionList.Contains(machine.Name, StringComparer.InvariantCultureIgnoreCase);
            bool excludedServerWithIP = exclusionList.Contains(machine.ExternalIP);

            if (excludedServerWithName || excludedServerWithIP)
            {
                return true;
            }
            return false;
        }
    }
}