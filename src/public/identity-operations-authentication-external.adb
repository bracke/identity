package body Identity.Operations.Authentication.External is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Assertion  : Identity.External_Providers.Assertions.Normalized_Assertion;
      Now        : Identity.Times.Instant)
      return Identity.Authentication.Results.Password_Authentication_Result is
   begin
      return Identity.Adapters.Repositories.Memory.Authenticate_External
        (Repository, Assertion, Now);
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Request    : Staged_Authentication_Request;
      Now        : Identity.Times.Instant)
      return Identity.Authentication.Results.Password_Authentication_Result is
   begin
      return Identity.Adapters.Repositories.Memory.Authenticate_External
        (Repository,
         Request.Assertion,
         Now,
         Request.Expected_Binding_Version);
   end Execute;
end Identity.Operations.Authentication.External;
