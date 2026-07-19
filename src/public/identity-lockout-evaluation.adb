with Identity.Times.Durations;

package body Identity.Lockout.Evaluation is
   function Evaluate
     (Failures  : Identity.Versions.Attempt_Count;
      Threshold : Identity.Versions.Attempt_Count) return Lockout_Decision is
   begin
      use type Identity.Versions.Attempt_Count;
      if Threshold = 0 then
         return Allow;
      elsif Failures >= Threshold then
         return Temporarily_Lock;
      else
         return Allow;
      end if;
   end Evaluate;

   function Evaluate_With_Policy
     (Failures : Identity.Versions.Attempt_Count;
      Policy   : Identity.Lockout.Policies.Lockout_Policy;
      Now      : Identity.Times.Instant) return Lockout_Transition
   is
      use type Identity.Versions.Attempt_Count;
      Until_Time : Identity.Times.Instant;
      Added      : Boolean;
   begin
      if Policy.Indefinite_Threshold > 0
        and then Failures >= Policy.Indefinite_Threshold
      then
         return
           (Decision => Indefinitely_Lock,
            Result_State => Identity.Lockout.States.Indefinitely_Locked,
            Locked_Until => (Present => False, Time_Point => 0),
            Time_Overflow => False);
      elsif Policy.Temporary_Threshold > 0
        and then Failures >= Policy.Temporary_Threshold
      then
         Until_Time :=
           Identity.Times.Add
             (Now,
              Identity.Times.Durations.To_Base (Policy.Temporary_Duration),
              Added);

         if Added then
            return
              (Decision => Temporarily_Lock,
               Result_State => Identity.Lockout.States.Temporarily_Locked,
               Locked_Until => (Present => True, Time_Point => Until_Time),
               Time_Overflow => False);
         else
            return
              (Decision => Indefinitely_Lock,
               Result_State => Identity.Lockout.States.Indefinitely_Locked,
               Locked_Until => (Present => False, Time_Point => 0),
               Time_Overflow => True);
         end if;
      else
         return
           (Decision => Allow,
            Result_State => Identity.Lockout.States.Not_Locked,
            Locked_Until => (Present => False, Time_Point => 0),
            Time_Overflow => False);
      end if;
   end Evaluate_With_Policy;
end Identity.Lockout.Evaluation;
