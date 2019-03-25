namespace Deployment.Domain.Operations
{
    public interface IDomainModelFactoryBuilder
    {
        IDomainModelFactory[] GetFactories(string defaultConfig);
        //IDomainModelFactory GetFactory(string defaultConfig);
    }
}