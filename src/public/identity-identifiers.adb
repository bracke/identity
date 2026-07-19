package body Identity.Identifiers is
   function Is_Valid_Text (Value : String) return Boolean is
   begin
      if Value'Length /= Identifier_Text'Length then
         return False;
      end if;

      for Ch of Value loop
         if not (Ch in '0' .. '9' or else Ch in 'a' .. 'f' or else Ch = '-') then
            return False;
         end if;
      end loop;

      return True;
   end Is_Valid_Text;

   function From_String (Value : String) return Encoded_Identifier is
      Result : Encoded_Identifier;
   begin
      Result.Text := Value;
      return Result;
   end From_String;

   function Image (Value : Encoded_Identifier) return String is
   begin
      return Value.Text;
   end Image;
end Identity.Identifiers;
