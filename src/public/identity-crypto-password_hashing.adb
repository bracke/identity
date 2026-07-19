with Ada.Streams;
with Identity.Crypto.CryptoLib.Password_Hashing;
with Identity.Limits;
with Identity.Secrets.Bytes;

package body Identity.Crypto.Password_Hashing is
   Prefix : constant String := "identity-pbkdf2-sha256:v1:1000:";

   function Create_Verifier
     (Password : Identity.Secrets.Passwords.New_Password) return String
   is
      Buffer : Ada.Streams.Stream_Element_Array
        (1 .. Ada.Streams.Stream_Element_Offset (Identity.Limits.Max_Secret_Bytes));
      Last   : Natural;
   begin
      Identity.Secrets.Bytes.Borrow (Password, Buffer, Last);
      return Prefix & Identity.Crypto.CryptoLib.Password_Hashing.PBKDF2_SHA256_Test_Envelope
        (Buffer (1 .. Ada.Streams.Stream_Element_Offset (Last)));
   end Create_Verifier;

   function Inspect (Envelope : String) return Verification_Outcome is
   begin
      if Envelope'Length < Prefix'Length
        or else Envelope (Envelope'First .. Envelope'First + Prefix'Length - 1) /= Prefix
      then
         return Unsupported_Format;
      end if;
      return Verified;
   end Inspect;

   function Validate_Parameters (Envelope : String) return Verification_Outcome is
     (Inspect (Envelope));

   function Determine_Upgrade (Envelope : String) return Migration_Status is
      pragma Unreferenced (Envelope);
   begin
      return Current;
   end Determine_Upgrade;

   function Verify
     (Password : Identity.Secrets.Passwords.Presented_Password;
      Envelope : String) return Verification_Result
   is
      Buffer : Ada.Streams.Stream_Element_Array
        (1 .. Ada.Streams.Stream_Element_Offset (Identity.Limits.Max_Secret_Bytes));
      Last   : Natural;
      Expected : String := Envelope;
   begin
      if Inspect (Envelope) /= Verified then
         return (Outcome => Inspect (Envelope), Migration => Current);
      end if;
      Identity.Secrets.Bytes.Borrow (Password, Buffer, Last);
      Expected := Prefix & Identity.Crypto.CryptoLib.Password_Hashing.PBKDF2_SHA256_Test_Envelope
        (Buffer (1 .. Ada.Streams.Stream_Element_Offset (Last)));
      if Expected = Envelope then
         return (Outcome => Verified, Migration => Current);
      else
         return (Outcome => Not_Verified, Migration => Current);
      end if;
   exception
      when others =>
         return (Outcome => Cryptographic_Failure, Migration => Current);
   end Verify;
end Identity.Crypto.Password_Hashing;
