with Ada.Streams;
with Identity.Crypto.Constant_Time;
with Identity.Crypto.CryptoLib.Entropy;
with Identity.Crypto.CryptoLib.Password_Hashing;
with Identity.Limits;
with Identity.Secrets.Bytes;

package body Identity.Crypto.Password_Hashing is
   package Backend renames Identity.Crypto.CryptoLib.Password_Hashing;

   Prefix : constant String := "identity-pbkdf2-sha256:v2:";

   Hex_Digits : constant String := "0123456789abcdef";

   --  Decimal image of a natural without the leading blank that 'Image adds.
   function Decimal_Image (Value : Natural) return String is
      Raw : constant String := Natural'Image (Value);
   begin
      return Raw (Raw'First + 1 .. Raw'Last);
   end Decimal_Image;

   Salt_Hex_Length    : constant := Backend.Salt_Length * 2;
   Derived_Hex_Length : constant := Backend.Derived_Length * 2;

   ---------------------------------------------------------------------------
   --  Hex helpers
   ---------------------------------------------------------------------------

   function To_Hex (Data : Ada.Streams.Stream_Element_Array) return String is
      Result : String (1 .. Data'Length * 2);
      Pos    : Natural := Result'First;
      Value  : Natural;
   begin
      for B of Data loop
         Value := Natural (B);
         Result (Pos) := Hex_Digits (Value / 16 + 1);
         Result (Pos + 1) := Hex_Digits (Value mod 16 + 1);
         Pos := Pos + 2;
      end loop;
      return Result;
   end To_Hex;

   function Hex_Value (Ch : Character; Valid : out Boolean) return Natural is
   begin
      Valid := True;
      case Ch is
         when '0' .. '9' => return Character'Pos (Ch) - Character'Pos ('0');
         when 'a' .. 'f' => return Character'Pos (Ch) - Character'Pos ('a') + 10;
         when others =>
            Valid := False;
            return 0;
      end case;
   end Hex_Value;

   --  Decode Text into Data; Valid is False when Text is not exactly the
   --  expected length or contains a non-hex character.
   procedure From_Hex
     (Text  : String;
      Data  : out Ada.Streams.Stream_Element_Array;
      Valid : out Boolean)
   is
      Pos      : Natural := Text'First;
      High     : Natural;
      Low      : Natural;
      Ok_High  : Boolean;
      Ok_Low   : Boolean;
   begin
      Data := [others => 0];
      if Text'Length /= Data'Length * 2 then
         Valid := False;
         return;
      end if;
      for Index in Data'Range loop
         High := Hex_Value (Text (Pos), Ok_High);
         Low := Hex_Value (Text (Pos + 1), Ok_Low);
         if not (Ok_High and then Ok_Low) then
            Data := [others => 0];
            Valid := False;
            return;
         end if;
         Data (Index) := Ada.Streams.Stream_Element (High * 16 + Low);
         Pos := Pos + 2;
      end loop;
      Valid := True;
   end From_Hex;

   ---------------------------------------------------------------------------
   --  Envelope parsing
   ---------------------------------------------------------------------------

   type Parsed_Envelope is record
      Outcome    : Verification_Outcome := Malformed_Verifier;
      Iterations : Natural := 0;
      Salt       : Backend.Salt_Bytes := [others => 0];
      Derived    : Backend.Derived_Bytes := [others => 0];
   end record;

   --  An envelope is "<prefix><iterations>:<salt-hex>:<derived-hex>".
   --  Outcome is Verified only when every field is well formed and the
   --  iteration count lies inside the accepted range.
   function Parse (Envelope : String) return Parsed_Envelope is
      Result     : Parsed_Envelope;
      Cursor     : Natural;
      Digits_End : Natural;
      Iterations : Natural := 0;
      Valid      : Boolean;
   begin
      if Envelope'Length <= Prefix'Length
        or else Envelope (Envelope'First .. Envelope'First + Prefix'Length - 1) /= Prefix
      then
         Result.Outcome := Unsupported_Format;
         return Result;
      end if;

      --  Iteration count: at least one digit, terminated by ':'.
      Cursor := Envelope'First + Prefix'Length;
      Digits_End := Cursor - 1;
      while Digits_End < Envelope'Last
        and then Envelope (Digits_End + 1) in '0' .. '9'
      loop
         Digits_End := Digits_End + 1;
         --  Bound the accumulator so an over-long digit run cannot overflow.
         if Iterations <= Maximum_Iterations then
            Iterations :=
              Iterations * 10
              + (Character'Pos (Envelope (Digits_End)) - Character'Pos ('0'));
         end if;
      end loop;

      if Digits_End < Cursor
        or else Digits_End >= Envelope'Last
        or else Envelope (Digits_End + 1) /= ':'
      then
         return Result;
      end if;

      --  Remaining text must be exactly "<salt-hex>:<derived-hex>".
      declare
         Rest_First : constant Natural := Digits_End + 2;
         Expected   : constant Natural :=
           Salt_Hex_Length + 1 + Derived_Hex_Length;
      begin
         if Envelope'Last - Rest_First + 1 /= Expected
           or else Envelope (Rest_First + Salt_Hex_Length) /= ':'
         then
            return Result;
         end if;

         From_Hex
           (Envelope (Rest_First .. Rest_First + Salt_Hex_Length - 1),
            Result.Salt,
            Valid);
         if not Valid then
            return Result;
         end if;

         From_Hex
           (Envelope (Rest_First + Salt_Hex_Length + 1 .. Envelope'Last),
            Result.Derived,
            Valid);
         if not Valid then
            return Result;
         end if;
      end;

      Result.Iterations := Iterations;
      if Iterations < Minimum_Iterations or else Iterations > Maximum_Iterations then
         Result.Outcome := Parameters_Outside_Limits;
      else
         Result.Outcome := Verified;
      end if;
      return Result;
   end Parse;

   ---------------------------------------------------------------------------
   --  Public operations
   ---------------------------------------------------------------------------

   function Create_Verifier
     (Password : Identity.Secrets.Passwords.New_Password) return String
   is
      Buffer : Ada.Streams.Stream_Element_Array
        (1 .. Ada.Streams.Stream_Element_Offset (Identity.Limits.Max_Secret_Bytes));
      Last   : Natural;
      Salt   : Backend.Salt_Bytes;
   begin
      --  Fail closed: never emit a verifier with a predictable salt.
      if not Identity.Crypto.CryptoLib.Entropy.Fill_Bytes (Salt) then
         raise Entropy_Unavailable
           with "OS CSPRNG unavailable; refusing to create a password verifier";
      end if;

      Identity.Secrets.Bytes.Borrow (Password, Buffer, Last);
      declare
         Derived : constant Backend.Derived_Bytes :=
           Backend.PBKDF2_SHA256
             (Password   => Buffer (1 .. Ada.Streams.Stream_Element_Offset (Last)),
              Salt       => Salt,
              Iterations => Default_Iterations);
      begin
         return Prefix
           & Decimal_Image (Default_Iterations)
           & ":" & To_Hex (Salt)
           & ":" & To_Hex (Derived);
      end;
   end Create_Verifier;

   function Inspect (Envelope : String) return Verification_Outcome is
     (Parse (Envelope).Outcome);

   function Validate_Parameters (Envelope : String) return Verification_Outcome is
     (Inspect (Envelope));

   function Determine_Upgrade (Envelope : String) return Migration_Status is
      Parsed : constant Parsed_Envelope := Parse (Envelope);
   begin
      if Parsed.Outcome /= Verified then
         --  Anything we cannot parse or that sits outside the accepted cost
         --  range must be re-derived on the next successful authentication.
         return Upgrade_Required;
      elsif Parsed.Iterations < Default_Iterations then
         return Upgrade_Recommended;
      else
         return Current;
      end if;
   end Determine_Upgrade;

   function Verify
     (Password : Identity.Secrets.Passwords.Presented_Password;
      Envelope : String) return Verification_Result
   is
      Parsed : constant Parsed_Envelope := Parse (Envelope);
      Buffer : Ada.Streams.Stream_Element_Array
        (1 .. Ada.Streams.Stream_Element_Offset (Identity.Limits.Max_Secret_Bytes));
      Last   : Natural;
   begin
      if Parsed.Outcome /= Verified then
         return (Outcome => Parsed.Outcome, Migration => Upgrade_Required);
      end if;

      Identity.Secrets.Bytes.Borrow (Password, Buffer, Last);
      declare
         Derived : constant Backend.Derived_Bytes :=
           Backend.PBKDF2_SHA256
             (Password   => Buffer (1 .. Ada.Streams.Stream_Element_Offset (Last)),
              Salt       => Parsed.Salt,
              Iterations => Parsed.Iterations);
         Migration : constant Migration_Status := Determine_Upgrade (Envelope);
      begin
         --  Constant-time comparison: the running time must not reveal how
         --  much of a candidate verifier matched.
         if Identity.Crypto.Constant_Time.Equal (Derived, Parsed.Derived) then
            return (Outcome => Verified, Migration => Migration);
         else
            return (Outcome => Not_Verified, Migration => Migration);
         end if;
      end;
   exception
      when Entropy_Unavailable =>
         raise;
      when others =>
         return (Outcome => Cryptographic_Failure, Migration => Upgrade_Required);
   end Verify;
end Identity.Crypto.Password_Hashing;
