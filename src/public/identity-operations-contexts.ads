with Identity.Events.Envelopes;
with Identity.Identifiers.Operations;
with Identity.Operations.Cancellation;
with Identity.Operations.Disclosure;
with Identity.Times;

package Identity.Operations.Contexts is
   pragma Pure;

   type Optional_Causation (Present : Boolean := False) is record
      case Present is
         when True =>
            Value : Identity.Identifiers.Operations.Causation_Id;
         when False =>
            null;
      end case;
   end record;

   type Optional_Request_Context (Present : Boolean := False) is record
      case Present is
         when True =>
            Value : Identity.Identifiers.Operations.Request_Context_Id;
         when False =>
            null;
      end case;
   end record;

   type Operation_Context is record
      Operation     : Identity.Identifiers.Operations.Operation_Id;
      Correlation   : Identity.Identifiers.Operations.Correlation_Id;
      Causation     : Optional_Causation;
      Request       : Optional_Request_Context;
      Actor         : Identity.Events.Envelopes.Event_Actor;
      Requested_At  : Identity.Times.Instant;
      Deadline      : Identity.Times.Deadline;
      Cancellation  : Identity.Operations.Cancellation.Cancellation_Source;
      Disclosure    : Identity.Operations.Disclosure.Disclosure_Profile :=
        Identity.Operations.Disclosure.Untrusted_Interactive;
      Diagnostic_Mode : Boolean := False;
   end record;

   type Checkpoint_Status is (Continue, Cancelled, Deadline_Exceeded);
   type Deadline_Status is
     (No_Deadline, Before_Deadline, At_Deadline, Past_Deadline);

   function Deadline_Unbounded (Status : Deadline_Status) return Boolean is
     (Status = No_Deadline);

   function Deadline_Open (Status : Deadline_Status) return Boolean is
     (Status = Before_Deadline);

   function Deadline_At_Boundary (Status : Deadline_Status) return Boolean is
     (Status = At_Deadline);

   function Deadline_Past (Status : Deadline_Status) return Boolean is
     (Status = Past_Deadline);

   function Checkpoint_Allows_Progress
     (Status : Checkpoint_Status) return Boolean is
     (Status = Continue);

   function Checkpoint_Cancelled
     (Status : Checkpoint_Status) return Boolean is
     (Status = Cancelled);

   function Checkpoint_Deadline_Blocked
     (Status : Checkpoint_Status) return Boolean is
     (Status = Deadline_Exceeded);

   function Evaluate_Deadline
     (Context : Operation_Context;
      Now     : Identity.Times.Instant) return Deadline_Status;
   function Deadline_Exceeded
     (Context : Operation_Context;
      Now     : Identity.Times.Instant) return Boolean;

   function Cancellation_Requested (Context : Operation_Context) return Boolean;

   function Evaluate_Checkpoint
     (Context : Operation_Context;
      Now     : Identity.Times.Instant) return Checkpoint_Status;
end Identity.Operations.Contexts;
