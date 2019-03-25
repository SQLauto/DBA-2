namespace Deployment.Domain.Parameters
{
    public struct TryGetParam
    {
        public DeploymentParameter DeploymentParameter { get; set; }
        public bool IsFound { get; set; }

        public TryGetParam(DeploymentParameter param, bool isFound)
        {
            DeploymentParameter = param;
            IsFound = isFound;
        }

        public TryGetParam(RawParamValue param, bool isFound)
        {
            DeploymentParameter = new DeploymentParameter(param.ParameterKey, isLookup: param.IsLookup);
            IsFound = isFound;
        }

    }
}
