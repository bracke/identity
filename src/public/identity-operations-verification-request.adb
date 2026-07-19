with Identity.Crypto.Domains;
with Identity.Crypto.Secret_Verifiers;
with Identity.Tokens.Purposes;

package body Identity.Operations.Verification.Request is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Contact    : Identity.Contacts.Bindings.Contact_Binding_Record;
      Token      : Identity.Tokens.Definitions.Action_Token_Record)
      return Identity.Adapters.Repositories.Memory.Command_Status is
   begin
      return Identity.Adapters.Repositories.Memory.Request_Contact_Verification
        (Repository, Contact, Token);
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Contact    : Identity.Contacts.Bindings.Contact_Binding_Record;
      Request    : Verification_Token_Request)
      return Identity.Adapters.Repositories.Memory.Command_Status is
   begin
      return Identity.Adapters.Repositories.Memory.Request_Contact_Verification
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
end Identity.Operations.Verification.Request;
