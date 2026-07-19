with Identity.Events.Envelopes;
with Identity.Identifiers.Entities;

package Identity.Projections.Events is
   pragma Pure;
   use type Identity.Events.Envelopes.Event_Actor_Kind;
   use type Identity.Events.Envelopes.Event_Outcome;
   use type Identity.Events.Envelopes.Event_Severity;
   use type Identity.Identifiers.Entities.Principal_Id;

   subtype Event_Projection is Identity.Events.Envelopes.Event_Envelope;

   function Actor_Is_Authenticated
     (Event : Event_Projection) return Boolean is
     (Event.Actor.Kind in Identity.Events.Envelopes.Authenticated_Principal
                        | Identity.Events.Envelopes.Service_Principal
                        | Identity.Events.Envelopes.System_Principal
      and then Event.Actor.Principal.Present);

   function Actor_Is_Unauthenticated
     (Event : Event_Projection) return Boolean is
     (Event.Actor.Kind = Identity.Events.Envelopes.Unauthenticated
      and then not Event.Actor.Principal.Present);

   function Has_Subject_Principal
     (Event : Event_Projection) return Boolean is
     (Event.Subject.Present);

   function Successful
     (Event : Event_Projection) return Boolean is
     (Event.Outcome = Identity.Events.Envelopes.Succeeded);

   function Rejected
     (Event : Event_Projection) return Boolean is
     (Event.Outcome = Identity.Events.Envelopes.Rejected);

   function Failed
     (Event : Event_Projection) return Boolean is
     (Event.Outcome = Identity.Events.Envelopes.Failed);

   function Actor_Matches_Subject
     (Event : Event_Projection) return Boolean is
     (Actor_Is_Authenticated (Event)
      and then Event.Subject.Present
      and then Event.Actor.Principal.Value = Event.Subject.Value);

   function Requires_Operational_Attention
     (Event : Event_Projection) return Boolean is
     (Event.Severity in Identity.Events.Envelopes.Error
                      | Identity.Events.Envelopes.Critical
      or else Event.Outcome in Identity.Events.Envelopes.Conflict
                            | Identity.Events.Envelopes.Failed);

   function High_Severity
     (Event : Event_Projection) return Boolean is
     (Event.Severity in Identity.Events.Envelopes.Error
                      | Identity.Events.Envelopes.Critical);
end Identity.Projections.Events;
