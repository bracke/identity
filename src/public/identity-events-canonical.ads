with Identity.Events.Envelopes;
with Identity.Text.Bounded;

package Identity.Events.Canonical is
   function Encode
     (Event : Identity.Events.Envelopes.Event_Envelope)
      return Identity.Text.Bounded.Bounded_Text;
end Identity.Events.Canonical;
