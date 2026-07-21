with Ada.Streams;
with Interfaces;

package Identity.Crypto.CryptoLib.TOTP is
   --  RFC 6238 time-based one-time passwords over RFC 4226 HOTP.
   --
   --  This is the code-verification half of TOTP that the crate previously did
   --  not implement: given the shared secret and a time step, compute the code
   --  the authenticator app would show, and check a presented code against a
   --  window of time steps. Verification is symmetric, so it needs the raw
   --  shared secret -- a one-way verifier cannot recompute a code.

   type Hash_Algorithm is (SHA1, SHA256, SHA512);
   --  SHA1 is the RFC 6238 default and what authenticator apps use unless
   --  configured otherwise.

   subtype Digit_Count is Positive range 6 .. 8;

   --  The HOTP value for one counter: HMAC over the 8-byte big-endian counter,
   --  dynamically truncated to Code_Length decimal digits (RFC 4226 section 5.3).
   function Compute_Code
     (Secret    : Ada.Streams.Stream_Element_Array;
      Counter   : Interfaces.Unsigned_64;
      Algorithm : Hash_Algorithm := SHA1;
      Code_Length    : Digit_Count := 6) return Natural;

   type Verification is record
      Matched : Boolean := False;
      --  The time step the presented code matched, valid only when Matched.
      Counter : Interfaces.Unsigned_64 := 0;
   end record;

   --  True when Presented equals the code for some counter in
   --  [Center - Skew, Center + Skew], checked in constant time per candidate.
   --  Returns the matched counter so the caller can advance replay state and
   --  reject a code that is not strictly newer than the last accepted step.
   function Verify_Code
     (Secret    : Ada.Streams.Stream_Element_Array;
      Presented : Natural;
      Center    : Interfaces.Unsigned_64;
      Skew      : Natural := 1;
      Algorithm : Hash_Algorithm := SHA1;
      Code_Length    : Digit_Count := 6) return Verification;

   --  The time step for an instant: (Now - Epoch) / Period, floored.
   function Time_Step
     (Now    : Interfaces.Unsigned_64;
      Period : Positive := 30;
      Epoch  : Interfaces.Unsigned_64 := 0) return Interfaces.Unsigned_64;
end Identity.Crypto.CryptoLib.TOTP;
