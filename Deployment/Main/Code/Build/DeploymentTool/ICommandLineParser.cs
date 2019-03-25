using System;
using System.Collections.Generic;
using Deployment.Domain.Operations;

namespace Deployment.Tool
{
    public interface ICommandLineParser
    {
        string GetHelp();
        DeploymentOperationParameters Parse(IList<string> args);
    }
}