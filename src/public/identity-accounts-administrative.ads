with Identity.Accounts.States;
with Identity.Events.Envelopes;
with Identity.Identifiers.Operations;
with Identity.Identifiers.Registry;
with Identity.Times;
with Identity.Versions;

package Identity.Accounts.Administrative is
   pragma Pure;
   use type Identity.Accounts.States.Administrative_State;
   use type Identity.Events.Envelopes.Event_Actor_Kind;

   subtype Administrative_State is Identity.Accounts.States.Administrative_State;

   type Administrative_Transition_Admission_Status is
     (Administrative_Transition_Admitted,
      Invalid_Administrative_Actor,
      Invalid_Administrative_Reason,
      Invalid_Administrative_Operation,
      Invalid_Administrative_Correlation,
      Missing_Mandatory_Audit,
      Same_Administrative_State,
      Closed_Administrative_State);

   function Admission_Accepted
     (Status : Administrative_Transition_Admission_Status) return Boolean is
     (Status = Administrative_Transition_Admitted);

   function Admission_Rejected
     (Status : Administrative_Transition_Admission_Status) return Boolean is
     (Status /= Administrative_Transition_Admitted);

   function Actor_Rejected
     (Status : Administrative_Transition_Admission_Status) return Boolean is
     (Status = Invalid_Administrative_Actor);

   function Reason_Rejected
     (Status : Administrative_Transition_Admission_Status) return Boolean is
     (Status = Invalid_Administrative_Reason);

   function Operation_Rejected
     (Status : Administrative_Transition_Admission_Status) return Boolean is
     (Status = Invalid_Administrative_Operation);

   function Correlation_Rejected
     (Status : Administrative_Transition_Admission_Status) return Boolean is
     (Status = Invalid_Administrative_Correlation);

   function Mandatory_Audit_Rejected
     (Status : Administrative_Transition_Admission_Status) return Boolean is
     (Status = Missing_Mandatory_Audit);

   function Same_State_Rejected
     (Status : Administrative_Transition_Admission_Status) return Boolean is
     (Status = Same_Administrative_State);

   function Closed_State_Rejected
     (Status : Administrative_Transition_Admission_Status) return Boolean is
     (Status = Closed_Administrative_State);

   function Allows_Authentication (State : Administrative_State) return Boolean is
     (State = Identity.Accounts.States.Enabled);

   function May_Transition
     (Current : Administrative_State;
      Next    : Administrative_State) return Boolean is
     (Current /= Identity.Accounts.States.Closed
      and then not (Current = Next));

   type Administrative_Transition_Request is record
      Actor            : Identity.Events.Envelopes.Event_Actor;
      Reason           : Identity.Identifiers.Registry.Registry_Id;
      Operation        : Identity.Identifiers.Operations.Operation_Id;
      Correlation      : Identity.Identifiers.Operations.Correlation_Id;
      Requested_At     : Identity.Times.Instant;
      Expected_Version : Identity.Versions.Entity_Version;
      Previous_State   : Identity.Accounts.States.Administrative_State;
      New_State        : Identity.Accounts.States.Administrative_State;
      Mandatory_Audit  : Boolean := True;
   end record;

   function Structurally_Valid_Actor
     (Actor : Identity.Events.Envelopes.Event_Actor) return Boolean is
     (Actor.Kind /= Identity.Events.Envelopes.Unauthenticated
      and then Actor.Principal.Present);

   function Admission
     (Request : Administrative_Transition_Request)
      return Administrative_Transition_Admission_Status is
     (if not Structurally_Valid_Actor (Request.Actor)
      then Invalid_Administrative_Actor
      elsif not Identity.Identifiers.Registry.Is_Valid (Request.Reason)
      then Invalid_Administrative_Reason
      elsif Identity.Identifiers.Operations.To_String (Request.Operation)'Length = 0
      then Invalid_Administrative_Operation
      elsif Identity.Identifiers.Operations.To_String (Request.Correlation)'Length = 0
      then Invalid_Administrative_Correlation
      elsif not Request.Mandatory_Audit
      then Missing_Mandatory_Audit
      elsif Request.Previous_State = Request.New_State
      then Same_Administrative_State
      elsif Request.Previous_State = Identity.Accounts.States.Closed
      then Closed_Administrative_State
      else Administrative_Transition_Admitted);

   function Valid_Transition_Request
     (Request : Administrative_Transition_Request) return Boolean is
     (Admission_Accepted (Admission (Request)));
end Identity.Accounts.Administrative;
