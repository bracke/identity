with Identity.Credentials.States;

package Identity.Credentials.Lifecycle is
   pragma Pure;
   use type Identity.Credentials.States.Credential_State;

   subtype Credential_State is Identity.Credentials.States.Credential_State;

   type Credential_Lifecycle_Action is
     (Activate_Credential,
      Begin_Factor_Enrollment,
      Complete_Factor_Enrollment,
      Remove_Factor,
      Issue_As_Active,
      Replacement_Predecessor,
      Replacement_Successor,
      Begin_Migration,
      Complete_Migration,
      Revoke_Credential);

   type Credential_Lifecycle_Admission_Status is
     (Credential_Lifecycle_Admitted,
      Credential_Active_Required,
      Credential_Inactive_Slot_Required,
      Credential_Terminal_Rejected,
      Credential_Successor_State_Rejected,
      Credential_Migration_State_Rejected);

   function Terminal (State : Credential_State) return Boolean is
     (State in Identity.Credentials.States.Retired | Identity.Credentials.States.Revoked);

   function Admission
     (State             : Credential_State;
      Action            : Credential_Lifecycle_Action;
      Target_State      : Credential_State := Identity.Credentials.States.Active)
      return Credential_Lifecycle_Admission_Status is
     (if Terminal (State)
      and then Action not in Complete_Factor_Enrollment | Complete_Migration
      then Credential_Terminal_Rejected
      else
        (case Action is
            when Activate_Credential =>
              (if State in Identity.Credentials.States.Created
                         | Identity.Credentials.States.Replacement_Pending
               then Credential_Lifecycle_Admitted
               else Credential_Inactive_Slot_Required),
            when Begin_Factor_Enrollment =>
              (if State = Identity.Credentials.States.Active
               then Credential_Inactive_Slot_Required
               else Credential_Lifecycle_Admitted),
            when Complete_Factor_Enrollment =>
              (if Target_State /= Identity.Credentials.States.Active
               then Credential_Successor_State_Rejected
               elsif State in Identity.Credentials.States.Active
                            | Identity.Credentials.States.Revoked
                            | Identity.Credentials.States.Retired
               then Credential_Inactive_Slot_Required
               else Credential_Lifecycle_Admitted),
            when Remove_Factor =>
              (if Terminal (State)
               then Credential_Terminal_Rejected
               else Credential_Lifecycle_Admitted),
            when Issue_As_Active | Replacement_Predecessor | Replacement_Successor
               | Begin_Migration | Revoke_Credential =>
              (if State = Identity.Credentials.States.Active
               then Credential_Lifecycle_Admitted
               else Credential_Active_Required),
            when Complete_Migration =>
              (if State /= Identity.Credentials.States.Migrating
               then Credential_Migration_State_Rejected
               elsif Target_State /= Identity.Credentials.States.Active
               then Credential_Successor_State_Rejected
               else Credential_Lifecycle_Admitted)));

   function Admission_Accepted
     (State        : Credential_State;
      Action       : Credential_Lifecycle_Action;
      Target_State : Credential_State := Identity.Credentials.States.Active) return Boolean is
     (Admission (State, Action, Target_State) = Credential_Lifecycle_Admitted);

   function Admission_Accepted
     (Status : Credential_Lifecycle_Admission_Status) return Boolean is
     (Status = Credential_Lifecycle_Admitted);

   function Admission_Rejected
     (Status : Credential_Lifecycle_Admission_Status) return Boolean is
     (Status /= Credential_Lifecycle_Admitted);

   function Active_Required_Rejection
     (Status : Credential_Lifecycle_Admission_Status) return Boolean is
     (Status = Credential_Active_Required);

   function Inactive_Slot_Rejection
     (Status : Credential_Lifecycle_Admission_Status) return Boolean is
     (Status = Credential_Inactive_Slot_Required);

   function Terminal_Rejection
     (Status : Credential_Lifecycle_Admission_Status) return Boolean is
     (Status = Credential_Terminal_Rejected);

   function Successor_State_Rejection
     (Status : Credential_Lifecycle_Admission_Status) return Boolean is
     (Status = Credential_Successor_State_Rejected);

   function Migration_State_Rejection
     (Status : Credential_Lifecycle_Admission_Status) return Boolean is
     (Status = Credential_Migration_State_Rejected);

   function No_Mutation
     (Status : Credential_Lifecycle_Admission_Status) return Boolean is
     (Status /= Credential_Lifecycle_Admitted);

   function Can_Activate (State : Credential_State) return Boolean is
     (Admission_Accepted (State, Activate_Credential));

   function Can_Begin_Factor_Enrollment (State : Credential_State) return Boolean is
     (Admission_Accepted (State, Begin_Factor_Enrollment));

   function Can_Complete_Factor_Enrollment
     (Stored_State    : Credential_State;
      Activated_State : Credential_State) return Boolean is
     (Admission_Accepted
        (Stored_State, Complete_Factor_Enrollment, Activated_State));

   function Can_Remove_Factor (State : Credential_State) return Boolean is
     (Admission_Accepted (State, Remove_Factor));

   function Occupies_Active_Slot (State : Credential_State) return Boolean is
     (State = Identity.Credentials.States.Active);

   function Can_Issue_As_Active (State : Credential_State) return Boolean is
     (Admission_Accepted (State, Issue_As_Active));

   function Can_Be_Replacement_Predecessor (State : Credential_State) return Boolean is
     (Admission_Accepted (State, Replacement_Predecessor));

   function Can_Be_Replacement_Successor (State : Credential_State) return Boolean is
     (Admission_Accepted (State, Replacement_Successor));

   function Can_Begin_Migration (State : Credential_State) return Boolean is
     (Admission_Accepted (State, Begin_Migration));

   function Can_Complete_Migration
     (Stored_State    : Credential_State;
      Completed_State : Credential_State) return Boolean is
     (Admission_Accepted (Stored_State, Complete_Migration, Completed_State));

   function Can_Revoke (State : Credential_State) return Boolean is
     (Admission_Accepted (State, Revoke_Credential));
end Identity.Credentials.Lifecycle;
