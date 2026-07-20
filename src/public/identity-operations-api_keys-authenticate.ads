with Identity.Adapters.Repositories.Stores;
with Identity.Authentication.Results;
with Identity.Identifiers.Entities;
with Identity.Operations.Contexts;
with Identity.Secrets.API_Keys;
with Identity.Text.Bounded;
with Identity.Times;
with Identity.Versions;

package Identity.Operations.API_Keys.Authenticate is
   type Staged_Authentication_Request is record
      Public_Key_Id               : Identity.Text.Bounded.Bounded_Text;
      Secret                      : Identity.Secrets.API_Keys.API_Key_Secret;
      Now                         : Identity.Times.Instant;
      Expected_Credential_Version : Identity.Versions.Entity_Version;
   end record;

   --  Audited form. Emits identity.api-key.authenticated for the attempt,
   --  carrying its outcome, and refuses the operation if the store cannot
   --  accept that event, so a key presentation is never handled unaudited.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : Staged_Authentication_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Authentication.Results.Password_Authentication_Result;

   --  Audited form of the shape above. Same event, same subject and
   --  target, same refusal rule as the audited request form.
   function Execute
     (Repository    : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Public_Key_Id : Identity.Text.Bounded.Bounded_Text;
      Secret        : Identity.Secrets.API_Keys.API_Key_Secret;
      Now           : Identity.Times.Instant;
      Context       : Identity.Operations.Contexts.Operation_Context;
      Event         : Identity.Identifiers.Entities.Event_Id;
      Recorded_At   : Identity.Times.Instant)
      return Identity.Authentication.Results.Password_Authentication_Result;
end Identity.Operations.API_Keys.Authenticate;
