with Identity.Adapters.Repositories.Stores;
with Identity.Authentication.Results;
with Identity.External_Providers.Assertions;
with Identity.Times;
with Identity.Versions;

package Identity.Operations.Authentication.External is
   type Staged_Authentication_Request is record
      Assertion                : Identity.External_Providers.Assertions.Normalized_Assertion;
      Expected_Binding_Version : Identity.Versions.Entity_Version;
   end record;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Assertion  : Identity.External_Providers.Assertions.Normalized_Assertion;
      Now        : Identity.Times.Instant)
      return Identity.Authentication.Results.Password_Authentication_Result;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Staged_Authentication_Request;
      Now        : Identity.Times.Instant)
      return Identity.Authentication.Results.Password_Authentication_Result;
end Identity.Operations.Authentication.External;
