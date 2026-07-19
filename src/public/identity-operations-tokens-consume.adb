package body Identity.Operations.Tokens.Consume is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Token      : Identity.Identifiers.Entities.Token_Id;
      Purpose    : Identity.Identifiers.Registry.Registry_Id;
      Secret     : Identity.Secrets.Tokens.Reset_Token_Secret;
      Now        : Identity.Times.Instant)
      return Identity.Tokens.Verification.Token_Verification_Outcome is
   begin
      return Identity.Adapters.Repositories.Stores.Consume_Token
        (Repository, Token, Purpose, Secret, Now);
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Consume_Request)
      return Identity.Tokens.Verification.Token_Verification_Outcome is
   begin
      return Identity.Adapters.Repositories.Stores.Consume_Token
        (Repository,
         Request.Token,
         Request.Expected_Version,
         Request.Purpose,
         Request.Secret,
         Request.Now);
   end Execute;
end Identity.Operations.Tokens.Consume;
