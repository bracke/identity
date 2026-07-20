with Identity.Adapters.Repositories.Stores;
with Identity.Contacts.Bindings;
with Identity.Identifiers.Entities;
with Identity.Operations.Contexts;
with Identity.Operations.Idempotency;
with Identity.Operations.Replay;
with Identity.Secrets.Tokens;
with Identity.Times;
with Identity.Tokens.Definitions;

package Identity.Operations.Verification.Request is
   type Verification_Token_Request is record
      Id         : Identity.Identifiers.Entities.Token_Id;
      Principal  : Identity.Identifiers.Entities.Principal_Id;
      Secret     : Identity.Secrets.Tokens.Verification_Token_Secret;
      Issued_At  : Identity.Times.Instant := 0;
      Expires_At : Identity.Times.Expiration;
   end record;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Contact    : Identity.Contacts.Bindings.Contact_Binding_Record;
      Token      : Identity.Tokens.Definitions.Action_Token_Record)
      return Identity.Adapters.Repositories.Stores.Command_Status;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Contact    : Identity.Contacts.Bindings.Contact_Binding_Record;
      Request    : Verification_Token_Request)
      return Identity.Adapters.Repositories.Stores.Command_Status;

   --  Audited form. Emits identity.contact.verification.requested for the
   --  transition, and refuses the operation if the store cannot accept that
   --  event, so a verification token is never sent out unrecorded.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Contact     : Identity.Contacts.Bindings.Contact_Binding_Record;
      Request     : Verification_Token_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status;

   --  Idempotent form. "Resend the verification message" is the retry users
   --  press hardest. Reserving the key before the transition keeps a retry
   --  from issuing a second live verification token, which would otherwise
   --  leave two valid secrets outstanding for one contact.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Contact     : Identity.Contacts.Bindings.Contact_Binding_Record;
      Request     : Verification_Token_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant;
      Key         : Identity.Operations.Idempotency.Idempotency_Key)
      return Identity.Operations.Replay.Command_Outcome;

   --  Audited form taking the token record directly, for callers that have
   --  already built it.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Contact     : Identity.Contacts.Bindings.Contact_Binding_Record;
      Token       : Identity.Tokens.Definitions.Action_Token_Record;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status;
end Identity.Operations.Verification.Request;
