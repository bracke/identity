with Identity.Times.Durations;

package body Identity.Throttling.Decisions is

   function Evaluate
     (Failures : Identity.Versions.Attempt_Count;
      Policy   : Identity.Throttling.Policies.Throttling_Policy;
      Now      : Identity.Times.Instant) return Throttle_Decision
   is
      use type Identity.Versions.Attempt_Count;
      Boundary : Identity.Times.Instant;
      Added    : Boolean;
   begin
      if Failures < Policy.Delay_After then
         return (Kind => Allow);
      end if;

      Boundary :=
        Identity.Times.Add
          (Now,
           Identity.Times.Durations.To_Base (Policy.Delay_Duration),
           Added);

      if not Added then
         return (Kind => Operational_Failure);
      elsif Failures >= Policy.Reject_After then
         return (Kind => Reject_Until, Boundary => Boundary);
      else
         return (Kind => Delay_Until, Boundary => Boundary);
      end if;
   end Evaluate;

end Identity.Throttling.Decisions;
