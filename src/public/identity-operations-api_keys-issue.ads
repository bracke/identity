with Identity.Adapters.Repositories.Stores;
with Identity.API_Keys.Credentials;
with Identity.Identifiers.Entities;
with Identity.Identifiers.Registry;
with Identity.Operations.Contexts;
with Identity.Operations.Idempotency;
with Identity.Operations.Replay;
with Identity.Secrets.API_Keys;
with Identity.Text.Bounded;
with Identity.Times;
with Identity.Versions;

package Identity.Operations.API_Keys.Issue is
   type Issue_Request is record
      Id                  : Identity.Identifiers.Entities.Credential_Id;
      Principal           : Identity.Identifiers.Entities.Principal_Id;
      Public_Key_Id       : Identity.Text.Bounded.Bounded_Text;
      Credential_Class_Id : Identity.Identifiers.Registry.Registry_Id;
      Secret              : Identity.Secrets.API_Keys.API_Key_Secret;
      Created_At          : Identity.Times.Instant := 0;
      Expires_At          : Identity.Times.Expiration;
      Rotation_Generation : Identity.Versions.Rotation_Generation := 0;
   end record;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Credential : Identity.API_Keys.Credentials.API_Key_Credential_Record)
      return Identity.Adapters.Repositories.Stores.Command_Status;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Issue_Request)
      return Identity.Adapters.Repositories.Stores.Command_Status;

   --  Audited form. Emits identity.api-key.issued for the issuance, and
   --  refuses the operation if the store cannot accept that event, so a key
   --  that can authenticate never exists without a record of its issue.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : Issue_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status;

   --  Idempotent form. Issuance is triggered from outside and hands back a
   --  credential that authenticates, so a retried request that issued a second
   --  key would leave a usable credential nobody expects to exist. Reserving
   --  the key first makes the retry report the recorded outcome instead.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : Issue_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant;
      Key         : Identity.Operations.Idempotency.Idempotency_Key)
      return Identity.Operations.Replay.Command_Outcome;

   --  Audited form of the shape above. Same event, same subject and
   --  target, same refusal rule as the audited request form.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Credential  : Identity.API_Keys.Credentials.API_Key_Credential_Record;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status;
end Identity.Operations.API_Keys.Issue;
