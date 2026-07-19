with Identity.Accounts.States;

package Identity.Accounts.Verification is
   pragma Pure;
   use type Identity.Accounts.States.Verification_State;

   subtype Verification_State is Identity.Accounts.States.Verification_State;

   type Verification_Use is
     (Verification_Authentication, Verification_Protected_Workflow);

   type Verification_Admission_Status is
     (Verification_Admitted,
      Verification_Not_Required,
      Verification_Pending_Rejected,
      Reverification_Required_Rejected);

   function Admission
     (State : Verification_State;
      Usage : Verification_Use) return Verification_Admission_Status is
     (case State is
        when Identity.Accounts.States.No_Verification_Required =>
          (case Usage is
             when Verification_Authentication =>
               Verification_Admitted,
             when Verification_Protected_Workflow =>
               Verification_Not_Required),
        when Identity.Accounts.States.Verified =>
          Verification_Admitted,
        when Identity.Accounts.States.Verification_Pending =>
          Verification_Pending_Rejected,
        when Identity.Accounts.States.Reverification_Required =>
          Reverification_Required_Rejected);

   function Admission_Accepted
     (Status : Verification_Admission_Status) return Boolean is
     (Status in Verification_Admitted | Verification_Not_Required);

   function Admission_Rejected
     (Status : Verification_Admission_Status) return Boolean is
     (Status not in Verification_Admitted | Verification_Not_Required);

   function Verification_Not_Required_Status
     (Status : Verification_Admission_Status) return Boolean is
     (Status = Verification_Not_Required);

   function Pending_Rejection
     (Status : Verification_Admission_Status) return Boolean is
     (Status = Verification_Pending_Rejected);

   function Reverification_Rejection
     (Status : Verification_Admission_Status) return Boolean is
     (Status = Reverification_Required_Rejected);

   function Satisfies_Requirement (State : Verification_State) return Boolean is
     (Admission_Accepted (Admission (State, Verification_Authentication)));

   function Requires_Action (State : Verification_State) return Boolean is
     (State in Identity.Accounts.States.Verification_Pending | Identity.Accounts.States.Reverification_Required);
end Identity.Accounts.Verification;
