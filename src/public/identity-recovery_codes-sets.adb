package body Identity.Recovery_Codes.Sets is
   function Summary
     (Codes : Recovery_Code_Set_Record) return Recovery_Code_Set_Projection
   is
      Active_Count   : Natural range 0 .. Max_Codes_Per_Set := 0;
      Consumed_Count : Natural range 0 .. Max_Codes_Per_Set := 0;
      Revoked_Count  : Natural range 0 .. Max_Codes_Per_Set := 0;
   begin
      for Index in 1 .. Codes.Count loop
         case Codes.Codes (Index).State is
            when Active =>
               Active_Count := Active_Count + 1;
            when Consumed =>
               Consumed_Count := Consumed_Count + 1;
            when Revoked =>
               Revoked_Count := Revoked_Count + 1;
         end case;
      end loop;

      return
        (Id => Codes.Id,
         Principal => Codes.Principal,
         Created_At => Codes.Created_At,
         Version => Codes.Version,
         Count => Codes.Count,
         Active_Count => Active_Count,
         Consumed_Count => Consumed_Count,
         Revoked_Count => Revoked_Count);
   end Summary;
end Identity.Recovery_Codes.Sets;
