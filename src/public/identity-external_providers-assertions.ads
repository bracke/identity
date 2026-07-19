with Identity.Identifiers.Entities;
with Identity.Identifiers.Registry;
with Identity.Text.Bounded;
with Identity.Times;

package Identity.External_Providers.Assertions is
   pragma Pure;

   type Nonce_Status is (Not_Required, Validated, Missing, Invalid);
   type Assertion_Admission_Status is (Admitted, Expired, Nonce_Not_Validated);

   type Normalized_Assertion is record
      Provider       : Identity.Identifiers.Entities.External_Provider_Id;
      Protocol       : Identity.Identifiers.Registry.Registry_Id;
      Issuer         : Identity.Text.Bounded.Bounded_Text;
      External_Subject : Identity.Text.Bounded.Bounded_Text;
      Issued_At      : Identity.Times.Instant := 0;
      Authentication_Time : Identity.Times.Instant := 0;
      Expires_At     : Identity.Times.Expiration;
      Nonce          : Nonce_Status := Not_Required;
      Assertion_Fingerprint : Identity.Text.Bounded.Bounded_Text;
      Validation_Profile    : Identity.Identifiers.Registry.Registry_Id;
   end record;

   function Nonce_Acceptable (Nonce : Nonce_Status) return Boolean is
     (Nonce in Not_Required | Validated);

   function Nonce_Not_Required (Nonce : Nonce_Status) return Boolean is
     (Nonce = Not_Required);
   function Nonce_Validated (Nonce : Nonce_Status) return Boolean is
     (Nonce = Validated);
   function Nonce_Missing (Nonce : Nonce_Status) return Boolean is
     (Nonce = Missing);
   function Nonce_Invalid (Nonce : Nonce_Status) return Boolean is
     (Nonce = Invalid);
   function Nonce_Unacceptable (Nonce : Nonce_Status) return Boolean is
     (not Nonce_Acceptable (Nonce));

   function Has_Replay_Fingerprint
     (Assertion : Normalized_Assertion) return Boolean is
     (Identity.Text.Bounded.Length (Assertion.Assertion_Fingerprint) > 0);

   function Same_External_Key
     (Left, Right : Normalized_Assertion) return Boolean is
     (Identity.Identifiers.Entities.To_String (Left.Provider)
      = Identity.Identifiers.Entities.To_String (Right.Provider)
      and then Identity.Text.Bounded.Equal (Left.Issuer, Right.Issuer)
      and then Identity.Text.Bounded.Equal
        (Left.External_Subject, Right.External_Subject));

   function Admit_For_Core
     (Assertion : Normalized_Assertion;
      Now       : Identity.Times.Instant) return Assertion_Admission_Status is
     (if Identity.Times.Expired (Now, Assertion.Expires_At) then Expired
      elsif not Nonce_Acceptable (Assertion.Nonce) then Nonce_Not_Validated
      else Admitted);

   function Assertion_Admitted
     (Status : Assertion_Admission_Status) return Boolean is
     (Status = Admitted);

   function Assertion_Expired
     (Status : Assertion_Admission_Status) return Boolean is
     (Status = Expired);

   function Nonce_Rejected
     (Status : Assertion_Admission_Status) return Boolean is
     (Status = Nonce_Not_Validated);

   function Assertion_Rejected
     (Status : Assertion_Admission_Status) return Boolean is
     (Status in Expired | Nonce_Not_Validated);

   function Replay_Registration_Eligible
     (Status : Assertion_Admission_Status) return Boolean is
     (Status = Admitted);

   function Ready_For_Replay_Registration
     (Assertion : Normalized_Assertion;
      Now       : Identity.Times.Instant) return Boolean is
     (Admit_For_Core (Assertion, Now) = Admitted
      and then Has_Replay_Fingerprint (Assertion));
end Identity.External_Providers.Assertions;
