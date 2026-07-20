with Identity.Adapters.Repositories.Stores;
with Identity.Authentication.Results;
with Identity.External_Providers.Assertions;
with Identity.Identifiers.Entities;
with Identity.Operations.Contexts;
with Identity.Times;
with Identity.Versions;

package Identity.Operations.Authentication.External is
   type Staged_Authentication_Request is record
      Assertion                : Identity.External_Providers.Assertions.Normalized_Assertion;
      Expected_Binding_Version : Identity.Versions.Entity_Version;
   end record;

   --  Audited form. An assertion whose fingerprint is already registered has
   --  been presented before; the store reports that as a conflict, and this
   --  form -- and only that case -- emits
   --  identity.external.assertion.replay-detected. Capacity is reserved
   --  before the fingerprint is registered, so a detected replay can always
   --  be recorded.
   --
   --  The staged form is audited the same way. A conflict there may equally
   --  mean the binding lost its version check, so the fingerprint is checked
   --  before the call: the store registers it before matching any binding, so
   --  a fingerprint that was already present is the only case that is a real
   --  replay.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Assertion   : Identity.External_Providers.Assertions.Normalized_Assertion;
      Now         : Identity.Times.Instant;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Authentication.Results.Password_Authentication_Result;

   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : Staged_Authentication_Request;
      Now         : Identity.Times.Instant;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Authentication.Results.Password_Authentication_Result;
end Identity.Operations.Authentication.External;
