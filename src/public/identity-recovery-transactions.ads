with Identity.Identifiers.Entities;
with Identity.Times;
with Identity.Versions;

package Identity.Recovery.Transactions is
   pragma Pure;

   type Recovery_Transaction_State is
     (Started,
      Evidence_Required,
      Evidence_Accepted,
      Additional_Evidence_Required,
      Approved,
      Credential_Reestablishment_Required,
      Restricted_Authentication_Established,
      Completed,
      Rejected,
      Attempt_Limit_Reached,
      Expired,
      Cancelled,
      Superseded);

   type Recovery_Transition_Status is
     (Applied, Unknown, State_Conflict, Version_Conflict, Capacity_Conflict);

   function Transition_Applied
     (Status : Recovery_Transition_Status) return Boolean is
     (Status = Applied);

   function Unknown_Transaction
     (Status : Recovery_Transition_Status) return Boolean is
     (Status = Unknown);

   function Conflict_Status
     (Status : Recovery_Transition_Status) return Boolean is
     (Status in State_Conflict | Version_Conflict | Capacity_Conflict);

   function State_Conflict_Status
     (Status : Recovery_Transition_Status) return Boolean is
     (Status = State_Conflict);

   function Version_Conflict_Status
     (Status : Recovery_Transition_Status) return Boolean is
     (Status = Version_Conflict);

   function Capacity_Conflict_Status
     (Status : Recovery_Transition_Status) return Boolean is
     (Status = Capacity_Conflict);

   function No_Mutation
     (Status : Recovery_Transition_Status) return Boolean is
     (Status /= Applied);

   type Recovery_Transaction_Action is
     (Begin_Recovery,
      Accept_Recovery_Evidence,
      Approve_Recovery,
      Require_Recovery_Credential_Reestablishment,
      Establish_Recovery_Restricted_Authentication,
      Complete_Recovery,
      Cancel_Recovery);

   type Recovery_Transaction_Admission_Status is
     (Recovery_Transaction_Admitted,
      Recovery_Transaction_State_Rejected,
      Recovery_Transaction_Terminal_Rejected);

   function Is_Terminal
     (State : Recovery_Transaction_State) return Boolean is
     (State in
        Restricted_Authentication_Established
        | Completed
        | Rejected
        | Attempt_Limit_Reached
        | Expired
        | Cancelled
        | Superseded);

   function Evidence_Phase
     (State : Recovery_Transaction_State) return Boolean is
     (State in Evidence_Required | Additional_Evidence_Required);

   function Evidence_Accepted_Phase
     (State : Recovery_Transaction_State) return Boolean is
     (State = Evidence_Accepted);

   function Approval_Phase
     (State : Recovery_Transaction_State) return Boolean is
     (State = Approved);

   function Credential_Reestablishment_Phase
     (State : Recovery_Transaction_State) return Boolean is
     (State = Credential_Reestablishment_Required);

   function Restricted_Authentication_Phase
     (State : Recovery_Transaction_State) return Boolean is
     (State = Restricted_Authentication_Established);

   function Successful_Terminal
     (State : Recovery_Transaction_State) return Boolean is
     (State in Restricted_Authentication_Established | Completed);

   function Failed_Terminal
     (State : Recovery_Transaction_State) return Boolean is
     (State in Rejected | Attempt_Limit_Reached | Expired | Cancelled | Superseded);

   function Cancelable_State
     (State : Recovery_Transaction_State) return Boolean is
     (not Is_Terminal (State));

   function Admission
     (State  : Recovery_Transaction_State;
      Action : Recovery_Transaction_Action)
      return Recovery_Transaction_Admission_Status is
     (case Action is
        when Begin_Recovery =>
          (if State = Started
           then Recovery_Transaction_Admitted
           elsif Is_Terminal (State)
           then Recovery_Transaction_Terminal_Rejected
           else Recovery_Transaction_State_Rejected),
        when Accept_Recovery_Evidence =>
          (if State in Evidence_Required | Additional_Evidence_Required
           then Recovery_Transaction_Admitted
           elsif Is_Terminal (State)
           then Recovery_Transaction_Terminal_Rejected
           else Recovery_Transaction_State_Rejected),
        when Approve_Recovery =>
          (if State = Evidence_Accepted
           then Recovery_Transaction_Admitted
           elsif Is_Terminal (State)
           then Recovery_Transaction_Terminal_Rejected
           else Recovery_Transaction_State_Rejected),
        when Require_Recovery_Credential_Reestablishment =>
          (if State = Approved
           then Recovery_Transaction_Admitted
           elsif Is_Terminal (State)
           then Recovery_Transaction_Terminal_Rejected
           else Recovery_Transaction_State_Rejected),
        when Establish_Recovery_Restricted_Authentication =>
          (if State in Approved | Credential_Reestablishment_Required
           then Recovery_Transaction_Admitted
           elsif Is_Terminal (State)
           then Recovery_Transaction_Terminal_Rejected
           else Recovery_Transaction_State_Rejected),
        when Complete_Recovery =>
          (if State in Evidence_Accepted | Approved
           then Recovery_Transaction_Admitted
           elsif Is_Terminal (State)
           then Recovery_Transaction_Terminal_Rejected
           else Recovery_Transaction_State_Rejected),
        when Cancel_Recovery =>
          (if State not in
                Restricted_Authentication_Established
                | Completed
                | Expired
                | Cancelled
                | Superseded
           then Recovery_Transaction_Admitted
           elsif Is_Terminal (State)
           then Recovery_Transaction_Terminal_Rejected
           else Recovery_Transaction_State_Rejected));

   function Admission_Accepted
     (Status : Recovery_Transaction_Admission_Status) return Boolean is
     (Status = Recovery_Transaction_Admitted);

   function Admission_Rejected
     (Status : Recovery_Transaction_Admission_Status) return Boolean is
     (Status /= Recovery_Transaction_Admitted);

   function Admission_State_Rejected
     (Status : Recovery_Transaction_Admission_Status) return Boolean is
     (Status = Recovery_Transaction_State_Rejected);

   function Admission_Terminal_Rejected
     (Status : Recovery_Transaction_Admission_Status) return Boolean is
     (Status = Recovery_Transaction_Terminal_Rejected);

   type Recovery_Transaction_Record is record
      Id         : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal  : Identity.Identifiers.Entities.Principal_Id;
      Account    : Identity.Identifiers.Entities.Account_Id;
      Created_At : Identity.Times.Instant := 0;
      Expires_At : Identity.Times.Expiration;
      State      : Recovery_Transaction_State := Started;
      Version    : Identity.Versions.Entity_Version := 0;
   end record;

   function Can_Accept_Evidence
     (State : Recovery_Transaction_State) return Boolean is
     (Admission_Accepted
        (Admission (State, Accept_Recovery_Evidence)));

   function Can_Begin
     (State : Recovery_Transaction_State) return Boolean is
     (Admission_Accepted (Admission (State, Begin_Recovery)));

   function Expired_At
     (Transaction : Recovery_Transaction_Record;
      Now         : Identity.Times.Instant) return Boolean is
     (Identity.Times.Expired (Now, Transaction.Expires_At));

   function Can_Complete
     (State : Recovery_Transaction_State) return Boolean is
     (Admission_Accepted (Admission (State, Complete_Recovery)));

   function Can_Approve
     (State : Recovery_Transaction_State) return Boolean is
     (Admission_Accepted (Admission (State, Approve_Recovery)));

   function Can_Require_Credential_Reestablishment
     (State : Recovery_Transaction_State) return Boolean is
     (Admission_Accepted
        (Admission (State, Require_Recovery_Credential_Reestablishment)));

   function Can_Establish_Restricted_Authentication
     (State : Recovery_Transaction_State) return Boolean is
     (Admission_Accepted
        (Admission (State, Establish_Recovery_Restricted_Authentication)));

   function Requires_Credential_Reestablishment
     (State : Recovery_Transaction_State) return Boolean is
     (State = Credential_Reestablishment_Required);

   function Can_Cancel
     (State : Recovery_Transaction_State) return Boolean is
     (Admission_Accepted (Admission (State, Cancel_Recovery)));
end Identity.Recovery.Transactions;
