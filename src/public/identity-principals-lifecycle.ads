with Identity.Principals.Definitions;

package Identity.Principals.Lifecycle is
   pragma Pure;
   use type Identity.Principals.Definitions.Principal_Lifecycle;

   subtype Principal_Lifecycle is Identity.Principals.Definitions.Principal_Lifecycle;

   type Principal_Lifecycle_Action is
     (Use_Principal, Retire_Principal, Reactivate_Principal);

   type Principal_Lifecycle_Admission_Status is
     (Principal_Lifecycle_Admitted,
      Principal_Retired_Rejected,
      Principal_Reactivation_Policy_Rejected);

   function Admission
     (State         : Principal_Lifecycle;
      Action        : Principal_Lifecycle_Action;
      Policy_Allows : Boolean := False)
      return Principal_Lifecycle_Admission_Status is
     (case Action is
        when Use_Principal | Retire_Principal =>
          (if State = Identity.Principals.Definitions.Active
           then Principal_Lifecycle_Admitted
           else Principal_Retired_Rejected),
        when Reactivate_Principal =>
          (if State = Identity.Principals.Definitions.Retired
              and then Policy_Allows
           then Principal_Lifecycle_Admitted
           elsif State = Identity.Principals.Definitions.Retired
           then Principal_Reactivation_Policy_Rejected
           else Principal_Lifecycle_Admitted));

   function Admission_Accepted
     (Status : Principal_Lifecycle_Admission_Status) return Boolean is
     (Status = Principal_Lifecycle_Admitted);

   function Admission_Rejected
     (Status : Principal_Lifecycle_Admission_Status) return Boolean is
     (Status /= Principal_Lifecycle_Admitted);

   function Retired_Rejection
     (Status : Principal_Lifecycle_Admission_Status) return Boolean is
     (Status = Principal_Retired_Rejected);

   function Reactivation_Policy_Rejection
     (Status : Principal_Lifecycle_Admission_Status) return Boolean is
     (Status = Principal_Reactivation_Policy_Rejected);

   function Active (State : Principal_Lifecycle) return Boolean is
     (Admission_Accepted (Admission (State, Use_Principal)));

   function May_Retire (State : Principal_Lifecycle) return Boolean is
     (Admission_Accepted (Admission (State, Retire_Principal)));

   function May_Reactivate
     (State          : Principal_Lifecycle;
      Policy_Allows  : Boolean) return Boolean is
     (Admission_Accepted
        (Admission (State, Reactivate_Principal, Policy_Allows))
      and then State = Identity.Principals.Definitions.Retired);
end Identity.Principals.Lifecycle;
