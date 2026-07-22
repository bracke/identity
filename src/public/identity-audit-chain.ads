with Identity.Events.Envelopes;
with Identity.Text.Bounded;

--  A tamper-evident hash chain over the ordered audit events. The audit log is
--  immutable in the reference store, but a durable backend's administrator could
--  otherwise delete or reorder events undetectably. Each head commits to the
--  previous head and the next event's canonical encoding under the event-
--  integrity domain, so deleting, reordering, or modifying any event changes the
--  final head. Anchor the head externally (or compare it across time) and any
--  such tampering is detectable.
package Identity.Audit.Chain is

   subtype Chain_Head is Identity.Text.Bounded.Bounded_Text;

   --  The head before any event -- a fixed domain-separated seed.
   function Genesis return Chain_Head;

   --  Fold the next event into the chain: the new head depends on both the
   --  previous head and this event's canonical form.
   function Extend
     (Previous : Chain_Head;
      Event    : Identity.Events.Envelopes.Event_Envelope) return Chain_Head;

   function Same_Head (Left, Right : Chain_Head) return Boolean;
end Identity.Audit.Chain;
