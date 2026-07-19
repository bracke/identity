with Identity.Adapters.Repositories.Stores;
with Identity.Identifiers.Entities;
with Identity.Operations.Contexts;
with Identity.Results;
with Identity.Secrets.Passwords;
with Identity.Times;
with Identity.Versions;

package Identity.Operations.Passwords.Change is
   type Change_Request is record
      Principal                : Identity.Identifiers.Entities.Principal_Id;
      New_Credential           : Identity.Identifiers.Entities.Credential_Id;
      Expected_Current_Version : Identity.Versions.Entity_Version;
      Current                  : Identity.Secrets.Passwords.Presented_Password;
      Replacement              : Identity.Secrets.Passwords.New_Password;
   end record;

   function Execute
     (Repository     : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Principal      : Identity.Identifiers.Entities.Principal_Id;
      New_Credential : Identity.Identifiers.Entities.Credential_Id;
      Current        : Identity.Secrets.Passwords.Presented_Password;
      Replacement    : Identity.Secrets.Passwords.New_Password)
      return Identity.Results.Operation_Status;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Change_Request)
      return Identity.Results.Operation_Status;

   --  Audited form. Emits identity.password.changed for the transition, and
   --  refuses the operation if the store cannot accept that event, so a
   --  password is never replaced without its audit record. A rejected
   --  current-password check is audited as a rejection, not as a store
   --  conflict.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : Change_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Results.Operation_Status;
end Identity.Operations.Passwords.Change;
