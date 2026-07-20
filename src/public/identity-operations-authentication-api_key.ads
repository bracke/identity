with Identity.Adapters.Repositories.Stores;
with Identity.Authentication.Results;
with Identity.Identifiers.Entities;
with Identity.Operations.Contexts;
with Identity.Secrets.API_Keys;
with Identity.Text.Bounded;
with Identity.Times;
with Identity.Versions;

package Identity.Operations.Authentication.API_Key is
   type Staged_Authentication_Request is record
      Public_Key_Id               : Identity.Text.Bounded.Bounded_Text;
      Secret                      : Identity.Secrets.API_Keys.API_Key_Secret;
      Now                         : Identity.Times.Instant;
      Expected_Credential_Version : Identity.Versions.Entity_Version;
   end record;

   --  Forwards to Identity.Operations.API_Keys.Authenticate, which records the
   --  attempt, so the audit context is carried through rather than dropped.
   function Execute
     (Repository    : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Public_Key_Id : Identity.Text.Bounded.Bounded_Text;
      Secret        : Identity.Secrets.API_Keys.API_Key_Secret;
      Now           : Identity.Times.Instant;
      Context       : Identity.Operations.Contexts.Operation_Context;
      Event         : Identity.Identifiers.Entities.Event_Id;
      Recorded_At   : Identity.Times.Instant)
      return Identity.Authentication.Results.Password_Authentication_Result;

   function Execute
     (Repository  : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : Staged_Authentication_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Authentication.Results.Password_Authentication_Result;
end Identity.Operations.Authentication.API_Key;
