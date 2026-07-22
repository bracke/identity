with Identity.Credentials.States;
with Identity.Identifiers.Entities;
with Identity.Text.Bounded;
with Identity.Times;
with Identity.Versions;

--  Public-key possession factors (WebAuthn / passkeys), the modern
--  phishing-resistant credential the crate was clearly designed for -- the
--  assurance model already carries Phishing_Resistant, Hardware_Bound and
--  User_Verification -- but had no storage shape or replay check for.
--
--  Just as the TOTP HMAC engine lives in the core while QR rendering is an
--  adapter, a passkey's credential storage and its signature-counter clone
--  detection belong in the core; only the CBOR/attestation parsing and the
--  ECDSA/EdDSA signature verification are the identity_webauthn adapter's job.
--  The adapter validates the assertion signature against the stored public key
--  and hands the core a verified sign count; the core owns clone detection and
--  the replay-state advance -- exactly as it consumes normalized external
--  assertions elsewhere.
package Identity.WebAuthn.Credentials is
   pragma Pure;

   --  The WebAuthn authenticator signature counter is a 32-bit value.
   type Sign_Count is range 0 .. 2**32 - 1;

   type Passkey_Credential_Record is record
      Id                   : Identity.Identifiers.Entities.Credential_Id;
      Principal            : Identity.Identifiers.Entities.Principal_Id;
      --  The public WebAuthn credential id (base64url) used to look the
      --  credential up. A reference, not a secret.
      Credential_Reference : Identity.Text.Bounded.Bounded_Text;
      --  The stored COSE public key, opaque to the core -- the adapter verifies
      --  signatures against it. Never a secret the crate must protect.
      Public_Key           : Identity.Text.Bounded.Bounded_Text;
      --  The authenticator model identifier (AAGUID), non-secret.
      Authenticator_Model  : Identity.Text.Bounded.Bounded_Text;
      Highest_Sign_Count   : Sign_Count := 0;
      State                : Identity.Credentials.States.Credential_State :=
                               Identity.Credentials.States.Active;
      Created_At           : Identity.Times.Instant := 0;
      Version              : Identity.Versions.Entity_Version := 0;
   end record;

   --  WebAuthn clone detection (WebAuthn L2, verifying an authentication
   --  assertion, the signature-counter step): a strictly greater count is a
   --  fresh assertion; an equal-or-lower count with either value non-zero is a
   --  cloned authenticator replaying a captured assertion; both zero means the
   --  authenticator does not implement a counter, which the spec permits.
   type Sign_Count_Verdict is (Fresh, Cloned_Authenticator, Counterless);

   function Evaluate_Sign_Count
     (Stored, Presented : Sign_Count) return Sign_Count_Verdict is
     (if Presented > Stored then Fresh
      elsif Stored = 0 and then Presented = 0 then Counterless
      else Cloned_Authenticator);

   type Assertion_Status is
     (Accepted,
      Cloned,
      Credential_Unusable,
      Unknown,
      Version_Conflict,
      No_Mutation);

   --  Admit a presented assertion (whose signature the adapter has already
   --  verified) against the stored credential: the credential must be usable,
   --  and the sign count must not indicate a clone.
   function Admit_Assertion
     (Credential : Passkey_Credential_Record;
      Presented  : Sign_Count) return Assertion_Status is
     (if not Identity.Credentials.States.Can_Authenticate (Credential.State)
      then Credential_Unusable
      elsif Evaluate_Sign_Count (Credential.Highest_Sign_Count, Presented)
            = Cloned_Authenticator
      then Cloned
      else Accepted);

   function Fresh_Assertion (Verdict : Sign_Count_Verdict) return Boolean is
     (Verdict = Fresh);
   function Clone_Detected (Verdict : Sign_Count_Verdict) return Boolean is
     (Verdict = Cloned_Authenticator);
   function Counterless_Authenticator (Verdict : Sign_Count_Verdict) return Boolean is
     (Verdict = Counterless);

   function Accepted_Assertion (Status : Assertion_Status) return Boolean is
     (Status = Accepted);
   function Cloned_Assertion (Status : Assertion_Status) return Boolean is
     (Status = Cloned);
   function Unusable_Assertion (Status : Assertion_Status) return Boolean is
     (Status = Credential_Unusable);
   function No_Mutation (Status : Assertion_Status) return Boolean is
     (Status /= Accepted);
end Identity.WebAuthn.Credentials;
