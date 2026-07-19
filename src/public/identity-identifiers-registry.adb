package body Identity.Identifiers.Registry is
   function Is_Valid (Value : String) return Boolean is
   begin
      if Value'Length = 0 or else Value'Length > Identity.Limits.Max_Registry_Id_Bytes then
         return False;
      end if;

      for Ch of Value loop
         if not (Ch in 'a' .. 'z'
                 or else Ch in '0' .. '9'
                 or else Ch = '.'
                 or else Ch = '-'
                 or else Ch = '_')
         then
            return False;
         end if;
      end loop;

      return True;
   end Is_Valid;

   function From_String (Value : String) return Registry_Id is
      Result : Registry_Id;
   begin
      Result.Length := Value'Length;
      Result.Text (1 .. Value'Length) := Value;
      return Result;
   end From_String;

   function Image (Value : Registry_Id) return String is
   begin
      if Value.Length = 0 then
         return "";
      end if;

      return Value.Text (1 .. Value.Length);
   end Image;

   function Is_Valid (Value : Registry_Id) return Boolean is
   begin
      return Is_Valid (Image (Value));
   end Is_Valid;
end Identity.Identifiers.Registry;
