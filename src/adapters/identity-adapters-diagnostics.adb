package body Identity.Adapters.Diagnostics is
   function Accepts (Value : Diagnostic_Submission) return Diagnostic_Sink_Status is
   begin
      if not Identity.Events.Classification.Allowed_In_Ordinary_Event (Value.Class) then
         return Rejected;
      elsif Value.Class in Identity.Events.Classification.Personal | Identity.Events.Classification.Sensitive then
         return Redacted;
      else
         return Accepted;
      end if;
   end Accepts;
end Identity.Adapters.Diagnostics;
