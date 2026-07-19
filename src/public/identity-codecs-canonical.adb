with Identity.Limits;

package body Identity.Codecs.Canonical
  with SPARK_Mode => On
is
   --  Decimal conversion is written out rather than delegated to 'Image so the
   --  digit count is provable: Frame's concatenation only fits inside the
   --  bounded-text limit because these lengths are bounded.

   --  Any Natural renders in at most 10 digits.
   function Decimal_Image (Value : Natural) return String
     with Post => Decimal_Image'Result'Length in 1 .. 10;

   --  Lengths embedded in a frame are always below 1000.
   function Small_Decimal_Image (Value : Natural) return String
     with Pre  => Value <= 999,
          Post => Small_Decimal_Image'Result'Length in 1 .. 3;

   function Decimal_Image (Value : Natural) return String is
      Buffer : String (1 .. 10) := [others => '0'];
      Rest   : Natural := Value;
      First  : Positive := Buffer'Last;
   begin
      for Pos in reverse Buffer'Range loop
         Buffer (Pos) := Character'Val (Character'Pos ('0') + Rest mod 10);
         if Rest > 0 then
            First := Pos;
         end if;
         Rest := Rest / 10;
      end loop;
      return Buffer (First .. Buffer'Last);
   end Decimal_Image;

   function Small_Decimal_Image (Value : Natural) return String is
      Buffer : String (1 .. 3) := [others => '0'];
      Rest   : Natural := Value;
      First  : Positive := Buffer'Last;
   begin
      for Pos in reverse Buffer'Range loop
         Buffer (Pos) := Character'Val (Character'Pos ('0') + Rest mod 10);
         if Rest > 0 then
            First := Pos;
         end if;
         Rest := Rest / 10;
      end loop;
      return Buffer (First .. Buffer'Last);
   end Small_Decimal_Image;

   function Frame
     (Version : Identity.Versions.Format_Version;
      Label   : Identity.Text.Bounded.Bounded_Text;
      Payload : Identity.Text.Bounded.Bounded_Text) return Identity.Text.Bounded.Bounded_Text
   is
      Version_Text : constant String := Decimal_Image (Natural (Version));
      Label_Text   : constant String := Identity.Text.Bounded.Image (Label);
      Payload_Text : constant String := Identity.Text.Bounded.Image (Payload);
   begin
      return Identity.Text.Bounded.From_String
        ("IF" & Version_Text
         & "#" & Small_Decimal_Image (Label_Text'Length)
         & ":" & Label_Text
         & "#" & Small_Decimal_Image (Payload_Text'Length)
         & ":" & Payload_Text);
   end Frame;

   function Is_Digit (Value : Character) return Boolean is
     (Value in '0' .. '9');

   --  Upper bound for any number a canonical frame may carry. Every legal
   --  field (format version, label length, payload length) is far below this,
   --  so capping here costs nothing and keeps the accumulator inside Natural
   --  no matter what a malformed frame contains.
   Max_Number : constant := 100_000;

   procedure Read_Number
     (Text  : String;
      Index : in out Positive;
      Value : out Natural;
      Ok    : out Boolean)
     with Pre  => Text'First = 1
                  and then Text'Last <= Identity.Limits.Max_Public_Text_Bytes
                  and then Index <= Text'Last + 1,
          Post => Index <= Text'Last + 1
                  and then Index >= Index'Old
                  and then Value <= Max_Number
   is
      First : constant Positive := Index;
   begin
      Value := 0;
      Ok := Index <= Text'Last and then Is_Digit (Text (Index));

      --  A digit run that would carry the accumulator past Max_Number is
      --  rejected outright rather than allowed to overflow.
      while Ok and then Index <= Text'Last and then Is_Digit (Text (Index)) loop
         if Value > (Max_Number - 9) / 10 then
            Ok := False;
            exit;
         end if;

         Value := Value * 10 + Character'Pos (Text (Index)) - Character'Pos ('0');
         Index := Index + 1;

         pragma Loop_Invariant (Index >= First and then Index <= Text'Last + 1);
         pragma Loop_Invariant (Value <= Max_Number);
         pragma Loop_Variant (Increases => Index);
      end loop;

      if not Ok then
         Value := 0;
      elsif Index - First > 1 and then Text (First) = '0' then
         Ok := False;
         Value := 0;
      end if;
   end Read_Number;

   function Is_Canonical_Frame
     (Value : Identity.Text.Bounded.Bounded_Text) return Boolean
   is
      Text     : constant String := Identity.Text.Bounded.Image (Value);
      Index    : Positive := Text'First;
      Number   : Natural := 0;
      Label_L  : Natural := 0;
      Payload_L : Natural := 0;
      Ok       : Boolean := False;
   begin
      if Text'Length < 7 or else Text (Index .. Index + 1) /= "IF" then
         return False;
      end if;

      Index := Index + 2;
      Read_Number (Text, Index, Number, Ok);
      if not Ok or else Number = 0 or else Index > Text'Last or else Text (Index) /= '#' then
         return False;
      end if;

      Index := Index + 1;
      Read_Number (Text, Index, Label_L, Ok);
      if not Ok
        or else Label_L > 96
        or else Index > Text'Last
        or else Text (Index) /= ':'
      then
         return False;
      end if;

      Index := Index + 1 + Label_L;
      if Index > Text'Last or else Text (Index) /= '#' then
         return False;
      end if;

      Index := Index + 1;
      Read_Number (Text, Index, Payload_L, Ok);
      if not Ok
        or else Payload_L > 384
        or else Index > Text'Last
        or else Text (Index) /= ':'
      then
         return False;
      end if;

      Index := Index + 1 + Payload_L;
      return Index = Text'Last + 1;
   end Is_Canonical_Frame;
end Identity.Codecs.Canonical;
