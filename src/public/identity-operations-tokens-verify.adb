package body Identity.Operations.Tokens.Verify is
   function Execute
     (Repository : Identity.Adapters.Repositories.Memory.Store;
      Token      : Identity.Identifiers.Entities.Token_Id;
      Purpose    : Identity.Identifiers.Registry.Registry_Id;
      Secret     : Identity.Secrets.Tokens.Reset_Token_Secret;
      Now        : Identity.Times.Instant)
      return Identity.Tokens.Verification.Token_Verification_Outcome is
   begin
      return Identity.Adapters.Repositories.Memory.Verify_Token
        (Repository, Token, Purpose, Secret, Now);
   end Execute;
end Identity.Operations.Tokens.Verify;
