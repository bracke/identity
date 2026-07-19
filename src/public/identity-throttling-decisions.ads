with Identity.Throttling.Policies;
with Identity.Times;
with Identity.Versions;

package Identity.Throttling.Decisions is
   pragma Pure;

   type Throttle_Decision_Kind is
     (Allow, Delay_Until, Reject_Until, Challenge_Required, Operational_Failure);

   type Throttle_Decision (Kind : Throttle_Decision_Kind := Allow) is record
      case Kind is
         when Delay_Until | Reject_Until =>
            Boundary : Identity.Times.Instant;
         when Allow | Challenge_Required | Operational_Failure =>
            null;
      end case;
   end record;

   function Allows_Request
     (Decision : Throttle_Decision) return Boolean is
     (Decision.Kind = Allow);

   function Delays_Request
     (Decision : Throttle_Decision) return Boolean is
     (Decision.Kind = Delay_Until);

   function Rejects_Request
     (Decision : Throttle_Decision) return Boolean is
     (Decision.Kind = Reject_Until);

   function Requires_Challenge
     (Decision : Throttle_Decision) return Boolean is
     (Decision.Kind = Challenge_Required);

   function Operational
     (Decision : Throttle_Decision) return Boolean is
     (Decision.Kind = Operational_Failure);

   function Has_Boundary
     (Decision : Throttle_Decision) return Boolean is
     (Decision.Kind in Delay_Until | Reject_Until);

   function Evaluate
     (Failures : Identity.Versions.Attempt_Count;
      Policy   : Identity.Throttling.Policies.Throttling_Policy;
      Now      : Identity.Times.Instant) return Throttle_Decision;
end Identity.Throttling.Decisions;
