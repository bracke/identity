with Identity.Crypto.Capabilities;
with Identity.Identifiers.Registry;

package Identity.Crypto.One_Time_Passwords is
   pragma Pure;
   use type Identity.Crypto.Capabilities.Capability_State;

   type OTP_Verification_Status is
     (Accepted,
      Not_Accepted,
      Replayed,
      Unsupported_Algorithm,
      Missing_Capability);

   type OTP_Capability is record
      HMAC : Identity.Crypto.Capabilities.Capability_State :=
        Identity.Crypto.Capabilities.Missing;
      Algorithm : Identity.Identifiers.Registry.Registry_Id;
   end record;

   function Available (Value : OTP_Capability) return Boolean is
     (Value.HMAC = Identity.Crypto.Capabilities.Available);

   function Verification_Accepted
     (Status : OTP_Verification_Status) return Boolean is
     (Status = Accepted);

   function Presentation_Rejected
     (Status : OTP_Verification_Status) return Boolean is
     (Status in Not_Accepted | Replayed);

   function Replay_Rejected
     (Status : OTP_Verification_Status) return Boolean is
     (Status = Replayed);

   function Unsupported_Algorithm_Rejected
     (Status : OTP_Verification_Status) return Boolean is
     (Status = Unsupported_Algorithm);

   function Missing_Cryptographic_Capability
     (Status : OTP_Verification_Status) return Boolean is
     (Status = Missing_Capability);

   function Operational_Failure
     (Status : OTP_Verification_Status) return Boolean is
     (Status in Unsupported_Algorithm | Missing_Capability);
end Identity.Crypto.One_Time_Passwords;
