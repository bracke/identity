with Identity.Lockout.Policies;
with Identity.Lockout.States;
with Identity.Times;
with Identity.Versions;

package Identity.Lockout.Evaluation is
   pragma Pure;

   type Lockout_Decision is (Allow, Temporarily_Lock, Indefinitely_Lock);

   type Lockout_Transition is record
      Decision      : Lockout_Decision := Allow;
      Result_State  : Identity.Lockout.States.Lock_State :=
        Identity.Lockout.States.Not_Locked;
      Locked_Until  : Identity.Times.Expiration;
      Time_Overflow : Boolean := False;
   end record;

   function Allows_Attempt (Decision : Lockout_Decision) return Boolean is
     (Decision = Allow);

   function Temporarily_Locks (Decision : Lockout_Decision) return Boolean is
     (Decision = Temporarily_Lock);

   function Indefinitely_Locks (Decision : Lockout_Decision) return Boolean is
     (Decision = Indefinitely_Lock);

   function Allows_Attempt
     (Transition : Lockout_Transition) return Boolean is
     (Allows_Attempt (Transition.Decision));

   function Temporarily_Locks
     (Transition : Lockout_Transition) return Boolean is
     (Temporarily_Locks (Transition.Decision));

   function Indefinitely_Locks
     (Transition : Lockout_Transition) return Boolean is
     (Indefinitely_Locks (Transition.Decision));

   function Overflowed_To_Indefinite
     (Transition : Lockout_Transition) return Boolean is
     (Transition.Time_Overflow and then Indefinitely_Locks (Transition));

   function Evaluate
     (Failures  : Identity.Versions.Attempt_Count;
      Threshold : Identity.Versions.Attempt_Count) return Lockout_Decision;

   function Evaluate_With_Policy
     (Failures : Identity.Versions.Attempt_Count;
      Policy   : Identity.Lockout.Policies.Lockout_Policy;
      Now      : Identity.Times.Instant) return Lockout_Transition;
end Identity.Lockout.Evaluation;
