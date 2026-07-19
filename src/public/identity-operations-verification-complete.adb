package body Identity.Operations.Verification.Complete is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Token      : Identity.Identifiers.Entities.Token_Id;
      Secret     : Identity.Secrets.Tokens.Verification_Token_Secret;
      Now        : Identity.Times.Instant;
      Contact    : Identity.Identifiers.Entities.Contact_Binding_Id)
      return Identity.Tokens.Verification.Token_Verification_Outcome is
   begin
      return Identity.Adapters.Repositories.Memory.Complete_Contact_Verification
        (Repository, Token, Secret, Now, Contact);
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Request    : Staged_Completion_Request)
      return Identity.Tokens.Verification.Token_Verification_Outcome is
   begin
      return Identity.Adapters.Repositories.Memory.Complete_Contact_Verification
        (Repository,
         Request.Token,
         Request.Expected_Token_Version,
         Request.Expected_Contact_Version,
         Request.Secret,
         Request.Now,
         Request.Contact);
   end Execute;
end Identity.Operations.Verification.Complete;
