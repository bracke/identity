with Identity.Accounts.States;
with Identity.Times;

package Identity.Accounts.Security_Locks is
   pragma Pure;
   use type Identity.Accounts.States.Security_Lock_State;

   subtype Security_Lock_State is Identity.Accounts.States.Security_Lock_State;

   type Lock_Evaluation is record
      State : Security_Lock_State := Identity.Accounts.States.Not_Locked;
      Temporary_Until : Identity.Times.Expiration;
   end record;

   function Allows_Attempt
     (Value : Lock_Evaluation;
      Now   : Identity.Times.Instant) return Boolean is
     (Value.State = Identity.Accounts.States.Not_Locked
      or else
        (Value.State = Identity.Accounts.States.Temporarily_Locked
         and then Identity.Times.Expired (Now, Value.Temporary_Until)));

   function Effective_State_At
     (Value : Lock_Evaluation;
      Now   : Identity.Times.Instant) return Security_Lock_State is
     (if Value.State = Identity.Accounts.States.Temporarily_Locked
        and then Identity.Times.Expired (Now, Value.Temporary_Until)
      then Identity.Accounts.States.Not_Locked
      else Value.State);
end Identity.Accounts.Security_Locks;
