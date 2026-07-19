package body Identity.Operations.Audit is
   package Stores renames Identity.Adapters.Repositories.Stores;
   package Envelopes renames Identity.Events.Envelopes;

   use type Stores.Command_Status;

   function Outcome_Of
     (Status : Stores.Command_Status) return Envelopes.Event_Outcome is
     (case Status is
        when Stores.Applied => Envelopes.Succeeded,
        when Stores.Version_Conflict
           | Stores.State_Conflict
           | Stores.Uniqueness_Conflict => Envelopes.Conflict,
        when Stores.Capacity_Conflict => Envelopes.Failed);

   function Severity_Of
     (Outcome : Envelopes.Event_Outcome) return Envelopes.Event_Severity is
     (case Outcome is
        when Envelopes.Succeeded => Envelopes.Informational,
        when Envelopes.Rejected  => Envelopes.Notice,
        when Envelopes.Conflict  => Envelopes.Warning,
        when Envelopes.Failed    => Envelopes.Error);

   function Subject_Of
     (Principal : Identity.Identifiers.Entities.Principal_Id)
      return Envelopes.Optional_Principal is
     ((Present => True, Value => Principal));

   function No_Subject return Envelopes.Optional_Principal is
     ((Present => False));

   function Envelope
     (Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Type_Id     : Identity.Identifiers.Registry.Registry_Id;
      Subject     : Envelopes.Optional_Principal;
      Target      : Identity.Text.Bounded.Bounded_Text;
      Outcome     : Envelopes.Event_Outcome;
      Severity    : Envelopes.Event_Severity;
      Recorded_At : Identity.Times.Instant)
      return Envelopes.Event_Envelope is
     ((Id          => Event,
       Type_Id     => Type_Id,
       Schema      => 1,
       Occurred_At => Context.Requested_At,
       Recorded_At => Recorded_At,
       Severity    => Severity,
       Correlation => Context.Correlation,
       Operation   => Context.Operation,
       Actor       => Context.Actor,
       Subject     => Subject,
       Target      => Target,
       Outcome     => Outcome));

   function Capacity_Reserved
     (Repository : Stores.Store_Interface'Class;
      Count      : Positive := 1) return Boolean is
     (Stores.Event_Capacity_Available (Repository, Count));

   function Emit
     (Repository : in out Stores.Store_Interface'Class;
      Event      : Envelopes.Event_Envelope) return Stores.Command_Status is
     (Stores.Append_Event (Repository, Event));

   function Emit
     (Repository  : in out Stores.Store_Interface'Class;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Type_Id     : Identity.Identifiers.Registry.Registry_Id;
      Subject     : Envelopes.Optional_Principal;
      Target      : Identity.Text.Bounded.Bounded_Text;
      Outcome     : Envelopes.Event_Outcome;
      Recorded_At : Identity.Times.Instant) return Stores.Command_Status
   is
   begin
      return Emit
        (Repository,
         Envelope
           (Context     => Context,
            Event       => Event,
            Type_Id     => Type_Id,
            Subject     => Subject,
            Target      => Target,
            Outcome     => Outcome,
            Severity    => Severity_Of (Outcome),
            Recorded_At => Recorded_At));
   end Emit;
end Identity.Operations.Audit;
