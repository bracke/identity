with Identity.Credentials.States;
with Identity.Crypto.Password_Hashing;
with Identity.Events.Types;
with Identity.Operations.Audit;
with Identity.Passwords.Credentials;
with Identity.Text.Bounded;

package body Identity.Operations.Passwords.Migrate_Verifier is
   package Stores renames Identity.Adapters.Repositories.Stores;
   package Hashing renames Identity.Crypto.Password_Hashing;

   use type Stores.Command_Status;
   use type Identity.Credentials.States.Credential_State;
   use type Hashing.Verification_Outcome;

   function Execute
     (Repository  : in out Stores.Store_Interface'Class;
      Request     : Migration_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant) return Migration_Outcome
   is
      Found      : Boolean;
      Credential : Identity.Passwords.Credentials.Password_Credential_Record;
   begin
      if not Identity.Operations.Audit.Capacity_Reserved (Repository) then
         return Audit_Capacity_Exceeded;
      end if;

      Stores.Find_Active_Password (Repository, Request.Principal, Found, Credential);
      if not Found
        or else Credential.State /= Identity.Credentials.States.Active
      then
         return Credential_Unknown;
      end if;

      declare
         Envelope : constant String :=
           Identity.Text.Bounded.Image (Credential.Verifier);
      begin
         if not Hashing.Requires_Migration (Hashing.Determine_Upgrade (Envelope))
         then
            return Not_Required;
         end if;

         --  Only re-derive on a verified password: migrating without checking
         --  would let anyone who can reach this operation overwrite a stored
         --  verifier with one of their choosing.
         if Hashing.Verify (Request.Password, Envelope).Outcome /= Hashing.Verified
         then
            return Password_Rejected;
         end if;
      end;

      declare
         Derived : constant Hashing.Verifier_Creation :=
           Hashing.Derive_Verifier (Request.Password);
      begin
         if not Hashing.Created_Verifier (Derived) then
            return Entropy_Unavailable;
         end if;

         declare
            Status : constant Stores.Command_Status :=
              Stores.Replace_Password
                (Repository,
                 Credential.Id,
                 (Id        => Request.Successor_Credential,
                  Principal => Request.Principal,
                  State     => Identity.Credentials.States.Active,
                  Verifier  => Derived.Envelope,
                  Version   => 0));

            Emitted : constant Stores.Command_Status :=
              Identity.Operations.Audit.Emit
                (Repository  => Repository,
                 Context     => Context,
                 Event       => Event,
                 Type_Id     => Identity.Events.Types.Password_Verifier_Migrated,
                 Subject     =>
                   Identity.Operations.Audit.Subject_Of (Request.Principal),
                 Target      => Identity.Text.Bounded.From_String ("password"),
                 Outcome     => Identity.Operations.Audit.Outcome_Of (Status),
                 Recorded_At => Recorded_At);
         begin
            if Emitted /= Stores.Applied then
               return Audit_Capacity_Exceeded;
            elsif Status /= Stores.Applied then
               return Store_Conflict;
            end if;
         end;
      end;

      return Migrated;
   end Execute;
end Identity.Operations.Passwords.Migrate_Verifier;
