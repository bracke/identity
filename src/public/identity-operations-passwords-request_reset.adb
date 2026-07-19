with Identity.Crypto.Domains;
with Identity.Crypto.Secret_Verifiers;
with Identity.Identifiers.Registry;
with Identity.Tokens.Purposes;

package body Identity.Operations.Passwords.Request_Reset is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Token      : Identity.Tokens.Definitions.Action_Token_Record)
      return Identity.Adapters.Repositories.Memory.Command_Status is
   begin
      if Identity.Identifiers.Registry.Image (Token.Purpose)
        /= Identity.Identifiers.Registry.Image (Identity.Tokens.Purposes.Password_Reset)
      then
         return Identity.Adapters.Repositories.Memory.State_Conflict;
      end if;

      return Identity.Adapters.Repositories.Memory.Issue_Token (Repository, Token);
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Request    : Reset_Request)
      return Identity.Adapters.Repositories.Memory.Command_Status is
   begin
      return Identity.Adapters.Repositories.Memory.Issue_Token
        (Repository,
         (Id              => Request.Id,
          Purpose         => Identity.Tokens.Purposes.Password_Reset,
          Principal       => Request.Principal,
          Secret_Verifier => Identity.Crypto.Secret_Verifiers.Derive_Text
            (Identity.Crypto.Domains.Password_Reset_Token, Request.Secret),
          Issued_At       => Request.Issued_At,
          Expires_At      => Request.Expires_At,
          State           => Identity.Tokens.Definitions.Issued,
          Attempts        => 0,
          Version         => 0));
   end Execute;
end Identity.Operations.Passwords.Request_Reset;
