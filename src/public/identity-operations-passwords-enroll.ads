with Identity.Adapters.Repositories.Stores;
with Identity.Identifiers.Entities;
with Identity.Operations.Contexts;
with Identity.Secrets.Passwords;
with Identity.Times;

package Identity.Operations.Passwords.Enroll is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Principal  : Identity.Identifiers.Entities.Principal_Id;
      Credential : Identity.Identifiers.Entities.Credential_Id;
      Password   : Identity.Secrets.Passwords.New_Password)
      return Identity.Adapters.Repositories.Stores.Command_Status;

   --  Audited form. Emits identity.password.enrolled for the transition, and
   --  refuses the operation if the store cannot accept that event, so a
   --  password credential never appears without its audit record.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Principal   : Identity.Identifiers.Entities.Principal_Id;
      Credential  : Identity.Identifiers.Entities.Credential_Id;
      Password    : Identity.Secrets.Passwords.New_Password;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status;
end Identity.Operations.Passwords.Enroll;
