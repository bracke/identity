with Identity.Credentials.States;
with Identity.Crypto.Password_Hashing;
with Identity.Events.Types;
with Identity.Operations.Audit;
with Identity.Text.Bounded;
with Identity.Tokens.Purposes;

package body Identity.Operations.Passwords.Complete_Reset is
   function Execute
      (Repository     : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
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
        Identity.Adapters.Repositories.Stores.Verify_Token
          (Repository, Token, Identity.Tokens.Purposes.Password_Reset, Secret, Now);
      Derived_Replacement : Identity.Text.Bounded.Bounded_Text;
   begin
      if Gate /= Identity.Tokens.Verification.Valid then
         return Gate;
      end if;

      --  Derived only after the current password checks out, so a rejected
      --  change does not pay for a key derivation. A CSPRNG failure is
      --  reported as a classified result rather than raised.
      declare
         Derived : constant Identity.Crypto.Password_Hashing.Verifier_Creation :=
           Identity.Crypto.Password_Hashing.Derive_Verifier (Password);
      begin
         if not Identity.Crypto.Password_Hashing.Created_Verifier (Derived) then
            return Identity.Tokens.Verification.Infrastructure_Failure;
         end if;
         Derived_Replacement := Derived.Envelope;
      end;

      return Identity.Adapters.Repositories.Stores.Complete_Password_Reset
        (Repository,
         Token,
         Identity.Tokens.Purposes.Password_Reset,
         Secret,
         Now,
         (Id        => New_Credential,
          Principal => Principal,
          State     => Identity.Credentials.States.Active,
          Verifier  => Derived_Replacement,
          Version   => 0));
   end Execute;

   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request    : Reset_Completion_Request)
      return Identity.Tokens.Verification.Token_Verification_Outcome
   is
      use type Identity.Tokens.Verification.Token_Verification_Outcome;

      Gate : constant Identity.Tokens.Verification.Token_Verification_Outcome :=
        Identity.Adapters.Repositories.Stores.Verify_Token
          (Repository,
           Request.Token,
           Identity.Tokens.Purposes.Password_Reset,
           Request.Secret,
           Request.Now);
      Derived_Replacement : Identity.Text.Bounded.Bounded_Text;
   begin
      if Gate /= Identity.Tokens.Verification.Valid then
         return Gate;
      end if;

      --  Derived only after the reset token checks out; a CSPRNG failure is
      --  reported as a classified result rather than raised.
      declare
         Derived : constant Identity.Crypto.Password_Hashing.Verifier_Creation :=
           Identity.Crypto.Password_Hashing.Derive_Verifier (Request.Password);
      begin
         if not Identity.Crypto.Password_Hashing.Created_Verifier (Derived) then
            return Identity.Tokens.Verification.Infrastructure_Failure;
         end if;
         Derived_Replacement := Derived.Envelope;
      end;

      return Identity.Adapters.Repositories.Stores.Complete_Password_Reset
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
          Verifier  => Derived_Replacement,
          Version   => 0));
   end Execute;

   --  A token verdict is not a store command status: an unusable token is a
   --  rejection, a losing version check is a conflict, and only broken
   --  infrastructure is a failure.

   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : Reset_Completion_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Tokens.Verification.Token_Verification_Outcome
   is
      use type Identity.Adapters.Repositories.Stores.Command_Status;
      Outcome : Identity.Tokens.Verification.Token_Verification_Outcome;
   begin
      --  Reserve first: refusing here consumes neither the token nor the
      --  existing password.
      if not Identity.Operations.Audit.Capacity_Reserved (Repository) then
         return Identity.Tokens.Verification.Infrastructure_Failure;
      end if;

      Outcome := Execute (Repository, Request);

      declare
         Emitted : constant Identity.Adapters.Repositories.Stores.Command_Status :=
           Identity.Operations.Audit.Emit
             (Repository  => Repository,
              Context     => Context,
              Event       => Event,
              Type_Id     => Identity.Events.Types.Password_Reset_Completed,
              Subject     =>
                Identity.Operations.Audit.Subject_Of (Request.Principal),
              Target      => Identity.Text.Bounded.From_String
                (Identity.Identifiers.Entities.To_String (Request.Token)),
              Outcome     => Identity.Operations.Audit.Outcome_Of (Outcome),
              Recorded_At => Recorded_At);
      begin
         if Emitted /= Identity.Adapters.Repositories.Stores.Applied then
            return Identity.Tokens.Verification.Infrastructure_Failure;
         end if;
      end;

      return Outcome;
   end Execute;
end Identity.Operations.Passwords.Complete_Reset;
