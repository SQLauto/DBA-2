namespace DeploymentTool
{
    public struct DeploymentTaskResult
    {
        public DeploymentTaskResult(bool valid)
        {
            Valid = valid;
            Message = null;
        }

        public DeploymentTaskResult(bool valid, string message)
        {
            Valid = valid;
            Message = message;
        }

        public bool Valid { get; private set; }

        public string Message { get; private set; }

        public static DeploymentTaskResult True
        {
            get { return new DeploymentTaskResult(true, null); }
        }

        public static DeploymentTaskResult False
        {
            get { return new DeploymentTaskResult(false); }
        }
    }
}