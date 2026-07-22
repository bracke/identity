with Identity.Crypto.Domains;
with Identity.Crypto.Secret_Verifiers;
with Identity.Events.Canonical;
with Identity.Secrets.Text;

package body Identity.Audit.Chain is

   --  The chain is a domain-separated keyed hash (the same construction the
   --  crate uses for every verifier), so it lives behind Secret_Verifiers and
   --  never imports the cryptolib backend directly. The event canonical form is
   --  public data, but the container is just a byte holder.
   function Head_Of (Material : String) return Chain_Head is
     (Identity.Crypto.Secret_Verifiers.Derive_Text
        (Identity.Crypto.Domains.Event_Integrity,
         Identity.Secrets.Text.From_UTF_8 (Material)));

   function Genesis return Chain_Head is
     (Head_Of ("identity.audit.chain.genesis"));

   function Extend
     (Previous : Chain_Head;
      Event    : Identity.Events.Envelopes.Event_Envelope) return Chain_Head is
     (Head_Of
        (Identity.Text.Bounded.Image (Previous)
         & "|"
         & Identity.Text.Bounded.Image
             (Identity.Events.Canonical.Encode (Event))));

   function Same_Head (Left, Right : Chain_Head) return Boolean is
     (Identity.Text.Bounded.Equal (Left, Right));
end Identity.Audit.Chain;
