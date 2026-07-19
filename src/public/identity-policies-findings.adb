package body Identity.Policies.Findings is
   function Has_Warnings (Report : Finding_Report) return Boolean is
   begin
      for Index in 1 .. Report.Count loop
         if Warning_Severity (Report.Findings (Index).Severity) then
            return True;
         end if;
      end loop;

      return False;
   end Has_Warnings;

   function Has_Errors (Report : Finding_Report) return Boolean is
   begin
      for Index in 1 .. Report.Count loop
         if Error_Severity (Report.Findings (Index).Severity) then
            return True;
         end if;
      end loop;

      return False;
   end Has_Errors;
end Identity.Policies.Findings;
