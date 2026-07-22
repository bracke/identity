with Identity.Adapters.Repositories.Stores;
with Identity.Identifiers.Entities;
with Identity.Operations.Contexts;
with Identity.Times;
with Identity.Versions;
with Identity.WebAuthn.Credentials;

--  Accept a WebAuthn assertion whose signature the identity_webauthn adapter has
--  already verified against the stored public key. The core does clone detection
--  on the presented sign count and advances the replay state, emitting
--  identity.mfa.challenge.completed -- the possession analogue of accepting a
--  TOTP counter.
package Identity.Operations.Factors.Accept_Passkey_Assertion is
   function Execute
     (Repository       : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Credential       : Identity.Identifiers.Entities.Credential_Id;
      Principal        : Identity.Identifiers.Entities.Principal_Id;
      Expected_Version : Identity.Versions.Entity_Version;
      Presented        : Identity.WebAuthn.Credentials.Sign_Count;
      Context          : Identity.Operations.Contexts.Operation_Context;
      Event            : Identity.Identifiers.Entities.Event_Id;
      Recorded_At      : Identity.Times.Instant)
      return Identity.WebAuthn.Credentials.Assertion_Status;
end Identity.Operations.Factors.Accept_Passkey_Assertion;
