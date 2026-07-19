package body Identity.Codecs.Canonical is
   function Decimal_Image (Value : Natural) return String is
      Raw : constant String := Natural'Image (Value);
   begin
      return Raw (Raw'First + 1 .. Raw'Last);
   end Decimal_Image;

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
         & "#" & Decimal_Image (Label_Text'Length)
         & ":" & Label_Text
         & "#" & Decimal_Image (Payload_Text'Length)
         & ":" & Payload_Text);
   end Frame;

   function Is_Digit (Value : Character) return Boolean is
     (Value in '0' .. '9');

   procedure Read_Number
     (Text  : String;
      Index : in out Positive;
      Value : out Natural;
      Ok    : out Boolean)
   is
      First : constant Positive := Index;
   begin
      Value := 0;
      Ok := Index <= Text'Last and then Is_Digit (Text (Index));

      while Ok and then Index <= Text'Last and then Is_Digit (Text (Index)) loop
         Value := Value * 10 + Character'Pos (Text (Index)) - Character'Pos ('0');
         Index := Index + 1;
      end loop;

      if Ok and then Index - First > 1 and then Text (First) = '0' then
         Ok := False;
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
