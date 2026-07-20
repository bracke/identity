with Ada.Streams;
with Identity.Crypto.Constant_Time;
with Identity.Crypto.CryptoLib.Entropy;
with Identity.Crypto.CryptoLib.Wipe;
with Identity.Crypto.CryptoLib.Password_Hashing;
with Identity.Limits;
with Identity.Secrets.Bytes;

package body Identity.Crypto.Password_Hashing
  with SPARK_Mode => On
is
   use type Ada.Streams.Stream_Element_Offset;
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

   --  Each byte's position is derived from its index rather than carried in a
   --  running cursor, so the bounds follow from the index and are provable.
   function To_Hex (Data : Ada.Streams.Stream_Element_Array) return String
     with Pre  => Data'Length <= 64,
          Post => To_Hex'Result'Length = Data'Length * 2
   is
      Result : String (1 .. Data'Length * 2) := [others => '0'];
      Offset : Natural;
      Value  : Natural;
   begin
      for Index in Data'Range loop
         Offset := Natural (Index - Data'First) * 2;
         Value := Natural (Data (Index));
         Result (Offset + 1) := Hex_Digits (Value / 16 + 1);
         Result (Offset + 2) := Hex_Digits (Value mod 16 + 1);
         pragma Loop_Invariant (Offset + 2 <= Result'Last);
      end loop;
      return Result;
   end To_Hex;

   --  Returned as a record rather than through an out parameter: a function
   --  with an out parameter is not legal in SPARK, and this parser consumes
   --  attacker-controlled text, so it is worth having provable.
   type Hex_Digit is record
      Valid : Boolean := False;
      Value : Natural range 0 .. 15 := 0;
   end record;

   function Hex_Value (Ch : Character) return Hex_Digit is
     (case Ch is
        when '0' .. '9' =>
          (Valid => True, Value => Character'Pos (Ch) - Character'Pos ('0')),
        when 'a' .. 'f' =>
          (Valid => True, Value => Character'Pos (Ch) - Character'Pos ('a') + 10),
        when others => (Valid => False, Value => 0));

   --  Decode Text into Data; Valid is False when Text is not exactly the
   --  expected length or contains a non-hex character.
   procedure From_Hex
     (Text  : String;
      Data  : out Ada.Streams.Stream_Element_Array;
      Valid : out Boolean)
     with Pre => Data'Length <= 64 and then Text'Length <= 512
   is
      High   : Hex_Digit;
      Low    : Hex_Digit;
      Offset : Natural;
   begin
      Data := [others => 0];
      if Text'Length /= Data'Length * 2 then
         Valid := False;
         return;
      end if;

      for Index in Data'Range loop
         --  Text'Length = Data'Length * 2 was just established, so both
         --  positions are inside Text for every index.
         Offset := Natural (Index - Data'First) * 2;
         pragma Loop_Invariant (Offset + 1 <= Text'Length - 1);
         High := Hex_Value (Text (Text'First + Offset));
         Low := Hex_Value (Text (Text'First + Offset + 1));
         if not (High.Valid and then Low.Valid) then
            Data := [others => 0];
            Valid := False;
            return;
         end if;
         Data (Index) := Ada.Streams.Stream_Element (High.Value * 16 + Low.Value);
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
      --  An envelope is bounded public text. Rejecting anything longer here
      --  both matches the storage bound and gives the position arithmetic
      --  below a ceiling it can be checked against.
      if Envelope'Length > Identity.Limits.Max_Public_Text_Bytes
        or else Envelope'Last >= Natural'Last - 4
        or else Envelope'Length <= Prefix'Length
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
         pragma Loop_Invariant (Digits_End in Cursor .. Envelope'Last);
         pragma Loop_Invariant (Iterations <= Maximum_Iterations * 10 + 9);
         pragma Loop_Variant (Increases => Digits_End);
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

   function Derive_Verifier
     (Password : Identity.Secrets.Passwords.New_Password)
      return Verifier_Creation
     with SPARK_Mode => Off
   is
   begin
      return
        (Status   => Created,
         Envelope => Identity.Text.Bounded.From_String (Create_Verifier (Password)));
   exception
      when Entropy_Unavailable =>
         return (Status => Entropy_Missing, Envelope => <>);
      when others =>
         return (Status => Cryptographic_Failure, Envelope => <>);
   end Derive_Verifier;

   function Create_Verifier
     (Password : Identity.Secrets.Passwords.New_Password) return String
     with SPARK_Mode => Off
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
         --  Borrow copies the plaintext into a local buffer; scrub it as soon
         --  as the derivation is done rather than leaving it on the stack.
         Identity.Crypto.CryptoLib.Wipe.Scrub (Buffer'Address, Buffer'Length);
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
     with SPARK_Mode => Off
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
         Identity.Crypto.CryptoLib.Wipe.Scrub (Buffer'Address, Buffer'Length);
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
