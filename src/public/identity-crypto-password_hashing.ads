with Identity.Secrets.Passwords;
with Identity.Text.Bounded;

--  The parsing half of this package is in SPARK: Inspect, Validate_Parameters
--  and Determine_Upgrade consume attacker-controlled envelope text, so their
--  freedom from runtime errors is proved rather than reviewed. The three
--  routines that reach cryptolib or borrow secret bytes are outside SPARK and
--  are marked individually.
package Identity.Crypto.Password_Hashing
  with SPARK_Mode => On
is
   --  PBKDF2-HMAC-SHA256 cost parameters. Default_Iterations follows the OWASP
   --  guidance for this PRF; envelopes below Minimum_Iterations are treated as
   --  requiring migration, and Maximum_Iterations bounds attacker-supplied
   --  envelopes so verification cannot be turned into a denial-of-service.
   Default_Iterations : constant := 600_000;
   Minimum_Iterations : constant := 100_000;
   Maximum_Iterations : constant := 10_000_000;

   --  Raised by Create_Verifier when the OS CSPRNG cannot supply a salt.
   --  Creating a verifier without unpredictable salt would silently weaken
   --  every stored password, so verifier creation fails closed instead.
   --
   --  Prefer Derive_Verifier in the operations layer: the rest of this crate
   --  reports failure as a classified result, and a caller written against
   --  that style has no reason to expect an exception.
   Entropy_Unavailable : exception;

   type Creation_Status is
     (Created,
      --  The OS CSPRNG could not supply a salt; nothing was produced.
      Entropy_Missing,
      --  The key derivation itself failed.
      Cryptographic_Failure);

   type Verifier_Creation is record
      Status   : Creation_Status := Entropy_Missing;
      Envelope : Identity.Text.Bounded.Bounded_Text;
   end record;

   function Created_Verifier (Value : Verifier_Creation) return Boolean is
     (Value.Status = Created);

   function Entropy_Rejected (Value : Verifier_Creation) return Boolean is
     (Value.Status = Entropy_Missing);

   function Cryptographic_Failed (Value : Verifier_Creation) return Boolean is
     (Value.Status = Cryptographic_Failure);

   --  Non-raising form of Create_Verifier. Fails closed the same way -- a
   --  result that is not Created carries an empty envelope.
   function Derive_Verifier
     (Password : Identity.Secrets.Passwords.New_Password)
      return Verifier_Creation
     with SPARK_Mode => Off;

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
     (Password : Identity.Secrets.Passwords.New_Password) return String
     with SPARK_Mode => Off;
   function Verify
     (Password : Identity.Secrets.Passwords.Presented_Password;
      Envelope : String) return Verification_Result
     with SPARK_Mode => Off;
   function Inspect (Envelope : String) return Verification_Outcome;
   function Validate_Parameters (Envelope : String) return Verification_Outcome;
   function Determine_Upgrade (Envelope : String) return Migration_Status;
end Identity.Crypto.Password_Hashing;
