with Identity.Adapters.Repositories.Idempotency;
with Identity.Crypto.Domains;
with Identity.Crypto.Secret_Verifiers;
with Identity.Events.Types;
with Identity.Operations.Audit;
with Identity.Text.Bounded;
with Identity.Tokens.Purposes;

package body Identity.Operations.Verification.Request is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Contact    : Identity.Contacts.Bindings.Contact_Binding_Record;
      Token      : Identity.Tokens.Definitions.Action_Token_Record)
      return Identity.Adapters.Repositories.Stores.Command_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Request_Contact_Verification
        (Repository, Contact, Token);
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Contact    : Identity.Contacts.Bindings.Contact_Binding_Record;
      Request    : Verification_Token_Request)
      return Identity.Adapters.Repositories.Stores.Command_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Request_Contact_Verification
        (Repository,
         Contact,
         (Id              => Request.Id,
          Purpose         => Identity.Tokens.Purposes.Contact_Verification,
          Principal       => Request.Principal,
          Secret_Verifier => Identity.Crypto.Secret_Verifiers.Derive_Text
            (Identity.Crypto.Domains.Contact_Verification_Token, Request.Secret),
          Issued_At       => Request.Issued_At,
          Expires_At      => Request.Expires_At,
          State           => Identity.Tokens.Definitions.Issued,
          Attempts        => 0,
          Version         => 0));
   end Execute;

   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Contact     : Identity.Contacts.Bindings.Contact_Binding_Record;
      Request     : Verification_Token_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status
   is
      use type Identity.Adapters.Repositories.Stores.Command_Status;
      Status : Identity.Adapters.Repositories.Stores.Command_Status;
   begin
      --  Reserve first: refusing here leaves the store untouched, whereas a
      --  full event log discovered afterwards would leave a live verification
      --  token with no record of who asked for it.
      if not Identity.Operations.Audit.Capacity_Reserved (Repository) then
         return Identity.Adapters.Repositories.Stores.Capacity_Conflict;
      end if;

      Status := Execute (Repository, Contact, Request);

      declare
         --  The contact binding id, not the address itself, identifies what
         --  the verification was aimed at.
         Emitted : constant Identity.Adapters.Repositories.Stores.Command_Status :=
           Identity.Operations.Audit.Emit
             (Repository  => Repository,
              Context     => Context,
              Event       => Event,
              Type_Id     => Identity.Events.Types.Contact_Verification_Requested,
              Subject     =>
                Identity.Operations.Audit.Subject_Of (Contact.Principal),
              Target      => Identity.Text.Bounded.From_String
                (Identity.Identifiers.Entities.To_String (Contact.Id)),
              Outcome     => Identity.Operations.Audit.Outcome_Of (Status),
              Recorded_At => Recorded_At);
      begin
         --  Capacity was reserved above, so a failure here is a real fault in
         --  the store and must not be hidden behind a successful transition.
         if Emitted /= Identity.Adapters.Repositories.Stores.Applied then
            return Emitted;
         end if;
      end;

      return Status;
   end Execute;

   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Contact     : Identity.Contacts.Bindings.Contact_Binding_Record;
      Request     : Verification_Token_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant;
      Key         : Identity.Operations.Idempotency.Idempotency_Key)
      return Identity.Operations.Replay.Command_Outcome
   is
      use type Identity.Adapters.Repositories.Stores.Command_Status;

      Kind : constant Identity.Operations.Idempotency.Idempotent_Operation_Kind :=
        Identity.Operations.Idempotency.Contact_Verification_Request;

      --  Reserve before the transition, so a duplicate request is answered
      --  from the record rather than by issuing a second token.
      Reserved : constant Identity.Adapters.Repositories.Idempotency.Reservation :=
        (if Identity.Operations.Idempotency.Valid (Key)
         then Identity.Adapters.Repositories.Stores.Reserve_Idempotency
                (Repository, Kind, Key)
         else Identity.Operations.Replay.Unusable_Key (Kind));

      Status : Identity.Adapters.Repositories.Stores.Command_Status;
   begin
      if not Identity.Adapters.Repositories.Idempotency.Fresh_Status
        (Reserved.Status)
      then
         return Identity.Operations.Replay.Refused (Reserved);
      end if;

      Status := Execute (Repository, Contact, Request, Context, Event, Recorded_At);

      if Status /= Identity.Adapters.Repositories.Stores.Applied then
         --  Nothing was applied, so nothing may be replayed under this key.
         return (Status => Status,
                 Decision => Identity.Operations.Idempotency.Fresh);
      end if;

      return Identity.Operations.Replay.Completed
        (Status,
         Identity.Adapters.Repositories.Stores.Complete_Idempotency
           (Repository, Kind, Key));
   end Execute;

   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Contact     : Identity.Contacts.Bindings.Contact_Binding_Record;
      Token       : Identity.Tokens.Definitions.Action_Token_Record;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status
   is
      use type Identity.Adapters.Repositories.Stores.Command_Status;
      Status : Identity.Adapters.Repositories.Stores.Command_Status;
   begin
      --  Reserve first: refusing here leaves the store untouched, whereas a
      --  full event log discovered afterwards would leave a live verification
      --  token with no record of who asked for it.
      if not Identity.Operations.Audit.Capacity_Reserved (Repository) then
         return Identity.Adapters.Repositories.Stores.Capacity_Conflict;
      end if;

      Status := Execute (Repository, Contact, Token);

      declare
         Emitted : constant Identity.Adapters.Repositories.Stores.Command_Status :=
           Identity.Operations.Audit.Emit
             (Repository  => Repository,
              Context     => Context,
              Event       => Event,
              Type_Id     => Identity.Events.Types.Contact_Verification_Requested,
              Subject     =>
                Identity.Operations.Audit.Subject_Of (Contact.Principal),
              Target      => Identity.Text.Bounded.From_String
                (Identity.Identifiers.Entities.To_String (Contact.Id)),
              Outcome     => Identity.Operations.Audit.Outcome_Of (Status),
              Recorded_At => Recorded_At);
      begin
         --  Capacity was reserved above, so a failure here is a real fault in
         --  the store and must not be hidden behind a successful transition.
         if Emitted /= Identity.Adapters.Repositories.Stores.Applied then
            return Emitted;
         end if;
      end;

      return Status;
   end Execute;
end Identity.Operations.Verification.Request;
