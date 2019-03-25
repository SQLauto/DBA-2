using System;
using System.Collections.Generic;
using System.IO;
using Deployment.Common;
using Deployment.Common.Exceptions;
using Deployment.Common.Logging;
using Deployment.Common.Xml;
using Deployment.Schemas;

namespace Deployment.Domain.Operations
{
    public class DomainModelValidator : IDomainModelValidator
    {
        private readonly ValidationResult _validationResult;
        private readonly IDeploymentLogger _logger;

        public DomainModelValidator(IDeploymentLogger logger = null) : this(new ValidationResult(), logger)
        {

        }

        public DomainModelValidator(ValidationResult validationResult, IDeploymentLogger logger = null)
        {
            _validationResult = validationResult;
            _logger = logger;
        }

        public bool ValidateCommonIncludes()
        {
            if (_validationResult.Result)
                return true;

            var exception =
                new ValidationException(_validationResult.ErrorString("Error validating Common Includes:"));

            exception.ValidationErrors.AddRange(_validationResult.ValidationErrors);

            throw exception;
        }

        public bool ValidateDeploymentFileParser()
        {
            if (_validationResult.Result)
                return true;

            var exception =
                new ValidationException(_validationResult.ErrorString("Error validating DeploymentFileParser:"));

            exception.ValidationErrors.AddRange(_validationResult.ValidationErrors);

            _logger?.WriteWarn("Failed to validate deployment file.");

            throw exception;
        }

        public bool ValidateMachineCreation(IList<Machine> machines)
        {
            machines.GetDuplicates(m => m.Id).ForEach(m =>
              {
                  _logger?.WriteError($"Machine [{m.Name}] has duplicate Id [{m.Id}] in config. This is not permitted.");
                  _validationResult.AddError($"Machine [{m.Name}] has duplicate Id [{m.Id}] in config. This is not permitted.");
              });

            machines.GetDuplicates(m => m.DeploymentAddress).ForEach(m =>
            {
                _logger?.WriteError($"Duplicate machine DeploymentAddress [{m.DeploymentAddress}] in config. This is not permitted.");
                _validationResult.AddError($"Duplicate machine DeploymentAddress [{m.DeploymentAddress}] in config. This is not permitted.");
            });

            //machines.GetDuplicates(m => m.DeploymentMachine).ForEach(m =>
            //{
            //    _logger?.WriteError($"Duplicate deployment machine [{m.Name}] in config. This is not permitted.");
            //    _validationResult.AddError($"Duplicate deployment machine [{m.Name}] in config. This is not permitted.");
            //});

            if (machines.CountGreaterThan(m => m.DeploymentMachine, 1))
            {
                _logger?.WriteError("More than one deployment machine has been defined in the config.");
                _validationResult.AddError("More than one deployment machine has been defined in the config.");
            }

            if (_validationResult.Result)
                return true;

            var exception =
                new ValidationException(_validationResult.ErrorString("Error validating Machine configurations:"));

            exception.ValidationErrors.AddRange(_validationResult.ValidationErrors);

            throw exception;
        }

        public bool ValidateDomainModelFile(string domainModelFile)
        {
            _logger?.WriteLine($"Beginning validation of config file {domainModelFile}");

            try
            {
                if (string.IsNullOrWhiteSpace(domainModelFile))
                    throw new ArgumentNullException(nameof(domainModelFile));

                if(!File.Exists(domainModelFile))
                    throw new FileNotFoundException($"File {domainModelFile} cannot be found.");

                var schemaSet = SchemaHelper.GetDeploymentSchemas();
                var result = XmlHelper.ValidateXml(schemaSet, domainModelFile);

                if (result.Item1)
                    return true;

                _validationResult.AddErrors(result.Item2);
            }
            catch (Exception ex)
            {
                _logger?.WriteError(ex);
                _validationResult.AddException(ex);
            }

            if (_validationResult.Result)
                return true;

            var rootString =
                $"There was an error validating the deployment config: [{domainModelFile ?? "config not defined"}]";

            var errorMessage = ValidationResult.ErrorString(rootString);

            var exception = new ValidationException(errorMessage);
            exception.ValidationErrors.AddRange(ValidationResult.ValidationErrors);
            throw exception;
        }

        public ValidationResult ValidationResult => _validationResult;
    }
}