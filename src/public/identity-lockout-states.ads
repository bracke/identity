with Identity.Times;

package Identity.Lockout.States is
   pragma Pure;

   type Lock_State is (Not_Locked, Temporarily_Locked, Indefinitely_Locked, Unlock_Pending);

   type Attempt_Admission_Status is
     (Attempt_Admitted,
      Temporary_Lock_Active,
      Indefinite_Lock_Active,
      Unlock_Pending_Active);

   function Attempt_Admission
     (Value           : Lock_State;
      Temporary_Until : Identity.Times.Expiration;
      Now             : Identity.Times.Instant) return Attempt_Admission_Status is
     (case Value is
        when Not_Locked =>
          Attempt_Admitted,
        when Temporarily_Locked =>
          (if Identity.Times.Expired (Now, Temporary_Until)
           then Attempt_Admitted
           else Temporary_Lock_Active),
        when Indefinitely_Locked =>
          Indefinite_Lock_Active,
        when Unlock_Pending =>
          Unlock_Pending_Active);

   function Admission_Accepted
     (Status : Attempt_Admission_Status) return Boolean is
     (Status = Attempt_Admitted);

   function Admission_Rejected
     (Status : Attempt_Admission_Status) return Boolean is
     (Status /= Attempt_Admitted);

   function Temporary_Rejection
     (Status : Attempt_Admission_Status) return Boolean is
     (Status = Temporary_Lock_Active);

   function Indefinite_Rejection
     (Status : Attempt_Admission_Status) return Boolean is
     (Status = Indefinite_Lock_Active);

   function Unlock_Pending_Rejection
     (Status : Attempt_Admission_Status) return Boolean is
     (Status = Unlock_Pending_Active);

   function Can_Attempt (Value : Lock_State) return Boolean is
     (Value = Not_Locked);

   function Can_Attempt_At
     (Value           : Lock_State;
      Temporary_Until : Identity.Times.Expiration;
      Now             : Identity.Times.Instant) return Boolean is
     (Admission_Accepted
        (Attempt_Admission (Value, Temporary_Until, Now)));

   function Effective_State_At
     (Value           : Lock_State;
      Temporary_Until : Identity.Times.Expiration;
      Now             : Identity.Times.Instant) return Lock_State is
     (if Value = Temporarily_Locked
        and then Identity.Times.Expired (Now, Temporary_Until)
      then Not_Locked
      else Value);
end Identity.Lockout.States;
