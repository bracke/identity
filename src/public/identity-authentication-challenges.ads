with Identity.Identifiers.Entities;
with Identity.Identifiers.Registry;
with Identity.Times;
with Identity.Versions;

package Identity.Authentication.Challenges is
   pragma Pure;

   type Challenge_State is (Issued, Completed, Failed, Expired, Cancelled);

   type Challenge_Action is
     (Issue_Action, Record_Failure_Action, Retry_Action, Cancel_Action);

   type Challenge_Action_Admission is
     (Challenge_Action_Admitted, Challenge_Expired_By_Time,
      Challenge_State_Rejected, Challenge_Terminal_Rejected);

   function Action_Admission_Accepted
     (Status : Challenge_Action_Admission) return Boolean is
     (Status = Challenge_Action_Admitted);

   function Action_Admission_Rejected
     (Status : Challenge_Action_Admission) return Boolean is
     (Status /= Challenge_Action_Admitted);

   function Action_Expired_Rejected
     (Status : Challenge_Action_Admission) return Boolean is
     (Status = Challenge_Expired_By_Time);

   function Action_State_Rejected
     (Status : Challenge_Action_Admission) return Boolean is
     (Status = Challenge_State_Rejected);

   function Action_Terminal_Rejected
     (Status : Challenge_Action_Admission) return Boolean is
     (Status = Challenge_Terminal_Rejected);

   type Challenge_Completion_Admission is
     (Admitted,
      Already_Completed,
      Failed_State,
      Expired_State,
      Cancelled_State,
      Expired_By_Time);

   function Completion_Admitted
     (Status : Challenge_Completion_Admission) return Boolean is
     (Status = Admitted);

   function Completion_Rejected
     (Status : Challenge_Completion_Admission) return Boolean is
     (Status /= Admitted);

   function Already_Completed_Rejected
     (Status : Challenge_Completion_Admission) return Boolean is
     (Status = Already_Completed);

   function State_Rejected
     (Status : Challenge_Completion_Admission) return Boolean is
     (Status in Already_Completed | Failed_State | Expired_State | Cancelled_State);

   function Expiration_Rejected
     (Status : Challenge_Completion_Admission) return Boolean is
     (Status in Expired_State | Expired_By_Time);

   function No_Mutation
     (Status : Challenge_Completion_Admission) return Boolean is
     (Status /= Admitted);

   type Challenge_Record is record
      Id          : Identity.Identifiers.Entities.Challenge_Id;
      Transaction : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal   : Identity.Identifiers.Entities.Principal_Id;
      Method      : Identity.Identifiers.Registry.Registry_Id;
      Created_At  : Identity.Times.Instant := 0;
      Expires_At  : Identity.Times.Expiration;
      State       : Challenge_State := Issued;
      Attempts    : Identity.Versions.Attempt_Count := 0;
      Version     : Identity.Versions.Entity_Version := 0;
   end record;

   type Challenge_Projection is record
      Id          : Identity.Identifiers.Entities.Challenge_Id;
      Transaction : Identity.Identifiers.Entities.Authentication_Transaction_Id;
      Principal   : Identity.Identifiers.Entities.Principal_Id;
      Method      : Identity.Identifiers.Registry.Registry_Id;
      Created_At  : Identity.Times.Instant := 0;
      Expires_At  : Identity.Times.Expiration;
      State       : Challenge_State := Issued;
      Attempts    : Identity.Versions.Attempt_Count := 0;
      Version     : Identity.Versions.Entity_Version := 0;
      Expired     : Boolean := False;
   end record;

   function Summary
     (Challenge : Challenge_Record;
      Now       : Identity.Times.Instant) return Challenge_Projection is
     ((Id          => Challenge.Id,
       Transaction => Challenge.Transaction,
       Principal   => Challenge.Principal,
       Method      => Challenge.Method,
       Created_At  => Challenge.Created_At,
       Expires_At  => Challenge.Expires_At,
       State       => Challenge.State,
       Attempts    => Challenge.Attempts,
       Version     => Challenge.Version,
       Expired     => Identity.Times.Expired (Now, Challenge.Expires_At)));

   function Admission
     (State      : Challenge_State;
      Action     : Challenge_Action;
      Is_Expired : Boolean := False) return Challenge_Action_Admission is
     (if Is_Expired then Challenge_Expired_By_Time
      else
        (case Action is
            when Issue_Action | Record_Failure_Action | Retry_Action =>
              (if State = Issued then Challenge_Action_Admitted
               elsif State in Completed | Failed | Expired | Cancelled
               then Challenge_Terminal_Rejected
               else Challenge_State_Rejected),
            when Cancel_Action =>
              (if State in Issued | Failed then Challenge_Action_Admitted
               elsif State in Completed | Expired | Cancelled
               then Challenge_Terminal_Rejected
               else Challenge_State_Rejected)));

   function Admission
     (Challenge : Challenge_Projection;
      Action    : Challenge_Action) return Challenge_Action_Admission is
     (Admission (Challenge.State, Action, Challenge.Expired));

   function Admission_Accepted
     (State  : Challenge_State;
      Action : Challenge_Action) return Boolean is
     (Action_Admission_Accepted (Admission (State, Action)));

   function Admission_Accepted
     (Challenge : Challenge_Projection;
      Action    : Challenge_Action) return Boolean is
     (Action_Admission_Accepted (Admission (Challenge, Action)));

   function Can_Issue (State : Challenge_State) return Boolean is
     (Admission_Accepted (State, Issue_Action));

   function Can_Issue (Challenge : Challenge_Projection) return Boolean is
     (Admission_Accepted (Challenge, Issue_Action));

   function Can_Record_Failure (State : Challenge_State) return Boolean is
     (Admission_Accepted (State, Record_Failure_Action));

   function Can_Record_Failure
     (Challenge : Challenge_Projection) return Boolean is
     (Admission_Accepted (Challenge, Record_Failure_Action));

   function Can_Retry (State : Challenge_State) return Boolean is
     (Admission_Accepted (State, Retry_Action));

   function Can_Retry (Challenge : Challenge_Projection) return Boolean is
     (Admission_Accepted (Challenge, Retry_Action));

   function Can_Cancel (State : Challenge_State) return Boolean is
     (Admission_Accepted (State, Cancel_Action));

   function Can_Cancel (Challenge : Challenge_Projection) return Boolean is
     (Admission_Accepted (Challenge, Cancel_Action));

   function Is_Terminal (State : Challenge_State) return Boolean is
     (State in Completed | Failed | Expired | Cancelled);

   function Is_Terminal (Challenge : Challenge_Projection) return Boolean is
     (Challenge.Expired or else Is_Terminal (Challenge.State));

   function Admit_Completion
     (Challenge : Challenge_Record;
      Now       : Identity.Times.Instant) return Challenge_Completion_Admission;
end Identity.Authentication.Challenges;
