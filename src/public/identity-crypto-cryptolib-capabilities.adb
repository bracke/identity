with Ada.Streams;
with Identity.Crypto.Constant_Time;
with Identity.Crypto.CryptoLib.Entropy;
with Identity.Crypto.CryptoLib.Event_Integrity;
with Identity.Crypto.CryptoLib.One_Time_Passwords;
with Identity.Crypto.CryptoLib.Password_Hashing;
with Identity.Crypto.CryptoLib.Secret_Verifiers;
with Identity.Crypto.Domains;
with Identity.Crypto.Event_Integrity;
with Identity.Crypto.One_Time_Passwords;

package body Identity.Crypto.CryptoLib.Capabilities is
   use type Ada.Streams.Stream_Element_Array;

   package Caps renames Identity.Crypto.Capabilities;

   function State (Ok : Boolean) return Caps.Capability_State is
     (if Ok then Caps.Available else Caps.Missing);

   --  Derive twice from the same inputs and require agreement, so a primitive
   --  that raises or returns garbage cannot be reported as Available.
   function Password_Hashing_Works return Boolean is
      Password : constant Ada.Streams.Stream_Element_Array (1 .. 8) :=
        [others => 16#41#];
      Salt : constant Identity.Crypto.CryptoLib.Password_Hashing.Salt_Bytes :=
        [others => 16#5A#];
      Left : constant Identity.Crypto.CryptoLib.Password_Hashing.Derived_Bytes :=
        Identity.Crypto.CryptoLib.Password_Hashing.PBKDF2_SHA256
          (Password, Salt, 1_000);
      Right : constant Identity.Crypto.CryptoLib.Password_Hashing.Derived_Bytes :=
        Identity.Crypto.CryptoLib.Password_Hashing.PBKDF2_SHA256
          (Password, Salt, 1_000);
   begin
      return Left = Right and then Left /= [Left'Range => 0];
   exception
      when others =>
         return False;
   end Password_Hashing_Works;

   function Secret_Verifiers_Work return Boolean is
      Secret : constant Ada.Streams.Stream_Element_Array (1 .. 8) :=
        [others => 16#42#];
      Digest : constant Ada.Streams.Stream_Element_Array :=
        Identity.Crypto.CryptoLib.Secret_Verifiers.Derive_SHA256
          ("identity.capability-probe", Secret);
   begin
      return Digest'Length = 32 and then Digest /= [Digest'Range => 0];
   exception
      when others =>
         return False;
   end Secret_Verifiers_Work;

   function Constant_Time_Works return Boolean is
      Left  : constant Ada.Streams.Stream_Element_Array (1 .. 4) := [1, 2, 3, 4];
      Right : constant Ada.Streams.Stream_Element_Array (1 .. 4) := [1, 2, 3, 5];
   begin
      return Identity.Crypto.Constant_Time.Equal (Left, Left)
        and then not Identity.Crypto.Constant_Time.Equal (Left, Right);
   exception
      when others =>
         return False;
   end Constant_Time_Works;

   function Current return Caps.Crypto_Capability_Set is
   begin
      return
        (Entropy =>
           Identity.Crypto.CryptoLib.Entropy.Capability,
         Password_Hashing => State (Password_Hashing_Works),
         Secret_Verifiers => State (Secret_Verifiers_Work),
         Constant_Time    => State (Constant_Time_Works),
         TOTP_HMAC        =>
           (if Identity.Crypto.One_Time_Passwords.Available
              (Identity.Crypto.CryptoLib.One_Time_Passwords.Capability
                 (Identity.Crypto.Domains.TOTP_Secret))
            then Caps.Available
            else Caps.Missing),
         Event_Integrity =>
           (if Identity.Crypto.Event_Integrity.Configured
              (Identity.Crypto.CryptoLib.Event_Integrity.Service
                 (Identity.Crypto.Domains.Event_Integrity))
            then Caps.Available
            else Caps.Missing));
   end Current;
end Identity.Crypto.CryptoLib.Capabilities;
