with Identity.Limits;

package Identity.Text.Bounded
  with SPARK_Mode => On
is
   pragma Pure;

   subtype Text_Length is Natural range 0 .. Identity.Limits.Max_Public_Text_Bytes;
   subtype Text_Buffer is String (1 .. Identity.Limits.Max_Public_Text_Bytes);

   type Bounded_Text is private;

   function From_String (Value : String) return Bounded_Text
     with Pre => Value'Length <= Identity.Limits.Max_Public_Text_Bytes;
   function Length (Value : Bounded_Text) return Text_Length;

   --  Image is 1-based and exactly Length characters long. Callers that parse
   --  the result (canonical framing) rely on both facts to stay inside
   --  machine-integer range while scanning.
   function Image (Value : Bounded_Text) return String
     with Post => Image'Result'First = 1
                  and then Image'Result'Length = Length (Value);
   function Equal (Left, Right : Bounded_Text) return Boolean;

private
   type Bounded_Text is record
      Used : Text_Length := 0;
      Data : Text_Buffer := [others => Character'Val (0)];
   end record;
end Identity.Text.Bounded;
