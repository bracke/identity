package body Identity.Operations.Verification.Complete_Contact_Change is
   function Execute
     (Repository  : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Token       : Identity.Identifiers.Entities.Token_Id;
      Secret      : Identity.Secrets.Tokens.Verification_Token_Secret;
      Now         : Identity.Times.Instant;
      Predecessor : Identity.Identifiers.Entities.Contact_Binding_Id;
      Successor   : Identity.Identifiers.Entities.Contact_Binding_Id)
      return Identity.Tokens.Verification.Token_Verification_Outcome is
   begin
      return Identity.Adapters.Repositories.Stores.Complete_Contact_Change
        (Repository, Token, Secret, Now, Predecessor, Successor);
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Staged_Completion_Request)
      return Identity.Tokens.Verification.Token_Verification_Outcome is
   begin
      return Identity.Adapters.Repositories.Stores.Complete_Contact_Change
        (Repository,
         Request.Token,
         Request.Expected_Token_Version,
         Request.Expected_Change_Version,
         Request.Expected_Predecessor_Version,
         Request.Expected_Successor_Version,
         Request.Secret,
         Request.Now,
         Request.Predecessor,
         Request.Successor);
   end Execute;
end Identity.Operations.Verification.Complete_Contact_Change;
