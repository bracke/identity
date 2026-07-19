package body Identity.Text.Bounded is
   function From_String (Value : String) return Bounded_Text is
      Result : Bounded_Text;
   begin
      Result.Used := Value'Length;
      if Value'Length > 0 then
         Result.Data (1 .. Value'Length) := Value;
      end if;
      return Result;
   end From_String;

   function Image (Value : Bounded_Text) return String is
   begin
      if Value.Used = 0 then
         return "";
      end if;
      return Value.Data (1 .. Value.Used);
   end Image;

   function Length (Value : Bounded_Text) return Text_Length is
     (Value.Used);

   function Equal (Left, Right : Bounded_Text) return Boolean is
     (Image (Left) = Image (Right));
end Identity.Text.Bounded;
