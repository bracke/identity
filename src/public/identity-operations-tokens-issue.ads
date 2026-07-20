with Identity.Adapters.Repositories.Stores;
with Identity.Identifiers.Entities;
with Identity.Identifiers.Registry;
with Identity.Operations.Contexts;
with Identity.Secrets.Bytes;
with Identity.Times;
with Identity.Tokens.Definitions;
with Identity.Versions;

package Identity.Operations.Tokens.Issue is
   type Issue_Request is record
      Id              : Identity.Identifiers.Entities.Token_Id;
      Purpose         : Identity.Identifiers.Registry.Registry_Id;
      Principal       : Identity.Identifiers.Entities.Principal_Id;
      Verifier_Domain : Identity.Identifiers.Registry.Registry_Id;
      Secret          : Identity.Secrets.Bytes.Secret_Bytes;
      Issued_At       : Identity.Times.Instant := 0;
      Expires_At      : Identity.Times.Expiration;
      Attempts        : Identity.Versions.Attempt_Count := 0;
   end record;

   --  Audited form. Emits identity.token.issued for the transition, and
   --  refuses the operation if the store cannot accept that event, so a token
   --  that can act on an account never exists without its audit record.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : Issue_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status;

   --  Audited form taking the token record directly, for callers that have
   --  already built it.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Token       : Identity.Tokens.Definitions.Action_Token_Record;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status;
end Identity.Operations.Tokens.Issue;
