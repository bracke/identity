package body Identity.Diagnostics is
   function Safe_Image (Value : Diagnostic_Record) return Identity.Text.Bounded.Bounded_Text is
   begin
      if Identity.Errors.Is_Failure (Value.Error) then
         return Value.Message;
      end if;

      return Identity.Text.Bounded.From_String ("identity.diagnostic.ok");
   end Safe_Image;
end Identity.Diagnostics;
