with Identity.Adapters.Repositories.Memory;
with Identity.Contacts.Bindings;
with Identity.Identifiers.Entities;
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
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Change     : Identity.Verification.Changes.Contact_Change_Record;
      Successor  : Identity.Contacts.Bindings.Contact_Binding_Record;
      Token      : Identity.Tokens.Definitions.Action_Token_Record)
      return Identity.Adapters.Repositories.Memory.Command_Status;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Change     : Identity.Verification.Changes.Contact_Change_Record;
      Successor  : Identity.Contacts.Bindings.Contact_Binding_Record;
      Request    : Contact_Change_Token_Request)
      return Identity.Adapters.Repositories.Memory.Command_Status;
end Identity.Operations.Verification.Begin_Contact_Change;
