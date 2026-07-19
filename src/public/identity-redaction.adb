package body Identity.Redaction is
   function Safe_For_Public_Output
     (Class : Identity.Events.Classification.Event_Data_Class) return Boolean is
     (Class in Identity.Events.Classification.Public | Identity.Events.Classification.Operational);

   function Public_Image
     (Class : Identity.Events.Classification.Event_Data_Class;
      Value : Identity.Text.Bounded.Bounded_Text) return Identity.Text.Bounded.Bounded_Text
   is
   begin
      if Safe_For_Public_Output (Class) then
         return Value;
      end if;

      return Identity.Text.Bounded.From_String ("[identity-redacted]");
   end Public_Image;
end Identity.Redaction;
