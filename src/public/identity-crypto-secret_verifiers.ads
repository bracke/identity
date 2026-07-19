with Ada.Streams;
with Identity.Identifiers.Registry;
with Identity.Secrets.Bytes;
with Identity.Text.Bounded;

package Identity.Crypto.Secret_Verifiers is
   type Verification_Outcome is
     (Verified, Not_Verified, Malformed_Verifier, Unsupported_Format, Unsupported_Algorithm,
      Parameters_Outside_Limits, Cryptographic_Failure);

   subtype Verifier_Length is Natural range 0 .. 128;
   type Verifier_Envelope is private;

   function Verification_Accepted
     (Outcome : Verification_Outcome) return Boolean is
     (Outcome = Verified);
   function Verification_Rejected
     (Outcome : Verification_Outcome) return Boolean is
     (Outcome = Not_Verified);
   function Malformed_Verifier_Rejected
     (Outcome : Verification_Outcome) return Boolean is
     (Outcome = Malformed_Verifier);
   function Unsupported_Format_Rejected
     (Outcome : Verification_Outcome) return Boolean is
     (Outcome = Unsupported_Format);
   function Unsupported_Algorithm_Rejected
     (Outcome : Verification_Outcome) return Boolean is
     (Outcome = Unsupported_Algorithm);
   function Resource_Limit_Rejected
     (Outcome : Verification_Outcome) return Boolean is
     (Outcome = Parameters_Outside_Limits);
   function Cryptographic_Failed
     (Outcome : Verification_Outcome) return Boolean is
     (Outcome = Cryptographic_Failure);
   function Operational_Failure
     (Outcome : Verification_Outcome) return Boolean is
     (Outcome in Unsupported_Format
              | Unsupported_Algorithm
              | Parameters_Outside_Limits
              | Cryptographic_Failure);

   function Derive
     (Domain : Identity.Identifiers.Registry.Registry_Id;
      Secret : Identity.Secrets.Bytes.Secret_Bytes) return Verifier_Envelope;

   function Verify
     (Domain   : Identity.Identifiers.Registry.Registry_Id;
      Secret   : Identity.Secrets.Bytes.Secret_Bytes;
      Verifier : Verifier_Envelope) return Verification_Outcome;

   function Derive_Text
     (Domain : Identity.Identifiers.Registry.Registry_Id;
      Secret : Identity.Secrets.Bytes.Secret_Bytes) return Identity.Text.Bounded.Bounded_Text;

   function Verify_Text
     (Domain   : Identity.Identifiers.Registry.Registry_Id;
      Secret   : Identity.Secrets.Bytes.Secret_Bytes;
      Verifier : Identity.Text.Bounded.Bounded_Text) return Verification_Outcome;

private
   type Verifier_Data is array (Positive range 1 .. 64) of Ada.Streams.Stream_Element;
   type Verifier_Envelope is record
      Format  : Positive := 1;
      Domain  : Identity.Identifiers.Registry.Registry_Id;
      Length  : Verifier_Length := 0;
      Data    : Verifier_Data := [others => 0];
   end record;
end Identity.Crypto.Secret_Verifiers;
