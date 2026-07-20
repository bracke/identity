with Identity.Adapters.Repositories.Stores;
with Identity.Identifiers.Entities;
with Identity.Operations.Contexts;
with Identity.Operations.Idempotency;
with Identity.Operations.Replay;
with Identity.Secrets.Tokens;
with Identity.Times;
with Identity.Tokens.Definitions;

package Identity.Operations.Passwords.Request_Reset is
   type Reset_Request is record
      Id         : Identity.Identifiers.Entities.Token_Id;
      Principal  : Identity.Identifiers.Entities.Principal_Id;
      Secret     : Identity.Secrets.Tokens.Reset_Token_Secret;
      Issued_At  : Identity.Times.Instant := 0;
      Expires_At : Identity.Times.Expiration;
   end record;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Token      : Identity.Tokens.Definitions.Action_Token_Record)
      return Identity.Adapters.Repositories.Stores.Command_Status;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Reset_Request)
      return Identity.Adapters.Repositories.Stores.Command_Status;

   --  Audited form. Emits identity.password.reset.requested for the issued
   --  token, and refuses the operation if the store cannot accept that event,
   --  so a reset token is never issued without its audit record.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : Reset_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status;

   --  Idempotent form. A reset request arrives from outside -- a form, a
   --  support call -- and a client that never saw the answer will send it
   --  again. Reserving the key before the transition means the retry reports
   --  the recorded outcome instead of minting a second live reset token for
   --  the same principal.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : Reset_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant;
      Key         : Identity.Operations.Idempotency.Idempotency_Key)
      return Identity.Operations.Replay.Command_Outcome;
end Identity.Operations.Passwords.Request_Reset;
