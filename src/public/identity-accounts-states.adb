package body Identity.Accounts.States is
   function Evaluate (State : Account_State_View) return Eligibility is
   begin
      if State.Administrative /= Enabled
        or else State.Lifecycle not in Pending_Activation | Active
        or else State.Lock_State in Indefinitely_Locked | Unlock_Pending
      then
         return Ineligible;
      end if;

      if State.Verification in Verification_Pending | Reverification_Required
        or else State.Lock_State = Temporarily_Locked
        or else State.Requirements.Password_Change_Required
        or else State.Requirements.MFA_Enrollment_Required
        or else State.Requirements.Credential_Reestablishment_Required
        or else State.Requirements.Recent_Authentication_Required
        or else State.Recovery.Restricted_Session
      then
         return Restricted;
      end if;

      return Eligible;
   end Evaluate;

   function Can_Apply
     (State      : Account_State_View;
      Transition : Account_State_Transition) return Boolean is
   begin
      if State.Administrative = Closed then
         return False;
      elsif State.Lifecycle = Retired then
         return False;
      elsif Transition = Close_Administrative then
         return True;
      end if;

      return True;
   end Can_Apply;

   function Apply
     (State      : Account_State_View;
      Transition : Account_State_Transition) return Account_State_View
   is
      Result : Account_State_View := State;
   begin
      if not Can_Apply (State, Transition) then
         return State;
      end if;

      case Transition is
         when Enable_Administrative =>
            Result.Administrative := Enabled;
         when Disable_Administrative =>
            Result.Administrative := Disabled;
         when Suspend_Administrative =>
            Result.Administrative := Suspended;
         when Close_Administrative =>
            Result.Administrative := Closed;
            Result.Lifecycle := Retired;
         when Unlock_Security =>
            Result.Lock_State := Not_Locked;
         when Require_Password_Change =>
            Result.Requirements.Password_Change_Required := True;
         when Require_MFA_Enrollment =>
            Result.Requirements.MFA_Enrollment_Required := True;
      end case;

      return Result;
   end Apply;
end Identity.Accounts.States;
