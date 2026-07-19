with Identity.Accounts.States;

package Identity.Accounts.Lifecycle is
   pragma Pure;
   use type Identity.Accounts.States.Lifecycle_State;

   subtype Lifecycle_State is Identity.Accounts.States.Lifecycle_State;

   type Lifecycle_Use is (Lifecycle_Authentication, Lifecycle_Mutation);

   type Lifecycle_Admission_Status is
     (Lifecycle_Admitted,
      Lifecycle_Pending_Rejected,
      Lifecycle_Expired_Rejected,
      Lifecycle_Retired_Rejected);

   function Admission
     (State : Lifecycle_State;
      Usage : Lifecycle_Use) return Lifecycle_Admission_Status is
     (case State is
        when Identity.Accounts.States.Active =>
          Lifecycle_Admitted,
        when Identity.Accounts.States.Pending_Activation =>
          Lifecycle_Pending_Rejected,
        when Identity.Accounts.States.Expired =>
          Lifecycle_Expired_Rejected,
        when Identity.Accounts.States.Retired =>
          (case Usage is
             when Lifecycle_Authentication | Lifecycle_Mutation =>
               Lifecycle_Retired_Rejected));

   function Admission_Accepted
     (Status : Lifecycle_Admission_Status) return Boolean is
     (Status = Lifecycle_Admitted);

   function Admission_Rejected
     (Status : Lifecycle_Admission_Status) return Boolean is
     (Status /= Lifecycle_Admitted);

   function Pending_Rejection
     (Status : Lifecycle_Admission_Status) return Boolean is
     (Status = Lifecycle_Pending_Rejected);

   function Expired_Rejection
     (Status : Lifecycle_Admission_Status) return Boolean is
     (Status = Lifecycle_Expired_Rejected);

   function Retired_Rejection
     (Status : Lifecycle_Admission_Status) return Boolean is
     (Status = Lifecycle_Retired_Rejected);

   function No_Mutation
     (Status : Lifecycle_Admission_Status) return Boolean is
     (Status /= Lifecycle_Admitted);

   function Allows_Authentication (State : Lifecycle_State) return Boolean is
     (Admission_Accepted (Admission (State, Lifecycle_Authentication)));

   function Terminal (State : Lifecycle_State) return Boolean is
     (State = Identity.Accounts.States.Retired);
end Identity.Accounts.Lifecycle;
