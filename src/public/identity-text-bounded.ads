with Identity.Limits;

package Identity.Text.Bounded is
   pragma Pure;

   subtype Text_Length is Natural range 0 .. Identity.Limits.Max_Public_Text_Bytes;
   subtype Text_Buffer is String (1 .. Identity.Limits.Max_Public_Text_Bytes);

   type Bounded_Text is private;

   function From_String (Value : String) return Bounded_Text
     with Pre => Value'Length <= Identity.Limits.Max_Public_Text_Bytes;
   function Image (Value : Bounded_Text) return String;
   function Length (Value : Bounded_Text) return Text_Length;
   function Equal (Left, Right : Bounded_Text) return Boolean;

private
   type Bounded_Text is record
      Used : Text_Length := 0;
      Data : Text_Buffer := [others => Character'Val (0)];
   end record;
end Identity.Text.Bounded;
