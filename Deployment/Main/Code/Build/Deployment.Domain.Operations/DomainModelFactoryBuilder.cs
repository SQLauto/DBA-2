using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using Deployment.Common;

namespace Deployment.Domain.Operations
{
    public class DomainModelFactoryBuilder : IDomainModelFactoryBuilder
    {
        private readonly IList<IDomainModelFactory> _factories;

        public DomainModelFactoryBuilder()
        {
            _factories = new List<IDomainModelFactory>();
        }

        public IDomainModelFactory[] GetFactories(string defaultConfig)
        {
            if (!_factories.IsNullOrEmpty())
                return _factories.ToArray();

            var assembly = Assembly.GetExecutingAssembly();

            var types = GetDomainModelFactoryTypes(assembly);

            types.ForEach(t =>
            {
                var instance =
                    assembly.CreateInstance(t.FullName, false, BindingFlags.Default, null, new object[] { defaultConfig },
                        null, null) as IDomainModelFactory;
                _factories.Add(instance);
            });

            return _factories.ToArray();
        }

        private IList<Type> GetDomainModelFactoryTypes(Assembly asm)
        {
            var type = typeof(IDomainModelFactory);

            return asm.GetLoadableTypes().Where(t=> type.IsAssignableFrom(t) && !t.IsAbstract && t.IsClass).ToList();
        }
    }
}