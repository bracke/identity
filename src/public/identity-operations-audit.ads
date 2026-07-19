with Identity.Adapters.Repositories.Stores;
with Identity.Events.Envelopes;
with Identity.Identifiers.Entities;
with Identity.Identifiers.Registry;
with Identity.Operations.Contexts;
with Identity.Text.Bounded;
with Identity.Times;

--  Emission of the audit events that accompany security-relevant transitions.
--
--  Operations that change security state must leave a record. To keep the
--  transition and its record inseparable, callers reserve event capacity
--  BEFORE mutating (Capacity_Reserved) and append AFTER the transition
--  succeeds (Emit). A store that cannot accept the event refuses the operation
--  outright rather than applying a change nobody can audit.
package Identity.Operations.Audit is

   --  Map a repository command outcome onto the outcome recorded in the event.
   function Outcome_Of
     (Status : Identity.Adapters.Repositories.Stores.Command_Status)
      return Identity.Events.Envelopes.Event_Outcome;

   --  Severity follows the outcome unless the caller states otherwise;
   --  conflicts are operationally interesting, plain success is not.
   function Severity_Of
     (Outcome : Identity.Events.Envelopes.Event_Outcome)
      return Identity.Events.Envelopes.Event_Severity;

   function Subject_Of
     (Principal : Identity.Identifiers.Entities.Principal_Id)
      return Identity.Events.Envelopes.Optional_Principal;

   function No_Subject return Identity.Events.Envelopes.Optional_Principal;

   --  Build the envelope for one transition. Correlation, operation id and
   --  actor come from the operation context, so an event can always be tied
   --  back to the request that caused it.
   function Envelope
     (Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Type_Id     : Identity.Identifiers.Registry.Registry_Id;
      Subject     : Identity.Events.Envelopes.Optional_Principal;
      Target      : Identity.Text.Bounded.Bounded_Text;
      Outcome     : Identity.Events.Envelopes.Event_Outcome;
      Severity    : Identity.Events.Envelopes.Event_Severity;
      Recorded_At : Identity.Times.Instant)
      return Identity.Events.Envelopes.Event_Envelope;

   --  True when the store can still accept the events this operation must
   --  emit. Check before mutating.
   function Capacity_Reserved
     (Repository : Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Count      : Positive := 1) return Boolean;

   --  Append the event. Returns the append status so an operation can report
   --  a lost audit record rather than silently discarding it.
   function Emit
     (Repository : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Event      : Identity.Events.Envelopes.Event_Envelope)
      return Identity.Adapters.Repositories.Stores.Command_Status;

   --  Convenience: build and append in one step.
   function Emit
     (Repository  : in out
        Identity.Adapters.Repositories.Stores.Store_Interface'Class;
      Context     : Identity.Operations.Contexts.Operation_Context;
      Event       : Identity.Identifiers.Entities.Event_Id;
      Type_Id     : Identity.Identifiers.Registry.Registry_Id;
      Subject     : Identity.Events.Envelopes.Optional_Principal;
      Target      : Identity.Text.Bounded.Bounded_Text;
      Outcome     : Identity.Events.Envelopes.Event_Outcome;
      Recorded_At : Identity.Times.Instant)
      return Identity.Adapters.Repositories.Stores.Command_Status;
end Identity.Operations.Audit;
