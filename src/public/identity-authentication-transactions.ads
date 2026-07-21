with Identity.Identifiers.Entities;
with Identity.Identifiers.Registry;
with Identity.Times;
with Identity.Versions;

package Identity.Authentication.Transactions is
   pragma Pure;

   type Authentication_Transaction_State is
     (Started,
      Primary_Evidence_Accepted,
      Additional_Factor_Required,
      Challenge_Issued,
      Challenge_Completed,
      Satisfied,
      Rejected,
      Expired,
      Cancelled,
      Consumed);

   type Authentication_Transaction_Status is
     (Applied, Unknown, State_Conflict, Version_Conflict, Capacity_Conflict);

   type Authentication_Transaction_Action is
     (Begin_Transaction,
      Issue_Challenge,
      Complete_Challenge,
      Satisfy_Transaction,
      Upgrade_Assurance,
      Consume_Transaction,
      Reject_Transaction,
      Cancel_Transaction);

   type Transaction_Admission_Status is
     (Transaction_Admitted, Transaction_Expired, Transaction_State_Rejected,
      Transaction_Evidence_Required);

   function Admission_Accepted
     (Status : Transaction_Admission_Status) return Boolean is
     (Status = Transaction_Admitted);

   function Admission_Rejected
     (Status : Transaction_Admission_Status) return Boolean is
     (Status /= Transaction_Admitted);

   function Expired_Rejected
     (Status : Transaction_Admission_Status) return Boolean is
     (Status = Transaction_Expired);

   function State_Rejected
     (Status : Transaction_Admission_Status) return Boolean is
     (Status = Transaction_State_Rejected);

   function Evidence_Required
     (Status : Transaction_Admission_Status) return Boolean is
     (Status = Transaction_Evidence_Required);

   function Command_Applied
     (Status : Authentication_Transaction_Status) return Boolean is
     (Status = Applied);

   function Unknown_Transaction
     (Status : Authentication_Transaction_Status) return Boolean is
     (Status = Unknown);

   function Conflict_Status
     (Status : Authentication_Transaction_Status) return Boolean is
     (Status in State_Conflict | Version_Conflict | Capacity_Conflict);

   function State_Conflict_Status
     (Status : Authentication_Transaction_Status) return Boolean is
     (Status = State_Conflict);

   function Version_Conflict_Status
     (Status : Authentication_Transaction_Status) return Boolean is
     (Status = Version_Conflict);

   function Capacity_Conflict_Status
     (Status : Authentication_Transaction_Status) return Boolean is
     (Status = Capacity_Conflict);

   function No_Mutation
     (Status : Authentication_Transaction_Status) return Boolean is
     (Status /= Applied);

   type Authentication_Transaction_Record is record
      Id                : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal         : Identity.Identifiers.Entities.Principal_Id;
      Requested_Profile : Identity.Identifiers.Registry.Registry_Id;
      Created_At        : Identity.Times.Instant := 0;
      Expires_At        : Identity.Times.Expiration;
      State             : Authentication_Transaction_State := Started;
      Attempts          : Identity.Versions.Attempt_Count := 0;
      Evidence_Count    : Natural := 0;
      Version           : Identity.Versions.Entity_Version := 0;
   end record;

   type Authentication_Transaction_Projection is record
      Id                : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal         : Identity.Identifiers.Entities.Principal_Id;
      Requested_Profile : Identity.Identifiers.Registry.Registry_Id;
      Created_At        : Identity.Times.Instant := 0;
      Expires_At        : Identity.Times.Expiration;
      State             : Authentication_Transaction_State := Started;
      Attempts          : Identity.Versions.Attempt_Count := 0;
      Evidence_Count    : Natural := 0;
      Version           : Identity.Versions.Entity_Version := 0;
      Expired           : Boolean := False;
   end record;

   function Summary
     (Transaction : Authentication_Transaction_Record;
      Now         : Identity.Times.Instant)
      return Authentication_Transaction_Projection is
     ((Id                => Transaction.Id,
       Principal         => Transaction.Principal,
       Requested_Profile => Transaction.Requested_Profile,
       Created_At        => Transaction.Created_At,
       Expires_At        => Transaction.Expires_At,
       State             => Transaction.State,
       Attempts          => Transaction.Attempts,
       Evidence_Count    => Transaction.Evidence_Count,
       Version           => Transaction.Version,
       Expired           => Identity.Times.Expired (Now, Transaction.Expires_At)));

   function Admission
     (State          : Authentication_Transaction_State;
      Action         : Authentication_Transaction_Action;
      Is_Expired     : Boolean := False;
      Evidence_Count : Natural := 0) return Transaction_Admission_Status is
     (if Is_Expired then Transaction_Expired
      else
        (case Action is
            when Begin_Transaction =>
              (if State = Started
               then Transaction_Admitted
               else Transaction_State_Rejected),
            when Issue_Challenge =>
              (if State in Primary_Evidence_Accepted | Additional_Factor_Required
               then Transaction_Admitted
               else Transaction_State_Rejected),
            when Complete_Challenge =>
              (if State = Challenge_Issued
               then Transaction_Admitted
               else Transaction_State_Rejected),
            when Satisfy_Transaction =>
              (if State /= Challenge_Completed then Transaction_State_Rejected
               elsif Evidence_Count = 0 then Transaction_Evidence_Required
               else Transaction_Admitted),
            when Upgrade_Assurance =>
              (if State = Satisfied
               then Transaction_Admitted
               else Transaction_State_Rejected),
            when Consume_Transaction =>
              (if State = Satisfied
               then Transaction_Admitted
               else Transaction_State_Rejected),
            when Reject_Transaction =>
              --  Policy or a failed factor denies the transaction; admissible
              --  from any live, non-terminal state.
              (if State not in Satisfied | Rejected | Expired | Cancelled | Consumed
               then Transaction_Admitted
               else Transaction_State_Rejected),
            when Cancel_Transaction =>
              (if State not in Satisfied | Rejected | Expired | Cancelled | Consumed
               then Transaction_Admitted
               else Transaction_State_Rejected)));

   function Admission
     (Transaction : Authentication_Transaction_Record;
      Action      : Authentication_Transaction_Action)
      return Transaction_Admission_Status is
     (Admission
        (Transaction.State,
         Action,
         False,
         Transaction.Evidence_Count));

   function Admission
     (Transaction : Authentication_Transaction_Projection;
      Action      : Authentication_Transaction_Action)
      return Transaction_Admission_Status is
     (Admission
        (Transaction.State,
         Action,
         Transaction.Expired,
         Transaction.Evidence_Count));

   function Can_Issue_Challenge
     (State : Authentication_Transaction_State) return Boolean is
     (Admission_Accepted (Admission (State, Issue_Challenge)));

   function Can_Issue_Challenge
     (Transaction : Authentication_Transaction_Projection) return Boolean is
     (Admission_Accepted (Admission (Transaction, Issue_Challenge)));

   function Can_Begin
     (State : Authentication_Transaction_State) return Boolean is
     (Admission_Accepted (Admission (State, Begin_Transaction)));

   function Can_Begin
     (Transaction : Authentication_Transaction_Projection) return Boolean is
     (Admission_Accepted (Admission (Transaction, Begin_Transaction)));

   function Can_Complete_Challenge
     (State : Authentication_Transaction_State) return Boolean is
     (Admission_Accepted (Admission (State, Complete_Challenge)));

   function Can_Complete_Challenge
     (Transaction : Authentication_Transaction_Projection) return Boolean is
     (Admission_Accepted (Admission (Transaction, Complete_Challenge)));

   function Can_Satisfy
     (Transaction : Authentication_Transaction_Record) return Boolean is
     (Admission_Accepted (Admission (Transaction, Satisfy_Transaction)));

   function Can_Satisfy
     (Transaction : Authentication_Transaction_Projection) return Boolean is
     (Admission_Accepted (Admission (Transaction, Satisfy_Transaction)));

   function Can_Upgrade_Assurance
     (State : Authentication_Transaction_State) return Boolean is
     (Admission_Accepted (Admission (State, Upgrade_Assurance)));

   function Can_Upgrade_Assurance
     (Transaction : Authentication_Transaction_Projection) return Boolean is
     (Admission_Accepted (Admission (Transaction, Upgrade_Assurance)));

   function Can_Consume
     (State : Authentication_Transaction_State) return Boolean is
     (Admission_Accepted (Admission (State, Consume_Transaction)));

   function Can_Consume
     (Transaction : Authentication_Transaction_Projection) return Boolean is
     (Admission_Accepted (Admission (Transaction, Consume_Transaction)));

   --  Primary_Evidence_Accepted is skipped by design: a transaction begins
   --  only after primary evidence (the password) has already been accepted, so
   --  Begin lands directly in Additional_Factor_Required. The state is retained
   --  as a valid Issue_Challenge precursor for flows that accept primary
   --  evidence inside the transaction.

   function Can_Reject
     (State : Authentication_Transaction_State) return Boolean is
     (Admission_Accepted (Admission (State, Reject_Transaction)));

   function Can_Cancel
     (State : Authentication_Transaction_State) return Boolean is
     (Admission_Accepted (Admission (State, Cancel_Transaction)));

   function Can_Cancel
     (Transaction : Authentication_Transaction_Projection) return Boolean is
     (Admission_Accepted (Admission (Transaction, Cancel_Transaction)));

   function Is_Terminal
     (State : Authentication_Transaction_State) return Boolean is
     (State in Rejected | Expired | Cancelled | Consumed);

   function Is_Terminal
     (Transaction : Authentication_Transaction_Projection) return Boolean is
     (Transaction.Expired or else Is_Terminal (Transaction.State));

   function Expired_At
     (Transaction : Authentication_Transaction_Record;
      Now         : Identity.Times.Instant) return Boolean is
     (Identity.Times.Expired (Now, Transaction.Expires_At));
end Identity.Authentication.Transactions;
