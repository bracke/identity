with Identity.Errors;

package body Identity.Adapters.Repositories.Contexts is
   function Opened
     (Capabilities : Identity.Adapters.Repositories.Capabilities.Repository_Capabilities)
      return Repository_Context is
     ((State => Identity.Adapters.Repositories.Opened,
       Mode => Identity.Adapters.Repositories.Read_Only,
       Capabilities => Capabilities,
       Failure =>
         (Code => Identity.Adapters.Repositories.Failures.No_Failure,
          Error =>
            (Category => Identity.Errors.Success,
             Retry => Identity.Errors.Do_Not_Retry,
             Cause => Identity.Errors.Caller_Input,
             Operation_Set => False,
             Correlation_Set => False))));
end Identity.Adapters.Repositories.Contexts;
