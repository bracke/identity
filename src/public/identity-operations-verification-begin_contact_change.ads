with Identity.Adapters.Repositories.Stores;
with Identity.Contacts.Bindings;
with Identity.Identifiers.Entities;
with Identity.Operations.Contexts;
with Identity.Secrets.Tokens;
with Identity.Times;
with Identity.Tokens.Definitions;
with Identity.Verification.Changes;

package Identity.Operations.Verification.Begin_Contact_Change is
   type Contact_Change_Token_Request is record
      Id         : Identity.Identifiers.Entities.Token_Id;
      Principal  : Identity.Identifiers.Entities.Principal_Id;
      Secret     : Identity.Secrets.Tokens.Verification_Token_Secret;
      Issued_At  : Identity.Times.Instant := 0;
      Expires_At : Identity.Times.Expiration;
   end record;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Change     : Identity.Verification.Changes.Contact_Change_Record;
      Successor  : Identity.Contacts.Bindings.Contact_Binding_Record;
      Token      : Identity.Tokens.Definitions.Action_Token_Record)
      return Identity.Adapters.Repositories.Stores.Command_Status;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Change     : Identity.Verification.Changes.Contact_Change_Record;
      Successor  : Identity.Contacts.Bindings.Contact_Binding_Record;
      Request    : Contact_Change_Token_Request)
      return Identity.Adapters.Repositories.Stores.Command_Status;

   --  Audited form. Emits identity.contact.change.began for the transition,
   --  and refuses the operation if the store cannot accept that event: moving
   --  the address that receives recovery mail is exactly the change an
   --  account owner needs to be able to see afterwards.
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Change      : Identity.Verification.Changes.Contact_Change_Record;
      Successor   : Identity.Contacts.Bindings.Contact_Binding_Record;
      Request     : Contact_Change_Token_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status;
end Identity.Operations.Verification.Begin_Contact_Change;
