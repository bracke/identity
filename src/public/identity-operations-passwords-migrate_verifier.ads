with Identity.Adapters.Repositories.Stores;
with Identity.Identifiers.Entities;
with Identity.Operations.Contexts;
with Identity.Secrets.Passwords;
with Identity.Times;

--  Re-derives a stored password verifier under the current cost parameters.
--
--  Verify already reports whether a stored envelope is below policy
--  (Migration), but reporting it changes nothing on its own: without this
--  operation, raising Default_Iterations can never roll existing verifiers
--  forward, because a verifier can only be re-derived while the plaintext
--  password is in hand -- that is, during a successful authentication.
--
--  Callers should invoke this straight after a successful password
--  authentication, passing the same presented password. It is a separate
--  operation rather than part of authentication because a replacement
--  credential needs an identifier, and this crate never invents identifiers:
--  the caller supplies them.
package Identity.Operations.Passwords.Migrate_Verifier is

   type Migration_Request is record
      Principal            : Identity.Identifiers.Entities.Principal_Id;
      Password             : Identity.Secrets.Passwords.Presented_Password;
      --  Identifier for the replacement credential. Must be unused.
      Successor_Credential : Identity.Identifiers.Entities.Credential_Id;
   end record;

   type Migration_Outcome is
     (Migrated,
      --  The stored verifier already meets the current cost parameters.
      Not_Required,
      --  The presented password does not match, so nothing was re-derived.
      --  Migrating on a wrong password would let anyone rewrite a verifier.
      Password_Rejected,
      Credential_Unknown,
      --  The CSPRNG could not supply a salt for the replacement.
      Entropy_Unavailable,
      Store_Conflict,
      --  The audit event could not be reserved, so nothing was attempted.
      Audit_Capacity_Exceeded);

   function Migration_Applied (Outcome : Migration_Outcome) return Boolean is
     (Outcome = Migrated);

   function Migration_Unnecessary (Outcome : Migration_Outcome) return Boolean is
     (Outcome = Not_Required);

   function Migration_Rejected (Outcome : Migration_Outcome) return Boolean is
     (Outcome in Password_Rejected | Credential_Unknown);

   function Migration_Failed (Outcome : Migration_Outcome) return Boolean is
     (Outcome in Entropy_Unavailable | Store_Conflict | Audit_Capacity_Exceeded);

   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Request     : Migration_Request;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant) return Migration_Outcome;
end Identity.Operations.Passwords.Migrate_Verifier;
