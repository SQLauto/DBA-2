namespace Deployment.Database
{
    internal class PatchLevel
    {
         public bool IsAtThisPatchLevel { get; private set; }
         public int CountOfRows { get; private set; }

        public PatchLevel(int countOfRows, bool isAtThisPatchLevel)
        {
            IsAtThisPatchLevel = isAtThisPatchLevel;
            CountOfRows = countOfRows;
        }
    }
}