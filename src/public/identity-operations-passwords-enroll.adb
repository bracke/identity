with Identity.Credentials.States;
with Identity.Crypto.Password_Hashing;
with Identity.Events.Types;
with Identity.Operations.Audit;
with Identity.Text.Bounded;

package body Identity.Operations.Passwords.Enroll is
   function Execute
     (Repository : in out Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Principal  : Identity.Identifiers.Entities.Principal_Id;
      Credential : Identity.Identifiers.Entities.Credential_Id;
      Password   : Identity.Secrets.Passwords.New_Password)
      return Identity.Adapters.Repositories.Stores.Command_Status
   is
      --  Derive_Verifier reports a CSPRNG failure as a result rather than
      --  raising, so a caller of this operation never has to expect an
      --  exception from an API that otherwise reports everything explicitly.
      Derived : constant Identity.Crypto.Password_Hashing.Verifier_Creation :=
        Identity.Crypto.Password_Hashing.Derive_Verifier (Password);
   begin
      if not Identity.Crypto.Password_Hashing.Created_Verifier (Derived) then
         return Identity.Adapters.Repositories.Stores.Cryptographic_Conflict;
      end if;

      return Identity.Adapters.Repositories.Stores.Enroll_Password
        (Repository,
         (Id        => Credential,
          Principal => Principal,
          State     => Identity.Credentials.States.Active,
          Verifier  => Derived.Envelope,
          Version   => 0));
   end Execute;

   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Principal   : Identity.Identifiers.Entities.Principal_Id;
      Credential  : Identity.Identifiers.Entities.Credential_Id;
      Password    : Identity.Secrets.Passwords.New_Password;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status
   is
      use type Identity.Adapters.Repositories.Stores.Command_Status;
      Status : Identity.Adapters.Repositories.Stores.Command_Status;
   begin
      --  Reserve first: refusing here leaves the store untouched, whereas a
      --  full event log discovered afterwards would leave a usable password
      --  with no record of when it was set.
      if not Identity.Operations.Audit.Capacity_Reserved (Repository) then
         return Identity.Adapters.Repositories.Stores.Capacity_Conflict;
      end if;

      Status := Execute (Repository, Principal, Credential, Password);

      declare
         Emitted : constant Identity.Adapters.Repositories.Stores.Command_Status :=
           Identity.Operations.Audit.Emit
             (Repository  => Repository,
              Context     => Context,
              Event       => Event,
              Type_Id     => Identity.Events.Types.Password_Enrolled,
              Subject     => Identity.Operations.Audit.Subject_Of (Principal),
              Target      => Identity.Text.Bounded.From_String
                (Identity.Identifiers.Entities.To_String (Credential)),
              Outcome     => Identity.Operations.Audit.Outcome_Of (Status),
              Recorded_At => Recorded_At);
      begin
         --  Capacity was reserved above, so a failure here is a real fault in
         --  the store and must not be hidden behind a successful transition.
         if Emitted /= Identity.Adapters.Repositories.Stores.Applied then
            return Emitted;
         end if;
      end;

      return Status;
   end Execute;
end Identity.Operations.Passwords.Enroll;
