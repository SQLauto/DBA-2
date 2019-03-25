using System;
using System.Collections.Generic;
using System.Linq;
using System.Reflection;
using Deployment.Common.Logging;
using Deployment.Domain.Roles;

namespace Deployment.Domain.Operations
{
    public class DomainOperatorFactory : IDomainOperatorFactory
    {
        private readonly IDictionary<Type, Type> _operatorTypes;
        private readonly IParameterService _parameterService;
        private readonly IDeploymentLogger _logger;

        public DomainOperatorFactory(IParameterService parameterService, IDeploymentLogger logger)
        {
            _logger = logger;
            _parameterService = parameterService;
            _operatorTypes = GetAllTypesImplementingOpenGenericType(Assembly.GetExecutingAssembly());
        }

        public IDeploymentOperator<T> GetOperator<T>() where T : IBaseRole
        {
            if (!_operatorTypes.ContainsKey(typeof(T)))
                return null;

            var type = _operatorTypes[typeof(T)];

            return (IDeploymentOperator<T>) Activator.CreateInstance(type, _parameterService, _logger);
        }

        private IDictionary<Type, Type> GetAllTypesImplementingOpenGenericType(Assembly assembly)
        {
            var openGenericType = typeof(IDeploymentOperator<>);

            var types = from x in assembly.GetTypes()
                from z in x.GetInterfaces()
                let y = x.BaseType
                where
                (y != null && y.IsGenericType &&
                 openGenericType.IsAssignableFrom(y.GetGenericTypeDefinition())) ||
                (z.IsGenericType &&
                 openGenericType.IsAssignableFrom(z.GetGenericTypeDefinition()))
                select x;

            var dictionary = types.ToDictionary(x => x.GetInterfaces().First().GenericTypeArguments.First());

            return dictionary;

        }
    }
}