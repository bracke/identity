with Identity.Identifiers.Entities;
with Identity.Identifiers.Operations;
with Identity.Identifiers.Registry;
with Identity.Text.Bounded;
with Identity.Times;

package Identity.Events.Envelopes is
   pragma Pure;

   type Event_Severity is (Debug, Informational, Notice, Warning, Error, Critical);
   type Event_Outcome is (Succeeded, Rejected, Conflict, Failed);
   type Event_Actor_Kind is (Unauthenticated, Authenticated_Principal, Service_Principal, System_Principal);

   function Low_Severity (Severity : Event_Severity) return Boolean is
     (Severity in Debug | Informational | Notice);
   function Warning_Severity (Severity : Event_Severity) return Boolean is
     (Severity = Warning);
   function High_Severity (Severity : Event_Severity) return Boolean is
     (Severity in Error | Critical);
   function Critical_Severity (Severity : Event_Severity) return Boolean is
     (Severity = Critical);

   function Succeeded_Outcome (Outcome : Event_Outcome) return Boolean is
     (Outcome = Succeeded);
   function Rejected_Outcome (Outcome : Event_Outcome) return Boolean is
     (Outcome = Rejected);
   function Conflict_Outcome (Outcome : Event_Outcome) return Boolean is
     (Outcome = Conflict);
   function Failed_Outcome (Outcome : Event_Outcome) return Boolean is
     (Outcome = Failed);
   function Requires_Operational_Attention
     (Outcome : Event_Outcome) return Boolean is
     (Outcome in Conflict | Failed);

   function Unauthenticated_Actor
     (Kind : Event_Actor_Kind) return Boolean is
     (Kind = Unauthenticated);
   function Authenticated_Actor
     (Kind : Event_Actor_Kind) return Boolean is
     (Kind in Authenticated_Principal | Service_Principal | System_Principal);
   function Human_Actor (Kind : Event_Actor_Kind) return Boolean is
     (Kind = Authenticated_Principal);
   function Service_Actor (Kind : Event_Actor_Kind) return Boolean is
     (Kind = Service_Principal);
   function System_Actor (Kind : Event_Actor_Kind) return Boolean is
     (Kind = System_Principal);

   type Optional_Principal (Present : Boolean := False) is record
      case Present is
         when True =>
            Value : Identity.Identifiers.Entities.Principal_Id;
         when False =>
            null;
      end case;
   end record;

   type Event_Actor is record
      Kind      : Event_Actor_Kind := Unauthenticated;
      Principal : Optional_Principal;
   end record;

   type Event_Envelope is record
      Id            : Identity.Identifiers.Entities.Event_Id;
      Type_Id       : Identity.Identifiers.Registry.Registry_Id;
      Schema        : Positive := 1;
      Occurred_At   : Identity.Times.Instant := 0;
      Recorded_At   : Identity.Times.Instant := 0;
      Severity      : Event_Severity := Informational;
      Correlation   : Identity.Identifiers.Operations.Correlation_Id;
      Operation     : Identity.Identifiers.Operations.Operation_Id;
      Actor         : Event_Actor;
      Subject       : Optional_Principal;
      Target        : Identity.Text.Bounded.Bounded_Text;
      Outcome       : Event_Outcome := Succeeded;
   end record;
end Identity.Events.Envelopes;
