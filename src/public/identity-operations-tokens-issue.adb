with Identity.Crypto.Secret_Verifiers;

package body Identity.Operations.Tokens.Issue is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Token      : Identity.Tokens.Definitions.Action_Token_Record)
      return Identity.Adapters.Repositories.Memory.Command_Status is
   begin
      return Identity.Adapters.Repositories.Memory.Issue_Token (Repository, Token);
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Request    : Issue_Request)
      return Identity.Adapters.Repositories.Memory.Command_Status is
   begin
      return Identity.Adapters.Repositories.Memory.Issue_Token
        (Repository,
         (Id              => Request.Id,
          Purpose         => Request.Purpose,
          Principal       => Request.Principal,
          Secret_Verifier => Identity.Crypto.Secret_Verifiers.Derive_Text
            (Request.Verifier_Domain, Request.Secret),
          Issued_At       => Request.Issued_At,
          Expires_At      => Request.Expires_At,
          State           => Identity.Tokens.Definitions.Issued,
          Attempts        => Request.Attempts,
          Version         => 0));
   end Execute;
end Identity.Operations.Tokens.Issue;
