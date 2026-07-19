package body Identity.Tokens.Generation is

   function Parse
     (Value     : String;
      Separator : Character := '.') return Presented_Token
   is
      Separator_Count : Natural := 0;
      Separator_Index : Natural := 0;
   begin
      if Value'Length = 0 then
         return (Status => Empty_Input);
      elsif Value'Length > Identity.Limits.Max_Public_Text_Bytes then
         return (Status => Too_Large);
      end if;

      for Index in Value'Range loop
         if Value (Index) = Separator then
            Separator_Count := Separator_Count + 1;
            Separator_Index := Index;
         end if;
      end loop;

      if Separator_Count = 0 then
         return (Status => Missing_Separator);
      elsif Separator_Count > 1 then
         return (Status => Multiple_Separators);
      elsif Separator_Index = Value'First then
         return (Status => Missing_Public_Part);
      elsif Separator_Index = Value'Last then
         return (Status => Missing_Secret_Part);
      else
         return
           (Status => Accepted,
            Public_Part =>
              Identity.Text.Bounded.From_String
                (Value (Value'First .. Separator_Index - 1)),
            Secret_Part =>
              Identity.Text.Bounded.From_String
                (Value (Separator_Index + 1 .. Value'Last)));
      end if;
   end Parse;

end Identity.Tokens.Generation;
