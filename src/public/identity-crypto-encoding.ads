with Identity.Identifiers.Registry;
with Identity.Text.Bounded;
with Identity.Versions;

package Identity.Crypto.Encoding is
   pragma Pure;

   function Canonical_Input
     (Version : Identity.Versions.Format_Version;
      Domain  : Identity.Identifiers.Registry.Registry_Id;
      Payload : Identity.Text.Bounded.Bounded_Text) return Identity.Text.Bounded.Bounded_Text
     with Pre => Identity.Text.Bounded.Length (Payload) <= 384;
end Identity.Crypto.Encoding;
