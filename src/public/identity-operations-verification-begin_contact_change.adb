with Identity.Crypto.Domains;
with Identity.Crypto.Secret_Verifiers;
with Identity.Events.Types;
with Identity.Operations.Audit;
with Identity.Text.Bounded;
with Identity.Tokens.Purposes;

package body Identity.Operations.Verification.Begin_Contact_Change is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Change     : Identity.Verification.Changes.Contact_Change_Record;
      Successor  : Identity.Contacts.Bindings.Contact_Binding_Record;
      Token      : Identity.Tokens.Definitions.Action_Token_Record)
      return Identity.Adapters.Repositories.Stores.Command_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Begin_Contact_Change
        (Repository, Change, Successor, Token);
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Change     : Identity.Verification.Changes.Contact_Change_Record;
      Successor  : Identity.Contacts.Bindings.Contact_Binding_Record;
      Request    : Contact_Change_Token_Request)
      return Identity.Adapters.Repositories.Stores.Command_Status is
   begin
      return Identity.Adapters.Repositories.Stores.Begin_Contact_Change
        (Repository,
         Change,
         Successor,
         (Id              => Request.Id,
          Purpose         => Identity.Tokens.Purposes.Contact_Change,
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
      Change      : Identity.Verification.Changes.Contact_Change_Record;
      Successor   : Identity.Contacts.Bindings.Contact_Binding_Record;
      Request     : Contact_Change_Token_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status
   is
      use type Identity.Adapters.Repositories.Stores.Command_Status;
      Status : Identity.Adapters.Repositories.Stores.Command_Status;
   begin
      --  Reserve first: refusing here leaves the store untouched, whereas a
      --  full event log discovered afterwards would leave a contact change in
      --  flight that nobody was told about.
      if not Identity.Operations.Audit.Capacity_Reserved (Repository) then
         return Identity.Adapters.Repositories.Stores.Capacity_Conflict;
      end if;

      Status := Execute (Repository, Change, Successor, Request);

      declare
         --  The successor binding is what the change is aimed at; its id, not
         --  the contact value itself, identifies it in the record.
         Emitted : constant Identity.Adapters.Repositories.Stores.Command_Status :=
           Identity.Operations.Audit.Emit
             (Repository  => Repository,
              Context     => Context,
              Event       => Event,
              Type_Id     => Identity.Events.Types.Contact_Change_Began,
              Subject     =>
                Identity.Operations.Audit.Subject_Of (Change.Principal),
              Target      => Identity.Text.Bounded.From_String
                (Identity.Identifiers.Entities.To_String (Successor.Id)),
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
end Identity.Operations.Verification.Begin_Contact_Change;
