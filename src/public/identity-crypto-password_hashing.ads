with Identity.Secrets.Passwords;

package Identity.Crypto.Password_Hashing is
   type Verification_Outcome is
     (Verified, Not_Verified, Malformed_Verifier, Unsupported_Format, Unsupported_Algorithm,
      Parameters_Outside_Limits, Cryptographic_Failure);
   type Migration_Status is (Current, Upgrade_Recommended, Upgrade_Required);
   type Verification_Result is record
      Outcome   : Verification_Outcome := Not_Verified;
      Migration : Migration_Status := Current;
   end record;

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

   function Migration_Current (Status : Migration_Status) return Boolean is
     (Status = Current);
   function Upgrade_Recommended_Status
     (Status : Migration_Status) return Boolean is
     (Status = Upgrade_Recommended);
   function Upgrade_Required_Status
     (Status : Migration_Status) return Boolean is
     (Status = Upgrade_Required);
   function Requires_Migration (Status : Migration_Status) return Boolean is
     (Status in Upgrade_Recommended | Upgrade_Required);

   function Create_Verifier
     (Password : Identity.Secrets.Passwords.New_Password) return String;
   function Verify
     (Password : Identity.Secrets.Passwords.Presented_Password;
      Envelope : String) return Verification_Result;
   function Inspect (Envelope : String) return Verification_Outcome;
   function Validate_Parameters (Envelope : String) return Verification_Outcome;
   function Determine_Upgrade (Envelope : String) return Migration_Status;
end Identity.Crypto.Password_Hashing;
