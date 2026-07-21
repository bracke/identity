with CryptoLib.Constant_Time;
with CryptoLib.Macs;

package body Identity.Crypto.CryptoLib.TOTP is
   use type Ada.Streams.Stream_Element;
   use type Ada.Streams.Stream_Element_Offset;
   use type Interfaces.Unsigned_64;

   --  Ten raised to Code_Length, for the final modulo.
   function Pow10 (Code_Length : Digit_Count) return Natural is
      Result : Natural := 1;
   begin
      for I in 1 .. Code_Length loop
         Result := Result * 10;
      end loop;
      return Result;
   end Pow10;

   --  RFC 4226 dynamic truncation over an HMAC tag of any length >= 20.
   function Truncate
     (Tag    : Ada.Streams.Stream_Element_Array;
      Code_Length : Digit_Count) return Natural
   is
      Offset : constant Ada.Streams.Stream_Element_Offset :=
        Tag'First
        + Ada.Streams.Stream_Element_Offset (Tag (Tag'Last) and 16#0F#);
      B0 : constant Natural := Natural (Tag (Offset) and 16#7F#);
      B1 : constant Natural := Natural (Tag (Offset + 1));
      B2 : constant Natural := Natural (Tag (Offset + 2));
      B3 : constant Natural := Natural (Tag (Offset + 3));
      Bin : constant Natural := B0 * 2 ** 24 + B1 * 2 ** 16 + B2 * 2 ** 8 + B3;
   begin
      return Bin mod Pow10 (Code_Length);
   end Truncate;

   --  The counter as 8 bytes, big-endian, per RFC 4226.
   function Counter_Bytes
     (Counter : Interfaces.Unsigned_64) return Ada.Streams.Stream_Element_Array
   is
      Result : Ada.Streams.Stream_Element_Array (1 .. 8);
      Value  : Interfaces.Unsigned_64 := Counter;
   begin
      for I in reverse Result'Range loop
         Result (I) := Ada.Streams.Stream_Element (Value and 16#FF#);
         Value := Interfaces.Shift_Right (Value, 8);
      end loop;
      return Result;
   end Counter_Bytes;

   function Compute_Code
     (Secret    : Ada.Streams.Stream_Element_Array;
      Counter   : Interfaces.Unsigned_64;
      Algorithm : Hash_Algorithm := SHA1;
      Code_Length    : Digit_Count := 6) return Natural
   is
      Message : constant Ada.Streams.Stream_Element_Array :=
        Counter_Bytes (Counter);
   begin
      case Algorithm is
         when SHA1 =>
            return Truncate
              (Ada.Streams.Stream_Element_Array
                 (Standard.CryptoLib.Macs.HMAC_SHA1 (Secret, Message)),
               Code_Length);
         when SHA256 =>
            return Truncate
              (Ada.Streams.Stream_Element_Array
                 (Standard.CryptoLib.Macs.HMAC_SHA256 (Secret, Message)),
               Code_Length);
         when SHA512 =>
            return Truncate
              (Ada.Streams.Stream_Element_Array
                 (Standard.CryptoLib.Macs.HMAC_SHA512 (Secret, Message)),
               Code_Length);
      end case;
   end Compute_Code;

   --  Compare two codes in time independent of their digits, so a near-miss
   --  is not distinguishable from a far-miss by timing.
   function Codes_Equal
     (Left  : Natural;
      Right : Natural;
      Code_Length : Digit_Count) return Boolean
   is
      function As_Bytes (Value : Natural) return Ada.Streams.Stream_Element_Array
      is
         Result : Ada.Streams.Stream_Element_Array (1 .. 4);
         V      : Natural := Value;
      begin
         for I in reverse Result'Range loop
            Result (I) := Ada.Streams.Stream_Element (V mod 256);
            V := V / 256;
         end loop;
         return Result;
      end As_Bytes;
      pragma Unreferenced (Code_Length);
   begin
      return Standard.CryptoLib.Constant_Time.Equal
        (As_Bytes (Left), As_Bytes (Right));
   end Codes_Equal;

   function Verify_Code
     (Secret    : Ada.Streams.Stream_Element_Array;
      Presented : Natural;
      Center    : Interfaces.Unsigned_64;
      Skew      : Natural := 1;
      Algorithm : Hash_Algorithm := SHA1;
      Code_Length    : Digit_Count := 6) return Verification
   is
      Low : constant Interfaces.Unsigned_64 :=
        (if Center >= Interfaces.Unsigned_64 (Skew)
         then Center - Interfaces.Unsigned_64 (Skew) else 0);
      High   : constant Interfaces.Unsigned_64 :=
        Center + Interfaces.Unsigned_64 (Skew);
      Result : Verification := (Matched => False, Counter => 0);
      Step   : Interfaces.Unsigned_64 := Low;
   begin
      --  Every candidate step is evaluated even after a match, so the running
      --  time does not reveal which step (or whether an early one) matched.
      loop
         if Codes_Equal
              (Compute_Code (Secret, Step, Algorithm, Code_Length), Presented, Code_Length)
           and then not Result.Matched
         then
            Result := (Matched => True, Counter => Step);
         end if;
         exit when Step >= High;
         Step := Step + 1;
      end loop;
      return Result;
   end Verify_Code;

   function Time_Step
     (Now    : Interfaces.Unsigned_64;
      Period : Positive := 30;
      Epoch  : Interfaces.Unsigned_64 := 0) return Interfaces.Unsigned_64 is
     (if Now <= Epoch then 0
      else (Now - Epoch) / Interfaces.Unsigned_64 (Period));
end Identity.Crypto.CryptoLib.TOTP;
