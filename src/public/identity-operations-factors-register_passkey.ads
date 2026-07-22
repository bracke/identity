with Identity.Adapters.Repositories.Stores;
with Identity.Identifiers.Entities;
with Identity.Operations.Contexts;
with Identity.Times;
with Identity.WebAuthn.Credentials;

--  Register a passkey (WebAuthn) credential. Audited: a new phishing-resistant
--  factor becoming usable is exactly the enrollment an account owner needs a
--  record of, so it emits identity.mfa.factor.enrolled and refuses if the store
--  cannot accept that event.
package Identity.Operations.Factors.Register_Passkey is
   function Execute
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Credential  : Identity.WebAuthn.Credentials.Passkey_Credential_Record;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status;
end Identity.Operations.Factors.Register_Passkey;
