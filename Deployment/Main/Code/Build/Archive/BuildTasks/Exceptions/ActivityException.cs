using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Runtime.Serialization;

namespace CustomBuildActivities.Exceptions
{
    
   [Serializable()]
   public class ActivityException : Exception
   {
      public ActivityException()
      {
         // Add any type-specific logic, and supply the default message.
      }

      public ActivityException(string message): base(message) 
      {
         // Add any type-specific logic.
      }
      public ActivityException(string message, Exception innerException): 
         base (message, innerException)
      {
         // Add any type-specific logic for inner exceptions.
      }
      protected ActivityException(SerializationInfo info, 
         StreamingContext context) : base(info, context)
      {
         // Implement type-specific serialization constructor logic.
      }
   }  

}
