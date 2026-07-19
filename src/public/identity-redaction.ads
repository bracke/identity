with Identity.Events.Classification;
with Identity.Text.Bounded;

package Identity.Redaction is
   pragma Pure;

   function Safe_For_Public_Output
     (Class : Identity.Events.Classification.Event_Data_Class) return Boolean;

   function Requires_Redaction
     (Class : Identity.Events.Classification.Event_Data_Class) return Boolean is
     (not Safe_For_Public_Output (Class));

   function Public_Image
     (Class : Identity.Events.Classification.Event_Data_Class;
      Value : Identity.Text.Bounded.Bounded_Text) return Identity.Text.Bounded.Bounded_Text;
end Identity.Redaction;
