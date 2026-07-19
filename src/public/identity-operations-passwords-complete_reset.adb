with Identity.Credentials.States;
with Identity.Crypto.Password_Hashing;
with Identity.Text.Bounded;
with Identity.Tokens.Purposes;

package body Identity.Operations.Passwords.Complete_Reset is
   function Execute
      (Repository     : in out Identity.Adapters.Repositories.Memory.Store;
      Token          : Identity.Identifiers.Entities.Token_Id;
      Principal      : Identity.Identifiers.Entities.Principal_Id;
      Secret         : Identity.Secrets.Tokens.Reset_Token_Secret;
      Now            : Identity.Times.Instant;
      New_Credential : Identity.Identifiers.Entities.Credential_Id;
      Password       : Identity.Secrets.Passwords.New_Password)
      return Identity.Tokens.Verification.Token_Verification_Outcome
   is
      use type Identity.Tokens.Verification.Token_Verification_Outcome;

      Gate : constant Identity.Tokens.Verification.Token_Verification_Outcome :=
        Identity.Adapters.Repositories.Memory.Verify_Token
          (Repository, Token, Identity.Tokens.Purposes.Password_Reset, Secret, Now);
   begin
      if Gate /= Identity.Tokens.Verification.Valid then
         return Gate;
      end if;

      return Identity.Adapters.Repositories.Memory.Complete_Password_Reset
        (Repository,
         Token,
         Identity.Tokens.Purposes.Password_Reset,
         Secret,
         Now,
         (Id        => New_Credential,
          Principal => Principal,
          State     => Identity.Credentials.States.Active,
          Verifier  => Identity.Text.Bounded.From_String
            (Identity.Crypto.Password_Hashing.Create_Verifier (Password)),
          Version   => 0));
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Memory.Store;
      Request    : Reset_Completion_Request)
      return Identity.Tokens.Verification.Token_Verification_Outcome
   is
      use type Identity.Tokens.Verification.Token_Verification_Outcome;

      Gate : constant Identity.Tokens.Verification.Token_Verification_Outcome :=
        Identity.Adapters.Repositories.Memory.Verify_Token
          (Repository,
           Request.Token,
           Identity.Tokens.Purposes.Password_Reset,
           Request.Secret,
           Request.Now);
   begin
      if Gate /= Identity.Tokens.Verification.Valid then
         return Gate;
      end if;

      return Identity.Adapters.Repositories.Memory.Complete_Password_Reset
        (Repository,
         Request.Token,
         Request.Expected_Token_Version,
         Request.Expected_Predecessor_Version,
         Identity.Tokens.Purposes.Password_Reset,
         Request.Secret,
         Request.Now,
         (Id        => Request.New_Credential,
          Principal => Request.Principal,
          State     => Identity.Credentials.States.Active,
          Verifier  => Identity.Text.Bounded.From_String
            (Identity.Crypto.Password_Hashing.Create_Verifier (Request.Password)),
          Version   => 0));
   end Execute;
end Identity.Operations.Passwords.Complete_Reset;
